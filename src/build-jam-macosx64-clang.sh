rm -rf ../bin/macosx64
mkdir ../bin/macosx64
clang -c -g -O3 -fomit-frame-pointer -arch x86_64 -Wno-parentheses -Wno-string-plus-int -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src onejam.c onejam-luaexpat.c
clang++ -c -g -O3 -fomit-frame-pointer -arch x86_64 -Wno-parentheses -Wno-string-plus-int -std=c++11 -I luaplus/Src/LuaPlus/lua53-luaplus/src -I luaplus/Src onejam-prettydump.cpp onejam-rapidjson.cpp onejam-ziparchive.cpp
clang++ -arch x86_64 -framework CoreFoundation -o ../bin/macosx64/jam onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
../bin/macosx64/jam --embedbuildmodules ../bin
mv ../bin/macosx64/jam.embed ../bin/macosx64/jam
chmod +x ../bin/macosx64/jam
rm onejam.o onejam-luaexpat.o onejam-prettydump.o onejam-rapidjson.o onejam-ziparchive.o
