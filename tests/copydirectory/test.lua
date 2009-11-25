function Test()
	local originalFiles =
	{
		'Jamfile.jam',
		'source/file1.txt',
		'source/file2.txt',
		'source/dira/file3.dat',
		'source/dirb/abc.txt',
		'source/dirb/copyme/copyme.txt',
		'source/dirb/ignore/dontcopy.txt',
	}

	local originalDirs =
	{
		'source/',
		'source/dira/',
		'source/dirb/',
		'source/dirb/copyme/',
		'source/dirb/ignore/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	local run1pattern =
	{
		'*** found 18 target(s)...',
		'*** updating 11 target(s)...',
		'@ CopyFile1 destination/file1.txt',
		'!NEXT!@ CopyFile1 destination/file2.txt',
		'!NEXT!@ CopyFile1 destination/dira/file3.dat',
		'!NEXT!@ CopyFile1 destination/dirb/abc.txt',
		'!NEXT!@ CopyFile1 destination/dirb/copyme/copyme.txt',
		'!NEXT!@ CopyFile1 destination/dirb/ignore/dontcopy.txt',
		'*** updated 11 target(s)...',
	}
	
	TestPattern(run1pattern, RunJam())

	local newFiles =
	{
		'Jamfile.jam',
		'destination/file1.txt',
		'destination/file2.txt',
		'destination/dira/file3.dat',
		'destination/dirb/abc.txt',
		'destination/dirb/copyme/copyme.txt',
		'destination/dirb/ignore/dontcopy.txt',
		'source/file1.txt',
		'source/file2.txt',
		'source/dira/file3.dat',
		'source/dirb/abc.txt',
		'source/dirb/copyme/copyme.txt',
		'source/dirb/ignore/dontcopy.txt',
	}
	TestFiles(newFiles)

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

