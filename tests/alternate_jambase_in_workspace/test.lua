function Test()
    local workspacePath = ospath.add_slash(ospath.join(ospath.getcwd(), '.build'))

    function RemoveWorkspace()
        ospath.remove(workspacePath)
    end

    function GenerateWorkspace(overrideJambaseFilename)
        RemoveWorkspace()
        osprocess.collectlines{ JAM_EXECUTABLE, '--workspace', '-gen=none', '"-jambase=' .. ospath.join(ospath.getcwd(), overrideJambaseFilename) .. '"', '.', workspacePath }
    end

    function RunJamInWorkspace(commandLine)
        commandLine[#commandLine + 1] = '-C' .. workspacePath
        return RunJam(commandLine)
    end

    -- No generated workspace.
    do
        RemoveWorkspace()

        local pattern = [[
warning: unknown rule PrintFromOverrideJambase (last file: Jamfile.jam)
*** found 1 target(s)...
]]

        TestPattern(pattern, RunJam{})
    end

    -- Use the OverrideJambase.jam.
    do
        GenerateWorkspace('OverrideJambase.jam')

        local pattern = [[
This is from OverrideJambase.jam.
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

        TestPattern(pattern, RunJamInWorkspace{})
    end

    -- Ensure the setting survives an updatebuildenvironment call.
    do
        osprocess.collectlines{ '"' .. ospath.join(workspacePath, 'updatebuildenvironment') .. '"' }

        local pattern = [[
This is from OverrideJambase.jam.
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

        TestPattern(pattern, RunJamInWorkspace{})
    end

    -- Use the OverrideJambaseCallRoot.jam.
    do
        GenerateWorkspace('OverrideJambaseCallRoot.jam')

        local pattern = [[
This is from OverrideJambaseCallRoot.jam.
*** found 1 target(s)...
]]

        TestPattern(pattern, RunJamInWorkspace{})
    end

    RemoveWorkspace()
end

