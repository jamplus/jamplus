BINARY_OR_TEXT_COMMAND_LINE = 'text'

ospath = require 'ospath'
filefind = require 'filefind'

--setmetatable(_G, { __index = jam })

local jam = jam
local jamvar = jamvar
local jamtarget = jamtarget

--jamvar['FILECACHE.generic.PATH'] = jam_expand('$(ALL_LOCATE_TARGET)/../cache')
--jamvar['FILECACHE.generic.GENERATE'] = '1'
--jamvar['FILECACHE.generic.USE'] = '1'

jam.SubDir('GameAssets')

local RAW_PATH = jamvar.GameAssets[1] .. "/../raw"
local COOKED_PATH = jamvar.GameAssets[1]
--IMAGE_PATH = jamvar.ALL_LOCATE_TARGET[1] .. '/../image/'
IMAGE_PATH = jamtarget['assets'].BUNDLE_PATH[1]
local TEMP_PATH = jamvar.ASSETS_INTERMEDIATES[1]

local TEMP_BOARDS_PATH = TEMP_PATH .. '/boards'
local TEMP_MASKS_PATH = TEMP_PATH .. '/masks'

assetsFileList = {}
optimizeimages = true

function AddToAssetsFileList(entryName, sourcePath)
    local compress = 8
    local ext = ospath.get_extension(entryName)
    if ext == ".png"  or
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
    jamtarget[inputTarget].SEARCH = COOKED_PATH

    local inputTarget2 = '<GameAssets|source>StringTable.merge.lua'
    jamtarget[inputTarget2].SEARCH = COOKED_PATH

    local outputTarget = '<GameAssets>StringTable.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH)

    jam.Depends('assets', outputTarget, { inputTarget, inputTarget2 })
    jam.Clean('clean:assets', outputTarget)

    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileStringTable(outputTarget, { inputTarget, inputTarget2 })

    AddToAssetsFileList("StringTable.lua", outputTarget)
end


local copiedBoards = {}

function BuildBoard(name)
    name = name:lower() .. '.board'
    if copiedBoards[name] then return end
    copiedBoards[name] = true

    local inputTarget = '<assets|source>' .. name
    jamtarget[inputTarget].SEARCH = COOKED_PATH .. '/boards'

    local outputTarget = '<assets>' .. name
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_BOARDS_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)
    jam.UseFileCache(outputTarget)

    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileBoard(outputTarget, inputTarget)

    AddToAssetsFileList('boards/' .. name, outputTarget)
end


local copiedMasks = {}
function BuildMask(name)
    name = name:lower() .. '.mask'
    if copiedMasks[name] then return end
    copiedMasks[name] = true

    local inputTarget = '<assets|source>' .. name
    jamtarget[inputTarget].SEARCH = COOKED_PATH .. '/masks'

    local outputTarget = '<assets>' .. name
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_MASKS_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)
    jam.UseFileCache(outputTarget)

    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileMask(outputTarget, inputTarget)

    AddToAssetsFileList('masks/' .. name, outputTarget)
end


local collectedBoards = {}
function BuildJourney()
    for index = 0, 4 do
        local progressionTable = _G["Progression" .. index]
        for _, info in ipairs(progressionTable) do
            if info.boardFileName then
                collectedBoards[info.boardFileName:lower()] = true
                BuildBoard(info.boardFileName)
            end
            if info.challenges then
                for _, challengeInfo in ipairs(info.challenges) do
                    if challengeInfo.boardFileName then
                        collectedBoards[challengeInfo.boardFileName:lower()] = true
                        BuildBoard(challengeInfo.boardFileName)
                    end
                end
            end
        end
    end
end


