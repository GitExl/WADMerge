/*
    Copyright (c) 2015, Dennis Meuwissen
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

module textlist;

import textlumps;
import orderedaa;
import util;
import wad;
import console;
import duplicatelist;


/// A text lump and it's contents.
private struct TextLump {
    string name;
    ubyte[] contents;
    
    WAD wad;
    Lump lump;
}


/**
 * A text list contains all text lumps found in a WAD file. It concatenates existing ones when they are added.
 * No regard is taken for text file encoding, they are simply treated as arrays of bytes.
 */
public final class TextList {

    /// The text lumps in this list.
    private OrderedAA!(string,TextLump*) mTextLumps;


    this() {
        this.mTextLumps = new OrderedAA!(string,TextLump*);
    }

    /**
     * Adds text lumps found in a WAD file to this list. If a text lump already exists, it will be
     * extended with the text of the new lump.
     *
     * Params:
     * wad = The WAD file to add text lumps from.
     */
    public DuplicateList readFrom(WAD wad) {
        string lumpName;
        TextLump* text;

        DuplicateList dupes = new DuplicateList();

        foreach (Lump lump; wad.getLumps()) {
            lumpName = lump.getName();

            if (lump.isUsed() == false && isTextLump(lumpName) == true) {

                // Add lump contents to an existing text lump.
                if (this.mTextLumps.contains(lumpName) == true) {
                    TextLump* other = this.mTextLumps[lumpName];
                    dupes.add("text lump", other.wad, other.name, other.lump.getIndex(), lump.getWAD(), lumpName, lump.getIndex(), true);

                    console.writeLine(Color.INFO, "Merging text lump %s", lumpName);

                    TextLump* text = this.mTextLumps.get(lumpName, null);
                    text.contents ~= cast(ubyte[])"\n";
                    text.contents ~= lump.getData();
                    text.lump = lump;
                    text.wad = wad;

                // Create a new text lump.
                } else {
                    text = new TextLump();
                    text.name = lumpName;
                    text.contents = lump.getData().dup;
                    text.wad = wad;
                    text.lump = lump;
                    this.mTextLumps.add(lumpName, text);
                }

                lump.setIsUsed(true);
            }
        }

        return dupes;
    }

    /**
     * Adds the text lumps from this list to a WAD file.
     *
     * Params:
     * wad = The WAD file to add the text lumps to.
     */
    public void addTo(WAD wad) {
        foreach (TextLump* text; this.mTextLumps) {
            wad.addLump(new Lump(text.name, text.contents));
        }
    }

    /**
     * Sorts the text lumps in this list.
     */
    public void sort() {
        this.mTextLumps.sort();
    }

    private bool isTextLump(const string name) {
        return (getArrayIndex(TEXT_LUMPS, name) != -1);
    }
}
