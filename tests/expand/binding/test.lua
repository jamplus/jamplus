function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	local pattern1 = [[
No LOCATE - somefile.txt
With LOCATE - /somewhere/on/the/hard/drive/somefile.txt
*** found 3 target(s)...
*** updating 2 target(s)...
@ DoSomething somefile.txt
*** updated 2 target(s)...
]]

	TestPattern(pattern1, RunJam())

	local pass1Files =
	{
		'Jamfile.jam',
		'temp/somefile.txt',
	}
	TestFiles(pass1Files)

	local pattern2 = [[
No LOCATE - somefile.txt
With LOCATE - /somewhere/on/the/hard/drive/somefile.txt
*** found 3 target(s)...
*** updating 1 target(s)...
@ DoSomething somefile.txt
*** updated 1 target(s)...
]]
	TestPattern(pattern2, RunJam())

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

