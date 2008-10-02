#!/bin/sh

# Add . to the path since the Jam stuff depends on it
PATH=$PATH:.
export PATH

if [ x$OS = xWindows_NT ]; then
    SUFEXE=.exe
    MAKECMD='make -f Makefile.Windows'
else
    SUFEXE=
    MAKECMD='make'
fi

$MAKECMD
jam=`find . -type f -name jam$SUFEXE`
$jam -sBUILD_J=yes
j=`find . -type f -name j$SUFEXE`
echo "stock jam is at $jam"
echo "j is at $j"