function BinaryizeLua(fileName, inputPath, outputPath, assetsFileListPath)
    local inputTarget = '<assets!source>' .. fileName
    jamtarget[inputTarget].SEARCH = inputPath
    local outputTarget = '<assets>' .. fileName
    jam.UseDepCache(outputTarget, 'platform')
    jamtarget[outputTarget].SOURCE_STRING = '@' .. fileName
    jamtarget[outputTarget].STRIP = '0'
    jam.MakeLocate(outputTarget, outputPath)
    jam.Clean('clean:assets', outputTarget)
    jam.Depends('assets', outputTarget, inputTarget)
    jam.UseFileCache(outputTarget)
    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileLua(outputTarget, inputTarget)
    AddToAssetsFileList(assetsFileListPath .. fileName, outputTarget)
end


local processedImages = {}
function ProcessImageDirectory(cookedPath, tempPath, options)
    local addToFileList = options.addToFileList
    if addToFileList == nil then
        addToFileList = true
    end
    local assetsFileListPath = options.assetsFileListPath

    Atlases = nil
    Images = nil

    local imagesPath = ospath.join(cookedPath, assetsFileListPath)
    local tempPath = ospath.join(tempPath, assetsFileListPath)

    -- Read in the ImageInfo
    local chunk = loadfile(imagesPath .. ".imageinfo")
    if chunk then chunk() end

    local ignoreFiles = {}

    if Atlases then
        for atlasName, atlas in pairs(Atlases) do
            local inputTargets = {}
            for _, imageName in ipairs(atlas) do
                local filename = imageName:lower() .. '.png'
                local inputTarget = '<images!source>' .. assetsFileListPath .. filename
                jamtarget[inputTarget].BINDING = filename
                jamtarget[inputTarget].SEARCH = imagesPath

                if not Images  or  not Images[imageName] then
                    ignoreFiles[filename] = true
                end
                inputTargets[#inputTargets + 1] = inputTarget
            end
            table.sort(inputTargets)

            local outputImageTarget = '<images!atlas>' .. assetsFileListPath .. atlasName:lower() .. '.png'
            local outputInfoTarget = '<images!atlas>' .. assetsFileListPath .. atlasName:lower() .. '.lua'
            local outputTargets = { outputImageTarget, outputInfoTarget }
            jam.MakeLocate(outputTargets, ospath.join(tempPath, 'atlas'))
            jamtarget[outputImageTarget].BINDING = atlasName:lower() .. '.png'
            jamtarget[outputInfoTarget].BINDING = atlasName:lower() .. '.lua'
            jam.Depends('assets', outputTargets, inputTargets)
            jam.UseDepCache(outputTargets, 'platform')
            jam.UseCommandLine(outputTargets, {
                "v5",
                "padding=" .. (atlas.padding or 0),
                "maxSize=" .. (atlas.maxSize or 0),
                "nosplit=" .. tostring(atlas.nosplit or false),
                table.unpack(inputTargets)
            })
            jamtarget[outputImageTarget].ATLAS_NAME = atlasName
            jamtarget[outputInfoTarget].ATLAS_NAME = atlasName
            jam._BuildAtlas(outputTargets, inputTargets)
            jam.Clean('clean:assets', outputTargets)

            local optimizedImageTarget = '<images>' .. assetsFileListPath .. atlasName:lower() .. '.png'
            jam.MakeLocate(optimizedImageTarget, tempPath)
            jamtarget[optimizedImageTarget].BINDING = atlasName:lower() .. '.png'
            jam.Depends('assets', optimizedImageTarget, outputImageTarget)
            jam.UseDepCache(optimizedImageTarget, 'platform')
            jam._Optipng(optimizedImageTarget, outputImageTarget)
            jam.Clean('clean:assets', optimizedImageTarget)

            if addToFileList then
                AddToAssetsFileList(assetsFileListPath .. atlasName:lower() .. '.png', optimizedImageTarget)
                AddToAssetsFileList(assetsFileListPath .. atlasName:lower() .. '.lua', outputInfoTarget)
            end
        end
    end

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
        if not entry.is_directory  and  not ignoreFiles[entry.filename:lower()] then
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

        if extension == '.lua'  and  addToFileList then
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
            jamtarget[inputTarget].SEARCH = imagesPath
            jamtarget[inputTarget].BINDING = fileName:lower()

            local outputTarget = '<images>' .. assetsFileListPath .. fileName:lower()
            jam.UseDepCache(outputTarget, 'platform')
            jamtarget[outputTarget].BINDING = fileName:lower()
            jam.MakeLocate(outputTarget, tempPath)

            if processedImages[outputTarget] then
                print('Duplicate', outputTarget)
            end
            processedImages[outputTarget] = true
            if imageInfo then
                local outputAlphaTarget = '<images>' .. assetsFileListPath .. fileTitle .. '_' .. extension
                jam.UseDepCache(outputAlphaTarget, 'platform')
                jamtarget[outputAlphaTarget].BINDING = fileTitle .. '_' .. extension
                jam.MakeLocate(outputAlphaTarget, tempPath)
                local pngnq = forcepngnq or imageInfo.pngnq or true

                -- If the image is described, we can run gfxmonger on it.
                if imageInfo.Palettize then
                    if pngnq  and  extension == ".png" then
                        local splitPath = tempPath .. 'split/'
                        local outputSplitRGBTarget = '<images!split>' .. assetsFileListPath .. fileTitle .. extension
                        local outputSplitAlphaTarget = '<images!split>' .. assetsFileListPath .. fileTitle .. '_' .. extension
                        jamtarget[outputSplitRGBTarget].BINDING = fileTitle .. extension
                        jamtarget[outputSplitAlphaTarget].BINDING = fileTitle .. '_' .. extension
                        jam.MakeLocate(outputSplitRGBTarget, splitPath)
                        jam.MakeLocate(outputSplitAlphaTarget, splitPath)

                        jam.UseDepCache({ outputSplitRGBTarget, outputSplitAlphaTarget }, 'platform')
                        jam.UseFileCache({ outputSplitRGBTarget, outputSplitAlphaTarget })
                        jam._SplitImageRGB_Alpha({ outputSplitRGBTarget, outputSplitAlphaTarget }, inputTarget)

                        local nq8Target = ospath.remove_extension(outputSplitRGBTarget) .. '-nq8.png'
                        jam.UseDepCache(nq8Target, 'platform')
                        jam.MakeLocate(nq8Target, splitPath)
                        jamtarget[nq8Target].BINDING = fileTitle .. '-nq8.png'
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
                        jamtarget[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                        jam.MakeLocate(outputInfoTarget, tempPath)
                        jam.Clean('clean:assets', outputInfoTarget)
                        jam.Depends('assets', outputInfoTarget, { outputTarget, outputAlphaTarget })
                        if addToFileList then
                            AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)
                        end

                        jam._AnalyzeImage(outputInfoTarget, { outputTarget, outputAlphaTarget })
                        jam.Clean('clean:assets', {outputTarget, outputAlphaTarget})
                        if addToFileList then
                            AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                            AddToAssetsFileList(assetsFileListPath .. fileTitle .. '_' .. extension, outputAlphaTarget)
                        end

                        jam.UseFileCache({outputInfoTarget, outputTarget, outputAlphaTarget})
                    end
                else
                    jam.Depends('assets', outputTarget, inputTarget)
                    if addToFileList then
                        AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                    end
                    if extension == ".png" then
                        jam._Optipng(outputTarget, inputTarget)
                        jam.UseFileCache(outputTarget)

                        local outputInfoTarget = outputTarget .. '.info'
                        jam.UseDepCache(outputInfoTarget, 'platform')
                        jamtarget[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                        jam.MakeLocate(outputInfoTarget, tempPath)
                        jam.Clean('clean:assets', outputInfoTarget)
                        jam.UseFileCache(outputInfoTarget)
                        jam.Depends('assets', outputInfoTarget, { outputTarget, outputAlphaTarget })
                        if addToFileList then
                            AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)
                        end
                        jam._AnalyzeImage(outputInfoTarget, { outputTarget, outputAlphaTarget })
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
                if addToFileList then
                    AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension, outputTarget)
                end
                if extension == ".png" and optimizeimages then
                    jam._Optipng(outputTarget, inputTarget)
                    jam.UseFileCache(outputTarget)
                else
                    jam._CopyFile(outputTarget, inputTarget)
                end

                local outputInfoTarget = outputTarget .. '.info'
                jam.UseDepCache(outputInfoTarget, 'platform')
                jamtarget[outputInfoTarget].BINDING = jam_expand('@(' .. outputInfoTarget .. ':BS)')
                jam.MakeLocate(outputInfoTarget, tempPath)
                jam.Clean('clean:assets', outputInfoTarget)
                jam.UseFileCache(outputInfoTarget)
                jam.Depends('assets', outputInfoTarget, outputTarget)
                if addToFileList then
                    AddToAssetsFileList(assetsFileListPath .. fileTitle .. extension .. '.info', outputInfoTarget)
                end

                jam._AnalyzeImage(outputInfoTarget, outputTarget)

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
        jamtarget[inputTarget].SEARCH = rawFontsPath
        local outputTarget = '<images>' .. fontName .. '.txt'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempFontsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        AddToAssetsFileList("fonts/" .. fontName .. '.txt', outputTarget)
    end

    local ttfFonts =
    {
        "lemon-regular",
    }

    for _, fontName in ipairs(ttfFonts) do
        local inputTarget = '<images!source>' .. fontName .. '.ttf'
        jamtarget[inputTarget].SEARCH = rawFontsPath
        local outputTarget = '<images>' .. fontName .. '.ttf'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempFontsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        AddToAssetsFileList("fonts/" .. fontName .. '.ttf', outputTarget)
    end
