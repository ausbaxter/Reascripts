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
    {"\n", "\\n"},
    {"%c", ""},
    {"%s$", ""}
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

function CsvToTable(csv)
    if not csv then error("CsvToTable Error: Invalid argument", 2) return end
    if csv == "" then error("CsvToTable Error: Empty csv", 2) return end
    local c_table = {}
    local out = {}
    local ignore_space = false
    local ignore_comma = false
    for i = 1, string.len(csv) do
        local c = string.sub(csv, i, i)
        if c == "," then
            ignore_space = true
            if ignore_comma then
                ignore_comma = false
            else
                table.insert(out, table.concat(c_table))
                c_table = {}
            end
        elseif c == "[" then
            ignore_comma = true
            table.insert(out, table.concat(c_table))
            c_table = {}
            table.insert(c_table, c)
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

function EnsureValidPath(path)
    if not path then return nil end
    if type(path) ~= "string" then return nil end
    if not reaper.EnumerateFiles(path, 1) then reaper.ShowMessageBox("Please specify a valid output path.", "Error: Invalid output path", 0) --[[error("Path Error: Output path does not exist")]] return nil end
    local li = string.len(path)
    if string.sub(path, li, li) ~= DIR_SEP then return path .. DIR_SEP else return path end
end

function GetVersion()
    return tonumber(string.match(reaper.GetAppVersion(), "[%d%.]+"))
end

function GetAPIPath()
    local req_new_api = true
    local cur_ver = GetVersion()
    local old_ver = reaper.GetExtState("api_snippets", "old_version")
    reaper.SetExtState("api_snippets", "old_version", cur_ver, true)
    
    if old_ver and old_ver ~= "" and cur_ver <= tonumber(old_ver) then
        req_new_api = false
    end
    
    local ext_api = reaper.GetExtState("api_snippets", "api_path")
    local ext_out_path = reaper.GetExtState("api_snippets", "out_path")
    if not ext_api or ext_api == "" or req_new_api then 
        ext_api = "Paste Here" 
        reaper.Main_OnCommand(OPEN_API, 0)
    end
    if not ext_out_path or ext_out_path == "" then 
        ext_out_path = "Paste Here" 
    end

    local retval, user_input = reaper.GetUserInputs("Generate Reascript API Snippets", 2, "API html file:,Output snippets path:", ext_api .. "," .. ext_out_path)
    if not retval then return end
    t_user_input = CsvToTable(user_input)

    local api = string.match(t_user_input[1], DIR_SEP .. "[^" .. DIR_SEP .. "].-$")
    if not reaper.file_exists(api) then error("Error: Invalid api path") end
    reaper.SetExtState("api_snippets", "api_path", api, true)

    local out_path = EnsureValidPath(t_user_input[2])
    if not out_path then return end
    reaper.SetExtState("api_snippets", "out_path", out_path, true)

    local out_file = out_path .. "reaper-api.code-snippets"

    return api, out_file
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

function Queue:DequeueAll(empty)
    if type(self) ~= "table" or self.type ~= "queue" then error("DequeueAll Error: Self has no object", 2) end
    if empty then for i, c in ipairs(self) do self[i] = nil end end
    return table.concat(self)
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

