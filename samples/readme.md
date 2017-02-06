JamPlus Samples
===============

This directory is comprised of a number of examples utilizing JamPlus as a build system.

  * **csharp-windowsforms/** - An example of a simple C# application.
  * **fakeps3/** - TODO: Broken. Needs to be updated.
  * **glob/** - Builds a command-line utility called `glob` exposing the filefind capabilities in Jam as standalone.
  * **ios/** - A number of iOS-specific samples. These must be built on a Mac either using macOS or a BootCamp partition running Windows and the iOS Build Environment for Windows.
    * **complex-info-plist/** - Shows a number of ways to generate an `Info.plist`.
    * **simple/** - Shows setup of a simple iOS application with `.ipa` generation and a local webserver to get the `.ipa` to your device. Build the executable with `jam c.toolchain=ios/release` or build the `.ipa` with `jam c.toolchain=ios/release archive:simple` after dropping a `test.mobileprovision` file of your choice in the directory.
    * **simple-multiple-architectures/** - Shows setup of a simple iOS application that is built for arm64 and armv7. Build the executable with `jam c.toolchain=ios/release` or build the `.ipa` with `jam c.toolchain=ios/release archive:simple` after dropping a `test.mobileprovision` file of your choice in the directory.
  * **lua/** - A number of Lua-driven examples.
    * **assetbuild/** - A complete asset build script used by an upcoming mobile game.
    * **helloworld/** - A simple Jamfile.lua showing how to build a helloworld app.
  * **lua-exe/** - Illustrates how to build a Lua executable, Lua shared library, and LuaSocket as a module.
  * **macosx/** - A number of macOS samples.
  * **newplatforms/** - Adds new platforms `win32dx` and `win32ogl`. Build with `jam c.toolchain=win32dx/release` or `jam c.toolchain=win32ogl/release`.
  * **onesharedlib/** - Just a single shared library that gets built.
  * **projects/** - Shows how to create custom projects and add them to your workspace.
  * **qt/mainwindow/** - A simple example showing how to build an application with Qt. This was last checked at an earlier major version of Qt than the current one.
  * **sdl/** - A multi-architecture example for an SDL application. It currently includes support for Windows, iOS, and Android.
  * **sharedlib/** - A sample showing off multiple shared libraries.
  * **simplemfc/** - An MFC example.
  * **simplewx/** - A wxWidgets example.
  * **toolchains-helloworld/** - Build lots of helloworld executables under a variety of compilers in a single Jam run.
  * **tutorials/** - The root of a number of tutorial directories.
    * **01-helloworld/** - A simple helloworld application.
    * **01-helloworld-static/** - A fully statically-linked helloworld application.
  * **unittest/** - Shows a method of running unit tests via a Lua action after an executable is built. Run `jam tests`.