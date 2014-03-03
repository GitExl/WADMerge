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


struct Namespace {
	string name;
	OrderedAA!(string,Lump) lumps;
}


class NamespaceList {
	private Namespace[string] mNamespaces;


	public void addFrom(WAD wad) {
		Namespace* namespace;
		string name;
		string lumpName;
		uint lumpSize;
		int nameIndex;

		OrderedAA!(string,Lump) lumps = wad.getLumps();
		foreach (Lump lump; lumps) {
			lumpName = lump.getName();
			lumpSize = lump.getSize();

			if (namespace is null && lumpSize == 0) {
				nameIndex = indexOf(lumpName, "_START");
				if (nameIndex > 0) {
					name = lumpName[0..nameIndex];

					// Turn IWAD namespaces into patch wad namespaces.
					// Also takes care of the edge case where the starting marker's name does not match the ending marker's name.
					if (name == "F" || name == "F1" || name == "F2" || name == "F3") {
						name = "FF";
					} else if (name == "S") {
						name = "SS";
					} else if (name == "P" || name == "P1" || name == "P2" || name == "P3") {
						name = "PP";
					}

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
				if (lumpSize == 0) {
					nameIndex = indexOf(lumpName, "_END");
					if (nameIndex > 0) {
						lump.setIsUsed(true);
						namespace = null;
						continue;
					}
				}
				
				if (namespace.lumps.contains(lumpName)) {
					console.writeLine(Color.IMPORTANT, "Overwriting %s:%s", namespace.name, lumpName);
					
				}
				namespace.lumps.update(lumpName, lump);
				
				lump.setIsUsed(true);
			}
		}
	}

	public void addTo(WAD wad) {
		foreach (ref Namespace namespace; this.mNamespaces) {
			wad.addLump(format("%s_START", namespace.name));
			foreach (Lump lump; namespace.lumps) {
				wad.addLump(lump);
			}
			wad.addLump(format("%s_END", namespace.name));
		}
	}

	public void sort() {
		foreach (ref Namespace namespace; this.mNamespaces) {
			namespace.lumps.sort();
		}
	}
}