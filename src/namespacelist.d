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

module namespacelist;

import std.string;
import std.stdio;

import wad;
import console;
import orderedaa;


// A namespace groups lumps by their type.
struct Namespace {
    // The name of this namespace. SS, FF, PP, etc.
    string name;

    // The list of lumps contained in this namespace.
    OrderedAA!(string,Lump) lumps;
}


class NamespaceList {

    // The namespaces in this namespace list.
    private Namespace[string] mNamespaces;

    // Loose lump namespace.
    private Namespace mLoose;


    this() {
        this.mLoose.lumps = new OrderedAA!(string,Lump);
    }

    /**
     * Adds namespaces and their lumps from a WAD's contents.
     *
     * @param wad
     * The WAD file to add namespaces from.
     */
    public void addFrom(WAD wad) {
        Namespace* namespace;
        string name;
        string lumpName;
        uint lumpSize;
        int nameIndex;

        foreach (Lump lump; wad.getLumps()) {
            lumpName = lump.getName();
            lumpSize = lump.getSize();

            // Namespaces start with a 0 size lump that ends in _START.
            if (namespace is null && lumpSize == 0) {
                nameIndex = indexOf(lumpName, "_START");
                if (nameIndex > 0) {
                    name = lumpName[0..nameIndex];

                    // Turn known IWAD namespaces into patch wad namespaces.
                    // Also takes care of the edge case where the starting marker's name does not match the ending marker's name.
                    if (name == "F" || name == "F1" || name == "F2" || name == "F3") {
                        name = "FF";
                    } else if (name == "S") {
                        name = "SS";
                    } else if (name == "P" || name == "P1" || name == "P2" || name == "P3") {
                        name = "PP";
                    }

                    // Either reuse an existing namespace or create a new one.
                    if (name in this.mNamespaces) {
                        namespace = &this.mNamespaces[name];
                    } else {
                        namespace = new Namespace();
                        namespace.name = name;
                        namespace.lumps = new OrderedAA!(string,Lump);
                        this.mNamespaces[namespace.name] = *namespace;
                    }

                    lump.setIsUsed(true);
                    continue;
                }

            } else if (namespace !is null) {
                // Namespaces end with 0 size lumps that end in _END.
                if (lumpSize == 0) {
                    nameIndex = indexOf(lumpName, "_END");
                    if (nameIndex > 0) {
                        lump.setIsUsed(true);
                        namespace = null;
                        continue;
                    }
                }

                // Track lumps that belong to the current namespace.
                if (namespace.lumps.contains(lumpName)) {
                    console.writeLine(Color.IMPORTANT, "Overwriting %s:%s", namespace.name, lumpName);
                }
                namespace.lumps.update(lumpName, lump);

                lump.setIsUsed(true);
            
            // Any lumps that are not part of a namespace become loose lumps.
            } else if (namespace is null && lump.isUsed() == false) {
                if (this.mLoose.lumps.contains(lumpName)) {
                    console.writeLine(Color.IMPORTANT, "Overwriting loose lump %s", lumpName);
                }
                this.mLoose.lumps.update(lumpName, lump);

            }
        }
    }

    /**
     * Adds the namespaces in this list to a WAD file.
     * Does not process the loose lump namespace.
     *
     * @param wad
     * The WAD file to add the namespaces to.
     */
    public void addTo(WAD wad) {
        foreach (ref Namespace namespace; this.mNamespaces) {
            if (namespace.lumps.length == 0) {
                continue;
            }

            wad.addLump(format("%s_START", namespace.name));
            foreach (Lump lump; namespace.lumps) {
                wad.addLump(lump);
            }

            // Write short style end markers for better vanilla compatibility.
            if (namespace.name == "SS") {
                wad.addLump("S_END");
            } else if (namespace.name == "FF") {
                wad.addLump("F_END");
            } else {
                wad.addLump(format("%s_END", namespace.name));
            }
        }
    }

    /**
     * Adds the lumps from the loose lump namespace to a WAD file.
     *
     * @param wad
     * The WAD file to add the loose lumps to.
     */
    public void addLooseTo(WAD wad) {
        if (this.mLoose.lumps.length == 0) {
            return;
        }

        foreach (Lump lump; this.mLoose.lumps) {
            wad.addLump(lump);
        }
    }

    /**
     * Sorts the lumps inside this list's namespaces by their name.
     */
    public void sort() {
        foreach (ref Namespace namespace; this.mNamespaces) {
            namespace.lumps.sort();
        }
    }

    /**
     * Sorts the lumps in the loose lumps namespace by their name.
     */
    public void sortLoose() {
        this.mLoose.lumps.sort();
    }
}
