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

module maplist;

import std.stdio;

import wad;
import console;
import orderedaa;


// Recognized map types.
enum MapType {
    DOOM,
    HEXEN,
    UDMF
}

// A map marker describing details about a single map marker lump.
struct MapMarker {
    // Map name.
    string name;

    // Map type.
    MapType type;

    // Index of the marker lump for this map.
    uint lumpIndexStart;

    // The number of lumps following the index lump that this map uses.
    uint lumpIndexEnd;

    // The WAD object that this map and it's lumps can be found in.
    WAD wad;
}


class MapList {
    OrderedAA!(string,MapMarker) mMapMarkers;


    this() {
        this.mMapMarkers = new OrderedAA!(string,MapMarker);
    }

    public void addFrom(WAD wad) {
        MapMarker marker;
        string lumpName;

        bool insideMap = false;
        OrderedAA!(string,Lump) lumps = wad.getLumps();
        foreach (int index, ref Lump lump; lumps) {
            lumpName = lump.getName();

            if (insideMap == false) {
                if (lumpName == "THINGS" || lumpName == "TEXTMAP") {
                    marker.name = lumps[index - 1].getName();
                    marker.lumpIndexStart = index;
                    marker.wad = wad;

                    if (lumpName == "TEXTMAP") {
                        marker.type = MapType.UDMF;
                    } else {
                        marker.type = MapType.DOOM;
                    }

                    lumps[index - 1].setIsUsed(true);
                    lump.setIsUsed(true);

                    insideMap = true;
                }

            } else {
                if (marker.type == MapType.UDMF) {
                    if (lumpName == "ENDMAP") {
                        marker.lumpIndexEnd = index + 1;
                        addMarker(marker);
                        insideMap = false;
                    }
                    lump.setIsUsed(true);

                } else {
                    if (lumpName == "BEHAVIOR") {
                        marker.type = MapType.HEXEN;
                    }

                    if (isMapLump(lumpName) == false) {
                        marker.lumpIndexEnd = index;
                        addMarker(marker);
                        insideMap = false;

                    } else if (index == lumps.length - 1) {
                        marker.lumpIndexEnd = index + 1;
                        addMarker(marker);
                        insideMap = false;
                        lump.setIsUsed(true);

                    } else {
                        lump.setIsUsed(true);
                    }
                }
            }
        }
    }

    public void addTo(WAD wad) {
        OrderedAA!(string,Lump) lumpList;

        foreach (ref MapMarker map; this.mMapMarkers) {
            lumpList = map.wad.getLumps();
            wad.addLump(map.name);
            for (uint index = map.lumpIndexStart; index < map.lumpIndexEnd; index++) {
                wad.addLump(lumpList[index]);
            }
        }
    }

    private void addMarker(MapMarker marker) {
        if (this.mMapMarkers.contains(marker.name)) {
            console.writeLine(Color.IMPORTANT, "Overwriting map %s.", marker.name);
        }

        this.mMapMarkers.update(marker.name, marker);
    }

    private bool isMapLump(string lumpName) {
        if (lumpName == "THINGS" || lumpName == "VERTEXES" || lumpName == "SIDEDEFS" ||
            lumpName == "SECTORS" || lumpName == "SEGS" || lumpName == "SSECTORS" ||
            lumpName == "NODES" || lumpName == "LINEDEFS" || lumpName == "REJECT" ||
            lumpName == "BLOCKMAP" || lumpName == "BEHAVIOR" || lumpName == "SCRIPTS") {
                return true;
        }

        return false;
    }

    public void sort() {
        this.mMapMarkers.sort();
    }
}
