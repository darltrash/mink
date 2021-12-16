#!/usr/bin/luajit
local lume = require("lib.lume")
local log = require("lib.log")

-- SETUP LOG STUFF:
log.usecolor = jit.os ~= "Windows" -- still lmao
math.randomseed(os.time())

local cmd = function (command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

local decodeJSON = function (json) -- http://lua-users.org/lists/lua-l/2011-10/msg01134.html
	local str = {}
	local escapes = { r='\r', n='\n', b='\b', f='\f', t='\t', Q='"', ['\\'] = '\\', ['/']='/' }
	json = json:gsub('([^\\])\\"', '%1\\Q'):gsub('"(.-)"', function(s)
		str[#str+1] = s:gsub("\\(.)", function(c) return escapes[c] end)
		return "$"..#str
	end):gsub("%s", ""):gsub("%[","{"):gsub("%]","}"):gsub("null", "nil")
	json = json:gsub("(%$%d+):", "[%1]="):gsub("%$(%d+)", function(s)
		return ("%q"):format(str[tonumber(s)])
	end)
	return assert(loadstring("return "..json))()
end

local encodeLua = function (tab)
    
end

local processes = {
    help = function()
        print("   help: print this help message")
        print("   pack <format>: package into <format>")
    end,

    pack = function (self, target_name)
        local uuid = lume.uuid()
        local targets = {
            love = function ()
                log.info("[1/3] Copying into temporary folder (./%s/)", uuid)
                cmd("cp -r ../* .")

                log.info("[2/3] Deleting extra files and folders")
                for _, value in ipairs({"README*", "*.txt", "map/*.ldtk", ".vscode/", "build.lua"}) do
                    cmd("rm -r "..value) 
                end

                log.info("[3/3] Packing files")
                cmd("zip -r ../love.love *")
            end
        }
        local targets_list = ""
        for k in pairs(targets) do
            targets_list = targets_list .. k .. ", "
        end
        targets_list = targets_list:sub(1, #targets_list-2)

        local target = log.assert(
            targets[log.assert(target_name, 
                "Please specify target! targets available are:\n%s\n", targets_list
            )], "Target '%s' not known! Available targets:\n%s\n", target_name, targets_list
        )
 
        cmd("mkdir ."..uuid)
        cmd("cd ."..uuid)
        cmd("echo $CWD")
        target(self, targets)
        log.info("Cleaning up")
        cmd("cd ../")
        cmd("rm -rf ."..uuid)
    end
}

do
    local do_what = arg[1] or "help"
    local process = processes[do_what]
    if not process then
        log.fatal("Process '%s' not known! falling back to 'help'", do_what)
        process = processes.help
        do_what = "help"
    end

    print("\n./build.lua " ..  do_what .. ":")
    process(processes, select(2, unpack(arg)))
    print()
end