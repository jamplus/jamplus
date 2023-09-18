function TestChecksum()
    local function WriteOriginalFiles()
        ospath.write_file('template', [[
#define VALUE 8
]])
    end

    -- Test for a clean directory.
    local originalFiles = {
        'Jamfile.jam',
        'main.c',
        'template',
    }

    local originalDirs = {
    }

    -- Clean up everything.
    WriteOriginalFiles()
    RunJam{ 'clean' }
    TestDirectories(originalDirs)
    TestFiles(originalFiles)

    ---------------------------------------------------------------------------
    local files
    local dirs = {
        '$(TOOLCHAIN_PATH)/test/',
    }

    local function TestNoopPattern()
        local noopPattern = [[
*** found 10 target(s)...
]]
        TestPattern(noopPattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    local function TestNoopPattern3()
        local noopPattern = [[
*** found 10 target(s)...
*** updating 3 target(s)...
*** updated 0 target(s)...
]]
        TestPattern(noopPattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    local patternA
    local patternB
    local patternC
    if Platform == 'win32' then
        files = {
            'generated.h',
            'Jamfile.jam',
            'main.c',
            'template',
            '$(TOOLCHAIN_PATH)/test/main.obj',
            '$(TOOLCHAIN_PATH)/test/test.exe',
            '?$(TOOLCHAIN_PATH)/test/test.exe.intermediate.manifest',
            '$(TOOLCHAIN_PATH)/test/test.pdb',
        }

        patternA = [[
*** found 21 target(s)...
*** updating 4 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generated.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 4 target(s)...
]]
    else
        files = {
            'generated.h',
            'Jamfile.jam',
            'main.c',
            'template',
            '$(TOOLCHAIN_PATH)/test/main.o',
            '$(TOOLCHAIN_PATH)/test/test',
        }

        patternA = [[
*** found 10 target(s)...
*** updating 4 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generated.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 4 target(s)...
]]
    end

    ---------------------------------------------------------------------------
    do
        TestPattern(patternA, RunJam{})
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
    do
        osprocess.sleep(1.0)
        ospath.touch('template')
        TestNoopPattern3()
    end

    ---------------------------------------------------------------------------
    do
        local pattern
        if Platform == 'win32' then
            pattern = [[
*** found 10 target(s)...
*** updating 3 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generated.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 3 target(s)...
]]
        else
            pattern = [[
*** found 10 target(s)...
*** updating 3 target(s)...
@ GenerateHeader <$(TOOLCHAIN_GRIST):test>generated.h
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o 
*** updated 2 target(s)...
]]
        end

        osprocess.sleep(1.0)
        ospath.write_file('template', [[
#define VALUE 10
]])
        TestPattern(pattern, RunJam{})
    end

    ---------------------------------------------------------------------------
    do
        TestNoopPattern()
    end

    ---------------------------------------------------------------------------
    WriteOriginalFiles()
    RunJam{ 'clean' }
    TestFiles(originalFiles)
    TestDirectories(originalDirs)
end
