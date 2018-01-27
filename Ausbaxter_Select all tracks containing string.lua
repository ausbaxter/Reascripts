--[[
 * ReaScript Name: Select all tracks containing string
 * Description: Selects only tracks whos name contains the entered string
 * Instructions: Run script, enter string to match project tracks with. Press Ok.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Select all tracks containing string.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-04)
  + Initial Release
--]]
------------------------------Required--------------------------------------

directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(directory .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------

function GetUserInput()
  
  local retval, input = GetInput("Select all tracks containing string", 1, {"string"}, ".*")
  local user_string = input["string"] == nil and "" or tostring(input["string"])
  return retval, string.lower(user_string) --make sure case sensitivity doesn't affect matching
  
end

function Main()

  local retval, user_string = GetUserInput() --get user string input to compare to track names
  
  if retval == true then --check if user cancelled
  
    reaper.Main_OnCommand(40297, 0) --unselect all tracks
    
    for i = 0, reaper.CountTracks(0) - 1 do
    
      local track = reaper.GetTrack(0, i)
      local rval, tr_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)--get current track name
      local tr_name = string.lower(tr_name) --make sure case sensitivity doesn't affect matching
      
      if user_string == "" then
      
        if tr_name == "" then
      
          reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
          
        end
      
      elseif string.find(tr_name, user_string) ~= nil then
      
        reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
        
      end
    
    end
    
  end

end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Select all tracks containing string", 0)
