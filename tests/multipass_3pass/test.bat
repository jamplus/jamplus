@echo off
del Foo.*
echo >Foo.cpp
echo >Foo.h
echo =====Building with all 3 passes.  Foo.o should be built in the third pass.
pause
jam
pause
del Foo.*
echo >Foo.cpp
echo >Foo.h
echo =====Building only with passes 2 and 3.  Foo.o will be built.
pause
jam -s PASS_NUM=2
pause