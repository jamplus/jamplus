rm Foo.*
echo >Foo.cpp
echo >Foo.h
echo =====Building with all 3 passes.  Foo.o should be built in the third pass.
read -p "Press any key to continue..."
jam
read -p "Press any key to continue..."
rm Foo.*
echo >Foo.cpp
echo >Foo.h
echo =====Building only with passes 2 and 3.  Foo.o will be built.
read -p "Press any key to continue..."
jam -s PASS_NUM=2
read -p "Press any key to continue..."
