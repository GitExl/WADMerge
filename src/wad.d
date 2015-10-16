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

module wad;

import std.string;
import std.stream;
import std.stdio;

import orderedaa;
import util;


/**
 * Valid WAD file types.
 * IWAD files (internal WADs) are only used as main game WADs. PWAD files (patch WADs) normally
 * contain lumps to extend or overwrite an IWAD's lumps with.
 */
public enum WADType : ubyte {
    IWAD,
    PWAD
}


/**
 * A single lump as it is found inside a Doom WAD file.
 */
public final class Lump {

    /// The offset of this lump in the containing WAD file.
    private int mOffset;

    /// The size of this lump's data, in bytes.
    private int mSize;

    /// The name of this lump.
    private string mName;

    /// If true, this lump is marked as used in a lump list.
    private bool mIsUsed;

    /// The raw data of this lump.
    private ubyte[] mData;

    /// The WAD this lump is in.
    private WAD mWAD;

    /// The index of this lump in it's WAD.
    private int mIndex;


    /**
     * Constructor for an empty lump.
     *
     * Params:
     * name = The name for the new lump object.
     */
    public this(string name) {
        this.mName = name;
    }

    /**
     * Constructor for a lump with predetermined data.
     *
     * Params:
     * name = The name for the new lump object.
     * data = The data to store in the new lump object.
     */
    public this(string name, ubyte[] data) {
        this.mName = name;
        this.mSize = cast(int)data.length;
        this.mData = data.dup;
    }

    /**
     * Constructor for a lump whose data will be read at a later point.
     *
     * Params:
     * name   = The name for the new lump object.
     * size   = The size of the new lump object's data.
     * offset = The byte location where the new lump object's data is stored in a WAD.
     */
    public this(string name, const int size, const int offset) {
        this.mOffset = offset;
        this.mSize = size;
        this.mName = name;
    }

    /**
     * Reads this lump's data from a Stream object.
     *
     * Params:
     * stream = The Stream object to read the data from. The data will be read from the offset that
     *          is set in this lump. The amount of data to read is determined by the size of this lump.
     */
    public void readData(Stream stream) {
        this.mData = new ubyte[this.mSize];

        stream.seek(this.mOffset, SeekPos.Set);
        stream.read(this.mData);
    }

    /**
     * Puts new data in this lump.
     *
     * Params:
     * data = The raw data to put in this lump. The lump's size will be updated to match the
     *        data's length.
     */
    public void putData(ubyte[] data) {
        this.mData = data.dup;
        this.mSize = cast(int)data.length;
    }

    /**
     * Compares the data of this lump to that of another Lump.
     *
     * Params:
     * other = The Lump to compare the data with.
     *
     * Returns: true if the contents are equal, false if not.
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

    /**
     * Returns: This lump's data.
     */
    public ubyte[] getData() {
        return this.mData;
    }

    /**
     * Returns: true if this lump is marked as used in a WAD.
     */
    public bool isUsed() {
        return this.mIsUsed;
    }

    /**
     * Sets this lump's used state.
     *
     * Params:
     * isUsed = If true, this lump is used by a WAD.
     */
    public void setIsUsed(const bool isUsed) {
        this.mIsUsed = isUsed;
    }

    /**
     * Returns: This lump's name.
     */
    public string getName() {
        return this.mName;
    }

    /**
     * Returns: This lump's data size.
     */
    public int getSize() {
        return this.mSize;
    }

    /**
     * Returns: This lump's byte offset.
     */
    public int getOffset() {
        return this.mOffset;
    }

    /**
     * Sets this lump's byte offset.
     *
     * Params:
     * offset = the byte offset at which this lump's data is located in a WAD file.
     */
    public void setOffset(const int offset) {
        this.mOffset = offset;
    }

    /**
     * Returns: A new MemoryStream object that points to this lump's raw data.
     */
    public MemoryStream getStream() {
        return new MemoryStream(this.mData);
    }