function GetJsonSnippet(name, prefix, scope, body, description)
    return table.concat(
        {"\t\"" .. name .. "\": {",
        "\t\t\"prefix\": \"" .. prefix .. "\",",
        "\t\t\"scope\": \"" .. scope .. "\",",
        "\t\t\"body\": \"" .. body .. "\",",
        "\t\t\"description\": \"" .. description .. "\"",
        "\t}"
        }, "\n")
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
    local tss = "" tse = ""
    local opt_args = false
    if #self.rets > 0 then 
        tab_num = 2
        tss = "${1:"
        tse = " = }"
    end
    if NumOptArgs() > 1 then opt_args = true end
    for i, s in ipairs(t) do
        local tab = {}
        for j, e in ipairs(s) do
            if string.find(e, "%[") then
                tab_num = tab_num + 1
                table.insert(tab, "${" .. tab_num - 1 .. ":${"..tab_num..":"..e.."}")
            elseif string.find(e, "%]") then
                table.insert(tab, "${"..tab_num..":"..e.."}}")
            else
                table.insert(tab, "${"..tab_num..":"..e.."}")
            end
            tab_num = tab_num + 1
        end
        table.insert(o, table.concat(tab, ", "))
    end
    -- if string.find(o[2], "[%[%]]") and NumOptArgs() > 0 then o[2] = string.gsub(o[2],"%${%d:.?%[.-%]", "${" .. #self.args + 1 .. ":%1" .. "}") end
    return tss .. o[1] .. tse, o[2]
end

function Func:GetSnippet()
    if type(self) ~= "table" or self.type ~= "func" then error("GetSnippet Error: Self has no object", 2) end
    local rets, args = self:GetTabStops()
    return GetJsonSnippet(self.name, 
        self.name, 
        self.scope, 
        rets .. self.name .. "(" .. args .. ")",
        self.desc
    )
end

function GetGfxQueue(str)
    local parse_queue = Queue.New()
    local char_table = {}
    local i = 1
    while i <= string.len( str ) do
        local c = string.sub( str, i, i )
        i = i + 1
        if c == "<" then
            if #char_table > 0 then
                parse_queue:Enqueue(table.concat(char_table))
                char_table = {}
            end
            local t = {"<"}
            while c ~= ">" do
                c = string.sub( str, i, i )
                i = i + 1
                table.insert(t, c)
            end
            parse_queue:Enqueue(table.concat(t))
        else
            table.insert(char_table, c)
        end
    end
    return parse_queue
end

function U_List(gfx_queue)
    local elm = gfx_queue:Dequeue() --get first element
    local t = {}
    while elm do
        if elm == "<li>" then
            table.insert(t, gfx_queue:Dequeue())
        elseif elm == "<ul>" then
            table.remove(t)
            gfx_queue:Putback(2)
            local par = gfx_queue:Dequeue()
            gfx_queue:Putback(-1)
            table.insert(t, {par, U_List(gfx_queue)})
        end
        elm = gfx_queue:Dequeue() -- get next element
    end
    return t
end

function ParseGfxVars(gfx_queue)
    local elm = gfx_queue:Dequeue()
    while elm and elm ~= "<ul>" do
        elm = gfx_queue:Dequeue()
    end
    return U_List(gfx_queue)
end

function WriteGfxSnippets(gfx_string, scope)
    local gfx_queue = GetGfxQueue(gfx_string)
    local gfx_vars = ParseGfxVars(gfx_queue)
    for i, v in ipairs(gfx_vars) do
        local output = ""
        if type(v) == "table" then
            local var, d1 = string.match(v[1], "(.-)%s[%w-]+%s(.+)")
            local d_tbl = {d1}
            for j, v2 in ipairs(v[2]) do table.insert(d_tbl, v2) end
            local var_list = CsvToTable(var)
            for i, single_var in ipairs(var_list) do
                local output = GetJsonSnippet(scope .." ".. single_var, 
                    single_var, 
                    scope, 
                    single_var,
                    CleanBadChars(table.concat(d_tbl, "\n\t"))
                )
                -- reaper.ShowConsoleMsg(output.."\n")
                io.write(output, ",\n")
            end
        else
            local var, desc = string.match(v, "(.-)%s[%w-]+%s(.+)")
            local var_list = CsvToTable(var)
            for i, single_var in ipairs(var_list) do
                local output = GetJsonSnippet(scope .." ".. single_var, 
                    single_var, 
                    scope, 
                    single_var,
                    CleanBadChars(desc)
                )
                -- reaper.ShowConsoleMsg(output.."\n")
                io.write(output, ",\n")
            end
        end
    end
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
            elseif string.find(string.lower(line), "gfx variables") then
                WriteGfxSnippets(line, html_scope.current)
            end
        elseif html_scope.lua or html_scope.python then
            local f_name, f_args = string.match(line, "<code>(.-)%((.-)%)")
            if f_name then
                local f_desc = api:Dequeue()
                if f_desc then f_desc = string.gsub(f_desc, "\\", "\\\\") end
                local f = Func.New(nil, f_name, f_args, f_desc, html_scope.current)
                io.write(f:GetSnippet(),",\n")
            elseif string.find(string.lower(line), "gfx variables") then
                WriteGfxSnippets(api:Dequeue(), html_scope.current)
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
    local path, out_path = GetAPIPath()
    if not path or not out_path then return end
    --TODO add other snippet support (sublime text, etc)
    --TODO create html parsing test module

    -- local path = "/Users/austin/Desktop/testing.html"
    -- local out_path = "/Users/austin/Desktop/output.code-snippets"
    -- local path = "/private/var/folders/2s/s65k1yzn4658vfwt9pwd9gd40000gn/T/reascripthelp.html"

    api = Queue.New()
    api:EnqueueFile(path)

    out_file = io.output(out_path, "w")
    io.write("{\n")

    ConvertToSnippets(api)

    io.write("}")
    io.close(out_file)
end

Main()