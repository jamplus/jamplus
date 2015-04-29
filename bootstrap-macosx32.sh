rm -rf bin/macosx32 src/bin.macosxx86 src/jam0 src/luaplus/.build/macosx32
cd src
make macosx32
cd luaplus
../../bin/macosx32/jam C.TOOLCHAIN=macosx32/releaseltcg
cd ..
export LUA_BIN=luaplus/.build/macosx32/bin
make macosx32
export LUA_BIN=
cd ..

