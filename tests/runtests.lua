require 'ex'
require 'glob'

rotatingCharacters = { '|', '/', '-', '\\' }

testsSucceeded = 0
totalTests = 0

function TestNumberUpdate()
	testNumber = testNumber + 1
	testsSucceeded = testsSucceeded + 1
	totalTests = totalTests + 1
	io.write( rotatingCharacters[testNumber % 4 + 1] .. '\b' )
end

function RunJam(commandLine)
	if not commandLine then commandLine = {} end
	table.insert(commandLine, 1, 'jam')
	table.insert(commandLine, 2, '-j1')
	
	if Platform == 'win32' then
		commandLine[#commandLine + 1] = '2>&1'
	end
	
	return ex.collectlines(commandLine)
end

function TestExpression(result, failMessage)
	TestNumberUpdate()

	if not result then
		error(failMessage)
	end
end

function TestPattern(pattern, lines)
	TestNumberUpdate()

	if type(pattern) == 'string' then
		local splitLines = {}
		for line in (pattern .. '\n'):gmatch('(.-)\n') do
			splitLines[#splitLines + 1] = line
		end
		if splitLines[#splitLines] == '' then
			table.remove(splitLines, #splitLines)
		end
		pattern = splitLines
	end

	local lineIndex = 1
	local patternIndex = 1
	local patternsToFind = {}
	while lineIndex <= #lines  and  (patternIndex - #patternsToFind) <= #pattern do
		local line = lines[lineIndex]:gsub('^%s+', ''):gsub('%s+$', '')
		local pattern = pattern[patternIndex]
		local ooo
		local next
		if pattern then
			pattern = pattern:gsub('^%s+', ''):gsub('%s+$', '')
			next = pattern:sub(1, 6) == '!NEXT!'
			if next then
				pattern = pattern:sub(7)
			else
				ooo = pattern:sub(1, 5) == '!OOO!'
				if ooo then
					pattern = pattern:sub(6)
				end
			end
		else
			hi = 5
		end
		if line ~= pattern then
			if not next  or  not pattern then
				if ooo then
					patternsToFind[#patternsToFind + 1] = pattern
				end
				if line ~= patternsToFind[1] then
					if not ooo  and  pattern then
						error('Found: ' .. line .. '\n\tExpected: ' .. (pattern or patternsToFind[1]) .. '\n\nFull output:\n' .. table.concat(lines, '\n'))
					else
						if pattern then
							lineIndex = lineIndex - 1
						else
							patternIndex = patternIndex - 1
						end
					end
				else
					table.remove(patternsToFind, 1)
					patternIndex = patternIndex - 1
				end
			else
				patternIndex = patternIndex - 1
			end
		end

		lineIndex = lineIndex + 1
		patternIndex = patternIndex + 1
	end

	if #patternsToFind > 0 then
		error('\nExpecting the following output:\n' .. table.concat(patternsToFind, '\n'))
	end
	return true
end


function TestDirectories(expectedDirs)
	TestNumberUpdate()

	local expectedDirsMap = {}
	for _, dirName in ipairs(expectedDirs) do
		if dirName:sub(1, 1) == '?' then
			expectedDirsMap[dirName:sub(2)] = '?'
		else
			expectedDirsMap[dirName] = true
		end
	end

	local foundDirsMap = {}
	for _, dirName in ipairs(glob.match('**/')) do
		foundDirsMap[dirName] = true
	end

	local extraDirs = {}
	for foundDir in pairs(foundDirsMap) do
		if not expectedDirsMap[foundDir] then
			extraDirs[#extraDirs + 1] = foundDir
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
end


function TestFiles(expectedFiles)
	TestNumberUpdate()

	local expectedFilesMap = {}
	for _, fileName in ipairs(expectedFiles) do
		if fileName:sub(1, 1) == '?' then
			expectedFilesMap[fileName:sub(2)] = '?'
		else
			expectedFilesMap[fileName] = true
		end
	end

	local foundFilesMap = {}
	for _, fileName in ipairs(glob.match('**')) do
		foundFilesMap[fileName] = true
	end

	local extraFiles = {}
	for foundFile in pairs(foundFilesMap) do
		if foundFile ~= 'test.lua'  and  foundFile ~= 'test.out' then
			if not expectedFilesMap[foundFile] then
				extraFiles[#extraFiles + 1] = foundFile
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
end


-- Detect OS
if os.getenv("OS") == "Windows_NT" then
 	Platform = 'win32'
elseif os.getenv("OSTYPE") == "darwin9.0" then
	Platform = 'macosx'
else
	local f = io.popen('uname')
	uname = f:read('*a'):lower():gsub('\n', '')
	f:close()
	
	if uname == 'darwin' then
		Platform = 'macosx'
	end
end


local dirs

if arg and arg[1] then
	dirs = arg
else
	dirs = glob.match('**/')
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

local cwd = os.getcwd()
for _, dir in ipairs(dirs) do
	os.chdir(dir)
	if os.path.exists('test.lua') then
		local text = 'Running tests for ' .. dir:gsub('[\\/]$', '') .. '...'
		io.write(('%-60s'):format(text))
		io.flush()

		local chunk, err = loadfile('test.lua')
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
	os.chdir(cwd)
end

print()
print(('-> %d out of %d tests succeeded.'):format(testsSucceeded, totalTests))