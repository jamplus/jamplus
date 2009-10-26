function Test()
	local pattern = [[
MD5 of  -> d41d8cd98f00b204e9800998ecf8427e
passes!
MD5 of a -> 0cc175b9c0f1b6a831c399e269772661
passes!
MD5 of abc -> 900150983cd24fb0d6963f7d28e17f72
passes!
MD5 of message digest -> f96b697d7cb7938d525a2f31aaf161d0
passes!
MD5 of abcdefghijklmnopqrstuvwxyz -> c3fcd3d76192e4007dfb496cca67e13b
passes!
MD5 of ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -> d174ab98d277d9f5a5611c2c9f419d9f
passes!
MD5 of 12345678901234567890123456789012345678901234567890123456789012345678901234567890 -> 57edf4a22be3c955ac49da2e2107b67a
passes!
MD5 of message digest -> f8cae54e40b7a527d435f52edaddf74a
Done with MD5 test, exiting...
]]

	TestPattern(pattern, RunJam{ '-fmd5test.jam' })
end