    /**
     * Returns: The WAD this lump is in, if any.
     */
    public WAD getWAD() {
        return this.mWAD;
    }
    
    /**
     * Sets the WAD this lump is in.
     */
    public void setWAD(WAD wad) {
        this.mWAD = wad;
    }

    /**
     * Returns: The index of this lump in the WAD.
     */
    public int getIndex() {
        return this.mIndex;
    }
    
    /**
     * Sets the index of this lump in the WAD.
     */
    public void setIndex(const int index) {
        this.mIndex = index;
    }
}


/**
 * A WAD file (Where's All the Data?) contains data for a Doom engine game, laid out in the form
 * of individual lumps.
 *
 * See <a href="http://doomwiki.org/wiki/WAD">The Doom Wiki</a> for more information about WAD files.
 */
public final class WAD {

    /// The file name of this WAD file.
    private string mFileName;

    /// The type of this WAD file.
    private WADType mType;

    /// The number of lumps in this WAD file.
    private int mLumpCount;

    /// The offset to the lump directory.
    private int mDirectoryOffset;

    /// A list of the lumps inside this WAD file.
    private OrderedAA!(string,Lump) mLumps;


    /**
     * Constructor for creating a new WAD file.
     *
     * Params:
     * type = The type of WAD to create.
     */
    this(WADType type) {
        this.mType = type;
        this.mLumps = new OrderedAA!(string,Lump);
    }

    /**
     * Constructor for reading a WAD file from storage.
     *
     * Params:
     * fileName = The name of the file to read this WAD from.
     */
    this(const string fileName) {
        char[4] id;

        mFileName = fileName;
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
     * Params:
     * fileName = The name of the file to write to. This file will be overwritten if it already exists.
     */
    public void writeTo(const string fileName) {
        mFileName = fileName;

        // Calculcate lump offsets inside the WAD file.
        // The directory follows the lump data.
        int offset = 12;
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

            // Update lump ownership.
            lump.setWAD(this);
        }

        file.close();
    }

    /**
     * Returns true if a lump name exists in this WAD.
     *
     * Params:
     * name = The lump name to search for.
     *
     * Returns: true if the lump is present, false otherwise.
     */
    public bool containsLump(const string name) {
        return this.mLumps.contains(name);
    }

    /**
     * Adds a copy of another lump to this WAD file.
     *
     * Params:
     * other = The lump to copy into this WAD file.
     *
     * Returns: A new Lump object copy.
     */
    public Lump addLump(Lump other) {
        Lump newLump = other;
        newLump.setWAD(this);
        newLump.setIndex(this.mLumpCount);

        this.mLumps.add(newLump.getName(), newLump);
        this.mLumpCount += 1;

        return newLump;
    }

    /**
     * Adds an empty lump to this WAD file.
     *
     * Params:
     * name = The name of the lump to add.
     *
     * Returns: The new Lump object that was added.
     */
    public Lump addLump(const string name) {
        Lump newLump = new Lump(name);
        newLump.setWAD(this);
        newLump.setIndex(this.mLumpCount);

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
            lump.setWAD(this);
            lump.setIndex(index);

            this.mLumps.add(name, lump);
        }
    }

    /**
     * Returns: A lump from this WAD by it's index.
     */
    public Lump getLump(const size_t index) {
        if (index >= this.mLumps.length || index < 0) {
            return null;
        }

        return this.mLumps[index];
    }

    /**
     * Returns: A lump from this WAD by it's name. The last occurrence of the lump's name will be used
     * if the name appears more than once in this WAD.
     */
    public Lump getLump(const string name) {
        return this.mLumps.get(name, null);
    }

    /**
     * Returns: The lumps contained in this WAD.
     */
    public OrderedAA!(string,Lump) getLumps() {
        return this.mLumps;
    }

    /**
     * Returns: The filename of this WAD, if any.
     */
    public string getFileName() {
        return this.mFileName;
    }
}
