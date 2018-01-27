reaper.Undo_BeginBlock()


function Main()

  markerCount, regionCount = reaper.CountProjectMarkers(0)
  totMarkers = markerCount + regionCount
  masterTrack = reaper.GetMasterTrack(0)
  masterTrackVolume = reaper.GetTrackEnvelopeByName(masterTrack, "Volume")
  numAutoItems = reaper.CountAutomationItems(masterTrackVolume)
  if numAutoItems == 1 then
    poolNum = reaper.GetSetAutomationItemInfo(masterTrackVolume, 0, "D_POOL_ID", 0, false)
    autoItemLength = reaper.GetSetAutomationItemInfo(masterTrackVolume, 0, "D_LENGTH", 0, false)
    envTest = reaper.GetSelectedEnvelope(0)
    
    for i = 0, totMarkers - 1 do
    
      retval, isrgn, regionPos, regionEnd, name, index = reaper.EnumProjectMarkers(i)
      
      if isrgn then
      
        regionLength = regionEnd - regionPos
        lengthScale = autoItemLength / regionLength
        index = reaper.InsertAutomationItem(masterTrackVolume, 0, regionPos, autoItemLength)
        
        reaper.GetSetAutomationItemInfo(masterTrackVolume, index, "D_POOL_ID", poolNum, true)
        reaper.GetSetAutomationItemInfo(masterTrackVolume, index, "D_LENGTH", regionLength, true)
        reaper.GetSetAutomationItemInfo(masterTrackVolume, index, "D_PLAYRATE", lengthScale, true)
        
      end    
    end
    
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Create Pooled Master Volume Automation", 0)
    
  end
end

Main()
