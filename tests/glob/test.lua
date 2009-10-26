function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'glob.jam',
	}

	local originalDirs =
	{
	}

	RunJam{ '-f', 'glob.jam', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	-- First build
	local pattern = [[
All - ../../bin/.gitignore ../../bin/Jambase.jam ../../bin/modules/ ../../bin/ntx86/ ../../bin/scripts/
Dirs Only - ../../bin/modules/ ../../bin/ntx86/ ../../bin/scripts/
Files Only - ../../bin/.gitignore ../../bin/Jambase.jam
----------------------- No prepend
All - .gitignore Jambase.jam modules/ ntx86/ scripts/
Dirs Only - modules/ ntx86/ scripts/
Files Only - .gitignore Jambase.jam
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

	TestPattern(pattern, RunJam{'-f', 'glob.jam'})
end

