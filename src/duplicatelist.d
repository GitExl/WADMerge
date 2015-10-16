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
module duplicatelist;

import std.stdio;
import std.string;
import std.path;
import std.algorithm;
import std.conv;

import wad;


/**
 * A duplicate WAD entry.
 */
private struct Duplicate {

    /// The type of entry that is duplicated.
    string typeName;

    /// WAD files both entries belong to.
    WAD wadA;
    WAD wadB;

    /// Lump names of the duplicates. These are not always equal.
    string nameA;
    string nameB;

    /// If true, entry B was merged with entry A.
    bool merged;


    /**
     * Returns: The name of the operation used to process this duplicate.
     */
    public string getOp() {
        return format("%s %s", merged ? "merge" : "overwrite", typeName);
    }

    /**
     * Returns: The full name of the WAD and entry of duplicate entry A.
     */
    public string getNameA() {
         return format("%s:%s", stripExtension(baseName(wadA.getFileName())), nameA);
    }

    /**
     * Returns: The full name of the WAD and entry of duplicate entry B.
     */
    public string getNameB() {
         return format("%s:%s", stripExtension(baseName(wadB.getFileName())), nameB);
    }
}


/**
 * Keeps track of a list of duplicate entries to be written to a readable text file.
 */
public final class DuplicateList {

    /// The list of duplicate entries.
    private Duplicate[] mDuplicates;


    /**
     * Adds a new duplicate entry.
     * 
     * Params:
     * typeName = The type of entry.
     * wadA = The WAD that the first entry is in.
     * nameA = The name of the first entry.
     * wadB = The WAD that the second entry is in.
     * nameB = The WAD that the second entry.
     * merged = If true, this duplicate was resolved by merging isntead of overwriting.
     */
    public void add(string typeName, WAD wadA, string nameA, WAD wadB, string nameB, immutable bool merged) {
        this.mDuplicates ~= Duplicate(typeName, wadA, wadB, nameA, nameB, merged);
    }

    /**
     * Adds another duplicate list's entries to this one.
     * 
     * Params:
     * other = The DuplicateList to add entries from.
     */
    public void add(DuplicateList other) {
        this.mDuplicates ~= other.getDuplicates();
    }

    /**
     * Returns: An array of Duplicate entries.
     */
    protected Duplicate[] getDuplicates() {
        return this.mDuplicates;
    }

    /**
     * Writes all duplicate entries to a readable text file.
     *
     * Params:
     * fileName = The file to write to.
     */
    public void writeTo(string fileName) {
        size_t opLen = 0;
        size_t nameALen = 0;
        size_t nameBLen = 0;

        // Determine the maximum lengths for the string formatter.
        foreach (ref Duplicate duplicate; mDuplicates) {
            string op = duplicate.getOp();
            string nameA = duplicate.getNameA();
            string nameB = duplicate.getNameB();

            opLen = max(op.length, opLen);
            nameALen = max(nameA.length, nameALen);
            nameBLen = max(nameB.length, nameBLen);
        }
        string formatStr = "%" ~ to!string(opLen) ~ "-s  %" ~ to!string(nameALen) ~ "-s  %" ~ to!string(nameBLen) ~ "-s\n";

        // Write entries to file.
        File f = File(fileName, "w");
        foreach (ref Duplicate duplicate; mDuplicates) {
            string op = duplicate.getOp();
            string nameA = duplicate.getNameA();
            string nameB = duplicate.getNameB();

            f.write(format(formatStr, op, nameA, nameB));
        }
        f.close();
    }
}