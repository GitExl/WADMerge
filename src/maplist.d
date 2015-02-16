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
import util;


/// A list of lump names that are known to be part of maps.
private string[] MAP_LUMPS = [
    "THINGS",
    "VERTEXES",
    "SIDEDEFS",
    "SECTORS",
    "SEGS",
    "SSECTORS",
    "NODES",
    "LINEDEFS",
    "REJECT",
    "BLOCKMAP",
    "BEHAVIOR",
    "SCRIPTS",
];

/// Recognized map types.
private enum MapType {
    DOOM,
    HEXEN,
    UDMF
}

/**
 * A map marker describing details about a single map marker lump.
 * These contain all the information needed to copy one map from one WAD to another.
 */
private struct MapMarker {
    /// The lump name of this map.
    string name;

    /// The type of this map.
    MapType type;

    /// The index of the marker lump for this map, in the WAD that contains it.
    size_t lumpIndexStart;

    /// The number of lumps following the index lump that this map uses.
    size_t lumpIndexEnd;

    /// The WAD object that this map and it's lumps can be found in.
    WAD wad;
}


/**
 * Holds a list of map lump markers and how many lumps they contain. It is used to marge multiple
 * maps from WAD files together. Aside from Doom map types, Hexen and UDMF maps are supported.
 */
public final class MapList {

    /// The map markers in this list of maps.
    private OrderedAA!(string,MapMarker) mMapMarkers;


    this() {
        this.mMapMarkers = new OrderedAA!(string,MapMarker);
    }

    /**
     * Adds map markers from a WAD file.
     *
     * Params:
     * wad = The WAD file to add map markers from.
     */
    public void readFrom(WAD wad) {
        MapMarker* marker;
        string lumpName;

        OrderedAA!(string,Lump) lumps = wad.getLumps();
        foreach (int index, ref Lump lump; lumps) {
            lumpName = lump.getName();

            if (marker is null) {
                // Detect the start of a new map.
                if (lumpName == "THINGS" || lumpName == "TEXTMAP") {
                    marker = new MapMarker();
                    marker.name = lumps[index - 1].getName();
                    marker.lumpIndexStart = index;
                    marker.wad = wad;

                    // Detect map type.
                    if (lumpName == "TEXTMAP") {
                        marker.type = MapType.UDMF;
                    } else {
                        marker.type = MapType.DOOM;
                    }

                    lumps[index - 1].setIsUsed(true);
                    lump.setIsUsed(true);
                }

            } else {
                // UDMF maps end with a ENDMAP marker.
                if (marker.type == MapType.UDMF) {
                    if (lumpName == "ENDMAP") {
                        marker.lumpIndexEnd = index + 1;
                        addMarker(*marker);
                        marker = null;
                    }
                    lump.setIsUsed(true);

                } else {
                    // Hexen type maps have a BEHAVIOR lump.
                    if (lumpName == "BEHAVIOR") {
                        marker.type = MapType.HEXEN;
                    }

                    // End this map if it is a not a known map lump.
                    if (isMapLump(lumpName) == false) {
                        marker.lumpIndexEnd = index;
                        addMarker(*marker);
                        marker = null;

                    // End this map if this lump is the last in the WAD.
                    } else if (index == lumps.length - 1) {
                        marker.lumpIndexEnd = index + 1;
                        addMarker(*marker);
                        marker = null;
                        lump.setIsUsed(true);

                    // This lump is part of the current map.
                    } else {
                        lump.setIsUsed(true);
                    }
                }
            }
        }
    }

    /**
     * Adds the maps in this list and their lumps to a WAD file.
     *
     * Params:
     * wad = The WAD file to add the lumps to.
     */
    public void addTo(WAD wad) {
        OrderedAA!(string,Lump) lumpList;

        foreach (ref MapMarker map; this.mMapMarkers) {
            lumpList = map.wad.getLumps();
            wad.addLump(map.name);
            for (size_t index = map.lumpIndexStart; index < map.lumpIndexEnd; index++) {
                wad.addLump(lumpList[index]);
            }
        }
    }

    /**
     * Sorts this list's map markers by name.
     */
    public void sort() {
        this.mMapMarkers.sort();
    }

    private void addMarker(MapMarker marker) {
        if (this.mMapMarkers.contains(marker.name)) {
            console.writeLine(Color.IMPORTANT, "Overwriting map %s.", marker.name);
        }

        this.mMapMarkers.update(marker.name, marker);
    }

    private bool isMapLump(const string lumpName) {
        return (getArrayIndex(MAP_LUMPS, lumpName) > -1);
    }
}
