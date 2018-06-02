JamPlus
=======

JamPlus is a very fast and powerful code and data build system built on the code base of the original Perforce version of Jam written by Christopher Seiwald. JamPlus is regularly used to efficiently parallelize the builds of massive code and data sets.

A sampling of the features in the JamPlus distribution follows:

- **Multiplatform:** Binaries can be easily bootstrapped for Windows, various Unix systems, and Mac OS X.
- **Compiler support:** Out of box compiler support for Visual C++ 201x/200x/6, GCC, Clang, and MinGW.
- **Platform targets:** Platform modules are provided for building for Windows, Linux, macOS, iOS, and Android targets. Additionally, an Xbox 360 console platform is provided as a sample. If the machine has iOS Build Environment for Windows installed (see http://www.pmbaty.com/iosbuildenv/), then iOS builds can be made on a Windows Boot Camp partition.
- **Workspace/Project Generator:** Output project files for the Visual Studio IDE and Xcode.
- **Multiple Passes:** Run multiple internal passes collecting unknown dependencies, and execute them in a future pass.
- **Network Cache:** Any to-be-built target can be retrieved from one or more shared network file caches of prebuilt targets.
- **Command-line Dependencies:** When the 'command line' of a target (not necessarily the real command line) changes, the target is rebuilt.
- **Powerful New Variable Expansion:** Convert between slash types, expand literal text, include or exclude list components, recursive file globs, and more.
- **Dependency (Header) Cache:** When dependency information is scanned, it is cached for the next build, offering a huge performance boost.
- **Batch Compilation:** JamPlus is able to batch files to tools that support it, such as the Visual C++ compiler.
- **Checksum support:** Enable a flag, and JamPlus will use the checksums of files to detect change instead of timestamps.
- **Lua support:** Either a partial build description or the entire build description can be written in Lua.

Authors
-------

Jam's author is Christopher Seiwald (seiwald@perforce.com).  *Note: Much of this documentation is taken verbatim from the jam.html file which ships with the Perforce Jam build.*

JamPlus's primary maintainer is Joshua Jensen (jjensen@workspacewhiz.com).

Patches come from the Jam mailing list and Perforce Public Depot, with the primary authors being Alen Ladavac, Craig McPheeters, and Matt Armstrong. Additional patches are linked from the source code back to the Jamming mailing list.
