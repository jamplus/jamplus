ospath = require 'ospath'
filefind = require 'filefind'

--setmetatable(_G, { __index = jam })

local jam = jam

--jam.globals['FILECACHE.generic.PATH'] = jam_expand('$(ALL_LOCATE_TARGET)/../cache')
--jam.globals['FILECACHE.generic.GENERATE'] = '1'
--jam.globals['FILECACHE.generic.USE'] = '1'

jam.SubDir('GameAssets')

local RAW_PATH = jam.globals.GameAssets[1] .. "/../raw"
local COOKED_PATH = jam.globals.GameAssets[1]
--IMAGE_PATH = jam.globals.ALL_LOCATE_TARGET[1] .. '/../image/'
IMAGE_PATH = jam.assets.BUNDLE_PATH[1]
local TEMP_PATH = jam.globals.ASSETS_INTERMEDIATES[1]

local TEMP_BOARDS_PATH = TEMP_PATH .. '/boards'
local TEMP_MASKS_PATH = TEMP_PATH .. '/masks'

assetsFileList = {}

function AddToAssetsFileList(entryName, sourcePath)
    local compress = 8
    local ext = ospath.get_extension(entryName)
    if ext == ".jpf"  or  ext == ".j2k"  or  ext == ".jp2"  or  ext == ".png"  or
        ext == ".ogg" or ext == ".caf" or ext == ".zip" then
        compress = 0
    end

    assetsFileList[#assetsFileList + 1] = {
        EntryName = entryName,
        SourcePath = jam_expand('@(' .. sourcePath .. ':T)')[1],
        CompressionMethod = compress,
    }
end


function CompileStringTable()
    local inputTarget = '<GameAssets|source>StringTable.lua'
    jam[inputTarget].SEARCH = COOKED_PATH

    local inputTarget2 = '<GameAssets|source>StringTable.merge.lua'
    jam[inputTarget2].SEARCH = COOKED_PATH

    local outputTarget = '<GameAssets>StringTable.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH)

    jam.Depends('assets', outputTarget, { inputTarget, inputTarget2 })
    jam.Clean('clean:assets', outputTarget)

    jam._CompileStringTable(outputTarget, { inputTarget, inputTarget2 })

    AddToAssetsFileList("StringTable.lua", outputTarget)
end


local copiedBoards = {}

function BuildBoard(name)
    name = name:lower() .. '.board'
    if copiedBoards[name] then return end
    copiedBoards[name] = true

    local inputTarget = '<assets|source>' .. name
    jam[inputTarget].SEARCH = COOKED_PATH .. '/boards'

    local outputTarget = '<assets>' .. name
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_BOARDS_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)
    jam.UseFileCache(outputTarget)

    jam._CompileBoard(outputTarget, inputTarget)

    AddToAssetsFileList('boards/' .. name, outputTarget)
end


local copiedMasks = {}
function BuildMask(name)
    name = name:lower() .. '.mask'
    if copiedMasks[name] then return end
    copiedMasks[name] = true

    local inputTarget = '<assets|source>' .. name
    jamtargets[inputTarget].SEARCH = COOKED_PATH .. '/masks'

    local outputTarget = '<assets>' .. name
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_MASKS_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)
    jam.UseFileCache(outputTarget)

    jam._CompileMask(outputTarget, inputTarget)

    AddToAssetsFileList('masks/' .. name, outputTarget)
end

function BuildEpisodes()
    for index = 0, 4 do
        for _, episode in ipairs(Episodes) do
            for _, info in ipairs(episode) do
                if info.boardFileName then
                    BuildBoard(info.boardFileName)
                end
            end
            if episode.BonusLevels then
                for _, info in ipairs(episode.BonusLevels) do
                    if info.boardFileName then
                        BuildBoard(info.boardFileName)
                    end
                end
            end
        end
    end
end

function BuildChallenge()
    for index = 0, 3 do
        local challengeTable = _G['Challenge' .. index]
        for _, info in pairs(challengeTable) do
            if info.boardFileName then
                BuildBoard(info.boardFileName)
            end
        end
    end
