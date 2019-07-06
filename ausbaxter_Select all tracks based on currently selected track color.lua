--[[
 * ReaScript Name: Select all tracks based on currently selected track color
 * Description:  Selects all the tracks within the project with the exact same color.
 * Instructions: Select ONE track to use as the color source, run the script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Select all tracks based on currently selected track color
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-10-05)
  + Initial Release
--]]

function Main()

  local selected_track_count = reaper.CountSelectedTracks()
  local selected_track = reaper.GetSelectedTrack(0,0)
  local selected_track_color = reaper.GetTrackColor(selected_track)
  
  if selected_track_count == 1 then
    
    for i = 0, reaper.CountTracks() - 1 do
    
      local this_track = reaper.GetTrack(0, i)
      
      if reaper.GetTrackColor(this_track) == selected_track_color then
      
        reaper.SetMediaTrackInfo_Value(this_track, "I_SELECTED", 1)
        
      end
      
    end
    
  else
  
    reaper.ReaScriptError("Error: Must have one track selected.")
    
  end

end

reaper.Undo_BeginBlock()

Main() --execute main function

reaper.Undo_EndBlock("Select all tracks based on currently selected track color", -1)
