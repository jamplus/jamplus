setlocal
cl /nologo /O2 onepackagesupportfiles.c
onepackagesupportfiles jamzipbuffer.c packagefiles.txt
rem cl /nologo /O2 /Oi /Gy /GL /I %~dp0luaplus/Src/LuaPlus/lua53-luaplus/src /Fe"%~dp0..\bin\win64\jam.exe" onejam.c
set OPTIM=/O2 /Oi /Gy /GL
set LUASRC=%~dp0luaplus/Src/LuaPlus/lua53-luaplus/src
cl /nologo /c %OPTIM% /I %LUASRC% onejam.c
cl /nologo /c %OPTIM% /I %LUASRC% onejam-luaexpat.c
cl /nologo /c %OPTIM% /EHsc /I %~dp0luaplus/Src /I %LUASRC% onejam-prettydump.cpp
cl /nologo /c %OPTIM% /EHsc /I %LUASRC% /I %~dp0luaplus/Src/Modules/lua-rapidjson/rapidjson/include onejam-rapidjson.cpp
rem cl /nologo /c %OPTIM% /I %LUASRC% onejam-luasocket.c
link /LTCG /out:"%~dp0..\bin\win64\jam.exe" onejam.obj onejam-luaexpat.obj onejam-prettydump.obj onejam-rapidjson.obj


