local osprocess = require 'osprocess'
local ospath = require 'ospath'

local argIndex = 1

local ssl
if arg[argIndex] == '-ssl' then
    ssl = true
    argIndex = argIndex + 1
end

local baseDirectory = arg[argIndex]
argIndex = argIndex + 1

JAM_EXECUTABLE = os.getenv('JAM_EXECUTABLE')

print('-------------------------------------------------------------')

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

function GetLocalIPAddress()
    if OS == 'NT' then
        for line in osprocess.lines{"FOR /F \"tokens=4 delims= \" %%i in ('route print ^| find \" 0.0.0.0\"') do echo %%i"} do
            return line:match('(.+)[^\n]')
        end
    else
        -- https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x
        local getipaddressScript = ospath.join(outputPath, 'getipaddress.sh')
        ospath.mkdir(getipaddressScript)
        ospath.write_file(getipaddressScript, [[ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p']])
        ospath.chmod(getipaddressScript, 777)
        for line in osprocess.lines{getipaddressScript} do
            return line
        end
    end
    error()
end

local hostname = GetLocalIPAddress()
local caKeyFilename = ospath.join(outputPath, 'jamplusCA-' .. hostname .. '.key')
local caCerFilename = ospath.join(outputPath, 'jamplusCA-' .. hostname .. '.cer')
local serverKeyFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.key')
local serverCsrFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.csr')
local serverCerFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.cer')
local serverPemFilename = ospath.join(outputPath, 'jamplusServer-' .. hostname .. '.pem')

if ssl  and  (not ospath.exists(caKeyFilename)
        or  not ospath.exists(caCerFilename)
        or  not ospath.exists(serverKeyFilename)
        or  not ospath.exists(serverCsrFilename)
        or  not ospath.exists(serverCerFilename)
        or  not ospath.exists(serverPemFilename)) then

    if OS == 'NT' then
        opensslExecutable = 'c:/OpenSSL-Win32/bin/openssl.exe'
        if not ospath.exists(opensslExecutable) then
            opensslExecutable = 'c:/OpenSSL-Win64/bin/openssl.exe'
            if not ospath.exists(opensslExecutable) then
                opensslExecutable = 'c:/openssl-1.1.0f-vs2017/bin/openssl.exe'
                if not ospath.exists(opensslExecutable) then
                    opensslExecutable = nil
                else
                    osprocess.setenv('OPENSSL_CONF', ospath.join(ospath.remove_filename(opensslExecutable), '..', 'ssl', 'openssl.cnf'))
                end
            end
        end
        if not opensslExecutable then
            for entry in os.getenv('PATH'):gmatch('[^;]*') do
                opensslExecutable = ospath.join(entry, 'openssl.exe')
                if ospath.exists(opensslExecutable) then
                    print(opensslExecutable)
                    break
                end
                opensslExecutable = nil
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

if ssl  and  not ospath.exists(serverPemFilename) then
    local pemLines = {}
    for line in io.lines(serverCerFilename) do
        pemLines[#pemLines + 1] = line .. '\n'
    end
    for line in io.lines(serverKeyFilename) do
        pemLines[#pemLines + 1] = line .. '\n'
    end
    ospath.write_file(serverPemFilename, table.concat(pemLines))
end

if ssl then
    print('Certificates are stored at: ' .. outputPath)
    print()
end


-----------------------------------------------------------------------------------------------
local civetwebPath = ospath.join(JAM_EXECUTABLE_PATH, 'civetweb')
local civetwebExecutable
if OS == 'NT' then
    civetwebExecutable = ospath.join(civetwebPath, 'civetweb.exe')
else
    civetwebExecutable = ospath.join(civetwebPath, 'civetweb')
end
if not ospath.exists(civetwebExecutable) then
    ospath.mkdir(civetwebExecutable)
    ospath.write_file(ospath.join(civetwebPath, 'Jamfile.jam'), [[
SubDir TOP ;

local CIVETWEB_ROOT = civetweb_src/civetweb-1.12 ;
local CIVETWEB_URL = https://github.com/civetweb/civetweb/archive/v1.12.zip ;

if ! $(PREPASS_FINISHED) {

    QueueJamfile $(JAM_CURRENT_SCRIPT) ;

    Download.DownloadAndUnzip civetweb : $(SUBDIR)/civetweb_src : $(CIVETWEB_URL) : $(SUBDIR)/$(CIVETWEB_ROOT)/src/civetweb.c ;

    PREPASS_FINISHED = true ;

} else {

    C.Defines civetweb : OPENSSL_API_1_1 ;
    C.IncludeDirectories : $(CIVETWEB_ROOT)/include ;
    if $(NT) {
        C.LinkPrebuiltLibraries : advapi32 comdlg32 gdi32 shell32 user32 ;
    }
    C.OutputPath : "]] .. civetwebPath .. [[" ;

    C.Application : $(CIVETWEB_ROOT)/src/civetweb.c $(CIVETWEB_ROOT)/src/main.c : console ;

}
]])

    for line in osprocess.lines{ JAM_EXECUTABLE, '-C' .. civetwebPath} do
        print(line)
    end
end

local confMakeSlash = OS == 'NT'  and  ospath.make_backslash  or  ospath.make_slash
local civetwebconfFilename = ospath.join(baseDirectory, 'civetweb.conf')
ospath.write_file(civetwebconfFilename,
"document_root " .. confMakeSlash(baseDirectory) .. "\n" ..
"listening_ports 9999" .. (ssl and 's' or '') .. "\n" ..
"ssl_certificate " .. confMakeSlash(serverPemFilename) .. "\n" ..
"url_rewrite_patterns /jamplusCA.cer=" .. confMakeSlash(caCerFilename))

print('-------------------------------------------------------------')
print(string.format('Local web server running at: %s://%s:%d/\n\nPress Enter to exit.', ssl  and  'https'  or  'http', hostname, 9999))

local lanes = require 'lanes'

local processInfo
if true then
    --do
    local linda = lanes.linda()
    local lane = lanes.gen('*', function(civetwebExecutable, civetwebconfFilename)
        local ospath = require 'ospath'
        local osprocess = require 'osprocess'
        local env = osprocess.environ()

        if OS == 'MACOSX' then
            env.DYLD_FALLBACK_LIBRARY_PATH = '/usr/local/opt/openssl/lib'
        end

        local command =
        {
            ospath.escape(civetwebExecutable), civetwebconfFilename,
            env = env,
            stderr_to_stdout = true,
            can_terminate = true,
        }

        local proc, input = osprocess.popen(command, false)
        local processInfo = proc:getinfo()
        linda:send('info', { processInfo = processInfo })
        while not cancel_test() do
            local line = input:read("*l")
            if not line then break end
        end
        input:close()
        args.exitcode = proc:wait()
    end)(civetwebExecutable, civetwebconfFilename)

    local startTime = os.clock()
    while os.clock() - startTime < 5 do
        local key, info = linda:receive(0.1, "info")
        if info then
            processInfo = info.processInfo
            break
        end
    end
end

io.stdin:read('*l')
osprocess.terminate(processInfo, 1)