end


function BinaryizeLua(fileName, inputPath, outputPath, assetsFileListPath)
    local inputTarget = '<assets!source>' .. fileName
    jam[inputTarget].SEARCH = inputPath
    local outputTarget = '<assets>' .. fileName
    jam.UseDepCache(outputTarget, 'platform')
    jam[outputTarget].SOURCE_STRING = '@' .. fileName
    jam[outputTarget].STRIP = '0'
    jam.MakeLocate(outputTarget, outputPath)
    jam.Clean('clean:assets', outputTarget)
    jam.Depends('assets', outputTarget, inputTarget)
    jam.UseFileCache(outputTarget)
    jam._CompileLua(outputTarget, inputTarget)
    AddToAssetsFileList(assetsFileListPath .. fileName, outputTarget)
end


local processedImages = {}
function ProcessImageDirectory(cookedPath, tempPath, options)
    local assetsFileListPath = options.assetsFileListPath

    Images = nil

    local imagesPath = ospath.join(cookedPath, assetsFileListPath)
    local tempPath = ospath.join(tempPath, assetsFileListPath)

    -- Read in the ImageInfo
    local chunk = loadfile(imagesPath .. ".imageinfo")
    if chunk then chunk() end

    -- Just a sanity check.
    if Images then
        local newImages = {}
        for key, value in pairs(Images) do
            newImages[key:lower()] = value
        end
        Images = newImages
    end

    -- Get all the filenames in the directory.
    local fileList = {}
    for entry in filefind.match(imagesPath .. '*.*') do
        if not entry.is_directory then
            fileList[#fileList + 1] = entry.filename
        end
    end

    -- Process each file.
    for _, fileName in ipairs(fileList) do repeat
        -- Get the filename and extension.
        local fileTitle, extension = fileName:match("(.*)(%..+)")
        if not fileTitle then
            extension = fileName:match("(%..+)")
            if not extension then
                fileTitle = fileName
            end
        end
        if fileTitle then
            fileTitle = fileTitle:lower()
        end
        if extension then
            extension = extension:lower()
        end

        if extension == '.lua'  and  assetsFileListPath then
            BinaryizeLua(fileTitle .. extension, imagesPath, tempPath, assetsFileListPath)
            break
        end

        -- See if the extension is an image.
        local isImageType = extension == ".png"  or  extension == ".jpg"  or  extension == ".gif"
        if isImageType then
            fileTitle = fileTitle:lower()
            local imageInfo = Images and Images[fileTitle] or nil
            if options.forcePalettize then
                imageInfo = { Palettize = true }
            end

            local inputTarget = '<images!source>' .. assetsFileListPath .. fileName:lower()
            jam[inputTarget].SEARCH = imagesPath
            jam[inputTarget].BINDING = fileName:lower()

            local outputTarget = '<images>' .. assetsFileListPath .. fileName:lower()
            jam.UseDepCache(outputTarget, 'platform')
            jam[outputTarget].BINDING = fileName:lower()
            jam.MakeLocate(outputTarget, tempPath)

            if processedImages[outputTarget] then
                print('Duplicate', outputTarget)
            end
            processedImages[outputTarget] = true
            if imageInfo then
                local outputAlphaTarget = '<images>' .. assetsFileListPath .. fileTitle .. '_' .. extension
                jam.UseDepCache(outputAlphaTarget, 'platform')
                jam[outputAlphaTarget].BINDING = fileTitle .. '_' .. extension
                jam.MakeLocate(outputAlphaTarget, tempPath)
                local pngnq = forcepngnq or imageInfo.pngnq or true

                -- If the image is described, we can run gfxmonger on it.
                if imageInfo.Palettize then
                    if pngnq  and  extension == ".png" then
                        local splitPath = tempPath .. 'split/'
                        local outputSplitRGBTarget = '<images!split>' .. assetsFileListPath .. fileTitle .. extension
                        local outputSplitAlphaTarget = '<images!split>' .. assetsFileListPath .. fileTitle .. '_' .. extension
                        jam[outputSplitRGBTarget].BINDING = fileTitle .. extension
                        jam[outputSplitAlphaTarget].BINDING = fileTitle .. '_' .. extension
                        jam.MakeLocate(outputSplitRGBTarget, splitPath)
                        jam.MakeLocate(outputSplitAlphaTarget, splitPath)

                        jam.UseDepCache({ outputSplitRGBTarget, outputSplitAlphaTarget }, 'platform')
                        jam.UseFileCache({ outputSplitRGBTarget, outputSplitAlphaTarget })
                        jam._SplitImageRGB_Alpha({ outputSplitRGBTarget, outputSplitAlphaTarget }, inputTarget)

                        local nq8Target = ospath.remove_extension(outputSplitRGBTarget) .. '-nq8.png'
                        jam.UseDepCache(nq8Target, 'platform')
                        jam.MakeLocate(nq8Target, splitPath)
                        jam[nq8Target].BINDING = fileTitle .. '-nq8.png'
                        jam.UseFileCache(nq8Target)
                        jam._pngnq(nq8Target, outputSplitRGBTarget)

                        --jam._CopyFile(outputTarget, nq8Target)
                        --jam._CopyFile(outputAlphaTarget, outputSplitAlphaTarget)
                        jam.Clean('clean:assets', { outputSplitRGBTarget, outputSplitAlphaTarget, nq8Target })
                        jam.Depends('assets', outputTarget, nq8Target, outputSplitRGBTarget, inputTarget)
                        jam.Depends('assets', outputAlphaTarget, outputSplitAlphaTarget, inputTarget)
                        if extension == ".png" then
                            jam._Optipng(outputTarget, nq8Target)
                            jam._Optipng(outputAlphaTarget, outputSplitAlphaTarget)
                        end

                        local outputInfoTarget = outputTarget .. '.info'
                        jam.UseDepCache(outputInfoTarget, 'platform')
                        jam[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                        jam.MakeLocate(outputInfoTarget, tempPath)
                        jam.Clean('clean:assets', outputInfoTarget)
                        AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)

                        jam._AnalyzeImage(outputTarget)
                        jam.Clean('clean:assets', {outputTarget, outputAlphaTarget})
                        AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                        AddToAssetsFileList(assetsFileListPath .. fileTitle .. '_' .. extension, outputAlphaTarget)

                        jam.UseFileCache({outputInfoTarget, outputTarget, outputAlphaTarget})
                    end
                else
                    jam.Depends('assets', outputTarget, inputTarget)
                    AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                    if extension == ".png" then
                        jam._Optipng(outputTarget, inputTarget)
                        jam._AnalyzeImage(outputTarget)
                        jam.UseFileCache(outputTarget)

                        local outputInfoTarget = outputTarget .. '.info'
                        jam.UseDepCache(outputInfoTarget, 'platform')
                        jam[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                        jam.MakeLocate(outputInfoTarget, tempPath)
                        jam.Clean('clean:assets', outputInfoTarget)
                        jam.UseFileCache(outputInfoTarget)
                        AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)
                    else
                        jam._CopyFile(outputTarget, inputTarget)
                    end
                    jam.Clean('clean:assets', outputTarget)
                end
                local imageInfoKeys = {}
                for key, value in pairs(imageInfo) do
                    imageInfoKeys[#imageInfoKeys + 1] = key .. '=' .. tostring(value)
                end
                table.sort(imageInfoKeys)
                jam.UseCommandLine(outputTarget, imageInfoKeys)

            else

                -- There may be issues with this if old key data is around.
                jam.Depends('assets', outputTarget, inputTarget)
                AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                if extension == ".png" and optimizeimages then
                    jam._Optipng(outputTarget, inputTarget)
                    jam.UseFileCache(outputTarget)
                else
                    jam._CopyFile(outputTarget, inputTarget)
                end

                local outputInfoTarget = outputTarget .. '.info'
                jam.UseDepCache(outputInfoTarget, 'platform')
                jam[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                jam.MakeLocate(outputInfoTarget, tempPath)
                jam.Clean('clean:assets', outputInfoTarget)
                jam.UseFileCache(outputInfoTarget)
                AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)

                jam._AnalyzeImage(outputTarget)

                jam.UseCommandLine(outputTarget, "")
                jam.Clean('clean:assets', outputTarget)
            end
        end
    until true end

    Images = nil
end


function BuildFonts()
    local fonts =
    {
        "Amaranth34",
        "Amaranth44",
        "Arial10BoldItalics",
        "Font10",
        "Font14",
        "Font18",
        "Font26",
        "Font120_time",
        "FontTitle_reduced",
    }

    local rawFontsPath = COOKED_PATH .. '/fonts/'
    local tempFontsPath = TEMP_PATH .. "/fonts/"

    ProcessImageDirectory(COOKED_PATH, TEMP_PATH, { assetsFileListPath = "fonts/" })

    for _, fontName in ipairs(fonts) do
        local inputTarget = '<images!source>' .. fontName .. '.txt'
        jam[inputTarget].SEARCH = rawFontsPath
        local outputTarget = '<images>' .. fontName .. '.txt'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempFontsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        AddToAssetsFileList("fonts/" .. fontName .. '.txt', outputTarget)
    end
end


function ProcessImageDirectoryHelper(directory)
    ProcessImageDirectory(COOKED_PATH, TEMP_PATH, { assetsFileListPath = directory })
end


function ProcessThemeDirectoryHelper(directory)
    ProcessImageDirectory(COOKED_PATH, TEMP_PATH, { assetsFileListPath = directory })
    ProcessImageDirectory(COOKED_PATH, TEMP_PATH, { assetsFileListPath = directory .. "walls/" })
end


function ProcessLevel()
    ProcessImageDirectoryHelper("images/level/")
    ProcessImageDirectoryHelper("images/level/hud/")
    ProcessImageDirectoryHelper("images/level/tiles_32/")

    -- Themes
    ProcessThemeDirectoryHelper("images/level/themes/theme_01/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_02/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_03/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_04/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_05/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_06/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_07/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_08/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_09/")
    --ProcessThemeDirectoryHelper("images/level/themes/theme_10/")

    ProcessImageDirectoryHelper("images/level/walls/masks/")
end


function ProcessStory()
	ProcessImageDirectoryHelper("images/level/story/")
end


function ProcessMenus()
    local cookedPath = COOKED_PATH
    local tempPath = TEMP_PATH

    ProcessImageDirectory(cookedPath, tempPath, { assetsFileListPath = "images/" })

    local cookedMenusPath = cookedPath .. "/images/menus/"
    local tempMenusPath = tempPath .. "/images/menus/"

    ProcessImageDirectory(cookedPath, tempPath, { assetsFileListPath = "images/menus/" })

    BinaryizeLua("main.lua", cookedPath, tempPath, "")
    --	BinaryizeLua("tutorial_bubbles.lua", rawMenusPath, tempMenusPath, "images/menus/")
    BinaryizeLua("tutorial_window.lua", cookedMenusPath, tempMenusPath, "images/menus/")
    BinaryizeLua("tutorial_pointer.lua", cookedMenusPath, tempMenusPath, "images/menus/")

    ProcessImageDirectory(cookedPath, tempPath, { assetsFileListPath = "images/menus/achievements/" })

    ProcessImageDirectory(cookedPath, tempPath, { assetsFileListPath = "map/ui/" })

    for entry in filefind.glob(cookedPath .. '/ui/*.ui.lua') do
        BinaryizeLua(ospath.remove_directory(entry.filename), cookedPath .. '/ui/', tempPath .. '/ui/', 'ui/')
    end
end


function ProcessSounds()
    local sounds =
    {
        "Chute",
        "InvalidSelection",
        "MapZoom",
        "MissHit",
        "MouseClick",
        "Star",
        "StartLevel",
        "TimeAlert",
        "TimeCountdown",
        "WinLevel",
        "WrongGuess",
    }

    local cookedSoundsPath = COOKED_PATH .. '/sounds'
    local tempSoundsPath = TEMP_PATH .. '/sounds'

    for _, soundName in ipairs(sounds) do
        local inputTarget = '<assets|source>' .. soundName:lower() .. '.ogg'
        jam[inputTarget].SEARCH = cookedSoundsPath
        local outputTarget = '<assets>' .. soundName:lower() .. '.ogg'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempSoundsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        AddToAssetsFileList('sounds/' .. soundName .. '.ogg', outputTarget)
    end
end


function ProcessProgression()
    local inputTarget = '<GameAssets|source>Progression.lua'
    jam[inputTarget].SEARCH = COOKED_PATH

    local outputTarget = '<GameAssets>Progression.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)

    jam._CompileProgression(outputTarget, inputTarget)

    AddToAssetsFileList('Progression.lua', outputTarget)

    dofile(jam_expand('@(' .. inputTarget .. ':T)')[1])

    BuildEpisodes()
    BuildChallenge()

    for entry in filefind.glob(COOKED_PATH .. '/masks/*.mask') do
        BuildMask(ospath.remove_extension(ospath.get_filename(entry.filename)))
    end
end


function ProcessMap()
    local inputTarget = '<GameAssets>levelmap.svg'
    jam[inputTarget].SEARCH = COOKED_PATH .. '/map'

    local outputTarget = '<GameAssets>levelmap.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH .. '/map')

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)

    jam._CompileLevelMap(outputTarget, inputTarget)

    AddToAssetsFileList('map/levelmap.lua', outputTarget)
end


jam_action('_CompileStringTable', [[
    $(LUA_EXE:C) $(GameAssets)/CompileStringTable.lua $(2[1]:C) $(2[2]:C) $(1:C)
]])

jam_parse[[
#actions _CompileStringTable {
	#    $(LUA_EXE:C) $(GameAssets)/CompileStringTable.lua $(2[1]:C) $(2[2]:C) $(1:C)
	#}


actions _CompileBoard {
    $(LUA_EXE:C) $(GameAssets)/CompileBoard.lua $(2:C) $(1:C)
}


actions _CompileMask {
    $(LUA_EXE:C) $(GameAssets)/CompileMask.lua $(2:C) $(1:C)
}


actions _CompileProgression {
    $(LUA_EXE:C) $(GameAssets)/CompileProgression.lua $(2:C) $(1:C)
}


if $(NT) {
    actions _CopyFile {
        $(CP) $(2:C\\) $(1:C\\)
    }
} else {
    actions _CopyFile {
        $(CP) $(2:C) $(1:C)
    }
}

actions _Optipng {
    $(GameAssets)/../bin/win32/optipng -quiet -out $(1) $(2)
}

actions _AnalyzeImage {
    $(GameAssets)/../bin/win32/AnalyzeImage $(1)
}

actions _SplitImageRGB_Alpha {
    $(GameAssets)/../bin/win32/SplitImageRGB_Alpha $(2) $(1)
}

actions _pngnq {
    $(GameAssets)/../bin/win32/pngnq -s 1 $(2)
}

actions _CompileLua {
    $(LUA_EXE:C) $(GameAssets)/../scripts/CompileLuaScript.lua $(2:C) $(1:C) $(SOURCE_STRING) $(STRIP)
}

actions _CompileLevelMap {
    $(LUA_EXE:C) $(GameAssets)/CompileLevelMap.lua $(2:C) $(1:C)
}
]]


CompileStringTable()
ProcessProgression()
BuildFonts()
ProcessLevel()
ProcessStory()
ProcessMenus()
ProcessSounds()

ProcessMap()

if jam.globals.JAM_COMMAND_LINE_TARGETS[1] == 'assets' then
    jam.QueueJamfile(jam.globals.GameAssets[1] .. '/ArchiveAssets.jam')
end

