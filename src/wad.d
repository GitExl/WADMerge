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

module wad;

import std.string;
import std.stream;
import std.stdio;

import orderedaa;
import util;


// Valid WAD file types.
// IWAD files (internal WADs) are only used as main game WADs. PWAD files (patch WADs) normally
// contain lumps to extend or overwrite an IWAD's lumps with.
public enum WADType : ubyte {
    IWAD,
    PWAD
}


/**
 * A single lump as it is found inside a Doom WAD file.
 */
public class Lump {

    // The offset of this lump in the containing WAD file.
    private uint mOffset;

    // The size of this lump's data, in bytes.
    private uint mSize;

    // The name of this lump.
    private string mName;

    // If true, this lump is marked as used in a lump list.
    private bool mIsUsed;

    // The raw data of this lump.
    private ubyte[] mData;


    /**
     * Constructor for an empty lump.
     */
    public this(string name) {
        this.mName = name;
    }

    /**
     * Constructor for a lump with predetermined data.
     */
    public this(string name, ubyte[] data) {
        this.mName = name;
        this.mSize = data.length;
        this.mData = data;
    }

    /**
     * Constructor for a lump whose data will be read at a later point.
     */
    public this(string name, uint size, uint offset) {
        this.mOffset = offset;
        this.mSize = size;
        this.mName = name;
    }

    /**
     * Reads this lump's data from a Stream object.
     *
     * @param stream
     * The Stream object to read the data from. The data will be read from the offset that is set
     * in this lump. The amount of data to read is determined by the size of this lump.
     */
    public void readData(Stream stream) {
        this.mData = new ubyte[this.mSize];

        stream.seek(this.mOffset, SeekPos.Set);
        stream.read(this.mData);
    }

    /**
     * Puts new data in this lump.
     *
     * @param data
     * The raw data to put in this lump. The lump's size will be updated to match the data's length.
     */
    public void putData(ubyte[] data) {
        this.mData = data;
        this.mSize = data.length;
    }

    /**
     * Compares the data of this lump to that of another Lump.
     *
     * @param other
     * The Lump to compare the data with.
     *
     * @returns
     * true if the contents are equal, false if not.
     */
    public bool areContentsEqual(Lump other) {
        ubyte[] otherData = other.getData();
        if (otherData.length != this.mData.length) {
            return false;
        }

        for (int index = 0; index < otherData.length; index++) {
            if (this.mData[index] != otherData[index]) {
                return false;
            }
        }

        return true;
    }

    public ubyte[] getData() {
        return this.mData;
    }

    public bool isUsed() {
        return this.mIsUsed;
    }

    public void setIsUsed(bool isUsed) {
        this.mIsUsed = isUsed;
    }

    public string getName() {
        return this.mName;
    }

    public uint getSize() {
        return this.mSize;
    }

    public uint getOffset() {
        return this.mOffset;
    }

    public void setOffset(uint offset) {
        this.mOffset = offset;
    }

    public MemoryStream getStream() {
        return new MemoryStream(this.mData);
    }
}


/**
 * A WAD file (Where's All the Data?) contains data for a Doom engine game, laid out in the form
 * of individual lumps.
 *
 * See http://doomwiki.org/wiki/WAD for more information about WAD files.
 */
public class WAD {

    // The type of this WAD file.
    private WADType mType;

    // The number of lumps in this WAD file.
    private uint mLumpCount;

    // The offset to the lump directory.
    private uint mDirectoryOffset;

    // A list of the lumps inside this WAD file.
    private OrderedAA!(string,Lump) mLumps;


    /**
     * Constructor for creating a new WAD file.
     */
    this(WADType type) {
        this.mType = type;
        this.mLumps = new OrderedAA!(string,Lump);
    }

