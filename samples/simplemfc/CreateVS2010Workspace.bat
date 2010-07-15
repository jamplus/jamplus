@echo off
jam --workspace --gen=vs2010 Jamfile.jam ../../build/simplemfc
start ..\..\build\simplemfc
