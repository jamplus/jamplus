cd src
make linux32
cd luaplus
../../bin/linux32/jam LUA_VERSION=lua53-luaplus C.TOOLCHAIN=linux32/release
cd ..
export LUA_BIN=luaplus/.build/linux32/bin
make linux32
export LUA_BIN=
cd ..

