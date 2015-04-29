cd src
make linux32
cd luaplus
../../bin/linux32/jam LUA_VERSION=lua52-luaplus
cd ..
export LUA_BIN=luaplus/.build/bin.lua52-luaplus.gcc.linux32
make linux32
export LUA_BIN=
cd ..

