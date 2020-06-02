rmdir /s/q %~dp0..\bin\win64
mkdir %~dp0..\bin\win64
clang -o onepackagesupportfiles.exe onepackagesupportfiles.c
onepackagesupportfiles jamzipbuffer.c packagefiles.txt
clang -c -m64 -Wno-parentheses -Wno-string-plus-int -fms-extensions -I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src -I%~dp0luaplus/Src onejam.c onejam-luaexpat.c
clang++ -c -m64 -Wno-parentheses -Wno-string-plus-int -fms-extensions -I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src -I%~dp0luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
clang++ -m64 -static -o %~dp0..\bin\win64\jam.exe onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
del /q onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o onepackagesupportfiles.exe jamzipbuffer.c

