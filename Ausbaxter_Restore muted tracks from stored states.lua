--[[
 * ReaScript Name: Restore muted tracks from stored states
 * Description: Restores the muted track arrangement that existed when "Mute tracks storing existing selected track mute states" was ran
 * Instructions: Run "Mute tracks storing existing selected track mute states", then when you want to recall the tracks previous mute state run this script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Restore muted tracks from stored states.lua
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
dofile('C:/Users/Austin/AppData/Roaming/REAPER/Scripts/My Scripts/' .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------
function Main()

  retval, track_indexes = reaper.GetProjExtState(0, "TrackMuteStates", "TrackIndexes")
  retval, track_mute_states = reaper.GetProjExtState(0, "TrackMuteStates", "MuteStates")
  
  track_index_table = TableFromCSV(track_indexes)
  track_mute_table = TableFromCSV(track_mute_states)
  
  for i, t_index in ipairs(track_index_table) do
  
    track = reaper.GetTrack(0, t_index)
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", track_mute_table[i])
  
  end

end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.Undo_EndBlock("Restore muted tracks from stored states.", 16)
reaper.UpdateArrange()
