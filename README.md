WADMerge
========
Merges multiple WAD files into one. Takes care of merging TEXTURE and PNAMES lumps, as well as merging multiple maps and namespaced lumps into one WAD. Known text-based lumps are concatenated, but no guarantees are given for the results. Run it without command line arguments to see usage instructions and available options.

Compiling
---------
This project is written in D.
http://dlang.org/

To compile it you can use the included Visual Studio 2012 project. You will need the VisualD plugin to use D with Visual Studio.
http://rainers.github.io/visuald/
