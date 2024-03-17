function Test()
	local pattern = [[
xxh3_128bits of  -> 99aa06d3014798d86001c324468d497f
passes!
xxh3_128bits of a -> a96faf705af16834e6c632b61e964e1f
passes!
xxh3_128bits of abc -> 06b05ab6733a618578af5f94892f3950
passes!
xxh3_128bits of message digest -> 34ab715d95e3b6490abfabecb8e3a424
passes!
xxh3_128bits of abcdefghijklmnopqrstuvwxyz -> db7ca44e84843d67ebe162220154e1e6
passes!
xxh3_128bits of ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -> 5bcb80b619500686a3c0560bd47a4ffb
passes!
xxh3_128bits of 12345678901234567890123456789012345678901234567890123456789012345678901234567890 -> 08dd22c3ddc34ce640cb8d6ac672dcb8
passes!
xxh3_128bits of message digest -> 3c609fa47ffdc695fafe513fca53a696
passes!
xxh3_128bits of digest -> 9ed571ba06bb2170dd1ac6cb03fb6c53
Done with xxh3_128bits test, exiting...
]]

	TestPattern(pattern, RunJam{ '-fxxh3test.jam' })
end

