@echo off
jam --workspace --gen=vs2005 Jamfile.jam ../../build/projects
start ..\..\build\projects
