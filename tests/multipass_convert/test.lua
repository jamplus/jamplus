function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'alternate_input1.txt',
		'input1.txt',
		'input2.txt',
	}

	local originalDirs =
	{
	}

	ospath.remove('.depcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 7 target(s)...
*** updating 3 target(s)...
@ ConvertInputToJam input1.txt.jam
@ ConvertAlternateInputToJam alternate_input1.txt.jam
@ ConvertInputToJam input2.txt.jam
*** updated 3 target(s)...
WriteOutput all - output1.dat
WriteOutput all - output2.dat
WriteOutput all - output3.dat
WriteOutput all - output4.dat
WriteOutput all - output5.dat
WriteOutput all - output6.dat
WriteOutput all - output7.dat
WriteAlternateOutput alternate_output1.dat
WriteAlternateOutput alternate_output2.dat
*** found 13 target(s)...
*** updating 12 target(s)...
@ WriteFile output1.dat
@ WriteFile output2.dat
@ WriteFile output3.dat
@ WriteFile output4.dat
@ WriteFile output5.dat
@ WriteFile output6.dat
@ WriteFile output7.dat
@ WriteFile alternate_output1.dat
@ WriteFile alternate_output2.dat
*** updated 12 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'.depcache',
		'Jamfile.jam',
		'alternate_input1.txt',
		'alternate_input1.txt.jam',
		'alternate_output1.dat',
		'alternate_output2.dat',
		'input1.txt',
		'input1.txt.jam',
		'input2.txt',
		'input2.txt.jam',
		'output1.dat',
		'output2.dat',
		'output3.dat',
		'output4.dat',
		'output5.dat',
		'output6.dat',
		'output7.dat',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 7 target(s)...
WriteOutput all - output1.dat
WriteOutput all - output2.dat
WriteOutput all - output3.dat
WriteOutput all - output4.dat
WriteOutput all - output5.dat
WriteOutput all - output6.dat
WriteOutput all - output7.dat
WriteAlternateOutput alternate_output1.dat
WriteAlternateOutput alternate_output2.dat
*** found 16 target(s)...
]]
	TestPattern(pattern2, RunJam{})
	TestFiles(pass1Files)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern = [[
*** found 2 target(s)...
WriteOutput all - output1.dat
WriteOutput all - output2.dat
WriteOutput all - output3.dat
WriteOutput all - output4.dat
WriteOutput all - output5.dat
WriteOutput all - output6.dat
WriteOutput all - output7.dat
WriteAlternateOutput alternate_output1.dat
WriteAlternateOutput alternate_output2.dat
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern, RunJam{ 'clean' })
	
	local cleanFiles =
	{
		'.depcache',
		'Jamfile.jam',
		'alternate_input1.txt',
		'input1.txt',
		'input2.txt',
	}
	TestFiles(cleanFiles)
	TestDirectories(originalDirs)
	ospath.remove('.depcache')
end

