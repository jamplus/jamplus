rm -rf bin/macosx64 src/bin.macosxx86 src/jam0 src/luaplus/.build/macosx64
cd src
make macosx64
cd luaplus
../../bin/macosx64/jam C.TOOLCHAIN=macosx64/releaseltcg
cd ..
export LUA_BIN=luaplus/.build/macosx64/bin
make macosx64
export LUA_BIN=
cd ..

