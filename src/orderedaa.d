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


class OrderedAA(K, I) {
	private I[] mItems;
	private int[K] mKeys;


	public void add(K key, I item) {
		this.mItems ~= item;
		this.mKeys[key] = this.mItems.length - 1;
	}

	public void update(K key, I item) {
		if (key in this.mKeys) {
			this.mItems[this.mKeys[key]] = item;
		} else {
			this.mItems ~= item;
			this.mKeys[key] = this.mItems.length - 1;
		}
	}

	public void sort() {
		K[] keyList = this.mKeys.keys.dup;
		keyList.sort();
		
		I[] newItems;
		foreach (int index, K key; keyList) {
			newItems ~= this.mItems[this.mKeys[key]];
			this.mKeys[key] = index;
		}
		this.mItems = newItems;
	}

	public I opIndex(int index) {
		return this.mItems[index];
	}

	public I opIndex(K key) {
		return this.mItems[this.mKeys[key]];
	}

	public bool contains(K key) {
		return ((key in this.mKeys) !is null);
	}

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

	public I get(K key, I def) {
		if (key in this.mKeys) {
			return this.mItems[this.mKeys[key]];
		} else {
			return def;
		}
	}

	public int indexOf(K key) {
		if (key in this.mKeys) {
			return this.mKeys[key];
		} else {
			return -1;
		}
	}

	public void clear() {
		this.mItems.length = 0;

		foreach (K key; this.mKeys.keys) {
			this.mKeys.remove(key);
		}
	}

	@property int length() {
		return this.mItems.length;
	}
}