gl-spec-parser
==============

A parser for OpenGL spec files that supports templated output.

Usage
-----

    $ glgen <target> <version>

Where target is the appropriate template name under templates and version is an
OpenGL version sans the version dot. For example:

    $ glgen luajit 42

The functions are also easily accessible from Lua, by importing the parser or
generator libraries. There's no documentation for these yet but they're nearly
single function interfaces and should be pretty straightforward.
