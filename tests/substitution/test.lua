function Test()
	do
		local pattern
		if Platform == 'win32' then			
			pattern = [[
$ = $
$
$(TEMP) - ]] .. os.getenv("TEMP") .. [[

M__UFFILENAME_UFFILENAME__F
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

		else
			local tmpdir = os.getenv('TMPDIR')
			if not tmpdir or tmpdir == '' then tmpdir = '/tmp' end
			
			pattern = [[
$ = $ 
$ 
$(TMPDIR) - ]] .. tmpdir .. [[

M__UFFILENAME_UFFILENAME__F 
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]		
		end

		TestPattern(pattern, RunJam{ '-f-substitution.jam' })
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
__/__/dir/__/dir2
hello hello world world
hello hello world
world hello Lua from
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

		TestPattern(pattern, RunJam{ '-f-testgsub.jam' })
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
substitution.jam testgsub.jam testwildcards.jam
file2.c file2.o file3.c file3.o
file1.c file2.c file3.c
file1.c file2.c file3.c file1.o file2.o file3.o
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

		TestPattern(pattern, RunJam{ '-f-testwildcards.jam' })
	end
end

TestChecksum = Test