end


function ProcessImageDirectoryHelper(directory)
    ProcessImageDirectory(COOKED_PATH, TEMP_PATH, { assetsFileListPath = directory })
end


function ProcessLevel()
	ProcessImageDirectoryHelper("images/level/")
	ProcessImageDirectoryHelper("images/level/balls/")
	ProcessImageDirectoryHelper("images/level/clouds/")
	ProcessImageDirectoryHelper("images/level/day/")
	ProcessImageDirectoryHelper("images/level/hud/")
	ProcessImageDirectoryHelper("images/level/night/")
	ProcessImageDirectoryHelper("images/level/tiles_32/")
end


function ProcessPlayer()
	ProcessImageDirectoryHelper("images/level/player/")
	ProcessImageDirectoryHelper("images/level/player/blink/")
	ProcessImageDirectoryHelper("images/level/player/doublejump/")
	ProcessImageDirectoryHelper("images/level/player/idle/")
	ProcessImageDirectoryHelper("images/level/player/magic/")
	ProcessImageDirectoryHelper("images/level/player/pointjump/")
	ProcessImageDirectoryHelper("images/level/player/throwball/")
	ProcessImageDirectoryHelper("images/level/player/throwspear/")
	ProcessImageDirectoryHelper("images/level/player/uncoverthrow/")
	ProcessImageDirectoryHelper("images/level/player/uncoverthrowspear/")
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

    ProcessImageDirectory(cookedPath, tempPath, { assetsFileListPath = "map/opening/" })

    for entry in filefind.glob(cookedPath .. '/ui/*.ui.lua') do
        BinaryizeLua(ospath.remove_directory(entry.filename), cookedPath .. '/ui/', tempPath .. '/ui/', 'ui/')
    end
