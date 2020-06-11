rm -rf ../bin/linux32
mkdir -p ../bin/linux32
gcc -c -DLUA_USE_LINUX -g -O3 -fomit-frame-pointer -m32 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src -pthread onejam.c onejam-luaexpat.c
g++ -c -DLUA_USE_LINUX -g -O3 -fomit-frame-pointer -m32 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -std=c++11 -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
g++ -m32 -pthread -o ../bin/linux32/jam onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o -luuid -ldl
../bin/linux32/jam --embedbuildmodules ../bin
mv ../bin/linux32/jam.embed ../bin/linux64/jam
chmod +x ../bin/linux32/jam
rm onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
