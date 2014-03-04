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


public struct TexturePatch {
    short offsetX;
    short offsetY;
    ushort patchIndex;
    string patchName;
}

public struct Texture {
    ushort width;
    ushort height;
    string name;
    TexturePatch[] patches;
}


public class TextureList {
    private OrderedAA!(string,Texture) mTextures;
    private string[] mPatchNames;
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
        this.addFrom(data);
    }

    public void addFrom(WAD wad) {
        if (wad.containsLump("PNAMES") == false) {
            return;
        }
        if (wad.containsLump("TEXTURE1") == false) {
            return;
        }

        Lump patches = wad.getLump("PNAMES");
        readPatchNames(patches.getStream());
        patches.setIsUsed(true);

        Lump texture1 = wad.getLump("TEXTURE1");
        this.addFrom(texture1.getStream());
        texture1.setIsUsed(true);

        if (wad.containsLump("TEXTURE2") == true) {
            Lump texture2 = wad.getLump("TEXTURE2");
            this.addFrom(texture2.getStream());
            texture2.setIsUsed(true);
        }
    }

    public void addFrom(MemoryStream data) {
        uint textureCount;
        uint[] textureOffsets;

        data.seek(0, SeekPos.Set);

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

            // Detect Strife 1.1 format.
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

    public void writeTo(WAD wad) {
        MemoryStream textures = new MemoryStream();
        textures.write(cast(uint)this.mTextures.length);
        uint offset = 4 + this.mTextures.length * 4;
        foreach (Texture texture; this.mTextures) {
            textures.write(offset);

            if (this.mStrifeMode == true) {
                offset += 18 + texture.patches.length * 6;
            } else {
                offset += 22 + texture.patches.length * 10;
            }
        }
        foreach (Texture texture; this.mTextures) {
            textures.write(cast(ubyte[])leftJustify(texture.name, 8, '\0'));
            textures.write(cast(uint)0);
            textures.write(texture.width);
            textures.write(texture.height);
            if (this.mStrifeMode == false) {
                textures.write(cast(uint)0);
            }
            textures.write(cast(ushort)texture.patches.length);

            foreach (TexturePatch patch; texture.patches) {
                textures.write(patch.offsetX);
                textures.write(patch.offsetY);
                textures.write(patch.patchIndex);
                if (this.mStrifeMode == false) {
                    textures.write(cast(uint)0);
                }
            }
        }
        Lump texturesLump = new Lump("TEXTURE1");
        texturesLump.putData(textures.data());
        wad.addLump(texturesLump);

        MemoryStream pnames = new MemoryStream();
        pnames.write(cast(uint)this.mPatchNames.length);
        foreach (string patchName; this.mPatchNames) {
            pnames.write(cast(ubyte[])leftJustify(patchName, 8, '\0'));
        }
        Lump pnamesLump = new Lump("PNAMES");
        pnamesLump.putData(pnames.data());
        wad.addLump(pnamesLump);
    }

    public void mergeWith(TextureList otherList) {
        OrderedAA!(string,Texture) otherTextures = otherList.getTextures();
        uint index;

        foreach (ref Texture otherTexture; otherTextures) {
            if (this.mTextures.contains(otherTexture.name)) {
                index = this.mTextures.indexOf(otherTexture.name);

                // Overwrite
                if (texturesAreEqual(otherTexture, this.mTextures[index]) != true) {
                    console.writeLine(Color.IMPORTANT, "Overwriting texture %s", otherTexture.name);
                    this.mTextures.update(otherTexture.name, otherTexture);
                }

            // Add
            } else {
                this.mTextures.add(otherTexture.name, otherTexture);
            }
        }
    }

    public void updatePatchNames() {
        uint[string] patchIndices;

        this.mPatchNames.length = 0;

        foreach (ref Texture texture; this.mTextures) {
            foreach (ref TexturePatch patch; texture.patches) {
                if (!(patch.patchName in patchIndices)) {
                    this.mPatchNames ~= patch.patchName;
                    patchIndices[patch.patchName] = this.mPatchNames.length - 1;
                }

                patch.patchIndex = cast(ushort)patchIndices[patch.patchName];
            }
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

    public void sort() {
        this.mTextures.sort();
    }

    public OrderedAA!(string,Texture) getTextures() {
        return this.mTextures;
    }

    public bool containsTexture(string name) {
        return this.mTextures.contains(name);
    }

    public void setStrifeMode(bool strifeMode) {
        this.mStrifeMode = strifeMode;
    }

    public bool getStrifeMode() {
        return this.mStrifeMode;
    }
}