end


function ProcessMusic()
    local music =
    {
        "Game1",
        "Game2",
        "MapIntro",
        "MapReward",
        "Menu",
    }

    local cookedMusicPath = COOKED_PATH .. '/music'
    local tempMusicPath = TEMP_PATH .. '/music'

    for _, musicName in ipairs(music) do
        local inputTarget = '<assets|source>' .. musicName:lower() .. '.ogg'
        jamtarget[inputTarget].SEARCH = cookedMusicPath
        local outputTarget = '<assets>' .. musicName:lower() .. '.ogg'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempSoundsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        AddToAssetsFileList('music/' .. musicName .. '.ogg', outputTarget)
    end
end


function ProcessSounds()
    local sounds =
    {
        "AllFound",
        "BallEntering",
        "BallExit",
        "BallRolling",
        "Bomb",
        "BouncerHit",
        "Chute",
        "FlipBouncer",
        "FoundBouncer",
        "InvalidSelection",
        --"MapReward",
        "MapZoom",
        "MissHit",
        "MistBurn",
        "MouseClick",
        "PathCompleted",
        "ShifterHit",
        "SplitterHit",
        "Star",
        "StartLevel",
        "ThrowBurn",
        "TimeAlert",
        "TimeCountdown",
        "TwirlerHit",
        "WinLevel",
        "WinTrophy",
        "WrongGuess",
    }

    local cookedSoundsPath = COOKED_PATH .. '/sounds'
    local tempSoundsPath = TEMP_PATH .. '/sounds'

    for _, soundName in ipairs(sounds) do
        local inputTarget = '<assets|source>' .. soundName:lower() .. '.ogg'
        jamtarget[inputTarget].SEARCH = cookedSoundsPath
        local outputTarget = '<assets>' .. soundName:lower() .. '.ogg'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempSoundsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        AddToAssetsFileList('sounds/' .. soundName .. '.ogg', outputTarget)
    end
