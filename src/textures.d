/*
    Copyright (c) 2014, Dennis Meuwissen
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

module textures;

import std.stdio;
import std.stream;
import std.string;

import wad;
import util;
import console;
import orderedaa;


// A patch that is part of a texture definition.
public struct TexturePatch {
    short offsetX;
    short offsetY;
    ushort patchIndex;
    string patchName;
}

// A texture definition.
public struct Texture {
    ushort width;
    ushort height;
    string name;
    TexturePatch[] patches;
}


public class TextureList {

    // A list of texture definitions.
    private OrderedAA!(string,Texture) mTextures;

    // Patch names, by index.
    private string[] mPatchNames;

    // If true, the textures that were last read from a WAD file were
    // in Strife 1.1 format.
    private bool mStrifeMode;


    this() {
        this.mTextures = new OrderedAA!(string,Texture);
    }

    this(WAD wad) {
        this();
        this.addFrom(wad);
    }

    this(MemoryStream data) {
        this();
        this.readTextures(data);
    }

    /**
     * Adds textures and patch names from a WAD file.
     * This will read the WAD's PNAMES and TEXTURE* lumps.
     *
     * @param wad
     * The WAD file to read the texture information from.
     */
    public void addFrom(WAD wad) {
        if (wad.containsLump("PNAMES") == false) {
            return;
        }
        if (wad.containsLump("TEXTURE1") == false) {
            return;
        }

        // Read patch names.
        Lump patches = wad.getLump("PNAMES");
        readPatchNames(patches.getStream());
        patches.setIsUsed(true);

        // Read texture lumps. If TEXTURE2 is present, add the textures from that lump as well.
        Lump texture1 = wad.getLump("TEXTURE1");
        this.readTextures(texture1.getStream());
        texture1.setIsUsed(true);
        if (wad.containsLump("TEXTURE2") == true) {
            Lump texture2 = wad.getLump("TEXTURE2");
            this.readTextures(texture2.getStream());
            texture2.setIsUsed(true);
        }
    }

    /**
     * Writes a PNAMES and TEXTURE1 lump containing this list's textures to a WAD file.
     *
     * @param wad
     * The WAD file to write the textures and patch names to.
     */
    public void writeTo(WAD wad) {
        // Create the data for a TEXTURES lump.
        MemoryStream textures = new MemoryStream();
        textures.write(cast(uint)this.mTextures.length);

        // Write offsets to the texture definitions in this data.
        uint offset = 4 + this.mTextures.length * 4;
        foreach (Texture texture; this.mTextures) {
            textures.write(offset);

            // The size of a normal texture definition is 22 bytes, 18 for Strife textures.
            // Each patch definition is 10 bytes or 6 for Strife patches.
            if (this.mStrifeMode == true) {
                offset += 18 + texture.patches.length * 6;
            } else {
                offset += 22 + texture.patches.length * 10;
            }
        }

        // Write texture definitions.
        foreach (Texture texture; this.mTextures) {
            textures.write(cast(ubyte[])leftJustify(texture.name, 8, '\0'));
            textures.write(cast(uint)0);
            textures.write(texture.width);
            textures.write(texture.height);

            if (this.mStrifeMode == false) {
                textures.write(cast(uint)0);
            }

            textures.write(cast(ushort)texture.patches.length);

            // Write the patch definitions for the current texture.
            foreach (TexturePatch patch; texture.patches) {
                textures.write(patch.offsetX);
                textures.write(patch.offsetY);
                textures.write(patch.patchIndex);

                if (this.mStrifeMode == false) {
                    textures.write(cast(uint)0);
                }
            }
        }

        // Create the data for a PNAMES lump.
        MemoryStream pnames = new MemoryStream();
        pnames.write(cast(uint)this.mPatchNames.length);
        foreach (string patchName; this.mPatchNames) {
            pnames.write(cast(ubyte[])leftJustify(patchName, 8, '\0'));
        }

        // Add the new lumps to the WAD file.
        wad.addLump(new Lump("TEXTURE1", textures.data()));
        wad.addLump(new Lump("PNAMES", pnames.data()));
    }

    /**
     * Merges the textures in this list with the textures from another list.
     * Texture names that already exist are overwritten if the other texture definition differs.
     *
     * @param otherList
     * The other TextureList object to merge with this one.
     */
    public void mergeWith(TextureList otherList) {
        foreach (ref Texture otherTexture; otherList.getTextures()) {
            
            // Overwrite the existing texture if the other texture differs.
            if (this.mTextures.contains(otherTexture.name)) {
                if (texturesAreEqual(otherTexture, this.mTextures[otherTexture.name]) != true) {
                    console.writeLine(Color.IMPORTANT, "Overwriting texture %s", otherTexture.name);
                    this.mTextures.update(otherTexture.name, otherTexture);
                }

            // If the texture name is new, just add it.
            } else {
                this.mTextures.add(otherTexture.name, otherTexture);
            }
        }
    }

    /**
     * Updates the patch names array and texture patch indices.
     * This should normally be called after modifications have been made to the textures or patches,
     * so that a valid TEXTURE lump can be written from this texture list.
     */
    public void updatePatchNames() {
        uint[string] patchIndices;

        this.mPatchNames.length = 0;
        foreach (ref Texture texture; this.mTextures) {
            foreach (ref TexturePatch patch; texture.patches) {
                // Add patch indices for newly encountered patch names.
                if (!(patch.patchName in patchIndices)) {
                    this.mPatchNames ~= patch.patchName;
                    patchIndices[patch.patchName] = this.mPatchNames.length - 1;
                }

                // Set the patch index from the indices list.
                patch.patchIndex = cast(ushort)patchIndices[patch.patchName];
            }
        }
    }

    /**
     * Sorts the textures in this list by name. Patch names are unaffected.
     */
    public void sort() {
        this.mTextures.sort();
    }

    private void readTextures(MemoryStream data) {
        uint textureCount;
        uint[] textureOffsets;

        data.seek(0, SeekPos.Set);

        // Allocate room for the amount of textures in the texture lump.
        data.read(textureCount);
        textureOffsets = new uint[textureCount];
        for (int index; index < textureCount; index++) {
            data.read(textureOffsets[index]);
        }

        ushort unused;
        ushort patchCount;
        foreach (uint textureIndex, uint offset; textureOffsets) {
            data.seek(offset, SeekPos.Set);

            Texture texture;
            texture.name = readPaddedString(data, 8);
            data.read(unused);
            data.read(unused);
            data.read(texture.width);
            data.read(texture.height);
            data.read(unused);

            // Strife 1.1 texture lumps do not store some unused bytes.
            if (unused != 0) {
                patchCount = cast(ushort)unused;
                this.mStrifeMode = true;
            } else {
                data.read(unused);
                data.read(patchCount);
            }

            for (uint patchIndex; patchIndex < patchCount; patchIndex++) {
                TexturePatch patch;

                data.read(patch.offsetX);
                data.read(patch.offsetY);
                data.read(patch.patchIndex);
                patch.patchName = this.mPatchNames[patch.patchIndex];

                if (this.mStrifeMode == false) {
                    data.read(unused);
                    data.read(unused);
                }

                texture.patches ~= patch;
            }

            this.mTextures.add(cast(string)texture.name, texture);
        }
    }

    private void readPatchNames(MemoryStream data) {
        uint count;
        data.read(count);

        this.mPatchNames.length = 0;
        for (int index = 0; index < count; index++) {
            this.mPatchNames ~= readPaddedString(data, 8).dup;
        }
    }

    private bool texturesAreEqual(Texture a, Texture b) {
        if (a.name != b.name) { return false; }
        if (a.width != b.width) { return false; }
        if (a.height != b.height) { return false; }
        if (a.patches.length != b.patches.length) { return false; }

        for (int index = 0; index < a.patches.length; index++) {
            if (a.patches[index].offsetX != b.patches[index].offsetX) { return false; }
            if (a.patches[index].offsetY != b.patches[index].offsetY) { return false; }
            if (a.patches[index].patchName != b.patches[index].patchName) { return false; }
        }

        return true;
    }

    public OrderedAA!(string,Texture) getTextures() {
        return this.mTextures;
    }
    
    public void setStrifeMode(bool strifeMode) {
        this.mStrifeMode = strifeMode;
    }

    public bool getStrifeMode() {
        return this.mStrifeMode;
    }
}
