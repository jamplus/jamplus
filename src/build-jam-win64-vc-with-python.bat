rmdir /s/q %~dp0..\bin\win64
mkdir %~dp0..\bin\win64
cl /nologo /O2 /Oi /Gy /GL /EHsc /I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src /I %~dp0luaplus/Src /I%~dp0python/include /Fe"%~dp0..\bin\win64\jam.exe" onejam.c onejam-luaexpat.c onejam-prettydump.cpp onejam-python.c onejam-rapidjson.cpp onejam-ziparchive.cpp /link /LIBPATH:%~dp0python/Libs
%~dp0..\bin\win64\jam.exe --embedbuildmodules %~dp0..\bin
move %~dp0..\bin\win64\jam.exe.embed %~dp0..\bin\win64\jam.exe
del /q onejam.obj onejam-luaexpat.obj onejam-prettydump.obj onejam-rapidjson.obj onejam-ziparchive.obj