end


function ProcessMapSounds()
	local sounds =
	{
		-- Sonomic.com
		"Buffalo",

		-- SoundDogs.com
		"Alligator",
		"Bear",
		"Crickets",
		"Dinosaur",
		"Swamp",
		"Elephant",
		"Gorilla",
		"Porcupine",
		"Rockfall",
		"Scorpion",
		"Sheep",
		"Tiger",
		"Tornado",
		"Whale",

		-- IndieSfx.co.uk
		"AcidLake",
		"Bees",
		"Birds",
		"Storm",
		"MountainPeak",
		"Inferno",
		"JungleAnimals",
		"Night",
		"SunnyDay",
		"Wind",

		-- SoundRangers.com
		"Brook",
		"Campfire",
		"Footsteps",
		"Horse",
		"Hiss",
		"Beast",
		"Thunder",
		"Waterfall",
		"Waves",
		"Wolf",
	}

    local cookedSoundsPath = COOKED_PATH .. '/map/sounds'
    local tempSoundsPath = TEMP_PATH .. '/map/sounds'

    for _, soundName in ipairs(sounds) do
        local inputTarget = '<assets|source>' .. soundName:lower() .. '.ogg'
        jamtarget[inputTarget].SEARCH = cookedSoundsPath
        local outputTarget = '<assets>' .. soundName:lower() .. '.ogg'
        jam.UseDepCache(outputTarget, 'platform')
        jam.MakeLocate(outputTarget, tempSoundsPath)
        jam.Depends('assets', outputTarget, inputTarget)
        jam.Clean('clean:assets', outputTarget)
        jam._CopyFile(outputTarget, inputTarget)
        AddToAssetsFileList('map/sounds/' .. soundName .. '.ogg', outputTarget)
    end
end


