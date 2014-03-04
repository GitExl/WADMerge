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


public enum WADType : ubyte {
    IWAD,
    PWAD
}


public class Lump {
    private uint mOffset;
    private uint mSize;
    private string mName;
    private bool mIsUsed;
    private ubyte[] mData;


    public this(string name) {
        this.mName = name;
    }

    public this(string name, ubyte[] data) {
        this.mName = name;
        this.mSize = data.length;
        this.mData = data;
    }

    public this(uint offset, uint size, string name) {
        this.mOffset = offset;
        this.mSize = size;
        this.mName = name;
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

    public void readData(Stream stream) {
        this.mData = new ubyte[this.mSize];

        stream.seek(this.mOffset, SeekPos.Set);
        stream.read(this.mData);
    }

    public void putData(ubyte[] data) {
        this.mData = data;
        this.mSize = data.length;
    }
}

public class WAD {
    private WADType mType;
    private uint mLumpCount;
    private uint mDirectoryOffset;

    private OrderedAA!(string,Lump) mLumps;


    this(WADType type) {
        this.mType = type;
        this.mLumps = new OrderedAA!(string,Lump);
    }

    this(string fileName) {
        char[4] id;

        BufferedFile file = new BufferedFile(fileName, FileMode.In);
        file.read(cast(ubyte[])id);
        file.read(this.mLumpCount);
        file.read(this.mDirectoryOffset);

        if (id == "IWAD") {
            this.mType = WADType.IWAD;
        } else if (id == "PWAD") {
            this.mType = WADType.PWAD;
        } else {
            throw new Exception(format("%s is not a valid WAD file.", fileName));
        }

        if (this.mDirectoryOffset > file.size()) {
            throw new Exception(format("%s has a corrupted header.", fileName));
        }

        readLumps(file);

        file.close();
    }

    private void readLumps(BufferedFile file) {
        uint offset;
        uint size;
        string name;

        ubyte[] directoryData = new ubyte[this.mLumpCount * 16];
        file.seek(this.mDirectoryOffset, SeekPos.Set);
        file.read(directoryData);

        MemoryStream directory = new MemoryStream(directoryData);
        this.mLumps = new OrderedAA!(string,Lump);

        for (int index; index < this.mLumpCount; index++) {
            directory.read(offset);
            directory.read(size);
            name = readPaddedString(directory, 8);

            Lump lump = new Lump(offset, size, name);
            lump.readData(file);

            this.mLumps.add(lump.getName(), lump);
        }
    }

    public void writeTo(string fileName) {
        // Calculcate lump offsets.
        uint offset = 12;
        foreach (Lump lump; this.mLumps) {
            lump.setOffset(offset);
            offset += lump.getSize();
        }
        this.mDirectoryOffset = offset;

        BufferedFile file = new BufferedFile(fileName, FileMode.OutNew);

        // Write header.
        if (this.mType == WADType.IWAD) {
            file.write(cast(ubyte[])"IWAD");
        } else {
            file.write(cast(ubyte[])"PWAD");
        }
        file.write(this.mLumpCount);
        file.write(this.mDirectoryOffset);

        // Write lump data.
        foreach (Lump lump; this.mLumps) {
            file.write(lump.getData());
        }

        // Write lump directory.
        foreach (Lump lump; this.mLumps) {
            file.write(lump.getOffset());
            file.write(lump.getSize());
            file.write(cast(ubyte[])leftJustify(lump.getName(), 8, '\0'));
        }

        file.close();
    }

    public Lump getLump(const int index) {
        if (index >= this.mLumps.length) {
            return null;
        }

        return this.mLumps[index];
    }

    public Lump getLump(string name) {
        int index = this.mLumps.indexOf(name);
        if (index == -1) {
            return null;
        }

        return this.mLumps[index];
    }

    public bool containsLump(string name) {
        return this.mLumps.contains(name);
    }

    public OrderedAA!(string,Lump) getLumps() {
        return this.mLumps;
    }

    public int getIndex(string name) {
        return this.mLumps.indexOf(name);
    }

    public Lump addLump(Lump other) {
        Lump newLump = other;

        this.mLumps.add(newLump.getName(), newLump);
        this.mLumpCount += 1;

        return newLump;
    }

    public Lump addLump(string name) {
        Lump newLump = new Lump(name);

        this.mLumps.add(newLump.getName(), newLump);
        this.mLumpCount += 1;

        return newLump;
    }
}
