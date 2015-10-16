WADMerge
========
This utility merges multiple WAD files into one. It takes care of merging TEXTURE and PNAMES lumps, as well as merging multiple maps and namespaced lumps. Known text-based lumps are concatenated, but no guarantees are given for the results. Run it without command line arguments or --help to see usage instructions and a list of available options.

Compiling
---------
This project is written in the D programming language.
http://dlang.org/

To compile it you can use the included Visual Studio 2013 project. You will need the VisualD plugin to use D with Visual Studio.
http://rainers.github.io/visuald/
