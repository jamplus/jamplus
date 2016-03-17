function TestChecksum()
    -- Test for a clean directory.
    local originalFiles = {
        'Jamfile.jam',
        'main.c',
        'notgenerated-a.h',
        'notgenerated-b.h',
        'notgenerated-c.h',
        'template-a-h',
        'template-b-h',
        'template-c',
        'template-c-h',
    }

    local originalDirs = {
    }

    -- Clean up everything.
    RunJam{ 'clean' }
    TestDirectories(originalDirs)
    TestFiles(originalFiles)

    ---------------------------------------------------------------------------
    local files
    local dirs = {
        'generateme/',
        '$(TOOLCHAIN_PATH)/test/',
    }

    local function TestNoopPattern()
        local noopPattern = [[
*** found 15 target(s)...
]]
        TestPattern(noopPattern, RunJam{})
        TestDirectories(dirs)
        TestFiles(files)
    end

    local pattern
    if Platform == 'win32' then
        files = {
            'Jamfile.jam',
            'main.c',
            'notgenerated-a.h',
            'notgenerated-b.h',
            'notgenerated-c.h',
            'template-a-h',
            'template-b-h',
            'template-c',
            'template-c-h',
            'generateme/generated-a.h',
            'generateme/generated-b.h',
            'generateme/generated-c.h',
            'generateme/generated.c',
            '$(TOOLCHAIN_PATH)/test/generated.obj',
            '$(TOOLCHAIN_PATH)/test/main.obj',
            '$(TOOLCHAIN_PATH)/test/test.exe',
            '$(TOOLCHAIN_PATH)/test/test.pdb',
        }

        pattern = [[
*** found 17 target(s)...
*** updating 9 target(s)...
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-a.h
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-b.h
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-c.h
@ GenerateC <$(TOOLCHAIN_GRIST):generateme>generated.c
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 9 target(s)...
]]
    else
        files = {
            'Jamfile.jam',
            'main.c',
            'notgenerated-a.h',
            'notgenerated-b.h',
            'notgenerated-c.h',
            'template-a-h',
            'template-b-h',
            'template-c',
            'template-c-h',
            'generateme/generated-a.h',
            'generateme/generated-b.h',
            'generateme/generated-c.h',
            'generateme/generated.c',
            '$(TOOLCHAIN_PATH)/test/generated.o',
            '$(TOOLCHAIN_PATH)/test/main.o',
            '$(TOOLCHAIN_PATH)/test/test',
        }

        pattern = [[
*** found 17 target(s)...
*** updating 9 target(s)...
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>main.o 
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-a.h
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-b.h
@ GenerateH <$(TOOLCHAIN_GRIST):generateme>generated-c.h
@ GenerateC <$(TOOLCHAIN_GRIST):generateme>generated.c
@ $(C_CC) <$(TOOLCHAIN_GRIST):test>generated.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 9 target(s)...
]]
    end

    ---------------------------------------------------------------------------
    do
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
    RunJam{ 'clean' }
    TestFiles(originalFiles)
    TestDirectories(originalDirs)
end
