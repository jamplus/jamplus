rmdir /s/q %~dp0..\bin\win64
mkdir %~dp0..\bin\win64
cl /nologo /O2 onepackagesupportfiles.c
onepackagesupportfiles jamzipbuffer.c packagefiles.txt
cl /nologo /O2 /Oi /Gy /GL /EHsc /I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src /I %~dp0luaplus/Src /Fe"%~dp0..\bin\win64\jam.exe" onejam.c onejam-luaexpat.c onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
del /q onejam.obj onejam-luaexpat.obj onejam-prettydump.obj onejam-rapidjson.obj onejam-ziparchive.obj onepackagesupportfiles.exe
