--[[
 * ReaScript Name: Render Item Columns Stereo
 * Description: Sequentually renders a selection of items based on item columns. Populates to a new track.
 * Instructions: Select desired items to render, run script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Render Item Columns Stereo.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.1
--]]
 
--[[
 * Changelog:
 * v1.1 (2018-01-01)
 * v1.0 (2017-11-06)
  + Initial Release
--]]

-------------------Debug--------------------------------
--[[function Print(m)

  reaper.ShowConsoleMsg(tostring(m) .. "\n")
  
end

function GetName(mediaItem, msg)

  local take = reaper.GetTake(mediaItem[1], 0)
  
  local name = reaper.GetTakeName(take)
  
  Print(msg .. name)
  
end]]------------------------------------------------------

-------------------Render Function--------------------------------
local cmd_id = 41719
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
  mediaItemTracks = {} --for storing the tracks containing selected mediaItems
  mediaItemColumns = {} --columns are stored as nested arrays
  selItemCount = reaper.CountSelectedMediaItems()
  timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
end

function InsertTrackIntoTable(track)

  local trackFound = false
  for i, track in ipairs(mediaItemTracks) do   --check if trying to add repeated track
 
    if itemTrack == track[1] then
    
      trackFound = true
      break
      
    end

  end
  if trackFound == false then
  
    local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
     table.insert(mediaItemTracks, {track, trackIndex})
     
  end

end

function GetSelectedItemsinColumns()

  for i = 0, selItemCount - 1 do
  
    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    local itemStart, itemEnd = GetMediaItemPosition(mediaItem)
    table.insert(selectedMediaItems, {mediaItem, itemStart, itemEnd}) --insert { mediaitem data | start | end } into table
    
    local itemTrack = reaper.GetMediaItem_Track(mediaItem)
    if reaper.GetMediaTrackInfo_Value(itemTrack, "B_MAINSEND") == 0 then return false end
    InsertTrackIntoTable(itemTrack)
    
  end
  
  
  table.sort(selectedMediaItems, function(a,b) return a[2] < b[2] end) --Sort table into chronological order
  SortItemsIntoColumns(selectedMediaItems) --Sort table into columns
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
    MuteColumns(1, i) --set other columns to muted
    local columnStart, columnEnd = GetLoopTimeSelection(mediaItemColumns, i)
    reaper.GetSet_LoopTimeRange(true, false, columnStart, columnEnd + offset, true)
    reaper.Main_OnCommand(cmd_id, 0) --render to mono 
    reaper.SetOnlyTrackSelected(mediaItemTracks[1][1])  
    reaper.SetMediaTrackInfo_Value(mediaItemTracks[1][1], "B_MUTE", 0)
    MuteColumns(0, i) --restore other columns to unmuted.
  end 
  
end

function CreateParentTrack()

  local trackIndex = 0
  for i, track in ipairs(mediaItemTracks) do --finding beginning track number 
    tempIndex = reaper.GetMediaTrackInfo_Value(track[1], "IP_TRACKNUMBER")
    if trackIndex == 0 then
      trackIndex = tempIndex
    else
      if  tempIndex < trackIndex then
        trackIndex = tempIndex
      end
    end
  end
  
  reaper.InsertTrackAtIndex(trackIndex - 1, false)
  track = reaper.GetTrack(0, trackIndex - 1)
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Column Render", true)
  reaper.TrackList_AdjustWindows(false)
  table.insert(mediaItemTracks, {track, trackIndex - 1})
  table.sort(mediaItemTracks, function(a,b) return a[2]<b[2]end)
  
end

function CreateFolderHierarchy()

  lastTrack = nil
  
  for i, trackArray in ipairs(mediaItemTracks) do
    track = trackArray[1]
    if i == 1 then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)
      reaper.SetOnlyTrackSelected(track)  
    end
    lastTrack = track
  end
  
  reaper.SetMediaTrackInfo_Value(lastTrack, "I_FOLDERDEPTH", -1)
  
end

function MoveRenderedItemsToTrack()

  index = reaper.GetMediaTrackInfo_Value(mediaItemTracks[1][1], "IP_TRACKNUMBER")
  
  for i = 1, columnNum do --move items to one track
    local track = reaper.GetTrack(0, index - 1 - i), 1
    local item = reaper.GetTrackMediaItem(track, 0)
    reaper.MoveMediaItemToTrack(item, mediaItemTracks[1][1])
    reaper.DeleteTrack(track)  
  end
  
  for i = 0, columnNum - 1 do --select tracks and edit item end.
    local renderItem = reaper.GetTrackMediaItem(mediaItemTracks[1][1], i)
    reaper.SetMediaItemSelected(renderItem, 1)
  end
  
end

function CleanUp()

  reaper.SetMediaTrackInfo_Value(mediaItemTracks[1][1], "I_FOLDERDEPTH", 0)
  reaper.SetMediaTrackInfo_Value(lastTrack, "I_FOLDERDEPTH", 0)
  reaper.GetSet_LoopTimeRange(true, true, timeSelStart, timeSelEnd, true)
  
  for i, item in ipairs(selectedMediaItems) do --mute source items
    reaper.SetMediaItemInfo_Value(item[1], "B_MUTE", 1)
    reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 0)
  end
  
end

function Main()

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  if reaper.CountSelectedMediaItems() > 0 then
    Initialize()
    if GetSelectedItemsinColumns() then  
      if GetInput() then
      CreateParentTrack()
      CreateFolderHierarchy()
      LoopColumns(mediaItemColumns)
      MoveRenderedItemsToTrack()
      CleanUp()
      reaper.UpdateArrange()
      reaper.Undo_EndBlock("Render Item Columns", 0)
      end
    else 
      reaper.ReaScriptError("One or more tracks of selected items do not have their Master/Parent Send activated. Items on that track will not be rendered.")
    end
  else
    reaper.ReaScriptError("Error: No items selected.")
    reaper.Undo_EndBlock("Render Item Columns Error", 8)
  end
  
end

Main()

