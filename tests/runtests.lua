ospath = require 'ospath'
osprocess = require 'osprocess'
local filefind = require 'filefind'

function io.writeall(filename, buffer)
    local file = io.open(filename, 'wb')
    file:write(buffer)
    file:close()
end

rotatingCharacters = { '|', '/', '-', '\\' }

testsSucceeded = 0
totalTests = 0

function TestNumberUpdate(amount)
	amount = amount or 1
	testNumber = testNumber + amount
	totalTests = totalTests + amount
	io.write( rotatingCharacters[(testNumber % 4) + 1] .. '\b' )
end

function TestSucceeded(amount)
	amount = amount or 1
	testsSucceeded = testsSucceeded + amount
end

function RunJam(commandLine)
	if not commandLine then commandLine = {} end
	table.insert(commandLine, 1, 'jam')
	table.insert(commandLine, 2, '-j1')

	if Compiler then
		table.insert(commandLine, 3, 'COMPILER=' .. Compiler)
	end

	commandLine.stderr_to_stdout = true

	return osprocess.collectlines(commandLine)
end

function TestExpression(result, failMessage)
	TestNumberUpdate()

	if not result then
		error(failMessage)
	end

	TestSucceeded()
end

function TestPattern(patterns, lines)
	TestNumberUpdate()

	if type(patterns) == 'string' then
		local splitLines = {}
		for line in (patterns .. '\n'):gmatch('(.-)\n') do
			splitLines[#splitLines + 1] = line
		end
		if splitLines[#splitLines] == '' then
			table.remove(splitLines, #splitLines)
		end
		patterns = splitLines
	end

	local lineIndex = 1
	local patternIndex = 1
	local oooGroupPatternsToFind = {}
	local oooPatternsToFind = {}
	local lastMatchedLineIndex = 0
	while lineIndex <= #lines  and  (patternIndex - #oooPatternsToFind) <= #patterns do
		local line = lines[lineIndex]:gsub('^%s+', ''):gsub('%s+$', '')
		line = line:gsub('@%s*%d+%%', '@')

		local pattern
		local ooo
		local ooogroup = oooGroupPatternsToFind[1] ~= nil
		if not ooogroup then
			pattern = patterns[patternIndex]
			if pattern then
				pattern = pattern:gsub('$%(SUFEXE%)', SUFEXE)
				pattern = pattern:gsub('$%(COMPILER%)', COMPILER)
				pattern = pattern:gsub('$%(C.ARCHIVE%)', C_ARCHIVE)
				pattern = pattern:gsub('$%(C.LINK%)', C_LINK)
				pattern = pattern:gsub('$%(PLATFORM%)', PlatformDir)
				pattern = pattern:gsub('$%(PLATFORM_CONFIG%)', PlatformDir .. '!release')
				pattern = pattern:gsub('$%(TOOLCHAIN_GRIST%)', 'c/' .. PlatformDir .. '/release')
				pattern = pattern:gsub('$%(CWD%)', patterncwd)
			end
		end

		local next
		if pattern then
			pattern = pattern:gsub('^%s+', ''):gsub('%s+$', '')
			ooogroup = pattern:sub(1, 10) == '!OOOGROUP!'
			if ooogroup then
				-- Collect Out Of Order entries.
				while patternIndex <= #patterns do
					pattern = patterns[patternIndex]
					pattern = pattern:gsub('^%s+', ''):gsub('%s+$', '')
					if pattern:sub(1, 10) ~= '!OOOGROUP!' then break end
					pattern = pattern:sub(11)
					pattern = pattern:gsub('$%(SUFEXE%)', SUFEXE)
					pattern = pattern:gsub('$%(COMPILER%)', COMPILER)
					pattern = pattern:gsub('$%(C.ARCHIVE%)', C_ARCHIVE)
					pattern = pattern:gsub('$%(C.LINK%)', C_LINK)
					pattern = pattern:gsub('$%(PLATFORM%)', PlatformDir)
					pattern = pattern:gsub('$%(PLATFORM_CONFIG%)', PlatformDir .. '!release')
					pattern = pattern:gsub('$%(TOOLCHAIN_GRIST%)', 'c/' .. PlatformDir .. '/release')
					pattern = pattern:gsub('$%(CWD%)', patterncwd)
					oooGroupPatternsToFind[#oooGroupPatternsToFind + 1] = pattern
					pattern = nil
					patternIndex = patternIndex + 1
				end
			else
				next = pattern:sub(1, 6) == '!NEXT!'
				if next then
					pattern = pattern:sub(7)
				else
					ooo = pattern:sub(1, 5) == '!OOO!'
					if ooo then
						pattern = pattern:sub(6)
					end
				end
			end
		else
			hi = 5
		end

		local patternMatches = false
		if pattern then
			if pattern:sub(1, 1) == '&' then
				patternMatches = not not line:match(pattern:sub(2))
			else
				patternMatches = line == pattern
			end
		end

		if patternMatches then
			lastMatchedLineIndex = lineIndex
		else
			if not next  or  not pattern then
				if oooGroupPatternsToFind[1] then
					local patternFoundIndex
					for patternsToFindIndex = 1, #oooGroupPatternsToFind do
						local testPattern = oooGroupPatternsToFind[patternsToFindIndex]
						if testPattern:sub(1, 1) == '&' then
							patternMatches = not not line:match(testPattern:sub(2))
						else
							patternMatches = line == testPattern
						end
						if patternMatches then
							patternFoundIndex = patternsToFindIndex
							break
						end
					end
					if oooGroupPatternsToFind[1]  and  not patternFoundIndex then
						if not ooo  and  pattern then
							error('Found: ' .. line .. '\n\tExpected: ' .. (pattern or oooGroupPatternsToFind[1]) .. '\n\nFull output:\n' .. table.concat(lines, '\n'))
						else
							if pattern then
								lineIndex = lineIndex - 1
							else
								patternIndex = patternIndex - 1
							end
						end
					else
						if patternFoundIndex then
							lastMatchedLineIndex = lineIndex
							table.remove(oooGroupPatternsToFind, patternFoundIndex)
						end
						patternIndex = patternIndex - 1
					end
				else
					if ooo then
						oooPatternsToFind[#oooPatternsToFind + 1] = pattern
					end

					local testPattern = oooPatternsToFind[1]
					if testPattern  and  testPattern:sub(1, 1) == '&' then
						patternMatches = not not line:match(testPattern:sub(2))
					else
						patternMatches = line == testPattern
					end

					if oooPatternsToFind[1]  and  not patternMatches then
						if not ooo  and  pattern then
							error('Found: ' .. line .. '\n\tExpected: ' .. (pattern or oooGroupPatternsToFind[1]) .. '\n\nFull output:\n' .. table.concat(lines, '\n'))
						else
							if pattern then
								lineIndex = lineIndex - 1
							else
								patternIndex = patternIndex - 1
							end
						end
					else
						table.remove(oooPatternsToFind, 1)
						patternIndex = patternIndex - 1
					end
				end
			else
				patternIndex = patternIndex - 1
			end
		end

		lineIndex = lineIndex + 1
		patternIndex = patternIndex + 1
	end

	if #oooGroupPatternsToFind > 0 then
		error('\nExpecting the following output:\n' .. table.concat(oooGroupPatternsToFind, '\n'))
	end
 	if #oooPatternsToFind > 0 then
 		error('\nExpecting the following output:\n' .. table.concat(oooPatternsToFind, '\n'))
 	end
	if patternIndex <= #patterns then
		local patternsExpected = {}
		for index = patternIndex, #patterns do
			patternsExpected[#patternsExpected + 1] = patterns[index]
		end
		local linesExpected = {}
		for index = lastMatchedLineIndex + 1, #lines do
			linesExpected[#linesExpected + 1] = lines[index]
		end
		error('\nExpected:\n' .. table.concat(patternsExpected, '\n') .. '\n\nFull output:\n' .. table.concat(linesExpected, '\n'))
	end

	TestSucceeded()
	return true
end


function TestDirectories(expectedDirs)
	TestNumberUpdate()

	local expectedDirsMap = {}
	local newExpectedDirs = {}
	for _, dirName in ipairs(expectedDirs) do
		dirName = dirName:gsub('$PlatformDir', PlatformDir)
		dirName = dirName:gsub('$%(PLATFORM_CONFIG%)', PlatformDir .. '-release')
		dirName = dirName:gsub('$%(TOOLCHAIN_PATH%)', '.build/' .. PlatformDir .. '-release/TOP')
		--dirName = dirName:gsub('$%(TOOLCHAIN_PATH%)', PlatformDir .. '-release')
		if dirName:sub(1, 1) == '?' then
			expectedDirsMap[dirName:sub(2)] = '?'
		else
			expectedDirsMap[dirName] = true
		end
		newExpectedDirs[#newExpectedDirs + 1] = dirName
	end

	local foundDirsMap = {}
	for entry in filefind.glob('**/') do
		foundDirsMap[entry.filename] = true
	end

	local extraDirs = {}
	local expectedSubDirs = {}
	for expectedDir in pairs(expectedDirsMap) do
		local path = ""
		for component in expectedDir:gmatch('([^/]+)') do
			path = path .. component .. '/'
			expectedSubDirs[path] = true
		end
	end
	for expectedSubDir in pairs(expectedSubDirs) do
		if not foundDirsMap[expectedSubDir] then
			extraDirs[#extraDirs + 1] = expectedDir
		else
			foundDirsMap[expectedSubDir] = nil
			expectedDirsMap[expectedSubDir] = nil
		end
	end

	for foundDir in pairs(foundDirsMap) do
		if not expectedDirsMap[foundDir] then
			local found = false
			for _, dirName in ipairs(newExpectedDirs) do
				local origDirName = dirName
				dirName = dirName:gsub('%%%-', '\x02')
				dirName = dirName:gsub('%%', '\x01')
				dirName = dirName:gsub('%-', '%%-')
				dirName = dirName:gsub('\x02', '%%-')
				dirName = dirName:gsub('\x01', '%%')
				if foundDir:match('^' .. dirName .. '$') then
					expectedDirsMap[origDirName] = nil
					found = true
					break
				end
			end

			if not found then
				extraDirs[#extraDirs + 1] = foundDir
			end
		end

		expectedDirsMap[foundDir] = nil
 	end


	if #extraDirs > 0 then
		table.sort(extraDirs)
		error('These directories should not exist:\n\t\t' .. table.concat(extraDirs, '\n\t\t'))
	end

	local missingDirs = {}
	for expectedFile, value in pairs(expectedDirsMap) do
		if value ~= '?' then
			missingDirs[#missingDirs + 1] = expectedFile
		end
	end
	if #missingDirs > 0 then
		error('These directories are missing:\n\t\t' .. table.concat(missingDirs, '\n\t\t'))
	end
	TestSucceeded()
end


function TestFiles(expectedFiles)
	TestNumberUpdate()

	local expectedFilesMap = {}
	expectedFiles[#expectedFiles + 1] = '?.build/.depcache'
	local newExpectedFiles = {}
	for _, fileName in ipairs(expectedFiles) do
		fileName = fileName:gsub('$PlatformDir', PlatformDir):gsub('$%(SUFEXE%)', SUFEXE)
		fileName = fileName:gsub('$%(PLATFORM_CONFIG%)', PlatformDir .. '-release')
		fileName = fileName:gsub('$%(TOOLCHAIN_PATH%)', '.build/' .. PlatformDir .. '-release/TOP')
		--fileName = fileName:gsub('$%(TOOLCHAIN_PATH%)', PlatformDir .. '-release')
		fileName = fileName:gsub('$%(CWD%)', patterncwd)
		if fileName:match('vc.pdb$') then fileName = '?' .. fileName end
		if fileName:sub(1, 1) == '?' then
			expectedFilesMap[fileName:sub(2)] = '?'
		else
			expectedFilesMap[fileName] = true
		end
		newExpectedFiles[#newExpectedFiles + 1] = fileName
	end

	local foundFilesMap = {}
	for entry in filefind.glob('**') do
		foundFilesMap[entry.filename] = true
	end

	local extraFiles = {}
	for foundFile in pairs(foundFilesMap) do
		if foundFile ~= 'test.lua'  and  foundFile ~= 'test.out'  and  not foundFile:match('%.swp')
				and  not foundFile:match('~$')  and  not foundFile:match('%.swo') then
			if not expectedFilesMap[foundFile] then
				local found = false
				for _, fileName in ipairs(newExpectedFiles) do
					local origFileName = fileName
					fileName = fileName:gsub('%%%-', '\x02')
					fileName = fileName:gsub('%%', '\x01')
					fileName = fileName:gsub('%-', '%%-')
					fileName = fileName:gsub('\x02', '%%-')
					fileName = fileName:gsub('\x01', '%%')
					if foundFile:match('^' .. fileName .. '$') then
						expectedFilesMap[origFileName] = nil
						found = true
						break
					end
				end

				if not found then
					extraFiles[#extraFiles + 1] = foundFile
				end
			end
		end
		expectedFilesMap[foundFile] = nil
	end
	if #extraFiles > 0 then
		table.sort(extraFiles)
		error('These files should not exist:\n\t\t' .. table.concat(extraFiles, '\n\t\t'))
	end

	local missingFiles = {}
	for expectedFile, value in pairs(expectedFilesMap) do
		if value ~= '?' then
			missingFiles[#missingFiles + 1] = expectedFile
		end
	end
	if #missingFiles > 0 then
		error('These files are missing:\n\t\t' .. table.concat(missingFiles, '\n\t\t'))
	end
	TestSucceeded()
end


-- Detect OS
if os.getenv("OS") == "Windows_NT" then
 	Platform = 'win32'
	PlatformDir = 'win32'
	SUFEXE = '.exe'
	COMPILER = 'vc'
	C_ARCHIVE = 'C.vc.Archive'
	C_LINK = 'C.vc.Link'
else
	local f = io.popen('uname')
	uname = f:read('*a'):lower():gsub('\n', '')
	f:close()

	if uname == 'darwin' then
		Platform = 'macosx'
		PlatformDir = 'macosx32'
		COMPILER = 'clang'
		C_ARCHIVE = 'C.macosx.clang.Archive'
		C_LINK = 'C.macosx.clang.Link'
	elseif uname == 'linux' then
		Platform = 'linux'
		PlatformDir = 'linux32'
		COMPILER = 'gcc'
		C_ARCHIVE = 'C.gcc.Archive'
		C_LINK = 'C.gcc.Link'
	end

	SUFEXE = ''
end


local dirs

if arg and arg[1] == '--compiler' then
	Compiler = arg[2]
	table.remove(arg, 1)
	table.remove(arg, 1)
end

if arg and arg[1] then
	dirs = arg
else
	dirs = {}
	for entry in filefind.glob('**/') do
		dirs[#dirs + 1] = entry.filename
	end
end
table.sort(dirs)

function ErrorHandler(inMessage)
	local message = {}
	if inMessage then
		table.insert(message, inMessage)
		table.insert(message, ':\n')
	end
	ErrorTraceback = debug.traceback()
	return table.concat(message)
end

cwd = ospath.getcwd()

for _, dir in ipairs(dirs) do
	ospath.chdir(dir)
--	patterncwd = ospath.add_slash(ospath.make_slash(ospath.getcwd()))
	patterncwd = ""
	if ospath.exists('test.lua') then
		local text = 'Running tests for ' .. dir:gsub('[\\/]$', '') .. '...'
		io.write(('%-60s'):format(text))
		io.flush()

		local chunk, err = loadfile(ospath.make_absolute('test.lua'))
		if chunk then
			testNumber = 0

			chunk()
			local ret, err = xpcall(Test, ErrorHandler)
			if not ret then
				io.write('FAILED!\n')
				io.write('\tFailed test #' .. testNumber)

				local lineNumber = ErrorTraceback:match('test.lua:(%d-):')
				if lineNumber then
					io.write(' at line number ' .. lineNumber)
				end
				io.write('.\n\n')

				err = err:gsub('^runtests.lua:%d-: ', '')
				io.write('\t' .. err .. '\n')
				print(ErrorTraceback)
os.exit()
			else
				io.write('OK\n')
			end

			if PostErrorMessage then
				io.write('\t' .. PostErrorMessage .. '\n')
				PostErrorMessage = nil
			end
		else
			io.write('FAILED!\n')
			io.write('\tError compiling test.lua!\n')
			io.write('\t' .. err .. '\n')
		end
	end
	ospath.chdir(cwd)
end

print()
print(('-> %d out of %d tests succeeded.'):format(testsSucceeded, totalTests))
