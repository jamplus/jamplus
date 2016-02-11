function TestChecksum()
    local buildPath = '.build/' .. PlatformDir .. '-release/TOP/test/'
    local testDllPath = buildPath .. 'test.dll'
    local generatedHeaderPath = buildPath .. 'generatedheader.h'

    local testDotCsBuffer
    local function WriteOriginalFiles()
        ospath.copy_file('original/main.c', 'main.c')
        ospath.copy_file('original/test.cs', 'test.cs')
        ospath.copy_file('original/testheader.h', 'testheader.h')
        ospath.copy_file('original/testheaderdeeper.h', 'testheaderdeeper.h')

        testDotCsBuffer = ospath.read_file('original/test.cs')
    end

    local function WriteTestDotCs(addCommentLines, valueNumber, anotherValueNumber)
        local buffer = testDotCsBuffer
        if addCommentLines then
            buffer = buffer .. string.rep('//\n', addCommentLines)
        end
        if valueNumber then
            buffer = buffer:gsub('#define VALUE (%d+)', '#define VALUE ' .. valueNumber)
        end
        if anotherValueNumber then
            buffer = buffer:gsub('#define ANOTHER_VALUE (%d+)', '#define ANOTHER_VALUE ' .. anotherValueNumber)
        end
        ospath.write_file('test.cs', buffer)
    end

    local function WriteTestDotDll(addCommentLines, valueNumber, anotherValueNumber)
        local buffer = testDotCsBuffer
        if addCommentLines then
            buffer = buffer .. string.rep('//\n', addCommentLines)
        end
        if valueNumber then
            buffer = buffer:gsub('#define VALUE (%d+)', '#define VALUE ' .. valueNumber)
        end
        if anotherValueNumber then
            buffer = buffer:gsub('#define ANOTHER_VALUE (%d+)', '#define ANOTHER_VALUE ' .. anotherValueNumber)
        end
        ospath.write_file(testDllPath, buffer)
    end

    -- Test for a clean directory.
    local originalFiles = {
        'Jamfile.jam',
        'main.c',
        'test.cs',
        'testheader.h',
        'testheaderdeeper.h',
        'original/main.c',
        'original/test.cs',
        'original/testheader.h',
        'original/testheaderdeeper.h',
    }

    local originalDirs = {
        'original/',
    }

    -- Clean up everything.
    WriteOriginalFiles()
    RunJam{ 'clean' }
    TestDirectories(originalDirs)
    TestFiles(originalFiles)

    ---------------------------------------------------------------------------
    local files
    if Platform == 'win32' then
        files = {
            'Jamfile.jam',
            'main.c',
            'test.cs',
            'testheader.h',
            'testheaderdeeper.h',
            'original/main.c',
            'original/test.cs',
            'original/testheader.h',
            'original/testheaderdeeper.h',
            '$(TOOLCHAIN_PATH)/test/generatedheader.h',
            '$(TOOLCHAIN_PATH)/test/main.obj',
            '$(TOOLCHAIN_PATH)/test/test.dll',
            '$(TOOLCHAIN_PATH)/test/test.release.exe',
            '?$(TOOLCHAIN_PATH)/test/test.release.exe.intermediate.manifest',
            '$(TOOLCHAIN_PATH)/test/test.release.pdb',
        }
    else
        files = {
            'Jamfile.jam',
            'main.c',
            'test.cs',
            'testheader.h',
            'testheaderdeeper.h',
            'original/main.c',
            'original/test.cs',
            'original/testheader.h',
            'original/testheaderdeeper.h',
            '$(TOOLCHAIN_PATH)/test/generatedheader.h',
            '$(TOOLCHAIN_PATH)/test/main.o',
            '$(TOOLCHAIN_PATH)/test/test.dll',
            '$(TOOLCHAIN_PATH)/test/test.release',
        }
    end

    local dirs = {
        'original/',
        '$(TOOLCHAIN_PATH)/test/',
    }

    local function TestNoopPattern()
        local noopPattern = [[
*** found 12 target(s)...
]]
        TestPattern(noopPattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    local function TestPatternForTestDllAndGeneratedHeader()
        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 12 target(s)...
*** updating 4 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
*** updated 2 target(s)...
]]
        else
            pattern = [[
*** found 12 target(s)...
*** updating 4 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
*** updated 2 target(s)...
]]
        end
        TestPattern(pattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end


    local function TestPatternForTestCsValueChange()
        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 12 target(s)...
*** updating 4 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 4 target(s)...
]]
        else
            pattern = [[
*** found 13 target(s)...
*** updating 4 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o 
*** updated 3 target(s)...
]]
        end
        TestPattern(pattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end


    ---------------------------------------------------------------------------
    do
        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 12 target(s)...
*** updating 5 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
]]
        else
            pattern = [[
*** found 13 target(s)...
*** updating 5 target(s)...
@ CompileCS <$(TOOLCHAIN_GRIST):test>test.dll
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 5 target(s)...
]]
        end

        TestPattern(pattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    ---------------------------------------------------------------------------
    do
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    do
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    if true then
        osprocess.sleep(1.0)
        ospath.touch('test.cs')
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    if true then
        osprocess.sleep(1.0)
        WriteTestDotCs()
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    -- Add a comment line to test.cs. This will cause test.dll and generatedheader.h to
    -- build, but nothing further should happen.
    do
        osprocess.sleep(1.0)
        WriteTestDotCs(1)
        TestPatternForTestDllAndGeneratedHeader()
    end

    ---------------------------------------------------------------------------
    do
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    -- Add more comment lines to test.cs. This will cause test.dll and generatedheader.h to
    -- build, but nothing further should happen.
    if true then
        osprocess.sleep(1.0)
        WriteTestDotCs(3)
        TestPatternForTestDllAndGeneratedHeader()
    end

    ---------------------------------------------------------------------------
    -- Change VALUE in test.cs. This will cause test.dll, generatedheader.h, main.obj, and
    -- main.exe to build.
    if true then
        osprocess.sleep(1.0)
        WriteTestDotCs(nil, 10)
        TestPatternForTestCsValueChange()
    end

    ---------------------------------------------------------------------------
    if true then
        osprocess.sleep(1.0)
        ospath.touch('test.cs')
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    -- Change ANOTHER_VALUE in test.cs. This will cause test.dll, generatedheader.h, main.obj, and
    -- main.exe to build.
    if true then
        osprocess.sleep(1.0)
        WriteTestDotCs(nil, nil, 20)
        TestPatternForTestCsValueChange()
    end

    ---------------------------------------------------------------------------
    if true then
        osprocess.sleep(1.0)
        ospath.touch('test.cs')
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    -- Test for failure when removing test.cs.
    if true then
        os.remove('test.cs')

        local pattern
        if Platform == 'win32' then
            pattern = [[
don't know how to make <$(TOOLCHAIN_GRIST):test>test.cs
*** found 12 target(s)...
*** can't find 1 target(s)...
&%*%*%* can't make %d+ target%(s%)%.%.%.
*** skipped <$(TOOLCHAIN_GRIST):test>test.dll for lack of <$(TOOLCHAIN_GRIST):test>test.cs...
...dependency on <$(TOOLCHAIN_GRIST):test>generatedheader.h failed, but don't care...
*** skipped <$(TOOLCHAIN_GRIST):test>main.obj for lack of <$(TOOLCHAIN_GRIST):test>main.c...
*** skipped <$(TOOLCHAIN_GRIST):test>test.exe for lack of <$(TOOLCHAIN_GRIST):test>main.obj...
!NEXT!&%*%*%* skipped %d+ target%(s%)%.%.%.
]]
        else
            pattern = [[
don't know how to make <$(TOOLCHAIN_GRIST):test>test.cs
*** found 12 target(s)...
*** can't find 1 target(s)...
*** can't make 4 target(s)...
*** skipped <$(TOOLCHAIN_GRIST):test>test.dll for lack of <$(TOOLCHAIN_GRIST):test>test.cs...
...dependency on <$(TOOLCHAIN_GRIST):test>generatedheader.h failed, but don't care...
*** skipped <$(TOOLCHAIN_GRIST):test>main.o for lack of <$(TOOLCHAIN_GRIST):test>main.c...
*** skipped <$(TOOLCHAIN_GRIST):test>test for lack of <$(TOOLCHAIN_GRIST):test>main.o...
*** skipped 3 target(s)...
]]
        end

        TestPattern(pattern, RunJam{})

        WriteOriginalFiles()
        TestDirectories(dirs)
        TestFiles(files)

        osprocess.sleep(1.0)
        ospath.touch('test.cs')
        TestPatternForTestCsValueChange()
    end

    ---------------------------------------------------------------------------
    -- Directly modify test.dll.
    if true then
        osprocess.sleep(1.0)
        WriteTestDotDll(2)

        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 12 target(s)...
*** updating 3 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
*** updated 1 target(s)...
]]
        else
            pattern = [[
*** found 12 target(s)...
*** updating 3 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generatedheader.h
*** updated 1 target(s)...
]]
        end

        TestPattern(pattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    ---------------------------------------------------------------------------
    -- Delete test.dll.
    if true then
        os.remove(testDllPath)
        TestPatternForTestDllAndGeneratedHeader()
    end

    ---------------------------------------------------------------------------
    do
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    -- Directly modify generatedheader.h.
    if true then
        osprocess.sleep(1.0)
        ospath.touch(generatedHeaderPath)
        TestNoopPattern()
    end

    if true then
        osprocess.sleep(1.0)
        ospath.write_file(generatedHeaderPath, [[
#define VALUE 10
#define ANOTHER_VALUE 20
]])

        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 2 target(s)...
]]
        else
            pattern = [[
*** found 13 target(s)...
*** updating 2 target(s)...
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 2 target(s)...
]]
        end

        TestPattern(pattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    ---------------------------------------------------------------------------
    -- Rewrite test.cs. Everything will build.
    if true then
        osprocess.sleep(1.0)
        WriteTestDotCs()
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    WriteOriginalFiles()
    RunJam{ 'clean' }
    TestFiles(originalFiles)
    TestDirectories(originalDirs)
end
