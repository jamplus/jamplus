require 'ex'
require 'glob'

function RunJam(commandLine)
	if not commandLine then commandLine = {} end
	table.insert(commandLine, 1, 'jam')
	table.insert(commandLine, 2, '-j1')
	return ex.collectlines(commandLine)
end

function TestExpression(result, failMessage)
	testNumber = testNumber + 1

	if not result then
		error(failMessage)
	end
end

function TestPattern(pattern, lines)
	testNumber = testNumber + 1

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
	while lineIndex <= #lines  and  patternIndex <= #pattern do
		local line = lines[lineIndex]:gsub('^%s+', ''):gsub('%s+$', '')
		local pattern = pattern[patternIndex]:gsub('^%s+', ''):gsub('%s+$', '')
		if line ~= pattern then
			error(line .. ' != ' .. pattern)
		end

		lineIndex = lineIndex + 1
		patternIndex = patternIndex + 1
	end

	return true
end


function TestDirectories(expectedDirs)
	testNumber = testNumber + 1

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
	testNumber = testNumber + 1

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
		if foundFile ~= 'test.lua' then
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


local dirs

if arg and arg[1] then
	dirs = arg
else
	dirs = glob.match('*/')
end
table.sort(dirs)

function ErrorHandler(inMessage)
	local message = {}
	if inMessage then
		table.insert(message, inMessage)
		table.insert(message, ':\n')
	end
	table.insert(message, debug.traceback())
	return table.concat(message)
end

for _, dir in ipairs(dirs) do
	os.chdir(dir)
	local chunk = loadfile('test.lua')
	if chunk then
		testNumber = 0

		local text = 'Running tests for ' .. dir .. '...'
		io.write(('%-60s'):format(text))
		io.flush()

		chunk()
		local ret, err = xpcall(Test, ErrorHandler)
		if not ret then
			io.write('FAILED test #' .. testNumber .. '!\n')
			io.write('\t' .. err .. '\n')
		else
			io.write('OK\n')
		end

		if PostErrorMessage then
			io.write('\t' .. PostErrorMessage .. '\n')
			PostErrorMessage = nil
		end
	end
	os.chdir('..')
end
