------------------------------Required--------------------------------------

directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(directory .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------

--chunks may be single statements or collections of statements and function definitions. You may separate lines with semicolons (;) they are not necessary but are useful for separating satements in the same line.
a = 1
b = a * 2

a = 1;
b = a * 2;

a = 1 ; b = a * 2;

a = 1 b = a * 2

--dofile. loads in a code library

--in reaper returning 0 will terminate the script execution.

--global variables can just be assigned. non-initialized global variables can be called and always return nil. You can assign nil to global variables to deleted them
--global variables can be thought to only exist if it has a non-nil value
--[[
global = "globlal variable"
Log("non-initialized: " .. tostring(global_nil) .. "\tinitialized: " .. global)
]]

--identifiers, can't use variable identifiers starting with numbers. starting with underscores should also be avoided. underscores can be useful for dummy variables.
--[[
_sketchy = "variable name"

_ = "dummy variable"
]]

--types and values. functions are first class values, so they can be manipulated like any other values:
--[[
function testfunc ()
  Log("Test function pring")
end

new = testfunc

new() --call testfunc from new variable.
]]

--Bools. false and nil return false, everything else (including empty strings and 0)
--[[
if (0) then
  Log("Zero is true")
end

if ("") then
  Log("\"\" is true")
end
]]

--strings. Strings in lua are immutable, they cannot be changed.
--[[
a = "one string"
b = string.gsub(a, "one", "another") --change string parts
Log(a) -- one string
Log(b) -- another string
a = nil --delete string
]]

--a unique example: a comparison btw 10 == "10" will return false because comparisons always look at type first. You need to use the tonumber() function to convert the string

--tables.
--tables cannot be declared but are created using a constructor expression. The simplest being '{}'

new_table = {}
