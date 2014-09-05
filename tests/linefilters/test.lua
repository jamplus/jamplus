function Test()
    local pattern = [[
*** found 1 target(s)...
*** updating 1 target(s)...
@ UpperCaseRule all
-> THIS TEXT WILL BE UPPERCASE.
-> THIS TEXT WILL ALSO BE UPPERCASE IN THE OUTPUT.
@ LowerCaseRule all
-> this text will be lowercase.
@ Compiler all
c:/the/directory/filename.cpp(1000) This is an error message.
*** updated 1 target(s)...
]]

    TestPattern(pattern, RunJam{})
end

