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

module textlumps;


/// These lump names are known to be text based and multiple of it's kind can likely be
/// concatenated together.
public string[] TEXT_LUMPS = [
    // Doom
    "DMXGUS",

    // Hexen
    "MAPINFO",
    "ANIMDEFS",
    "SNDINFO",
    "SNDSEQ",

    // ZDoom
    "ALTHUDCF",
    "CVARINFO",
    "DECALDEF",
    "DECORATE",
    "DEHSUPP",
    "FSGLOBAL",
    "FONTDEFS",
    "GAMEINFO",
    "GLDEFS",
    "KEYCONF",
    "LANGUAGE",
    "LOADACS",
    "LOCKDEFS",
    "MENUDEF",
    "MODELDEF",
    "MUSINFO",
    "PALVERS",
    "REVERBS",
    "S_SKIN",
    "SBARINFO",
    "SCRIPTS",
    "SECRETS",
    "TEAMINFO",
    "TERRAIN",
    "TEXTCOLO",
    "TEXTURES",
    "VOXELDEF",
    "XHAIRS",
    "X11R6RGB",
    "ZMAPINFO",

    // Skulltag
    "ANCRINFO",
    "BOTINFO",
    "CMPGNINF",
    "SECTINFO",
    "SKININFO",

    // Doomsday
    "DD_DEFNS",
];
