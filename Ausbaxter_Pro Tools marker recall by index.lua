--[[
 * ReaScript Name: Pro Tools marker recall by index
 * Description: Similar recall method to pro tools.
 * Instructions: Run Script (for instance with period '.') and type the index of the marker you want to go to.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Pro Tools marker recall by index.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2015-11-27)
  + Initial Release
--]]

--Gets user input
Retval, mk_input = reaper.GetUserInputs("Go To Marker", 1, "Index:", "")

--Checks for compatible input
numcheck = tonumber(mk_input)

if numcheck ~= nil then

  --Goes to Marker with same index as user  input
  reaper.GoToMarker(0, mk_input, false)
  
end

