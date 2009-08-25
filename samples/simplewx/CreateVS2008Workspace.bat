@echo off
jam --workspace --gen=vs2008 Jamfile.jam ../../build/simplewx
start ..\..\build\simplewx
