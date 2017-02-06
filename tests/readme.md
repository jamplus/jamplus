JamPlus Test Suite
==================

JamPlus contains an extensive test suite covering a majority of its features. The test suite also serves as a large list of examples of techniques for Jam usage.

The following is a high-level list of what each directory's purpose is:

  * **alternate_jambase_in_workspace/examples/** - Illustrates overriding the default generated Jambase.jam within an out-of-source build directory created with `jam --workspace -jambase=TheNewJambase.jam`.
  * **autosettings/** - Shows how the third argument to an action is used to further alter the environment the action runs within. For example, within the C module, the third argument is a 'target' containing information about the compiler suite and what applications and settings to use for a build. The **autosettings** test is a simpler version of that.
  * **batch/** - An example of using the `actions` modifier `maxtargets` to limit the number of targets batched to an action at a time.
  * **bindingname/** - Targets in Jam are just names. When the `NotFile` flag is not present on a target, the target is intended to represent a file on the disk. By default, the name of the target is the name of the file. By applying the `BINDING` variable to a target, the name of the file will be that specified by `BINDING` while the name of the target can be different. This test ensures `BINDING` works properly.
  * **checksum/** - Various tests ensuring `JAM_CHECKSUMS=1` works properly.
    * **generated-c-and-h/** - Tests generation and modification of `.c` and `.h` files.
    * **generated-c-and-h-circular/** - Tests generation and modification of `.c` and `.h` files where the `.h` file is in a set of circular #includes.
    * **generated-c-and-h-deep/** - Tests generation and modification of a `.c` and multiple `.h` files where the generated `.h` files #include other generated `.h` files.
    * **generated-c-and-h-deep-circular/** - Tests generation and modification of a `.c` and multiple `.h` files where the generated `.h` files #include other generated `.h` files in a circular fashion.
    * **generated-c-and-h-deep-extra/** - Tests generation into a another directory and modification of a `.c` and multiple `.h` files where the generated `.h` files #include other generated `.h` files.
    * **generated-c-and-h-extra/** - Tests generation into another directory and modification of a `.c` and multiple `.h` files where the generated `.h` files #include other generated `.h` files.
    * **simple/** - Tests generation and modification of a single `.h` file.
    * **simple-complete/** - Tests generation and modification of a deeper set of files.
    * **simple-transform-with-exe** - TODO: Make it work.
  * **clean_up/** - Various illustrations of JamPlus' ability to remove extra files and directories that are not part of the build or user-specified as to keep.
  * **command_line_targets/** - Targets specified to build by the user via the Jam executable command-line are inserted into the variable `JAM_COMMAND_LINE_TARGETS`. This test ensures that works properly. TODO: Show how to alter `JAM_COMMAND_LINE_TARGETS`.
  * **compile_outputastree/** - Ensures the `C.CompileOptions outputastree` setting causes directory hierarchies are used in the intermediate outputs of the build.
  * **configurefile/** - JamPlus contains a simple facility to expand a 'config' file through `C.ConfigureFile` in an approach similar to CMake. This basic test shows how that is done. TODO: Fix `test.broken.lua`.
  * **config_overrides/** - TODO: Broken.
  * **copydirectory/** - Illustrates the `CopyDirectory` rule.
  * **dependency/** - A test from the Jamming mailing list to ensure targets are processed in the correct order.
  * **expand/** - Tests all of the various variable expansion modifiers.
  * **filecache/** - A simple transformation test showing how a file cache can be used to cache the results of the build to be retrieved in subsequent builds.
  * **filecache_luamd5callback/** - A more advanced transformation test showing how to generate custom checksums from `.png` and `.zip` files. The built-in checksum reads the entire file and may be slow depending on your file's size. This test reads just portions of standard `.png` and `.zip` files to generate a reasonable enough checksum for the job.
  * **forceinclude/** - Tests both project-wide and single file force includes for C projects.
  * **fx/** - TODO: Broken.
  * **generatedc/** - Tests generating a C file and then using it to build an executable.
  * **generatedheader/** - A suite of tests generating header files for C code.
    * **circular/** - Tests generating a header used in a circular fashion.
    * **scancontents-multiproject/** - Tests generating a header and using it properly across multiple libraries and an executable.
    * **scancontents-single/** - Tests generating a header and using `ScanContents` to detect whether the generated header file actually changes to initiate a build. Note: The `ScanContents` facility is nowhere near as powerful as the `JAM_CHECKSUMS` support, so consider just using `JAM_CHECKSUMS` instead.
    * **simple/** - Tests generating a simple header and using it in an executable build.
  * **generate_libs/** - Used to test performance for a lot of libraries and files.
  * **glob/** - Tests the `Glob` and `ListSort` rules.
  * **groupbyvar/** - Tests the `GroupByVar` rule.
  * **helloworld/** - It's a "Hello, world!" test. That is all.
  * **includes/** - Tests the `C.IncludeDirectories` and `C.ObjectIncludeDirectories` rules by touching and modifying header files in a C build.
  * **inherits/** - Tests the `C.Inherits` rule.
  * **language/local_variables/** - Tests a portion of local variable scoping in the Jam language.
  * **linefilters/** - Tests the line filtering facility, the ability to alter lines of output text from an action.
  * **listsort/** - Tests the `ListSort` rule.
  * **lua/** - Tests JamPlus' Lua support both at the parser level and at the actions level.
  * **manifest_generation/** - Tests support for proper Visual C++ manifest generation.
  * **math/** - Tests the `Math` rule.
  * **md5/** - Tests the `MD5` rule.
  * **minusequals/** - Tests the `-=` operator which is a JamPlus extension.
  * **multipass/** - Tests `QueueJamFile` ability to queue up a second pass of Jam after the initial parsing+actions phases are complete. The second pass writes out a `Pass3.jam` file, and then the third pass is initiated.
  * **multipass_3pass/** - Tests a multipass build of Jam by reloading the same Jamfile across 3 passes.
  * **multipass_3pass_generatedheader/** - Tests a 3-pass build by first writing a `main.cpp` and `foo.cpp` file that #includes a non-existent `foo.h` and then attempting to build an application with `main.cpp` and `foo.cpp`. Upon realizing `foo.h` is missing, Jam executes its second pass and writes `foo.h`. The third pass is used to provide a `clean` target instruction for the generated targets.
  * **multipass_convert/** - Tests a multipass build where the names of the targets are not known until read from a file.
  * **multipass_error/** - Tests the ability to detect errors in a multipass build.
  * **multipass_nocare/** - Tests `NoCare` being applied to generated files in a multipass build.
  * **multipass_waittargets/** - Tests the ability to continue collecting information for targets in a multipass build and act on the target in a subsequent pass when the needed information is known.
  * **multipass_waittargets_more/** - Tests the ability to collect information for targets in a 3-pass build and act on the target at the earliest possible point.
  * **multiplatform/** - Compiles the code with different source files and #defines depending on which platform and config is specified.
  * **platform/** - Illustrates the creation of a new set of platforms.
    * **groovyplatform/** - Tests the creation of the groovyplatform with its own set of configurations.
    * **groovypluswin32/** - Tests the creation of the groovyplatform and makes win32 available in the generated workspace.
  * **precompiled_header/** - Tests creation and usage of a C++ precompiled header.
  * **precompiled_header_no_cpp/** - Tests creation and usage of a C++ precompiled header without having a `.cpp` file to generate the precompiled header with, a necessity with Visual C++.
  * **precompiled_header_no_cpp_pch/** - Tests automatic creation of a C++ precompiled header without having a `.cpp` file.
  * **scancontents/** - Shows simple generation of a `.h` file with the `ScanContents` flag applied. A `JAM_CHECKSUMS` build is far better to use than `ScanContents`, although `ScanContents` works in simple cases.
  * **semicolon/** - Tests JamPlus' extensions for detection of improper usage of colons and semicolons, since Jam is a whitespace-significant language.
  * **sharedlib/** - Tests various scenarios for building a shared library.
  * **shell/** - Tests the `Shell` rule.
  * **simplelib/** - Tests various scenarios for building a static library.
  * **source_and_jamfiles_separate/** - Tests the ability for a Jamfile to reside in a directory structure separate from the source files. TODO: Show the other technique that does not require relative paths to the source files.
  * **split/** - Test the `Split` rule.
  * **substitution/** - Tests various methods of substituting text within Jam.
  * **usecommandline/** - Tests the `UseCommandLine` rule.
  * **workspace/** - Shows some additional workspace generation techniques.
    * **external_project/** - Illustrates how to add an external non-Jam generated project to a generated workspace.
    * **user_configs/** - Illustrates how to add user configurations and altering the toolchain to account for the changes.

