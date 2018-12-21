function Print(value)
  reaper.ShowConsoleMsg(value)
end


function GetSelectedItems()

  mediaItemCount = reaper.CountSelectedMediaItems()
  
  selMediaItems = {}
  
  for i = 0, mediaItemCount - 1 do
    selMediaItems[i] = reaper.GetSelectedMediaItem(0, i)
    
  end      
  
end

function KeepSelectedTrackItems()

  for i = 0,  mediaItemCount - 1 do
    thisItem = selMediaItems[i]
    
    trackTest = reaper.GetMediaItemTrack(thisItem)
          
    if reaper.GetMediaTrackInfo_Value(trackTest, "I_SELECTED") == 0 then
    
      reaper.SetMediaItemInfo_Value(thisItem, "B_UISEL", 0)
    
    end
    
  end
  
end

function Main()

  GetSelectedItems()
  KeepSelectedTrackItems()
  
end

Main()
