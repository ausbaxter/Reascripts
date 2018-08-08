--Render Item Columns
--store each item column in array iterate through the array to render out each column in sequence
--get in and out for each item column

function Print(m)

  reaper.ShowConsoleMsg(tostring(m) .. "\n")
  
end

function GetName(mediaItem, msg)

  local itemType = reaper.GetMediaItemNumTakes(mediaItem)
  
  local name = nil
  
  if itemType == 0 then
  
    name = reaper.ULT_GetMediaItemNote(mediaItem)
  
  else
    
    local take = reaper.GetTake(mediaItem, 0)
    
    name = reaper.GetTakeName(take)
  
  end
  
  Print(msg .. " " .. name)

end

function Initialize()
  
  selItemCount = reaper.CountSelectedMediaItems()

end

function GetSelectedItemsInOrder()

  --returns chronologically sorted table of selected items and their start and end times
  
  local selected_MediaItems = {}
  
  for i = 0, selItemCount - 1 do
  
    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    
    local itemStart, itemEnd = GetMediaItemPosition(mediaItem)
    
    local itemTrack = reaper.GetMediaItem_Track(mediaItem)
    
    local trackFound = false
    
    table.insert(selected_MediaItems, {mediaItem, itemStart, itemEnd})
        
  end
  
  --Sort table into chronological order
  table.sort(selected_MediaItems, function(a,b) return a[2] < b[2] end)
  
  return selected_MediaItems
  
  --SortItemsIntoColumns(selectedMediaItems)
  
end

function GetMediaItemPosition(mediaItem)

  local itemStart = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  
  return itemStart, itemEnd
  
end

function GetSortedItemsInColumns(mediaItems)

  local itemEnd = 0.0
  
  local columnNum = 1
  
  local loopItemCount = 1
  
  local columnItemNum = 1
  
  local newColumn = false
    
  local media_ItemColumns = {}
    
  numColumns = 0
  
  --Handles dynamic table creation
  while loopItemCount <= selItemCount do
    
    newColumn = false
    
    if numColumns > 0 then
    
    
    
    end
    
    --Creates nested table containing items in the same column
    while newColumn == false and loopItemCount <= selItemCount do
    
      local mediaItem = mediaItems[loopItemCount]
                
      if loopItemCount == 1 then
      
        media_ItemColumns[columnNum] = {}
      
        media_ItemColumns[columnNum][columnItemNum] = mediaItem
        
        itemEnd = mediaItem[3]
        
        columnStart = mediaItem[2] --Store the first column's start value
        columnEnd = itemEnd
        
        --GetName(mediaItem[1], "First Item: ")
              
      else
      
        local itemStart = mediaItem[2]
                        
        if itemStart < itemEnd then
                
          media_ItemColumns[columnNum][columnItemNum] = mediaItem
          
          if mediaItem[3] > itemEnd then
                       
            itemEnd = mediaItem[3]
                                  
          end
        
          --GetName(mediaItem[1], "Column Item: ")
                    
        else
                    
          columnStart = mediaItem[2]
          
          itemEnd = mediaItem[3]
                    
          columnItemNum = 1
          
          columnNum = columnNum + 1
          
          media_ItemColumns[columnNum] = {}
                    
          newColumn = true
          
          media_ItemColumns[columnNum][columnItemNum] = mediaItem
          
          --GetName(mediaItem[1], "New Column: ")
          
        end
      
      end
                  
      columnItemNum = columnItemNum + 1
      
      loopItemCount = loopItemCount + 1
          
    end    
        
    numColumns = numColumns + 1
        
  end
  
  return media_ItemColumns
    
end

function GroupItemsInColumns()

  for i, column in ipairs(mediaItemColumns) do
  
    reaper.Main_OnCommand(40289, 0)
  
    for j, item in ipairs(column) do
                
        reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
        
    end
    
    reaper.Main_OnCommand(40032, 0)
  
  end

end

function RestoreOriginalItemSelection()

  for i, item in ipairs(selectedMediaItems) do
  
    reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
  
  end

end

function GetUserInput()
  
  retval, userTail = reaper.GetUserInputs("Update Item as Region", 1, "(Optional) Region Tail (ms): ", 000)
  
  return retval, userTail / 1000

end

function GetColumnUpdateValues(columns)

  local newStartTime = 0
  
  local newEndTime = 0
  
  local init = false
    
  for i, column in ipairs(mediaItemColumns) do
  
    for j, item in ipairs(column) do
    
      if reaper.GetMediaItemNumTakes(item[1]) == 0 then
      
        regionItem = item[1]
         
      else
      
        if init == false then
               
          newStartTime = item[2]
          
          newEndTime = item[3]
          
          init = true
        
        else
        
          if item[2] < newStartTime then
          
            newStartTime = item[2]
            
          end
          
          if item[3] > newEndTime then
          
            newEndTime = item[3]
            
          end
        
        end
                 
      end
    
    end
    
    reaper.SetMediaItemInfo_Value(regionItem, "D_POSITION", newStartTime)
    reaper.SetMediaItemInfo_Value(regionItem, "D_LENGTH", newEndTime - newStartTime + tail)
    
    init = false
    newStartTime = 0
    newEndTime = 0
  
  end

end


function Main()

  reaper.Undo_BeginBlock()
  
  if reaper.CountSelectedMediaItems() > 0 then
  
    scriptRun, tail = GetUserInput()
  
    if scriptRun then
  
      reaper.PreventUIRefresh(1)    
          
      
      reaper.Main_OnCommand( 40034, 0)
      
      Initialize()
      
      selectedMediaItems = GetSelectedItemsInOrder()
      
      mediaItemColumns = GetSortedItemsInColumns(selectedMediaItems)
      
      columnUpdateInfo = GetColumnUpdateValues()
      
      GroupItemsInColumns()
              
      reaper.UpdateArrange()
    
    else
     
      reaper.Undo_EndBlock("Exited", 16)
      
    end
    
  else
  
    reaper.ReaScriptError("Error: No items selected.")
    
    reaper.Undo_EndBlock("Group Contiguous Items in Columns Error", 8)
    
  end
end

Main()

reaper.Undo_EndBlock("Update Item As Region", 0)

