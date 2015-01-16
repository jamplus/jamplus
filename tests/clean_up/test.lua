function Test()
    RunJam{ 'clean' }

    local cleanFiles =
    {
        'Jamfile.jam',
    }
    TestFiles(cleanFiles)

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
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 5 target(s)...',
		'@ WriteFile out.txt',
		'@ WriteFile out2.txt',
		'@ WriteExtraFiles all',
		'*** updated 5 target(s)...',
	}, RunJam())

    TestFiles(allFiles)
    TestDirectories(allDirectories)

    ---------------------------------------------
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 1 target(s)...',
		'@ WriteExtraFiles all',
		'*** updated 1 target(s)...',
	}, RunJam())

    TestFiles(allFiles)
    TestDirectories(allDirectories)

    ---------------------------------------------
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
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 1 target(s)...',
		'@ WriteExtraFiles all',
		'*** updated 1 target(s)...',
		'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
		'Removing subdira/subdirb/subdirc/subdird/junk.txt...',
		'Removing subdir1/junk.txt...',
	}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=2'})

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
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 1 target(s)...',
		'@ WriteExtraFiles all',
		'*** updated 1 target(s)...',
		'Removing subdir1/junk.txt...',
	}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_KEEP_WILDCARDS=3'})

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
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 1 target(s)...',
		'@ WriteExtraFiles all',
		'*** updated 1 target(s)...',
		'Removing subdira/extrafile.txt...',
		'Removing subdira/subdirb/subdirc/subdird/anotherjunk.txt...',
		'Removing subdir1/junk.txt...',
	}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=2'})

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
	TestPattern({
		'*** found 5 target(s)...',
		'*** updating 1 target(s)...',
		'@ WriteExtraFiles all',
		'*** updated 1 target(s)...',
		'Removing subdira/extrafile.txt...',
		'Removing subdir1/junk.txt...',
	}, RunJam{'CLEAN.VERBOSE=1', 'TEST_CLEAN_ROOTS=3'})

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

    RunJam{ 'clean' }
end

