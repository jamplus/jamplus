lua-miniz - Lua module for miniz support

This module add deflate/inflate and zip file operations support to Lua
language. some code from luvit's miniz module, thanks for that work!

license:
This module has the same license with Lua (the Lua license here[1]).
note that the modified version of miniz.c has its own license (see miniz.c file).

[1]: https://www.lua.org/license.html

build:

use your fabourite compiler to build lminiz.c and miniz.c, get miniz.dll
or miniz.so

usage:

local miniz = require "miniz"


functions:

miniz.adler32([string[, prev: number]]) -> number
miniz.crc32([string[, prev: number]]) -> number
    calculate adler32 and crc32 checksum for string. without arguments, give a
    initialize checksum.

    local a = miniz.crc32("hello")
    local b = miniz.crc32("world", a)
    -- a is the checksum of "hello", and b is the checksum of "helloworld"

miniz.compress(string[, level: number[, window_size: number]]) -> [string]
miniz.decompress(string[, window_bits: number]) -> [string]
    compress/decompress string, use given flags.
    when window_size and window_bits are negature, the compress result will
    not include a zlib-compatible header.

miniz.compress([level: number[, window_size: number]]) -> [stream]
miniz.decompress([window_bits: number]) -> [stream]
    create a new compress/decompress stream,

    when compress:
    output, eof, input_bytes, output_bytes = stream(string[, flush])
    where flush are "sync", "full" or "finish"

    when decompress:
    output, eof, input_bytes, output_bytes = stream(string)

    same as lua-zlib module.

miniz.zip_read_file(filename: string[, flags: number]) -> [miniz.ZipReader]
miniz.zip_read_string(content: string[, flags: number]) -> [miniz.ZipReader]
    read a zip from file (given filename) or content string.

    flags: (from miniz.c)
	0x100: case sensitive file name in zip file.
	0x200: ignore path of file in zip.
	0x400: file is compressed data.
	0x800: do not sort central directory in zip file.

miniz.zip_write_file(filename: string[, reserved: number]) -> miniz.ZipWriter
miniz.zip_write_string([reserved: number[, init_size: number]]) -> miniz.ZipWriter
    write files to a zip file or a string.
    reserved is the reserved size before zip file itself. init_size is the
    first allocated memory for write file content. 

#ZipReader -> number
ZipReader:get_num_files() -> number
    get the file count in zip file.

ZipReader[idx:number] -> string
ZipReader:get_filename(idx:number) -> string
    get the idx-th file name in zip file.

ZipReader:close() -> boolean
    close zip file, return success or not.

ZipReader:locate_file(filename: string) -> number
    get the index from file name

ZipReader:stat(idx: number) -> table
    get file information from given index.

    returned table fields:
	index: index of file
	version_made_by: zip version
	version_needed: extract file need version
	bit_flag: flags of file
	method: compress method
	time: file time
	crc32: file crc32 checksum
	comp_size: compressed size
	uncomp_size: uncompressed size
	internal_attr: internal attribute
	external_attr: external attribute
	filename: filename
	comment: comment

ZipReader:is_file_a_directory(idx: number) -> boolean
    return whether given idx of file is a directory.

ZipReader:get_offset() -> number
    get the start offset of zip file in given file/string.

ZipReader:extract(idx: number[, flags: number]) -> [string]
ZipReader:extract(filename: string[, flags: number]) -> [string]
    extract a file from zip. flags see miniz.zip_read_file()

ZipWriter:close() -> boolean
    close a zip file

ZipWriter:add_string(path: string, content: string[, comment: string[, flags: number]]) -> ZipWriter
ZipWriter:add_file(path: string, filename: string[, comment: string[, flags: number]]) -> ZipWriter
    add a file to zip.

ZipWriter:add_from_zip_reader(src: miniz.ZipReader, idx: number) -> ZipWriter
    add a file from zip reader to zip.

ZipWriter:finalize() -> string
ZipWriter:finalize() -> ZipWriter
ZipWriter:finalize() -> nil, string
    finalize the write of zip. if zip writer is created from zip_write_string,
    then the result string is returned; if zip writer is created from
    zip_write_file, then ZipWriter itself is returned, otherwire a nil and a
    error message is returned.

