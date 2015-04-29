cd src
rm -rf bin.macosxx86 jam0
make macosx32
cd luaplus
../../bin/macosx32/jam LUA_VERSION=lua52-luaplus
cd ..
export LUA_BIN=luaplus/.build/bin.lua52-luaplus.clang.macosx32
make macosx32
export LUA_BIN=
cd ..

