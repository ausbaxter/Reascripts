--[[
 * ReaScript Name: Insert automation items using selected item boundaries
 * Description: Inserts pooled automation items on selected envelope under selected items.
 * Instructions: Select items on track. Select an envelope on that track. Run this script. Create a node in any of the automation items.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Insert automation items using selected item boundaries.lua
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

function Print(msg)
  reaper.ShowConsoleMsg(tostring(msg) .. "\n")
end

num_selItems = reaper.CountSelectedMediaItems(0)
affectedTrack = reaper.GetLastTouchedTrack()
selMediaItems = {}
selEnvelope = reaper.GetSelectedTrackEnvelope(0)

function GetMediaItems()

  for i = 0, num_selItems - 1 do
  
    this_MediaItem = reaper.GetSelectedMediaItem(0, i)
    
    if reaper.GetMediaItemTrack(this_MediaItem) == affectedTrack then
    
      this_MediaItem_Start = reaper.GetMediaItemInfo_Value(this_MediaItem, "D_POSITION")
      this_MediaItem_Length = reaper.GetMediaItemInfo_Value(this_MediaItem, "D_LENGTH")
      
      table.insert(selMediaItems, {this_MediaItem, this_MediaItem_Start, this_MediaItem_Length})      
      
    end
  end
  
  table.sort(selMediaItems, function(a,b) return a[3] < b[3] end)
  
end

function CreateAutomationItems()
  
  for i, item in ipairs(selMediaItems) do
  
    if i == 1 then

      ref_length = item[3]
      
      auto_Item = reaper.InsertAutomationItem(selEnvelope, -1, item[2], item[3])
      
      pool_ID = reaper.GetSetAutomationItemInfo(selEnvelope, auto_Item, "D_POOL_ID", 0, false)
      
     reaper.DeleteEnvelopePointRangeEx(selEnvelope, auto_Item, item[2], item[2] + item[3])
     
      
    else
    
      local pbkRate = ref_length / item[3]
      
      auto_Item = reaper.InsertAutomationItem(selEnvelope, pool_ID, item[2], item[3]* pbkRate)      
      
      reaper.GetSetAutomationItemInfo(selEnvelope, auto_Item, "D_PLAYRATE", pbkRate, true)
      
      reaper.GetSetAutomationItemInfo(selEnvelope, auto_Item, "D_LENGTH", item[3], true)
      
      reaper.DeleteEnvelopePointRangeEx(selEnvelope, auto_Item, item[2], item[2] + item[3])
      
    end
    
    
  end
end

function Main()

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  if selEnvelope ~= nil then
  
    GetMediaItems()
    CreateAutomationItems()
    
    reaper.UpdateArrange()
    
    reaper.Undo_EndBlock("Insert Unpooled Automation Items Under Selected Items On Selected Envelope", -1)
  
  else
  
    reaper.ReaScriptError("Error: Please select an envelope to create automation items on")
  
  end
end

Main()
