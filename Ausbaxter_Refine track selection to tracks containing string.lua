--[[
 * ReaScript Name: 
 * Description: 
 * Instructions: 
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/
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
------------------------------Required--------------------------------------

directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(directory .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------

function GetUserInput()
  
  local retval, input = GetInput("Refine selected tracks selection", 1, {"string"}, ".+")
  local user_string = input["string"] == nil and "" or tostring(input["string"])
  return retval, string.lower(user_string) --make sure case sensitivity doesn't affect matching
  
end

function Main()
  
  retval, user_string = GetUserInput() --get user string to compare to track names
  
  if retval == true then
  
    sel_track_count, selected_tracks = GetSelectedTracks({"P_NAME"})
    reaper.Main_OnCommand(40297, 0)--unselect all currently selected tracks
    
    for i, track in ipairs(selected_tracks) do
    
      local name_compare = string.lower(track["P_NAME"])
    
      if user_string == "" then
           
             if name_compare == "" then
           
               reaper.SetMediaTrackInfo_Value(track["TRACK"], "I_SELECTED", 1)
               
             end
           
      elseif string.find(name_compare, user_string) ~= nil then
           
          reaper.SetMediaTrackInfo_Value(track["TRACK"], "I_SELECTED", 1)
             
      end
    
    end
    
  end

end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Refine selected tracks selection", 0)
