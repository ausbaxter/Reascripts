--[[
 * ReaScript Name: Rename all tracks based on track's first item
 * Description: Set the track's name field to whatever name the first item contains. Useful if bring in stems.
 * Instructions: Select tracks you want the naming to apply to. Run Script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Rename all tracks based on first track item.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-03)
  + Initial Release
--]]

function Main()
  local track_count = reaper.CountTracks(0)

  for i = 0, track_count - 1 do
  
    --get track
    local track = reaper.GetTrack(0, i ) 
    local item = reaper.GetTrackMediaItem(track, 0)
    
    if item ~= nil then --checks if track has any items
    
      --get item's first take name 
      local retval, item_name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item, 0),"P_NAME", "", false)
    
      --format item string to accept %w (alphanumeric) > %s (space) > %d (digits)
      local formatted_name = string.match(item_name, "[%w*%s*_]+")
      
      -- assign formatted item name to track
      reaper.GetSetMediaTrackInfo_String(track, "P_NAME", formatted_name, true)
      
    end 
  end 
end

reaper.Undo_BeginBlock()

Main()

reaper.Undo_EndBlock("Rename all tracks based on first item name", 0)
