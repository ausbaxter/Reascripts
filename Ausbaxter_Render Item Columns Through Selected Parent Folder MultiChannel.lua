--[[
 * ReaScript Name: Render Item Columns Through Selected Parent Folder Multichannel
 * Description: Sequentually renders a selection of items based on item columns. Populates to a new track.
 * Instructions: Select desired items to render, select folder to render through, make sure the folder is a parent of selected items, run script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Render Item Columns Through Selected Parent Folder Multichannel.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.1 (2018-01-01)
 * v1.0 (2017-11-06)
  + Initial Release
--]]

--[[-----------------Debug--------------------------------
function Print(m)

  reaper.ShowConsoleMsg(tostring(m) .. "\n")
  
end
]]------------------------------------------------------

-------------------Render Function--------------------------------
local cmd_id = 41720
------------------------------------------------------------------

function GetInput()

  retval, offset = reaper.GetUserInputs("Render Item Columns Mono", 1, "Tail Length (secs):", "")
  if (offset == "") then
    offset = 0
  end
  if string.find(offset, "%d+") == nil then reaper.ReaScriptError("Must enter in a number.") end
  return retval
  
end

function Initialize()

  selectedMediaItems = {} --for sorting media items in order   
  mediaItemColumns = {} --columns are stored as nested arrays
  selItemTracks = {}
  selItemCount = reaper.CountSelectedMediaItems() 
  renderTrack = nil 
  timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

end

function GetSelectedItemsinColumns()
  
  --insert media items, start pos and end pos into a table     
  for i = 0, selItemCount - 1 do
    local mediaItem = reaper.GetSelectedMediaItem(0, i) 
    local itemStart, itemEnd = GetMediaItemPosition(mediaItem)    
    local itemTrack = reaper.GetMediaItem_Track(mediaItem)   
    local trackFound = false   
    local trackIsChild = reaper.MediaItemDescendsFromTrack(mediaItem, renderTrack)
        
    if trackIsChild < 2 then      
      return false
    end
    
    table.insert(selectedMediaItems, {mediaItem, itemStart, itemEnd}) 
    table.insert(selItemTracks, itemTrack)     
  end
  
  --Sort table into chronological order
  table.sort(selectedMediaItems, function(a,b) return a[2] < b[2] end)
  SortItemsIntoColumns(selectedMediaItems) 
  return true 
end

function GetMediaItemPosition(mediaItem)

  local itemStart = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  return itemStart, itemEnd
  
end

function SortItemsIntoColumns(mediaItems)

  columnNum = 1

  local itemEnd = 0.0 
  local loopItemCount = 1 
  local columnItemNum = 1  
  local newColumn = false 
  
  --Handles dynamic table creation
  while loopItemCount <= selItemCount do 
    newColumn = false
    
    --Creates nested table containing items in the same column
    while newColumn == false and loopItemCount <= selItemCount do
      local mediaItem = mediaItems[loopItemCount]
                
      if loopItemCount == 1 then
        mediaItemColumns[columnNum] = {} --initialize first column      
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
          mediaItemColumns[columnNum] = {} --intialized new column                  
          newColumn = true        
          mediaItemColumns[columnNum][columnItemNum] = mediaItem        
        end  
      end                  
      columnItemNum = columnItemNum + 1      
      loopItemCount = loopItemCount + 1  
    end       
  end
    
end

function GetLoopTimeSelection(mediaItemColumn, column)

  local columnStart = 0.0
  local columnEnd = 0.0
            
  for j, item in ipairs(mediaItemColumn[column]) do
    if columnStart == 0.0 then         
      columnStart = item[2]   
      columnEnd = item[3]
    
    else
      if item[3] > columnEnd then   
        columnEnd = item[3]  
      end 
    end          
  end   
     return columnStart, columnEnd
            
end

function MuteColumns(mutestate, i)

  for j, m_column in ipairs(mediaItemColumns) do
    if j ~= i then 
      for k, item in ipairs(m_column) do
        reaper.SetMediaItemInfo_Value(item[1], "B_MUTE", mutestate)
      end
    end
  end
  
end

function LoopColumns(mediaItemColumns)
  for i, column in ipairs(mediaItemColumns) do
    --set other columns to muted
    MuteColumns(1, i)
  
    columnStart, columnEnd = GetLoopTimeSelection(mediaItemColumns, i)
    reaper.GetSet_LoopTimeRange(true, false, columnStart, columnEnd + offset, true) 
    reaper.Main_OnCommand(41721, 0) --render to mono 
    reaper.SetOnlyTrackSelected(renderTrack) 
    reaper.SetMediaTrackInfo_Value(renderTrack, "B_MUTE", 0)
    
    --restore other columns to unmuted.    
    MuteColumns(0, i)          
  end

end

function SetTrackWithSelItemsSolo(solo_State)

  for i in ipairs(selItemTracks) do
    reaper.SetMediaTrackInfo_Value(selItemTracks[i], "I_SOLO", solo_State)
  end

end

function GetSelectedParentTrack()

  local track = reaper.GetSelectedTrack(0,0)
  local trackFolderStatus = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
  if trackFolderStatus == 1.0 then
      renderTrack = track  
      retval, renderTrackName = reaper.GetSetMediaTrackInfo_String(renderTrack, "P_NAME", "", false)                 
  end
  
end

function MoveRenderedItemsToTrack()
  
  index = reaper.GetMediaTrackInfo_Value(renderTrack, "IP_TRACKNUMBER")
  destTrack = reaper.GetTrack(0, index - 2)
  
  for i = 1, columnNum do
    local track = reaper.GetTrack(0, index - 1 - i), 1
    local item = reaper.GetTrackMediaItem(track, 0)
    reaper.MoveMediaItemToTrack(item, destTrack)
    if i ~= 1 then 
    reaper.DeleteTrack(track) 
    end    
  end
  
  for i = 0, columnNum - 1 do
    local renderItem = reaper.GetTrackMediaItem(destTrack, i)
    reaper.SetMediaItemSelected(renderItem, 1)
  end
  
end

function CleanUp()
  
  reaper.GetSet_LoopTimeRange(true, true, timeSelStart, timeSelEnd, true)
  newTrackName = renderTrackName .. " - Column Render"
  reaper.GetSetMediaTrackInfo_String(destTrack, "P_NAME",newTrackName, true)
  for i, item in ipairs(selectedMediaItems) do
  
    reaper.SetMediaItemInfo_Value(item[1], "B_MUTE", 1)
    reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 0)
  
  end

end

function ThrowError(errorMsg)

  reaper.ReaScriptError(errorMsg)  
  reaper.Undo_EndBlock("", 8)

end

function Main()

  reaper.Undo_BeginBlock()
  
  if reaper.CountSelectedMediaItems() > 0 and reaper.CountSelectedTracks() == 1 then
  
    Initialize()
    GetSelectedParentTrack()
    if renderTrack ~= nil then
    
      if GetSelectedItemsinColumns() then
      
        if GetInput() then
      
          reaper.PreventUIRefresh(1)
          SetTrackWithSelItemsSolo(1)
          LoopColumns(mediaItemColumns)
          MoveRenderedItemsToTrack()
          SetTrackWithSelItemsSolo(0)
          CleanUp()
          reaper.UpdateArrange()
          reaper.Undo_EndBlock("Render Item Columns", 0)
        else end
        
      else
        ThrowError("Error: Not all selected items are children of your selected folder.") 
      end
    
    else
    
      ThrowError("Error: Please Select a parent folder track to render.")     
    end
  else
  
    ThrowError("Error: Be sure you have items selected, and one folder track to render your item columns through")  
  end
end

Main()

