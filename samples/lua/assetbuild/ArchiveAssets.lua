local ospath = require 'ospath'
local ziparchive = require 'ziparchive'

local StatusUpdate_StatusToText = {}
StatusUpdate_StatusToText[ziparchive.UPDATING_ARCHIVE] = "-> "
StatusUpdate_StatusToText[ziparchive.DELETING_ENTRY] = "\tdel: "
StatusUpdate_StatusToText[ziparchive.DIRECT_COPY_FROM_ANOTHER_ARCHIVE] = "\tdirect-copy: "
StatusUpdate_StatusToText[ziparchive.COPYING_ENTRY_FROM_CACHE] = "\tfrom-cache: "
StatusUpdate_StatusToText[ziparchive.COPYING_ENTRY_TO_CACHE] = "\tto-cache: "
StatusUpdate_StatusToText[ziparchive.UPDATING_ENTRY] = "\tupdate: "
StatusUpdate_StatusToText[ziparchive.PACKING_ARCHIVE] = "\tpack: "
--StatusUpdate_StatusToText[ziparchive.PACKING_COPY] = "\tpack-copy: "
 

local fileListOptions =
{
    --	FileCache = 'thecache',
    StatusUpdate = function(status, text)
        if StatusUpdate_StatusToText[status] then
            io.write(StatusUpdate_StatusToText[status] .. text .. '\n')
        end
    end,

    --RetrieveChecksum = function(sourcePath)
    --local crc, md5 = ziparchive.filecrcmd5(sourcePath)
    --print(sourcePath, crc, md5)
    --return crc, md5
    --end,
}


local inputFilename, outputFilename = ...
ospath.mkdir(outputFilename)

dofile(inputFilename)

print('Creating archive...')
local archive = ziparchive.new()
archive:open(outputFilename, 'a', 0, password)
local succeeded, errorMessage = archive:processfilelist(assetsFileList, fileListOptions)
if not succeeded then
    print(errorMessage)
end
archive:close()

