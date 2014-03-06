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

import std.stdio;
import std.getopt;
import std.file;
import std.string;
import std.algorithm;
import std.c.stdlib;

import wad;
import console;
import license;
import help;
import util;
import orderedaa;

import texturelist;
import maplist;
import namespacelist;
import textlist;
import animatedlist;


// Version information.
immutable string NAME = "WADMerge";
immutable ubyte VERSION_MAJOR = 2;
immutable ubyte VERSION_MINOR = 2;
immutable ubyte VERSION_PATCH = 0;
immutable bool VERSION_BETA = true;


int main(string[] argv) {
    writeHeader();

    if (argv.length == 1) {
        writeHelp();
    }

    console.init();

    // Command line parameter variables and their default values.
    string outputFile = "merged.wad";
    bool overwrite = false;
    bool filterPatches = true;
    bool mergeText = true;
    bool sortNamespaces = true;
    bool sortMaps = true;
    bool sortLoose = false;
    bool sortTextures = false;
    bool sortText = true;

    // Parse command line parameters.
    try {
        getopt(argv,
            "license|l",      &writeLicense,
            "help|h|?",       &writeHelp,

            "output|o",       &outputFile,
            "overwrite|w",    &overwrite,
            "filter-patches", &filterPatches,
            "merge-text",     &mergeText,

            "sort-ns",        &sortNamespaces,
            "sort-maps",      &sortMaps,
            "sort-loose",     &sortLoose,
            "sort-textures",  &sortTextures,
            "sort-text",      &sortText
        );
    } catch (Exception e) {
        stderr.writeln(e.msg);
        return -1;
    }

    // Get a list of WAD filenames to process.
    string[] wadPaths = getInputFiles(argv);

    // Determine if the output file is going to be overwritten or not.
    if (exists(outputFile) == true) {
        if (overwrite == false) {
            stderr.writef("The output file %s already exists. Overwrite? (Y/N) ", outputFile);
            if (getYesNo() == false) {
                return 0;
            }
        } else {
            console.writeLine(Color.INFO, "Overwriting %s.", outputFile);
        }
    }

    // These lists contain merged WAD data.
    TextureList textures = new TextureList();
    MapList maps = new MapList();
    NamespaceList namespaces = new NamespaceList();
    TextList textLumps = new TextList();
    AnimatedList animated = new AnimatedList();

    // Read and process each WAD file.
    WAD[] wadList;
    foreach (string wadPath; wadPaths) {
        console.writeLine(Color.NORMAL, "Adding %s...", wadPath);

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
        textures.mergeWith(wadTextures);
        
        // Merge in other resource types.
        animated.readFrom(wad);
        maps.readFrom(wad);
        if (mergeText == true) {
            textLumps.readFrom(wad);
        }
        namespaces.readFrom(wad);
    }

    // Create the output WAD.
    WAD output = new WAD(WADType.PWAD);
    if (sortLoose == true) {
        namespaces.sortLoose();
    }
    namespaces.addLooseTo(output);

    if (mergeText == true) {
        if (sortText == true) {
            textLumps.sort();
        }
        textLumps.addTo(output);
    }

    animated.addTo(output);

    textures.updatePatchNames();
    if (sortTextures == true) {
        textures.sort();
    }
    textures.writeTo(output);

    if (sortMaps == true) {
        maps.sort();
    }
    maps.addTo(output);

    // Remove unused patch names.
    if (filterPatches == true) {
        string[] patchNames = textures.getPatchNames();
        if (patchNames.length > 0) {
            filterNamespace(namespaces.getNamespace("PP"), patchNames);
        }
    }

    if (sortNamespaces == true) {
        namespaces.sort();
    }
    namespaces.addTo(output);

    writefln("Writing %s...", outputFile);
    output.writeTo(outputFile);
    writefln("Done.");

    return 0;
}

/**
 * Filters a namespace's lumps so that only those from a list of lump names appear in it.
 *
 * @param namespace
 * The namespace of which the lumps are filtered.
 *
 * @param lumpName
 * A string array of lump names that will be included in the filtered namespace lump list.
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

    writeln("Copyright (c) 2014, Dennis Meuwissen");
    writeln("All rights reserved.");
    writeln();

    if (VERSION_BETA == true) {
        console.writeLine(Color.INFO, "This is a beta version, bugs may be present!");
        writeln();
    }
}

/**
 * Outputs the program's license text.
 */
private void writeLicense() {
    writeln(license.LICENSE);
    exit(0);
}

/**
 * Outputs the program's help text.
 */
private void writeHelp() {
    writeln(help.HELP);
    exit(0);
}

/**
 * Validate all pathnames for existence.
 *
 * @param paths
 * The paths to validate as an array of strings.
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
 * @param args
 * The commandline arguments passed into this program.
 *
 * @returns
 * An array of validated file paths.
 */
private string[] getInputFiles(string[] args) {
    if (args.length == 1) {
        stderr.writeln("No input WAD files specified.");
        exit(-1);
    }

    if (args.length == 2) {
        stderr.writeln("Need at least 2 WAD files to merge.");
        exit(-1);
    }

    // Strip the program name from the arguments list and validate the remaining paths.
    string[] files = args[1..args.length];
    validateInputFiles(files);

    return files;
}

/**
 * Returns true if the user enters Y as input, false for all other input.
 */
private bool getYesNo() {
    string answer;

    readf("%s\n", &answer);
    if (toLower(answer) != "y") {
        return false;
    }

    return true;
}
