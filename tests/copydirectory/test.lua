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
		'*** found 30 target(s)...',
		'*** updating 20 target(s)...',
		'!OOOGROUP!@ Copy1File $(CWD)destination/file1.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination/file2.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination/dira/file3.dat',
		'!OOOGROUP!@ Copy1File $(CWD)destination/dirb/abc.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination/dirb/copyme/copyme.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination/dirb/ignore/dontcopy.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination2/dira/file3.dat',
		'!OOOGROUP!@ Copy1File $(CWD)destination2/dirb/abc.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination2/dirb/copyme/copyme.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination2/file1.txt',
		'!OOOGROUP!@ Copy1File $(CWD)destination2/file2.txt',
		'!NEXT!*** updated 20 target(s)...',
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
		'destination2/file1.txt',
		'destination2/file2.txt',
		'destination2/dira/file3.dat',
		'destination2/dirb/abc.txt',
		'destination2/dirb/copyme/copyme.txt',
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

