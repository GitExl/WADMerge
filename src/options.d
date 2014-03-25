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

module options;

import std.stdio;
import std.getopt;
import std.c.stdlib;

import license;
import help;


/// Container for commandline options.
public struct Options {
    string outputFile = "merged.wad";
    bool overwrite = false;
    bool filterPatches = true;
    bool mergeText = true;
    bool sortNamespaces = true;
    bool sortMaps = true;
    bool sortLoose = false;
    bool sortTextures = false;
    bool sortText = true;
}


/**
 * Parse options from the commandline parameters and return them.
 * Recognized options are removed from argv.
 *
 * Params:
 * argv = The arguments passed to this program through main().
 *
 * Returns: An Options structure.
 */
public Options parse(ref string[] argv) {
    Options opts;
    
    if (argv.length == 1) {
        writeHelp();
    }

    getopt(argv,
        "license|l",      &writeLicense,
        "help|h|?",       &writeHelp,

        "output|o",       &opts.outputFile,
        "overwrite|w",    &opts.overwrite,
        "filter-patches", &opts.filterPatches,
        "merge-text",     &opts.mergeText,

        "sort-ns",        &opts.sortNamespaces,
        "sort-maps",      &opts.sortMaps,
        "sort-loose",     &opts.sortLoose,
        "sort-textures",  &opts.sortTextures,
        "sort-text",      &opts.sortText
    );

    return opts;
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
