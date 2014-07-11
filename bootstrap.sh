cd src
make macosx32
cd luaplus
../../bin/macosx32/jam LUA_VERSION=lua51-luaplus
cd ..
export LUA_BIN=luaplus/.build/bin.lua51-luaplus.clang.macosx32
make macosx32

