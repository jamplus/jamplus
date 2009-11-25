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
All - ../copydirectory/Jamfile.jam ../copydirectory/source/ ../copydirectory/test.lua 
Dirs Only - ../copydirectory/source/ 
Files Only - ../copydirectory/Jamfile.jam ../copydirectory/test.lua 
----------------------- No prepend 
All - Jamfile.jam source/ test.lua 
Dirs Only - source/ 
Files Only - Jamfile.jam test.lua 
]]

	TestPattern(pattern, RunJam{'-f', 'glob.jam'})
end

