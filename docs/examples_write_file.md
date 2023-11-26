# Examples Write File {#examples_write_file}

## Writing a file {#examples_write_file_overview}

The following are various methods to write a file within Jam.


---
## Write a file with a custom action {#examples_write_file_1}

Copy the following to a `Jamfile.jam` file.

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My custom file > $(1)
}

WriteOneLineCustomFile file.txt ;
```

Note that `$(1)` ends up being the filename `file.txt`, so the `echo` line will end up writing `My custom file` to `file.txt`.

If we run Jam at this point, `file.txt` will not be written:

```
> jam
*** found 1 target(s)...
```

`file.txt` is not in the dependency chain yet, so it won't be automatically build. It can be written by running *jam* with the target name:

```
> jam file.txt
*** found 1 target(s)...
*** updating 1 target(s)...
@ WriteOneLineCustomFile file.txt
*** updated 1 target(s)...
```

Building with *jam* again does no additional work:

```
> jam file.txt
*** found 1 target(s)...
```

It would be nice if we could run jam without specifying the `file.txt` target. We can throw it into the `all` dependency chain to make this happen, since `all` is the default target when *jam* is run without arguments.

Add a [Depends](#rule_Depends) call to `Jamfile.jam`.

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My custom file > $(1)
}

Depends all : file.txt ;
WriteOneLineCustomFile file.txt ;
```

Jam informs us that the target count has gone up, but nothing builds. The file is already there on disk from the last time we ran *jam*.

```
> jam
*** found 2 target(s)...
```

There is a target called `clean` that will remove anything it depends on from the disk. If `file.txt` is added to the `clean` target, then running `jam clean` will remove `file.txt`:

Change `Jamfile.jam` to:

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My custom file > $(1)
}

Depends all : file.txt ;
Clean clean : file.txt ;
WriteOneLineCustomFile file.txt ;
```

Then clean up the already existing `file.txt` by running *jam* with the `clean` target.

```
# Shell
> jam clean
*** found 2 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
```

Run *jam* again without a target to cause `file.txt` to be written to disk:

```
# Shell
> jam
*** found 2 target(s)...
*** updating 1 target(s)...
@ WriteOneLineCustomFile file.txt
*** updated 1 target(s)...
```





---
## Write a file with changing content {#examples_write_file_2}

We need to write different text to the file in the `WriteOneLineCustomFile` rule, so the `WriteOneLineCustomFile` action is updated to this.

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My NEW custom file > $(1)
}

Depends all : file.txt ;
Clean clean : file.txt ;
WriteOneLineCustomFile file.txt ;
```

And then running *Jam*:

```
# Shell
> jam
*** found 2 target(s)...
```

Nothing happened.

In *Jam*, changes to the script lines in actions are not factored into the build. Out of box, Jam performs build operations based on timestamps, but in this example, there are no timestamps to be considered. We have to tell *Jam* the action changed in another way.

The [UseCommandLine](#rule_UseCommandLine) rule can be used for this. `UseCommandLine` adds user-defined data to the build calculations. If that user-defined data changes from one build to another, the target will be updated regardless of timestamps. Despite its name, `UseCommandLine` does not change the command line of any tool used in the build; it only performs additional dependency calculations.

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My NEW custom file > $(1)
}

Depends all : file.txt ;
Clean clean : file.txt ;
UseCommandLine file.txt : update-to-version-2 ;
WriteOneLineCustomFile file.txt ;
```

Run *jam*:

```
> jam
*** found 2 target(s)...
*** updating 1 target(s)...
@ WriteOneLineCustomFile file.txt
*** updated 1 target(s)...
```

Good. `file.txt` gets updated.

Any time a change is made to the text in `WriteOneLineCustomFile`, we should also update the `UseCommandLine` version to get it to build.

```makefile
# Jamfile.jam
actions WriteOneLineCustomFile
{
    echo My even NEWER custom file > $(1)
}

