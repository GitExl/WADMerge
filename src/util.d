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

module util;

import std.stream;
import std.file;


/**
 * Reads a string from a Stream object that is padded with null characters.
 *
 * @param stream
 * The Stream object to read the string from.
 *
 * @param pad
 * The amount of characters that the string is padded with.
 *
 * @returns
 * A non-padded string that was read from the stream.
 */
public string readPaddedString(Stream stream, uint pad) {
    uint length;
    char[] padName = new char[pad];

    stream.read(cast(ubyte[])padName);
    for (length = 0; length < pad; length++) {
        if (padName[length] == 0) {
            break;
        }
    }

    return cast(string)padName[0..length].dup;
}

/**
 * Returns the index of an element in an array.
 *
 * @param array
 * The array to search.
 *
 * @param find
 * The element to find.
 *
 * @returns
 * The index of the element in the array, or -1 if the element was not found.
 */
public int getArrayIndex(T)(T[] array, T find) {
    foreach (int index, T item; array) {
        if (item == find) {
            return index;
        }
    }

    return -1;
}