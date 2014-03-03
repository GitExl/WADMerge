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
import textures;
import maplist;
import console;
import license;
import help;
import namespacelist;


// Version information.
immutable string NAME = "WADMerge";
immutable ubyte VERSION_MAJOR = 2;
immutable ubyte VERSION_MINOR = 0;
immutable ubyte VERSION_PATCH = 0;


int main(string[] argv) {
    console.init();
    writeHeader();

    if (argv.length == 1) {
        writeHelp();
    }

    // Command line parameter variables and their default values.
    string outputFile = "merged.wad";
    bool overwrite = false;
    bool sortNamespaces = true;
    bool sortMaps = true;
    bool sortLoose = false;
    bool sortTextures = false;

    // Parse command line parameters.
    try {
        getopt(argv,
            "license|l",       &writeLicense,
            "help|h|?",        &writeHelp,
            "output|o",        &outputFile,
            "overwrite|w",     &overwrite,
            "sort-ns|n",       &sortNamespaces,
            "sort-maps|m",     &sortMaps,
            "sort-loose|l",    &sortLoose,
            "sort-textures|t", &sortTextures
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

    // Read and process each WAD file.
    WAD[] wadList;
    foreach (string wadPath; wadPaths) {
        console.writeLine(Color.NORMAL, "Adding %s...", wadPath);

        WAD wad = new WAD(wadPath);
        wadList ~= wad;

        // Merge in different types of lumps.
        TextureList wadTextures = new TextureList(wad);
        if (wadTextures.getStrifeMode() == true) {
            console.writeLine(Color.INFO, "Merging textures in Strife mode.");
        }

        textures.mergeWith(wadTextures);
        maps.addFrom(wad);
        namespaces.addFrom(wad);
    }

    // Update texture patch indices from patch names.
    textures.updatePatchNames();
    if (sortTextures == true) {
        textures.sort();
    }

    // Create the output WAD.
    WAD output = new WAD(WADType.PWAD);
    addLooseLumps(output, wadList, sortLoose);
    textures.writeTo(output);

    if (sortMaps == true) {
        maps.sort();
    }
    maps.addTo(output);

    if (sortNamespaces == true) {
        namespaces.sort();
    }
    namespaces.addTo(output);

    writefln("Writing %s...", outputFile);
    output.writeTo(outputFile);
    writefln("Done.");

    return 0;
}

private void addLooseLumps(WAD outputWAD, WAD[] wadList, bool sort) {
    Lump[string] looseLumps;

    foreach (WAD wad; wadList) {
        foreach (Lump lump; wad.getLumps()) {
            if (lump.isUsed() == false) {
                looseLumps[lump.getName()] = lump;
            }
        }
    }

    string[] keys = looseLumps.keys.dup;
    if (sort == true) {
        keys.sort();
    }
    foreach (string key; keys) {
        outputWAD.addLump(looseLumps[key]);
    }
}

/**
 * Outputs the program's header text.
 */
private void writeHeader() {
    writefln("%s, version %d.%d.%d", NAME, VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
    writeln("Copyright (c) 2014, Dennis Meuwissen");
    writeln("All rights reserved.");
    writeln();
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
