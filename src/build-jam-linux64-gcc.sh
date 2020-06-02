rm -rf ../bin/linux64
mkdir -p ../bin/linux64
gcc -o onepackagesupportfiles onepackagesupportfiles.c
./onepackagesupportfiles jamzipbuffer.c packagefiles.txt
gcc -c -DLUA_USE_LINUX -g -O3 -fomit-frame-pointer -m64 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src -pthread onejam.c onejam-luaexpat.c
g++ -c -DLUA_USE_LINUX -g -O3 -fomit-frame-pointer -m64 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -std=c++11 -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
g++ -m64 -pthread -o ../bin/linux64/jam onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o -luuid -ldl
rm onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o onepackagesupportfiles jamzipbuffer.c
