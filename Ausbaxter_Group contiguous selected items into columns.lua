--@description Group contiguous selected items into columns
--@version 1.0
--@author ausbaxter
--@about
--    # Group contiguous selected items into columns
--    Select a range of items. Run this script. Any selected item whose edges overlap others in time and across tracks will be grouped together.
--@changelog
--  + Initial release

function Initialize()

  selectedMediaItems = {} --for sorting media items in order
    
  mediaItemColumns = {} --columns are stored as nested arrays
  
  selItemCount = reaper.CountSelectedMediaItems()

end

function GetSelectedItemsinColumns()
  
  --insert media items, start pos and end pos into a table  
    
  for i = 0, selItemCount - 1 do
  
    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    
    local itemStart, itemEnd = GetMediaItemPosition(mediaItem)
    
    local itemTrack = reaper.GetMediaItem_Track(mediaItem)
    
    local trackFound = false
    
    table.insert(selectedMediaItems, {mediaItem, itemStart, itemEnd})
        
  end
  
  --Sort table into chronological order
  table.sort(selectedMediaItems, function(a,b) return a[2] < b[2] end)
  
  SortItemsIntoColumns(selectedMediaItems)
  
end

function GetMediaItemPosition(mediaItem)

  local itemStart = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  
  return itemStart, itemEnd
  
end

function SortItemsIntoColumns(mediaItems)

  local itemEnd = 0.0
  
  local columnNum = 1
  
  local loopItemCount = 1
  
  local columnItemNum = 1
  
  local newColumn = false
  
  numColumns = 0
  
  --Handles dynamic table creation
  while loopItemCount <= selItemCount do
    
    newColumn = false
    
    --Creates nested table containing items in the same column
    while newColumn == false and loopItemCount <= selItemCount do
    
      local mediaItem = mediaItems[loopItemCount]
                
      if loopItemCount == 1 then
      
        mediaItemColumns[columnNum] = {}
      
        mediaItemColumns[columnNum][columnItemNum] = mediaItem
        
        itemEnd = mediaItem[3]     
              
      else
      
        local itemStart = mediaItem[2]
                        
        if itemStart < itemEnd then
                
          mediaItemColumns[columnNum][columnItemNum] = mediaItem
          
          if mediaItem[3] > itemEnd then
                       
            itemEnd = mediaItem[3]
            
          end
                    
        else
          
          itemEnd = mediaItem[3]
                    
          columnItemNum = 1
          
          columnNum = columnNum + 1
          
          mediaItemColumns[columnNum] = {}
                    
          newColumn = true
          
          mediaItemColumns[columnNum][columnItemNum] = mediaItem
          
        end
      
      end
                  
      columnItemNum = columnItemNum + 1
      
      loopItemCount = loopItemCount + 1
    
    end    
    
    numColumns = numColumns + 1
    
  end
    
end

function GroupItemsInColumns()

  for i, column in ipairs(mediaItemColumns) do
  
    reaper.Main_OnCommand(40289, 0)
  
    for j, item in ipairs(column) do
                
        reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
        
    end
    
    reaper.Main_OnCommand(40032, 0)
    
    reaper.Main_OnCommand(40706, 0)
  
  end

end

function RestoreOriginalItemSelection()

  for i, item in ipairs(selectedMediaItems) do
  
    reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
  
  end

end

function Main()

  reaper.Undo_BeginBlock()
  
  if reaper.CountSelectedMediaItems() > 0 then
  
    reaper.PreventUIRefresh(1)
    
    Initialize()
    
    GetSelectedItemsinColumns()
    
    GroupItemsInColumns()
    
    RestoreOriginalItemSelection()
    
    reaper.UpdateArrange()
    
    reaper.Undo_EndBlock("Group Contiguous Items in Columns", 0)
    
  else
  
    reaper.ReaScriptError("Error: No items selected.")
    
    reaper.Undo_EndBlock("Group Contiguous Items in Columns Error", 8)
    
  end
end

Main()

