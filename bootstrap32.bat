cd src
call clean
call jmake
cd luaplus
..\..\bin\win32\jam LUA_VERSION=lua52-luaplus
cd ..
set LUA_BIN=%~dp0src/luaplus/.build/bin.lua52-luaplus.vs2013.win32
call jmake