function ProcessProgression()
    local inputTarget = '<GameAssets|source>Progression.lua'
    jamtarget[inputTarget].SEARCH = COOKED_PATH

    local outputTarget = '<GameAssets>Progression.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH)

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)

    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileProgression(outputTarget, inputTarget)

    AddToAssetsFileList('Progression.lua', outputTarget)

    dofile(jam_expand('@(' .. inputTarget .. ':T)')[1])

    BuildJourney()

    do
        local collectedBoardsSorted = {}
        for boardFilename in pairs(collectedBoards) do
            collectedBoardsSorted[#collectedBoardsSorted + 1] = boardFilename
        end
        table.sort(collectedBoardsSorted)

        local inputTargets = { inputTarget }
        for _, name in ipairs(collectedBoardsSorted) do
            name = name:lower() .. '.board'

            local grist = '<assets|source>' .. name
            inputTargets[#inputTargets + 1] = grist
        end

        local outputTarget = '<GameAssets>BoardsInfo.lua'
        jam.MakeLocate(outputTarget, TEMP_PATH)

        jam.Depends('assets', outputTarget, inputTargets)
        jam.Clean('clean:assets', outputTarget)

        jam.UseCommandLine(outputTarget, inputTargets)
        jam._DumpBoardsInfo(outputTarget, inputTargets)

        AddToAssetsFileList('BoardsInfo.lua', outputTarget)
    end

    for entry in filefind.glob(COOKED_PATH .. '/masks/*.mask') do
        BuildMask(ospath.remove_extension(ospath.get_filename(entry.filename)))
    end
end


function ProcessMap()
    local inputTarget = '<GameAssets>levelmap.svg'
    jamtarget[inputTarget].SEARCH = COOKED_PATH .. '/map'

    local outputTarget = '<GameAssets>levelmap.lua'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, TEMP_PATH .. '/map')

    jam.Depends('assets', outputTarget, inputTarget)
    jam.Clean('clean:assets', outputTarget)

    jam.UseCommandLine(outputTarget, BINARY_OR_TEXT_COMMAND_LINE)
    jam._CompileLevelMap(outputTarget, inputTarget)

    AddToAssetsFileList('map/levelmap.lua', outputTarget)
end


function AddToMapFileList(entryName, sourceFilePath)
    local compress = 8
    local ext = ospath.get_extension(entryName)
    if ext == ".png"  or
        ext == ".ogg" or ext == ".caf" or ext == ".zip" then
        compress = 0
    end

    assetsFileList[#assetsFileList + 1] = {
        EntryName = entryName,
        SourcePath = sourceFilePath,
        CompressionMethod = compress,
    }
end


function ProcessMapArchive()
    local mapPath = 'map/rewards/'

    local tempMapGeneratedPath = TEMP_PATH .. "/map/generated/"

    local wipeLowerLeftTarget = "<images!source>map/wipe_lower_left.png"
    local wipeLowerRightTarget = "<images!source>map/wipe_lower_right.png"
    local wipeUpperLeftTarget = "<images!source>map/wipe_upper_left.png"
    local wipeUpperRightTarget = "<images!source>map/wipe_upper_right.png"
    jamtarget[wipeLowerLeftTarget].SEARCH = COOKED_PATH
    jamtarget[wipeLowerRightTarget].SEARCH = COOKED_PATH
    jamtarget[wipeUpperLeftTarget].SEARCH = COOKED_PATH
    jamtarget[wipeUpperRightTarget].SEARCH = COOKED_PATH

    local mapWipeTarget = '<images>map/mapwipe.dat'
    jam.MakeLocate(mapWipeTarget, tempMapGeneratedPath)

    --local inputTargets = { mapColorTarget, mapNoColorTarget, mapSimpleTarget }
    local inputTargets = { wipeLowerLeftTarget, wipeLowerRightTarget, wipeUpperLeftTarget, wipeUpperRightTarget }
    local outputTargets = { mapWipeTarget }

    jam.Depends('assets', outputTargets, inputTargets)
    jam.UseDepCache(outputTargets, 'platform')
    jam.UseCommandLine(outputTargets, { 'v1' })
    jam._GenerateWipe(outputTargets, inputTargets)
    jam.Clean('clean:assets', outputTargets)

    ProcessImageDirectoryHelper("map/rewards/")
    --ProcessImageDirectoryHelper("map/")

	local mapColorFileName = "map_color"
	AddToMapFileList('map/' .. mapColorFileName .. '.png', COOKED_PATH .. '/map/' .. mapColorFileName .. '.png')
	local mapNoColorFileName = "map_no_color"
	AddToMapFileList('map/' .. mapNoColorFileName .. '.png', COOKED_PATH .. '/map/' .. mapNoColorFileName .. '.png')
	local mapSimpleFileName = "map_simple"
	AddToMapFileList('map/' .. mapSimpleFileName .. '.jpg', COOKED_PATH .. '/map/' .. mapSimpleFileName .. '.jpg')

	AddToMapFileList('map/mappoints.lua', COOKED_PATH .. '/map/MapPoints.lua')
   AddToMapFileList('map/mapwipe.dat', tempMapGeneratedPath .. '/map/mapwipe.dat')
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


actions _DumpBoardsInfo {
    $(LUA_EXE:C) $(GameAssets)/DumpBoardsInfo.lua ^^^($(2[2-]:J=$(NEWLINE))) $(1:C)
}


actions _GenerateWipe {
    $(LUA_EXE:C) $(GameAssets)/GenerateWipe.lua "$(1[1]:D)/" $(2[1]:CD)/
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

if $(NT) {
	BIN_PATH = $(GameAssets)/../bin/win32 ;
} else {
	BIN_PATH = $(GameAssets)/../bin/macosx32 ;
}


if $(NT) {
    actions _Optipng {
        copy $(2:C\\) $(1:C\\) > nul
        $(BIN_PATH)/optipng -quiet $(1)
    }
} else {
    actions _Optipng {
        cp $(2:C) $(1:C)
        $(BIN_PATH)/optipng -quiet $(1)
    }
}

actions _AnalyzeImage {
    $(BIN_PATH)/AnalyzeImage $(2[1])
}

actions _SplitImageRGB_Alpha {
    $(BIN_PATH)/SplitImageRGB_Alpha $(2) $(1)
}

actions _pngnq {
    $(BIN_PATH)/pngnq -f -s 1 $(2)
}

actions _CompileLua {
    $(LUA_EXE:C) $(GameAssets)/../scripts/CompileLuaScript.lua $(2:C) $(1:C) $(SOURCE_STRING) $(STRIP)
}

actions _CompileLevelMap {
    $(LUA_EXE:C) $(GameAssets)/CompileLevelMap.lua $(2:C) $(1:C)
}

actions _BuildAtlas {
    $(LUA_EXE:C) $(GameAssets)/../scripts/BuildAtlas.lua $(ATLAS_NAME) $(2[1]:DC) $(1[1]:DC) $(1[1]:B)
}

]]


