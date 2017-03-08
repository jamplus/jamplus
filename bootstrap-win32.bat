setlocal
cd %~dp0src
call clean-win32
cmd /c call jmake-win32
cd luaplus
..\..\bin\win32\jam C.TOOLCHAIN=win32/releaseltcg
cd ..
set LUA_BIN=%~dp0src/luaplus/.build/win32/bin
cmd /c call jmake-win32
cd ..
