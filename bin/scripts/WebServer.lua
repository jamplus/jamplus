local osprocess = require 'osprocess'
local ospath = require 'ospath'

local arg = {...}
local argIndex = 1

local ssl
if arg[argIndex] == '-ssl' then
    ssl = true
    argIndex = argIndex + 1
end

local baseDirectory = arg[argIndex]

print('-------------------------------------------------------------')

function GetLocalIPAddress()
	local socket = require 'socket'.udp()
	socket:setpeername('10.10.10.10', '9999')
	return socket:getsockname()
end

local outputPath
local opensslExecutable = 'openssl'

local OS = os.getenv('OS')
if OS == 'Windows_NT' then
    OS = 'NT'
end
if OS == 'NT' then
    outputPath = ospath.join(os.getenv('LOCALAPPDATA'), 'jamplus', 'webserver')
else
    outputPath = ospath.join(os.getenv('HOME'), '.jamplus', 'webserver')
end

local hostname = GetLocalIPAddress()
local caKeyFilename = ospath.join(outputPath, 'jamplusCA-' .. hostname .. '.key')
local caCerFilename = ospath.join(outputPath, 'jamplusCA-' .. hostname .. '.cer')
local serverKeyFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.key')
local serverCsrFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.csr')
local serverCerFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.cer')

if ssl  and  (not ospath.exists(caKeyFilename)
        or  not ospath.exists(caCerFilename)
        or  not ospath.exists(serverKeyFilename)
        or  not ospath.exists(serverCsrFilename)
        or  not ospath.exists(serverCerFilename)) then

    if OS == 'NT' then
        for entry in os.getenv('PATH'):gmatch('[^;]*') do
            opensslExecutable = ospath.join(entry, 'openssl.exe')
            if ospath.exists(opensslExecutable) then
                break
            end
            opensslExecutable = nil
        end
        if not opensslExecutable then
            opensslExecutable = 'c:/OpenSSL-Win32/bin/openssl.exe'
            if not ospath.exists(opensslExecutable) then
                opensslExecutable = 'c:/OpenSSL-Win64/bin/openssl.exe'
                if not ospath.exists(opensslExecutable) then
                    opensslExecutable = 'c:/openssl-1.0.2f-vs2015/bin/opensslMT.exe'
                    if not ospath.exists(opensslExecutable) then
                        opensslExecutable = nil
                    else
                        osprocess.setenv('OPENSSL_CONF', ospath.join(ospath.remove_filename(opensslExecutable), '..', 'ssl', 'openssl.cnf'))
                    end
                end
            end
        end
    else
        for entry in os.getenv('PATH'):gmatch('[^:]*') do
            opensslExecutable = ospath.join(entry, 'openssl')
            if ospath.exists(opensslExecutable) then
                break
            end
            opensslExecutable = nil
        end
    end

    if not opensslExecutable then
        print('Unable to find an openssl executable.  Please ensure it is in your PATH.')
        os.exit(1)
    end

    opensslExecutable = ospath.escape(opensslExecutable)

    local cn = 'JamPlus-' .. hostname

    ospath.mkdir(caKeyFilename)

    print('Generating certificates...')
    for line in osprocess.lines{ opensslExecutable, 'genrsa', '-out', caKeyFilename, '2048', stderr_to_stdout = true } do
        --print(line)
    end

    for line in osprocess.lines{ opensslExecutable, 'req', '-x509', '-new', '-key', caKeyFilename, '-out', caCerFilename, '-days', '3650', '-subj', '/CN=' .. ospath.escape(cn), stderr_to_stdout = true } do
        --print(line)
    end

    for line in osprocess.lines{ opensslExecutable, 'genrsa', '-out', serverKeyFilename, '2048', stderr_to_stdout = true } do
        --print(line)
    end

    for line in osprocess.lines{ opensslExecutable, 'req', '-new', '-key', serverKeyFilename, '-out', serverCsrFilename, '-subj', '/CN=' .. ospath.escape(hostname), stderr_to_stdout = true } do
        --print(line)
    end

    for line in osprocess.lines{ opensslExecutable, 'x509', '-req', '-in', serverCsrFilename, '-out', serverCerFilename, '-CAkey', caKeyFilename, '-CA', caCerFilename, '-days', '3650', '-CAcreateserial', '-CAserial', 'serial', stderr_to_stdout = true } do
        --print(line)
    end

	os.remove('serial')
end

if ssl then
    print('Certificates are stored at: ' .. outputPath)
    print()
end


-----------------------------------------------------------------------------------------------
local xavante = require "xavante"
local filehandler = require "xavante.filehandler"
local redirecthandler = require 'xavante.redirecthandler'

local params

if ssl then
    params = {
        mode = "server",
        protocol = "sslv23",
        verify = {"none"},
        options = {"all", "no_sslv2"},
        key = serverKeyFilename,
        certificate = serverCerFilename,
    }
end

local rules = {
	{
		match = "^[^%./]*/$",
		with = redirecthandler,
		params = {"index.html"}
	}, 

	{
		match = "jamplusCA%.cer$",
		with = redirecthandler,
		params = {"jamplusCA-" .. hostname .. '.cer'}
	},

	{
		match = "jamplusCA%-" .. hostname .. ".cer",
		with = filehandler,
		params = {baseDir = outputPath}
	},

	{
		match = ".",
		with = filehandler,
		params = {baseDir = baseDirectory}
	},
}

xavante.start_message(function(ports) print(string.format('Local web server running at: %s://%s:%d/\n\nPress Enter to exit.', ssl  and  'https'  or  'http', hostname, ports[1])) end)
xavante.HTTP{ server = { host = '*', port = 9999, ssl = params }, defaultHost = { rules = rules, } }

local lanes = require 'lanes'.configure()
local lane = lanes.gen('*', function() return io.stdin:read('*l') end)()

xavante.start(function() return lane:join(0) ~= nil end, 0.1)

