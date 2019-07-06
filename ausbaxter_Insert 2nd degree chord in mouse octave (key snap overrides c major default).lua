--@description script name
--@version 1.0
--@author ausbaxter
--@about
--  # {Package Title}
--  {Any Documentation}
--@changelog
--  + Initial release

--------------------------------------------------------------------------------------------
--[[                                   Load Functions                                     ]]
--------------------------------------------------------------------------------------------
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
local p_delim = string.find(reaper.GetOS(), "Win") and "\\" or "/"
local base_directory = string.match(filename, ".*" .. p_delim)
loadfile(base_directory .. "ausbaxter_Functions.lua")()
--------------------------------------------------------------------------------------------
--[[                                                                                      ]]
--------------------------------------------------------------------------------------------

InsertChordFromScaleDegree(2)