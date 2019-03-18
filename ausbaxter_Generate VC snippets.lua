local OPEN_API = 41065
local DIR_SEP = string.find(reaper.GetOS(), "OSX") and "/" or "\\"

local in_functions = false
local html_scope = {
    current = nil,
    gen = false,
    lua = false,
    eel = false,
    python = false
}
local bad_chars = {
    {"<.->", ""},
    {"&amp;", "+"},
    {"&lt;", "<"},
    {"&gt;", ">"},
    {"\"", "\\\""},
    {"\t", "\\t"},
    {"\f", "\\f"},
    {"\r", "\\r"},
    {"%c", ""}
}

function SetHtmlScope(scope)
    if html_scope[scope] == nil then reaper.ReaScriptError("Html scope does not exist.") return false end
    for i, s in pairs(html_scope) do 
        if i ~= "current" then html_scope[i] = false end
    end
    if scope then
        html_scope[scope] = true
        html_scope.current = scope
    end
    return true
end

function CleanBadChars(s)
    for j, t in ipairs(bad_chars) do
        s = string.gsub(s, t[1], t[2])
    end
    return s
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

function CsvToTable(csv)
    if not csv then error("CsvToTable Error: Invalid argument", 2) return end
    if csv == "" then error("CsvToTable Error: Empty csv", 2) return end
    local c_table = {}
    local out = {}
    local ignore_space = false
    for i = 1, string.len(csv) do
        local c = string.sub(csv, i, i)
        if c == "," then
            ignore_space = true
            table.insert(out, table.concat(c_table))
            c_table = {}
        else
            if ignore_space then
                if c ~= " " then 
                    table.insert(c_table, c)
                    ignore_space = false
                end
            else
                table.insert(c_table, c)
            end
        end
    end
    table.insert(out, table.concat(c_table))
    return out
end

Queue = {type = "queue"}
Queue.__index = Queue

function Queue.New()
    self = setmetatable({}, Queue)
    self.index = 1
    return self
end

function Queue:Enqueue(val) 
    table.insert(self, val) 
end

function Queue:EnqueueFile(file)
    if type(self) ~= "table" or self.type ~= "queue" then error("EnqueueFile Error: Self has no object", 2) end
    if type(file) == "string" then file = io.open(file , "r") end
    if not file or not type(file) == "userdata" then error("File Enqueue Error: No file", 2) end
    for line in file:lines() do self:Enqueue(line) end
end

function Queue:Dequeue()
    if not self then error("Dequeue Error: Self has no object", 2) end
    if self.index > #self then return nil end
    retval = self[self.index]
    self.index = self.index + 1
    return retval
end

function Queue:Putback(num_entries)
    if type(self) ~= "table" or self.type ~= "queue" then error("Putback Error: Self has no object", 2) end
    local n = num_entries or 1
    if self.index - n < 1 then self.index = 1
    else self.index = self.index - n end
end

function Queue:SetIndex(index)
    if type(self) ~= "table" or self.type ~= "queue" then error("SetIndex Error: Self has no object", 2) end
    if index < 1 then index = 1
    elseif index > #self then index = #self end
    self.index = index
end

Func = {type = "func"}
Func.__index = Func

function Func.New(str_rets,str_name,str_args,str_desc,str_scope)
    self = setmetatable({}, Func)
    if not str_name or str_name == "" then error("Func error: Func object requires a function name", 2) return nil end
    if str_rets and str_rets ~= "" then self.rets = CsvToTable(CleanBadChars(str_rets)) else self.rets = {} end
    self.name = str_name
    if str_args and str_args ~= "" then self.args = CsvToTable(CleanBadChars(str_args)) else self.args = {} end
    self.desc = CleanBadChars(string.match(string.gsub(str_desc, "<[bB][rR]>", "\\n"),"(.-)[\\n]*$"))
    self.scope = str_scope
    return self
end

