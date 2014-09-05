function Test()
    RunJam{ 'clean' }

    local cleanFiles =
    {
        'Jamfile.jam',
    }
    TestFiles(cleanFiles)

	if Platform == 'win32' then
		local run1pattern =
		{
			'*** found 8 target(s)...',
			'*** updating 8 target(s)...',
			'@ WriteFile out.txt',
			'@ WriteFile out2.txt',
			'@ WriteExtraFiles all',
			'*** updated 8 target(s)...',
		}

		TestPattern(run1pattern, RunJam())
	else
		local run1pattern =
		{
			'*** found 5 target(s)...',
			'*** updating 5 target(s)...',
			'@ WriteFile out.txt',
			'@ WriteFile out2.txt',
			'@ WriteExtraFiles all',
			'*** updated 5 target(s)...',
		}

		TestPattern(run1pattern, RunJam())
	end

    local allFiles = {
        'Jamfile.jam',
        'subdir1/junk.txt',
        'subdir1/subdir2/out2.txt',
        'subdira/extrafile.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
        'subdira/subdirb/subdirc/subdird/anotherjunk.txt',
        'subdira/subdirb/subdirc/subdird/junk.txt',
    }
    TestFiles(allFiles)

    local allDirectories = {
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
        'subdira/subdirb/subdirc/subdird/',
    }
    TestDirectories(allDirectories)

    TestPattern({
        '*** found 2 target(s)...',
        '*** updating 1 target(s)...',
        '@ Clean clean',
        '@ CleanTree clean',
        '*** updated 1 target(s)...',
    }, RunJam{ 'clean' })

    TestFiles(cleanFiles)

    ---------------------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 8 target(s)...',
			'@ WriteFile out.txt',
			'@ WriteFile out2.txt',
			'@ WriteExtraFiles all',
			'*** updated 8 target(s)...',
		}, RunJam())
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 5 target(s)...',
			'@ WriteFile out.txt',
			'@ WriteFile out2.txt',
			'@ WriteExtraFiles all',
			'*** updated 5 target(s)...',
		}, RunJam())
	end

    TestFiles(allFiles)
    TestDirectories(allDirectories)

    ---------------------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
		}, RunJam())
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
		}, RunJam())
	end

    TestFiles(allFiles)
    TestDirectories(allDirectories)

    ---------------------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=1'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=1'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
    }

    ---------------------------------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    ---------------------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=2'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=2'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/extrafile.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
    }

    ---------------------------------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    -----------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=3'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=3'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/extrafile.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
        'subdira/subdirb/subdirc/subdird/anotherjunk.txt',
        'subdira/subdirb/subdirc/subdird/junk.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
        'subdira/subdirb/subdirc/subdird/',
    }

    --------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    -----------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/junk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_TARGETS=1'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/junk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_TARGETS=1'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/junk.txt',
        'subdir1/subdir2/out2.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
    }

    --------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    -----------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/junk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=1'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/junk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=1'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
    }

    --------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    -----------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=2'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=2'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/subdird/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
        'subdira/subdirb/subdirc/subdird/',
    }

    --------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)

    -----------------------------------
	if Platform == 'win32' then
		TestPattern({
			'*** found 8 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=3'})
	else
		TestPattern({
			'*** found 5 target(s)...',
			'*** updating 1 target(s)...',
			'@ WriteExtraFiles all',
			'*** updated 1 target(s)...',
			'Removing subdira/extrafile.txt...',
			'Removing subdir1/junk.txt...',
		}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=3'})
	end

    TestFiles({
        'Jamfile.jam',
        'subdir1/subdir2/out2.txt',
        'subdira/junk.txt',
        'subdira/subdirb/subdirc/subdird/anotherjunk.txt',
        'subdira/subdirb/subdirc/subdird/junk.txt',
        'subdira/subdirb/subdirc/out.txt',
    })

    TestDirectories{
        'subdir1/',
        'subdir1/subdir2/',
        'subdira/',
        'subdira/subdirb/',
        'subdira/subdirb/subdirc/',
        'subdira/subdirb/subdirc/subdird/',
    }

    --------------------
    RunJam()
    TestFiles(allFiles)
    TestDirectories(allDirectories)
end

