@echo off
jam --workspace --gen=vs2005 --compiler=vs2005 Jamfile.jam ../../build/simplemfc
start ..\..\build\simplemfc
