rm -rf ../bin/win64
mkdir -p ../bin/win64
gcc -c -g -O3 -fomit-frame-pointer -fms-extensions -m64 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src -pthread onejam.c onejam-luaexpat.c
g++ -c -g -O3 -fomit-frame-pointer -fms-extensions -m64 -Wno-parentheses -Wno-unused-result -Wno-stringop-overflow -std=c++11 -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
g++ -m64 -pthread -o ../bin/win64/jam onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o -lWinmm -lRpcrt4
../bin/win64/jam --embedbuildmodules ../bin
mv ../bin/win64/jam.exe.embed ../bin/win64/jam.exe
rm onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
