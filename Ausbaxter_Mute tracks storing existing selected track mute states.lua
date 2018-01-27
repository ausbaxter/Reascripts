--[[
 * ReaScript Name: Mute tracks storing existing selected track mute states
 * Description: Allows you to quickly mute a selection of tracks without having to worry about 
       restoring previous mute states manually.
 * Instructions: Select a group of tracks, run this script. When you want to restore original mute
       states use the script "Restore muted tracks from stored states"
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Mute tracks storing existing selected track mute states
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
dofile('C:/Users/Austin/AppData/Roaming/REAPER/Scripts/My Scripts/' .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------
function Main()

  local index_table = {}
  local mutes_table = {}
  tracks = GetSelectedTracks()
  
  for i, track in ipairs(tracks) do
  
    local mute_state = math.floor(reaper.GetMediaTrackInfo_Value(track.track, "B_MUTE"))
    table.insert(index_table, track.index)
    table.insert(mutes_table, mute_state)
    
    reaper.SetMediaTrackInfo_Value(track.track, "B_MUTE", 1)
  
  end
  
  reaper.SetProjExtState(0, "TrackMuteStates", "TrackIndexes", TableToCSV(index_table, ""))
  reaper.SetProjExtState(0, "TrackMuteStates", "MuteStates", TableToCSV(mutes_table, ""))
  
end

if reaper.CountSelectedTracks() > 0 then

  reaper.Undo_BeginBlock()
  Main()
  reaper.Undo_EndBlock("Mute tracks storing existing mute states.", 16)

else

  reaper.ReaScriptError("You do not have any tracks selected.")

end