    /**
     * Constructor for reading a WAD file from storage.
     *
     * @param fileName
     * The name of the file to read this WAD from.
     */
    this(const string fileName) {
        char[4] id;

        BufferedFile file = new BufferedFile(fileName, FileMode.In);

        // Validate magic bytes, which should correspond to a known WAD type.
        file.read(cast(ubyte[])id);
        if (id == "IWAD") {
            this.mType = WADType.IWAD;
        } else if (id == "PWAD") {
            this.mType = WADType.PWAD;
        } else {
            throw new Exception(format("%s is not a valid WAD file.", fileName));
        }

        file.read(this.mLumpCount);
        file.read(this.mDirectoryOffset);

        if (this.mDirectoryOffset > file.size()) {
            throw new Exception(format("%s has a corrupted or invalid header.", fileName));
        }

        readLumps(file);

        file.close();
    }

    /**
     * Writes this WAD's contents to a file.
     *
     * @param fileName
     * The name of the file to write to. This file will be overwritten if it already exists.
     */
    public void writeTo(const string fileName) {

        // Calculcate lump offsets inside the WAD file.
        // The directory follows the lump data.
        uint offset = 12;
        foreach (Lump lump; this.mLumps) {
            lump.setOffset(offset);
            offset += lump.getSize();
        }
        this.mDirectoryOffset = offset;

        BufferedFile file = new BufferedFile(fileName, FileMode.OutNew);

        // Write the file header.
        if (this.mType == WADType.IWAD) {
            file.write(cast(ubyte[])"IWAD");
        } else {
            file.write(cast(ubyte[])"PWAD");
        }
        file.write(this.mLumpCount);
        file.write(this.mDirectoryOffset);

        // Write raw lump data.
        foreach (Lump lump; this.mLumps) {
            file.write(lump.getData());
        }

        // Write the lump directory.
        foreach (Lump lump; this.mLumps) {
            file.write(lump.getOffset());
            file.write(lump.getSize());
            writePaddedString(file, lump.getName(), 8);
        }

        file.close();
    }

    /**
     * Returns true if a lump name exists in this WAD.
     *
     * @param name
     * The lump name to search for.
     *
     * @returns
     * True if the lump is present, false otherwise.
     */
    public bool containsLump(const string name) {
        return this.mLumps.contains(name);
    }

    /**
     * Adds a copy of another lump to this WAD file.
     *
     * @param other
     * The lump to copy into this WAD file.
     *
     * @returns
     * The new Lump object.
     */
    public Lump addLump(Lump other) {
        Lump newLump = other;

        this.mLumps.add(newLump.getName(), newLump);
        this.mLumpCount += 1;

        return newLump;
    }

    /**
     * Adds an empty lump to this WAD file.
     *
     * @param name
     * The name of the lump to add.
     *
     * @returns
     * The new Lump object.
     */
    public Lump addLump(const string name) {
        Lump newLump = new Lump(name);

        this.mLumps.add(newLump.getName(), newLump);
        this.mLumpCount += 1;

        return newLump;
    }

    private void readLumps(BufferedFile file) {
        uint offset;
        uint size;
        string name;

        // Read the raw directory data in one operation.
        ubyte[] directoryData = new ubyte[this.mLumpCount * 16];
        file.seek(this.mDirectoryOffset, SeekPos.Set);
        file.read(directoryData);

        MemoryStream directory = new MemoryStream(directoryData);
        this.mLumps = new OrderedAA!(string,Lump);

        // Create new lumps from the directory data and read their raw data.
        for (size_t index; index < this.mLumpCount; index++) {
            directory.read(offset);
            directory.read(size);
            name = readPaddedString(directory, 8);

            Lump lump = new Lump(name, size, offset);
            lump.readData(file);

            this.mLumps.add(name, lump);
        }
    }

    public Lump getLump(const size_t index) {
        if (index >= this.mLumps.length || index < 0) {
            return null;
        }

        return this.mLumps[index];
    }

    public Lump getLump(const string name) {
        return this.mLumps.get(name, null);
    }

    public OrderedAA!(string,Lump) getLumps() {
        return this.mLumps;
    }
}
