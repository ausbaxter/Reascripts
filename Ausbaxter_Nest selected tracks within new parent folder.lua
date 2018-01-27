 --[[
 * Name: Nest selected tracks within new parent folder
 * Description: Creates a new parent folder for the selected tracks
 * Instructions: Select tracks. Run Script. Get Coin.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter > Reascripts
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Nest selected tracks within new parent folder.lua
 * Licence: GPL v3
 * REAPER: 5.XX
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-02)
  + Initial Release
--]]

--Get useful project info
selTrackCount = reaper.CountSelectedTracks()
firstItemTrack = reaper.GetSelectedTrack(0,0)
firstTrackIndex = reaper.GetMediaTrackInfo_Value(firstItemTrack, "IP_TRACKNUMBER")

--Insert parent function
function InsertAndSelectParentTrack(trackindex)

  reaper.InsertTrackAtIndex(firstTrackIndex - 1, false)
  reaper.SetMediaTrackInfo_Value(reaper.GetTrack(0, firstTrackIndex - 1), "I_SELECTED", 1)
  selTrackCount = reaper.CountSelectedTracks()
  
end

function main() -- Main Function

  InsertAndSelectParentTrack(firstTrackIndex)
  
    for i = 0, selTrackCount - 1 do    
      track = reaper.GetSelectedTrack(0, i)
      
      if i == 0 then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)
      elseif i == selTrackCount - 1 then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", -1)
      end
      
    end
    
end

--Run main function if there are tracks selected
if selTrackCount > 0 then

  reaper.Undo_BeginBlock()
  main()
  
else
  
  reaper.ReaScriptError("Error: Select tracks to be nested within a folder")
  
end

reaper.Undo_EndBlock("Make selected tracks child tracks", -1)
