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

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import core.stdc.stdlib;

import wad;
import console;
import util;
import orderedaa;
import options;
import texturelist;
import maplist;
import namespacelist;
import textlist;
import animatedlist;
import duplicatelist;


/// Full program name.
private immutable string NAME = "WADMerge";

/// Program version information.
private immutable ubyte VERSION_MAJOR = 2;
private immutable ubyte VERSION_MINOR = 3;
private immutable ubyte VERSION_PATCH = 1;

/// If true, this program is marked as a beta version.
private immutable bool VERSION_BETA = false;


/**
 * Main entry point.
 */
public int main(string[] argv) {
    writeHeader();
    console.init();

    Options opts;
    try {
        opts = options.parse(argv);
    } catch (Exception e) {
        stderr.writeln(e.msg);
        return -1;
    }

    // Get a list of WAD filenames to process.
    string[] wadPaths = getInputFiles(argv);

    // Determine if the output file is going to be overwritten or not.
    if (exists(opts.outputFile) == true) {
        if (opts.overwrite == false) {
            stderr.writef("The output file %s already exists. Overwrite? (Y/N) ", opts.outputFile);
            if (getYesNo() == false) {
                return 0;
            }
        } else {
            console.writeLine(Color.INFO, "Overwriting '%s'.", opts.outputFile);
        }
    }

    // These lists contain merged WAD data.
    TextureList textures = new TextureList();
    MapList maps = new MapList();
    NamespaceList namespaces = new NamespaceList();
    TextList textLumps = new TextList();
    AnimatedList animated = new AnimatedList();

    // Contains duplicate entry information.
    DuplicateList dupes = new DuplicateList();

    // Read and process each WAD file.
    WAD[] wadList;
    foreach (string wadPath; wadPaths) {
        console.writeLine(Color.NORMAL, "Adding '%s'...", wadPath);

        WAD wad;
        try {
            wad = new WAD(wadPath);
        } catch (Exception e) {
            console.writeLine(Color.IMPORTANT, "Cannot read WAD: %s", e.msg);
            continue;
        }
        wadList ~= wad;

        // Merge in textures.
        TextureList wadTextures = new TextureList();
        wadTextures.readFrom(wad);
        if (wadTextures.getStrifeMode() == true && textures.getStrifeMode() == false) {
            textures.setStrifeMode(true);
            console.writeLine(Color.INFO, "Merging textures in Strife mode.");
        }
        dupes.add(textures.mergeWith(wadTextures));
        
        // Merge in other resource types.
        dupes.add(animated.readFrom(wad));
        dupes.add(maps.readFrom(wad));
        if (opts.mergeText == true) {
            dupes.add(textLumps.readFrom(wad));
        }
        dupes.add(namespaces.readFrom(wad));
    }

    textures.updatePatchNames();

    // Remove unused patch names.
    if (opts.filterPatches == true) {
        string[] patchNames = textures.getPatchNames();
        if (patchNames.length > 0) {
            filterNamespace(namespaces.getNamespace("PP"), patchNames);
        }
    }

    // Sort resources.
    console.writeLine(Color.NORMAL, "Sorting...");
    if (opts.sortLoose == true) {
        namespaces.sortLoose();
    }
    if (opts.mergeText == true && opts.sortText == true) {
        textLumps.sort();
    }
    if (opts.sortTextures == true) {
        textures.sort();
    }
    if (opts.sortMaps == true) {
        maps.sort();
    }
    if (opts.sortNamespaces == true) {
        namespaces.sort();
    }

    // Create the output WAD and write resources to it.
    console.writeLine(Color.NORMAL, "Writing '%s'...", opts.outputFile);
    
    WAD output = new WAD(WADType.PWAD);
    namespaces.addLooseTo(output);
    if (opts.mergeText == true) {
        textLumps.addTo(output);
    }
    animated.addTo(output);
    textures.writeTo(output);
    maps.addTo(output);
    namespaces.addTo(output);
    output.writeTo(opts.outputFile);

    // Write duplicate information to a separate file.
    if (opts.duplicateFile != "") {
        console.writeLine(Color.NORMAL, "Writing duplicates information to '%s'...", opts.duplicateFile);
        dupes.writeTo(opts.duplicateFile);
    }

    console.writeLine(Color.NORMAL, "Done.");

    return 0;
}

/**
 * Filters a namespace's lumps so that only those from a list of lump names appear in it.
 *
 * Params:
 * namespace = The namespace of which the lumps are filtered.
 * lumpName  = A string array of lump names that will be included in the filtered namespace lump list.
 */
private void filterNamespace(ref Namespace namespace, string[] lumpNames) {
    string lumpName;

    // Create a new list of lumps containing only those that appear in the lumpNames list.
    OrderedAA!(string,Lump) newLumps = new OrderedAA!(string,Lump);
    foreach (Lump lump; namespace.lumps) {
        lumpName = lump.getName();
        if (getArrayIndex(lumpNames, lumpName) > -1) {
            newLumps.add(lumpName, lump);
        } else {
            console.writeLine(Color.INFO, "Not adding unused lump %s:%s", namespace.name, lumpName);
        }
    }

    namespace.lumps = newLumps;
}

/**
 * Outputs the program's header text.
 */
private void writeHeader() {
    if (VERSION_BETA == true) {
        writefln("%s, version %d.%d.%d beta", NAME, VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
    } else {
        writefln("%s, version %d.%d.%d", NAME, VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
    }

    writeln("Copyright (c) 2015, Dennis Meuwissen");
    writeln("All rights reserved.");
    writeln();

    if (VERSION_BETA == true) {
        console.writeLine(Color.INFO, "This is a beta version, bugs may be present!");
        writeln();
    }
}

/**
 * Validate all pathnames for existence.
 *
 * Params:
 * paths = The paths to validate as an array of strings.
 */
private void validateInputFiles(string[] paths) {
    bool error = false;

    foreach (string path; paths) {
        if (exists(path) == false) {
            stderr.writefln("The file %s does not exists.", path);
            error = true;
        }
    }

    // Exit if any of the paths do not exist.
    if (error == true) {
        exit(-1);
    }
}

/**
 * Gets a list of WAD file paths from the commandline arguments.
 *
 * Params:
 * args = The commandline arguments passed into this program.
 *
 * Returns: An array of validated file paths.
 */
private string[] getInputFiles(string[] args) {
    if (args.length <= 2) {
        stderr.writeln("At least 2 WAD files are needed to perform a merge.");
        exit(-1);
    }

    // Strip the program name from the arguments list and validate the remaining paths.
    string[] files = args[1..args.length];
    validateInputFiles(files);

    return files;
}

/**
 * Returns: true if the user enters Y as input, false for all other input.
 */
private bool getYesNo() {
    string answer;

    readf("%s\n", &answer);
    if (toLower(answer) != "y") {
        return false;
    }

    return true;
}
