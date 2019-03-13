local OPEN_API = 41065
local DIR_SEP = string.find(reaper.GetOS(), "OSX") and "/" or "\\"

local in_functions = false
local html_scope = {
    lua = false,
    eel = false,
    python = false
}

r_func = {}
r_func.__index = r_func

function r_func.new(arg) -- constructor is r_func(arg,s)
    self = setmetatable({}, r_func) -- set self to a new table with a prototype for implementation
    self.arg = arg
    return self
end

function SetHtmlScope(scope)
    if html_scope[scope] == nil then reaper.ReaScriptError("Html scope does not exist.") return false end
    for i, s in pairs(html_scope) do html_scope[i] = false end
    html_scope[scope] = true
    return true
end

function GetAPIPath()
    reaper.ShowMessageBox(
        "Please copy and paste the path name of the reascript api html file to the 'Reascript API Doc Path' window.\n\n"..
        "The API and 'Reascript API Doc Path' window will be opened after pressing 'Ok'.",
        "Generate Reaper Visual Studio Code Snippets", 
        0
    )
    reaper.Main_OnCommand(OPEN_API, 0)
    local retval, user_input = reaper.GetUserInputs("Reascript API Doc Path", 1, "Path to API html:", "Paste Here")
    if not retval then return end
    local path = string.gsub(user_input, "file:"..DIR_SEP..DIR_SEP, "")
    if not reaper.file_exists(path) then return end
    return path
end

function Main()
    -- local path = GetAPIPath()
    -- if not path then return end

    local path = "/Users/austin/Desktop/testing.html"

    local api = io.open(path, "r")
    if not api then return end

    local index = 1 --used to keep track of current function entry to update values line over line
    local multiline = false
    for line in api:lines() do
        if string.find(line, "API Function List") then in_functions = true end

        if in_functions then

            if html_scope.eel then
                -- handle gfx VARIABLES differently
                brk = "<[bBrR]+><[bBrR]+>"
                local f, d = string.match(line, ".*<code>([^<>]*)</code>"..brk.."([^<>]*)"..brk..".*$") -- split function and description
                if f and d then reaper.ShowConsoleMsg(f .. "\n" .. d .. "\n\n") end -- found function
            elseif html_scope.lua then
                if string.find(line, "<code>.*</code>") then -- found function (line over line)
                    string.match(line, ".*<code>([^<>]*)</code>")
                end
            elseif html_scope.python then
                -- reaper.ShowConsoleMsg("PYTHON\t")
            else
                -- reaper.ShowConsoleMsg("GENERAL\t")
            end

        end

        -- reaper.ShowConsoleMsg(line.."\n")

        --not switching successfully??
        if string.find(string.lower(line), "reascript/eel built%-in function list") then SetHtmlScope("eel")
        elseif string.find(string.lower(line), "reascript/lua built%-in function list") then SetHtmlScope("lua")
        elseif string.find(string.lower(line), "reascript/python built%-in function list") then SetHtmlScope("python") end
    end

end

Main()