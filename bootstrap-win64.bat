setlocal
cd %~dp0src
call clean-win64
call jmake-win64
cd luaplus
..\..\bin\win64\jam C.TOOLCHAIN=win64/releaseltcg
cd ..
set LUA_BIN=%~dp0src/luaplus/.build/win64/bin
call jmake-win64
cd ..
