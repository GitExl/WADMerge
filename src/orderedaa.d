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

module orderedaa;

import std.algorithm;


/**
 * A simplistic implementation of an ordered associative array.
 *
 * This is built on top of a normal associative array which keeps track of the indices into a regular array.
 * Items that are added are always appended to the array, and it's index added (or updated) in
 * the associative array holding the keys.
 *
 * For items that are updated, the index is looked up in the associative array if it exists and the item is
 * updated in the array, in place. It is added if they key does not exist in the associative array.
 */
public final class OrderedAA(K, I) {

    /// The items in this array, in the order that they were added.
    private I[] mItems;

    /// Keys pointing to item array indices for presence tests and fast lookups.
    private size_t[K] mKeys;


    /**
     * Adds a new item to this array.
     * This function will always add a new item, and will not update any old one by
     * the same key if present.
     *
     * Params: 
     * key  = They key to add.
     * item = They item to add.
     *
     * Returns: The index of the item that was added.
     */
    public size_t add(const K key, I item) {
        this.mItems ~= item;
        this.mKeys[key] = this.mItems.length - 1;

        return this.mItems.length - 1;
    }

    /**
     * Updates an item in this array.
     * This function will replace an already existing item if present, otherwise it
     * will add it to the end of the array.
     *
     * Params:
     * key  = They key to update.
     * item = They item to update.
     *
     * Returns: The index of the item that was added.
     */
    public size_t update(const K key, I item) {
        if (key in this.mKeys) {
            this.mItems[this.mKeys[key]] = item;
            return this.mKeys[key];
        }

        return this.add(key, item);
    }

    /**
     * Sorts the items in this array by their key.
     */
    public void sort() {
        // Create a flat list of the keys present in this array and sort them.
        K[] keyList = this.mKeys.keys.dup;
        keyList.sort();

        // Rebuild the item array in the order of the key list.
        I[] newItems;
        foreach (size_t index, K key; keyList) {
            newItems ~= this.mItems[this.mKeys[key]];
            this.mKeys[key] = index;
        }
        this.mItems = newItems;
    }

    /**
     * Returns: true if an item with the specified key is present in this array.
     */
    public bool contains(const K key) {
        return ((key in this.mKeys) !is null);
    }

    /**
     * Returns an item from this array, or a default value if the item does not exist.
     *
     * Params: 
     * key = They key of the item to return.
     * def = They default value to return if the key is not present in this array.
     *
     * Returns: The item with the specified key.
     */
    public I get(const K key, I def) {
        if (key in this.mKeys) {
            return this.mItems[this.mKeys[key]];
        } else {
            return def;
        }
    }

    /**
     * Empties the contents of this array.
     */
    public void clear() {
        this.mItems.length = 0;

        foreach (const K key; this.mKeys.keys) {
            this.mKeys.remove(key);
        }
    }

    /**
     * Describes the number of items in this array.
     */
    @property size_t length() {
        return this.mItems.length;
    }

    /**
     * foreach iterator for the obejcts in this array.
     */
    public int opApply(int delegate(ref I) dg) {
        int result;

        for (int index = 0; index < this.mItems.length; index++) {
            result = dg(this.mItems[index]);
            if (result) {
                break;
            }
        }

        return result;
    }

    /**
     * foreach iterator for the index and objects in this array.
     */
    public int opApply(int delegate(ref int, ref I) dg) {
        int result;

        for (int index = 0; index < this.mItems.length; index++) {
            result = dg(index, this.mItems[index]);
            if (result) {
                break;
            }
        }

        return result;
    }

    /**
     * Index function for an integer value.
     */
    public I opIndex(const size_t index) {
        return this.mItems[index];
    }

    /**
     * Index function for a key.
     */
    public I opIndex(const K key) {
        return this.mItems[this.mKeys[key]];
    }
}
