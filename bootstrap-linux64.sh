cd src
make linux64
cd luaplus
../../bin/linux64/jam LUA_VERSION=lua52-luaplus C.TOOLCHAIN=linux64/release
cd ..
export LUA_BIN=luaplus/.build/bin.lua52-luaplus.gcc.linux64
make linux64
export LUA_BIN=
cd ..