Depends all : file.txt ;
Clean clean : file.txt ;
UseCommandLine file.txt : update-to-version-3 ;
WriteOneLineCustomFile file.txt ;
```

This feels, though, as if mistakes could be made frequently. We can build a better approach and make `WriteOneLineCustomFile` more reusable in the process:

```makefile
# Jamfile.jam
# ONE_LINE_CONTENT is a setting assigned to the target in $(1)
actions WriteOneLineCustomFile
{
    echo $(ONE_LINE_CONTENT) > $(1)
}

Depends all : file.txt ;
Clean clean : file.txt ;

# Assign local variable 'content' with the text to write to the file.
local content = "My newest best custom file" ;

# Use 'content' in the build calculation.
UseCommandLine file.txt : $(content) ;

# Assign the setting ONE_LINE_CONTENT to the file.txt target.
ONE_LINE_CONTENT on file.txt = $(content) ;
WriteOneLineCustomFile file.txt ;
```




---
## Writing larger text files {#examples_write_file_3}

Within `WriteOneLineCustomFile`, we are only writing a single line of content. Jam's list expansion features could be used to automatically expand the "echo" lines into as many as we provide, but it is ugly. A better way is to use the special expansion syntax for writing files. In `Jambase.jam`, this syntax is hidden within rule [WriteFile](#actions_WriteFile).

```makefile
actions WriteFile
{
    ^^($(1)|$(CONTENTS:J=))
}
```

We can use this to write multiple lines to the file:

```makefile
# Jamfile.jam
Depends all : file.txt ;
Clean clean : file.txt ;

local contents = "My newest custom file with WriteFileContents
    This one has multiple lines.
    Line #3
" ;
UseCommandLine file.txt : $(contents) ;
CONTENTS on file.txt = $(contents) ;
WriteFile file.txt ;
```

In fact, Jam provides [WriteFileContents](#rule_WriteFileContents) to make this as easy to use as possible:

```makefile
# Jamfile.jam
Depends all : file.txt ;
Clean clean : file.txt ;
WriteFileContents file.txt : "My newest custom file with WriteFileContents
    This one has multiple lines.
    Line #3
" ;
```

In all cases, changing the content will result in Jam updating the generated target `file.txt`.


----

## Refactoring the build script {#examples_write_file_5}

Using `file.txt` everywhere gets harder and harder to maintain.

Let's swap it out for a variable instead:

```makefile
# Jamfile.jam
local target = file.txt ;
Depends all : $(target) ;
Clean clean : $(target) ;
WriteFileContents $(target) : "Refactoring in progress." ;
```



----

## Writing the target file to a directory {#examples_write_file_6}

When the target needs to be written into another directory, Jam provides a couple different approaches to this.

The easiest is to use the [MakeLocate](#rule_MakeLocate) rule to have Jam add a dependency on the directory the target is to be written into. Jam will check first whether the directory exists. If it doesn't, the directory will be created and then the target file can be written.

```makefile
# Jamfile.jam
local target = file.txt ;
Depends all : $(target) ;
Clean clean : $(target) ;
MakeLocate $(target) : the/output/directory ;
WriteFileContents $(target) : "Written into the/output/directory/file.txt" ;
```

Make note that the `target` is still `file.txt`. The directory that `file.txt` is to be put in, `the/output/directory`, is assigned to `file.txt`'s `LOCATE` setting. This keeps the target name clean and allows simple reassignment of the output directory via `LOCATE`. See [the documentation for LOCATE](#built_in_variables_binding_binding_search_locate) for more information.

`target` can also be a full relative or absolute path. We just have to call `MakeLocate` with the `combine` option.

```makefile
# Jamfile.jam
local target = the/output/directory/file.txt ;
Depends all : $(target) ;
Clean clean : $(target) ;
# MakeLocate options are specified in the third parameter. We don't have any
# directory overrides to fill in, so the second parameter is empty.
#   MakeLocate $(target) : **EMPTY_HERE** : combine ;
MakeLocate $(target) : : combine ;
WriteFileContents $(target) : "Written into the/output/directory/file.txt" ;
```