CompileStringTable()
ProcessProgression()
BuildFonts()
ProcessLevel()
ProcessPlayer()
ProcessStory()
ProcessMenus()
ProcessSounds()
ProcessMapSounds()
ProcessMusic()

ProcessMapArchive()

jamvar["CLEAN.VERBOSE"] = 1
--jamvar["CLEAN.NOOP"] = 1
jamvar["CLEAN.ROOTS"] = TEMP_PATH .. "/**@-" .. TEMP_PATH .. "/.depcache@-" .. TEMP_PATH .. "/assetsfilelist.lua@-" .. TEMP_PATH .. "/map/generated/map_simple.jpg@-" .. TEMP_PATH .. "/map/generated/map/mapwipe.dat"

jam_parse[[
actions screenoutput _BuildArchive {
    $(LUA_EXE:C) $(GameAssets)/ArchiveAssets.lua $(2:C) $(1:C)
}
]]


function ProcessArchive()
    local inputTarget = '<GameAssets>assetsFileList.lua'
    jam.MakeLocate(inputTarget, jamvar.ASSETS_INTERMEDIATES[1])

    local allAssets = jam.DependsList('assets')
    jam.Depends(inputTarget, allAssets)

    local prettydump = require 'prettydump'
    local assetsFileListDumpText = prettydump.dumpascii(':string', 'assetsFileList', assetsFileList)
    jamtarget[inputTarget].CONTENTS = assetsFileListDumpText
    jam.UseCommandLine(inputTarget, assetsFileListDumpText)
    jam.WriteFile(inputTarget)
    jam.Clean('clean:assets', inputTarget)

    local outputTarget = '<GameAssets>assets.dat'
    jam.UseDepCache(outputTarget, 'platform')
    jam.MakeLocate(outputTarget, IMAGE_PATH)

    jam.Depends('assets', outputTarget, { allAssets, inputTarget })
    jam.Clean('clean:assets', outputTarget)

    jam.UseCommandLine(outputTarget, 'v1')
    jam._BuildArchive(outputTarget, inputTarget)
end

ProcessArchive()

--if jamvar.JAM_COMMAND_LINE_TARGETS[1] == 'assets' then
--    jam.QueueJamfile(jamvar.GameAssets[1] .. '/ArchiveAssets.jam')
--end

