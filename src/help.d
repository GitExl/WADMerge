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

module help;


// Command line help text.
string HELP = "Merges multiple WAD files into one.

Usage: wadmerge [input files] [options]

-h, --help     Show this help message.
-l, --license  Display this program's license.

Output
-o, --output=path      Set the output WAD filename. Default: merged.wad
-w, --overwrite        Overwrite the output file without asking for
                       confirmation.
--filter-patches=true  Do not include patch graphic lumps that are not present
                       in any texture definition.
--merge-text=true      Merges text-based lumps together.

Sorting
--sort-ns=true         Sort namespaced lumps alphabetically.
--sort-maps=true       Sort maps alphabetically.
--sort-loose=false     Sort loose lumps alphabetically.
--sort-textures=false  Sort textures alphabetically.
--sort-text=true       Sort text lumps alphabetically.";
