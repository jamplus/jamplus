c:\llvm-mingw\bin\clang -o onepackagesupportfiles.exe onepackagesupportfiles.c
onepackagesupportfiles jamzipbuffer.c packagefiles-win.txt
c:\llvm-mingw\bin\clang -c -Wno-parentheses -Wno-string-plus-int -fms-extensions -I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src -I%~dp0luaplus/Src onejam.c onejam-luaexpat.c
c:\llvm-mingw\bin\clang++ -c -Wno-parentheses -Wno-string-plus-int -fms-extensions -I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src -I%~dp0luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
c:\llvm-mingw\bin\clang++ -static -o onejam.exe onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
