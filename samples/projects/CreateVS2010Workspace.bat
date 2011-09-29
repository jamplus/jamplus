@echo off
jam --workspace --gen=vs2010 Jamfile.jam ../../build/projects
start ..\..\build\projects
