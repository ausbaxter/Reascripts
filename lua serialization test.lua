--Credit for serialization to Rochet2, LuaSerializer @ https://github.com/Rochet2/LuaSerializer/blob/master/LuaSerializer.lua

-- LuaSerializer main table
LuaSerializer = {}

-- ID characters for the serialization
local LuaSerializer_True            = 'T'
local LuaSerializer_False           = 'F'
local LuaSerializer_Nil             = 'N'
local LuaSerializer_Table           = 't'
local LuaSerializer_String          = 's'
local LuaSerializer_Number          = 'n'
local LuaSerializer_pInf            = 'i'
local LuaSerializer_nInf            = 'I'
local LuaSerializer_nNan            = 'a'
local LuaSerializer_pNan            = 'A'
local LuaSerializer_CodeChar        = '&' -- some really rare character in serialized data
local LuaSerializer_CodeEscaper     = LuaSerializer_CodeChar..'~'
local LuaSerializer_TableSep        = LuaSerializer_CodeChar..'D'
local LuaSerializer_EndData         = LuaSerializer_CodeChar..'E'

local assert = assert
local type = type
local tonumber = tonumber
local pairs = pairs
local sub = string.sub
local gsub = string.gsub
local gmatch = string.gmatch
local find = string.find
local len = string.len
local tconcat = table.concat
-- Some lua compatibility between 5.1 and 5.2
local unpack = unpack or table.unpack

local LuaSerializer_ToMsgVal
local LuaSerializer_ToRealVal

-- Functions for handling converting table to string and from string
-- local s = LuaSerializer_Table_tostring(t), local t = LuaSerializer_Table_fromstring(s)
-- Does not support circular table relation which will cause stack overflow
local function LuaSerializer_Table_tostring( tbl )
    -- assert(type(tbl) == "table", "#1 table expected")
    local result = {}
    for k, v in pairs( tbl ) do
        result[#result+1] = LuaSerializer_ToMsgVal( k )
        result[#result+1] = LuaSerializer_ToMsgVal( v )
    end
    return tconcat( result, LuaSerializer_TableSep )..LuaSerializer_TableSep
end
local function LuaSerializer_Table_fromstring( str )
    -- assert(type(str) == "string", "#1 string expected")
    local res = {}
    for k, v in gmatch(str, "(.-)"..LuaSerializer_TableSep.."(.-)"..LuaSerializer_TableSep) do
        local _k, _v = LuaSerializer_ToRealVal(k), LuaSerializer_ToRealVal(v)
        if _k ~= nil then
            res[_k] = _v
        end
    end
    return res
end

-- Escapes special characters
local function LuaSerializer_Encode(str)
    assert(type(str) == "string", "#1 string expected")
    return (gsub(str, LuaSerializer_CodeChar, LuaSerializer_CodeEscaper))
end
-- Unescapes special characters
local function LuaSerializer_Decode(str)
    assert(type(str) == "string", "#1 string expected")
    return (gsub(str, LuaSerializer_CodeEscaper, LuaSerializer_CodeChar))
end

-- Converts a value to string using special characters to represent the value
function LuaSerializer_ToMsgVal(val)
    local ret
    local Type = type(val)
    if Type == "string" then
        return LuaSerializer_String..val
    elseif Type == "number" then
        if val == math.huge then      -- test for +inf
            ret = LuaSerializer_pInf
        elseif val == -math.huge then -- test for -inf
            ret = LuaSerializer_nInf
        elseif val ~= val then        -- test for nan and -nan
            if find(''..val, '-', 1, true) == 1 then
                ret = LuaSerializer_nNan
            end
            ret = LuaSerializer_pNan
        end
        ret = LuaSerializer_Number..val
    elseif Type == "boolean" then
        if val then
            ret = LuaSerializer_True
        else
            ret = LuaSerializer_False
        end
    elseif Type == "nil" then
        ret = LuaSerializer_Nil
    elseif Type == "table" then
        ret = LuaSerializer_Table..LuaSerializer_Table_tostring(val)
    end
    if not ret then
        error("#1 Invalid value type ".. Type)
    end
    return LuaSerializer_Encode(ret)
end

-- Converts a string value from a message to the actual value it represents
function LuaSerializer_ToRealVal(val)
    local decoded = LuaSerializer_Decode(val)
    local Type = sub(decoded,1,1)
    if Type == LuaSerializer_Nil then
        return nil
    elseif Type == LuaSerializer_True then
        return true
    elseif Type == LuaSerializer_False then
        return false
    elseif Type == LuaSerializer_String then
        return sub(decoded, 2)
    elseif Type == LuaSerializer_Number then
        return tonumber(sub(decoded, 2))
    elseif Type == LuaSerializer_pInf then
        return math.huge
    elseif Type == LuaSerializer_nInf then
        return -math.huge
    elseif Type == LuaSerializer_pNan then
        return -(0/0)
    elseif Type == LuaSerializer_nNan then
        return 0/0
    elseif Type == LuaSerializer_Table then
        return LuaSerializer_Table_fromstring(sub(decoded, 2))
    end
    return nil
end

-- Takes in values and returns a string with them serialized
-- Does not compress the result
function LuaSerializer.serialize_nocompress(...)
    -- convert values into string form
    local n = select('#', ...)
    local serializeddata = {...}
    for i = 1, n do
        serializeddata[i] = LuaSerializer_ToMsgVal(serializeddata[i])
    end
    serializeddata = tconcat(serializeddata, LuaSerializer_EndData)..LuaSerializer_EndData

    return serializeddata
end
local LuaSerializer_serialize_nocompress = LuaSerializer.serialize_nocompress

-- Takes in a string of serialized data and returns a table with the values in it and the amount of values
-- The data must have been serialized with LuaSerializer.serialize_nocompress
function LuaSerializer.unserialize_nocompress(serializeddata)
    assert(type(serializeddata) == 'string', "#1 string expected")

    -- parse all data and convert it to real values
    local res = {}
    local i = 1
    for data in gmatch(serializeddata, "(.-)"..LuaSerializer_EndData) do
        -- tinsert is not used here since it ignores nil values
        res[i] = LuaSerializer_ToRealVal(data)
        i = i+1
    end

    return res, i-1
end
local LuaSerializer_unserialize_nocompress = LuaSerializer.unserialize_nocompress

-- Takes in values and returns a string with them serialized
-- Uses LZW compression, use LuaSerializer.serialize_nocompress if you dont want this
function LuaSerializer.serialize(...)
    -- Serialize and compress data
    return (assert(TLibCompress.CompressLZW(LuaSerializer_serialize_nocompress(...))))
end

-- Takes in a string of serialized data and returns a table with the values in it and the amount of values
-- The data must have been serialized with LuaSerializer.serialize
function LuaSerializer.unserialize(serializeddata)
    assert(type(serializeddata) == 'string', "#1 string expected")
    -- uncompress and unserialize data
    return LuaSerializer_unserialize_nocompress(assert(TLibCompress.DecompressLZW(serializeddata)))
end

tbl = {
    name = "Austin",
    age = 26,
    occupation = "Audio Person",
    hobbies = "coding, and in the past snowboarding.",
    other_info = "He can usually be found eating at fast food restaraunts, not working out, not working on things he should be and j'ing off."
}

s = LuaSerializer_Table_tostring(tbl)

reaper.ShowConsoleMsg(s .. "\n") -- serialized values

tbl_new = LuaSerializer_Table_fromstring(s)

reaper.ShowConsoleMsg(tbl_new.name .. "\n")