function Func:GetTabStops()
    local function NumOptArgs()
        for i, arg in ipairs(self.args) do
            if string.find(arg, "%[") then return #self.args - i end
        end
        return 0
    end
    if not self then error("GetTabStops Error: Self has no object", 2) end
    local t = {self.rets, self.args}
    local o = {}
    local tab_num = 1
    for i, s in ipairs(t) do
        local tab = {}
        for j, e in ipairs(s) do
            table.insert(tab, "${"..tab_num..":"..e.."}")
            tab_num = tab_num + 1
        end
        table.insert(o, table.concat(tab, ", "))
    end
    if string.find(o[2], "[%[%]]") and NumOptArgs() > 0 then o[2] = string.gsub(o[2],"%${%d:.?%[.-%]", "${" .. #self.args + 1 .. ":%1" .. "}") end
    return o[1], o[2]
end

function Func:GetSnippet()
    if type(self) ~= "table" or self.type ~= "func" then error("GetSnippet Error: Self has no object", 2) end
    local rets, args = self:GetTabStops()
    local eq = ""
    if rets ~= "" then eq = " = " end
    local t = {"\t\"" .. self.name .. "\": {",
        "\t\t\"prefix\": \"" .. self.name .. "\",",
        "\t\t\"scope\": \"" .. self.scope .. "\",",
        "\t\t\"body\": \"" .. rets .. eq .. self.name .. "(" .. args .. ")\",",
        "\t\t\"description\": \"" .. self.desc .. "\"",
        "\t}"
    }
    return table.concat(t, "\n")
end

function Func:Print()
    if not self then error("Print Error: Self has no object", 2) end
    local rets = #self.rets > 0 and table.concat(self.rets, ", ") .. " " or ""
    local args = #self.args > 0 and table.concat(self.args, ", ") or ""
    local desc = self.desc ~= "" and "\n" .. self.desc
    reaper.ShowConsoleMsg(self:GetSnippet() .. "\n\n")
end

function ConvertToSnippets(api)
    repeat
        local line = api:Dequeue()
        if html_scope.gen then
            local func_name = string.match(line, "<a name=\"(.-)\"><hr></a><br>")
            if func_name then 
                in_functions = true
                -- reaper.ShowConsoleMsg(func_name.."\n")
            end
            if in_functions then
                local f_line = api:Dequeue()
                local f_desc = {}
                local f_store = {}
                while not string.find(f_line, "<a name.+>") and not string.find(f_line, "<div class.-[fF]unction [lL]ist") do
                    local scope, f_def = string.match(f_line, "<div class=\".-\"><span class='all_view'>(.+):.-<code>(.-%(.-%))</code>")
                    if scope and f_def then
                        scope = string.lower(scope)
                        if scope ~= "c" then
                            f_def = string.gsub(f_def, "<.->", "")
                            local f_ret, f_name, f_args = string.match(f_def, "%(?(.-)%)?[=%s]-([^ ]-)%((.-)%)") -- arbitrary # returns
                            if not f_ret then f_name, f_args = string.match(f_def, "([^ ]-)%((.-)%)") end --  or void
                            table.insert(f_store, {f_ret, f_name, f_args, scope})
                        end
                    else
                        f_line = string.gsub(f_line, "\\", "\\\\")
                        table.insert(f_desc, f_line)
                    end
                    f_line = api:Dequeue()
                end
                api:Putback()
                for i, t in ipairs(f_store) do 
                    local f = Func.New(t[1], t[2], t[3], table.concat(f_desc, "\\n"), t[4])
                    io.write(f:GetSnippet(),",\n")
                end
                in_functions = false
            end
        elseif html_scope.eel then
            local f_name, f_args, f_desc = string.match(line, "<code>(.-)%((.-)%)</code><BR><BR>(.-)<BR>")
            if f_name then
                if f_desc then f_desc = string.gsub(f_desc, "\\", "\\\\") end
                local f = Func.New(nil, f_name, f_args, f_desc, html_scope.current)
                io.write(f:GetSnippet(),",\n")
            end
        elseif html_scope.lua or html_scope.python then
            local f_name, f_args = string.match(line, "<code>(.-)%((.-)%)")
            if f_name then
                local f_desc = api:Dequeue()
                if f_desc then f_desc = string.gsub(f_desc, "\\", "\\\\") end
                local f = Func.New(nil, f_name, f_args, f_desc, html_scope.current)
                io.write(f:GetSnippet(),",\n")
            end
        end
        
        if string.find(string.lower(line), "api function list") then SetHtmlScope("gen")
        else
            local scope = string.match(string.lower(line), "reascript/(.-) built%-in function list")
            if scope then SetHtmlScope(scope) end
        end

    until string.find(line, "</html>")
end

function Main()
    local path = GetAPIPath()
    if not path then return end

    -- local path = "/Users/austin/Desktop/testing.html"
    -- local path = "/private/var/folders/2s/s65k1yzn4658vfwt9pwd9gd40000gn/T/reascripthelp.html"

    local out_path = "/Users/austin/Desktop/output.code-snippets"
    local out_file = io.output(out_path, "w")

    api = Queue.New()
    api:EnqueueFile(path)

    io.write("{\n")

    ConvertToSnippets(api)

    io.write("}")
    io.close(out_file)
end

Main()