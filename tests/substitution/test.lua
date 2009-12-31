function Test()
	do
		local pattern
		if Platform == 'win32' then			
			pattern = [[
$ = $
$
$(TEMP) - ]] .. os.getenv("TEMP") .. [[

M__UFFILENAME_UFFILENAME__F
]]

		else
			pattern = [[
$ = $ 
$ 
$(TMPDIR) - ]] .. os.getenv('TMPDIR') .. [[

M__UFFILENAME_UFFILENAME__F 
]]		
		end

		TestPattern(pattern, RunJam{ '-fsubstitution.jam' })
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
__/__/dir/__/dir2
hello hello world world
hello hello world
world hello Lua from
]]

		TestPattern(pattern, RunJam{ '-ftestgsub.jam' })
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
substitution.jam testgsub.jam testwildcards.jam
file2.c file3.c file2.o file3.o
file1.c file2.c file3.c
file1.c file2.c file3.c file1.o file2.o file3.o
]]

		TestPattern(pattern, RunJam{ '-ftestwildcards.jam' })
	end
end

