--@description Nest selected tracks within new parent folder
--@version 1.0
--@author ausbaxter
--@about
--    # Creates a new parent folder for the selected tracks
--@changelog
--  + Initial release

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
        local last_folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", last_folder_depth - 1)
      end
    end
    
end

--Run main function if there are tracks selected
if selTrackCount > 0 then

  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock("Nest tracks in new folder", -1)
  
else
  
  reaper.ReaScriptError("Error: Select tracks to be nested within a folder")
  
end
