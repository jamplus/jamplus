git submodule update --init
cd src
rm -rf bin.macosxx64 jam0
make macosx64
cd luaplus
../../bin/macosx64/jam LUA_VERSION=lua52-luaplus C.TOOLCHAIN=macosx64/releaseltcg
cd ..
export LUA_BIN=luaplus/.build/bin.lua52-luaplus.clang.macosx64
make macosx64

