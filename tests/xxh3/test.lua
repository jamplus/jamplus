function Test()
	local pattern = [[
xxh3_128bits of  -> 7f498d4624c30160d8984701d306aa99
passes!
xxh3_128bits of a -> 1f4e961eb632c6e63468f15a70af6fa9
passes!
xxh3_128bits of abc -> 50392f89945faf7885613a73b65ab006
passes!
xxh3_128bits of message digest -> 24a4e3b8ecabbf0a49b6e3955d71ab34
passes!
xxh3_128bits of abcdefghijklmnopqrstuvwxyz -> e6e154012262e1eb673d84844ea47cdb
passes!
xxh3_128bits of ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -> fb4f7ad40b56c0a386065019b680cb5b
passes!
xxh3_128bits of 12345678901234567890123456789012345678901234567890123456789012345678901234567890 -> b8dc72c66a8dcb40e64cc3ddc322dd08
passes!
xxh3_128bits of message digest -> 96a653ca3f51fefa95c6fd7fa49f603c
passes!
Done with xxh3_128bits test, exiting...
]]

	TestPattern(pattern, RunJam{ '-fxxh3test.jam' })
end

