--[[
 * ReaScript Name: Tab to transient or clip edge left (no undo)
 * Description: Tabs to clip edges and transients without creating bloated undo's
 * Instructions: Assign the Opt/Alt Tab and profit
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Tab to transient or clip edge left (no undo).lua
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

function SelectAll()

  for i = 0, c_SelTracks - 1 do
    a_SelTracks[i] = reaper.GetSelectedTrack(0, i)
    
    for j = 0, reaper.CountTrackMediaItems(a_SelTracks[i]) - 1  do
      thisItem = reaper.GetTrackMediaItem(a_SelTracks[i], j)
      reaper.SetMediaItemSelected(thisItem, true)
    end
    
  end
  
end

function SelectItemsUnderEditCursor()

  cursorpos = reaper.GetCursorPosition()
  
  for i = 0, c_SelTracks - 1 do
    a_SelTracks[i] = reaper.GetSelectedTrack(0, i)
    
    for j = 0, reaper.CountTrackMediaItems(a_SelTracks[i]) - 1  do
      thisItem = reaper.GetTrackMediaItem(a_SelTracks[i], j)
      thisItem_S = reaper.GetMediaItemInfo_Value(thisItem, "D_POSITION")
      thisItem_E = thisItem_S + reaper.GetMediaItemInfo_Value(thisItem, "D_LENGTH")  
      
      if thisItem_S >= cursorpos + .0001 or thisItem_E <= cursorpos - .0001 then
        reaper.SetMediaItemSelected(thisItem, false)          
      end
      
    end
    
  end
  
end

function Main()

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  reaper.Main_OnCommand(40289, 0)
  c_SelTracks = reaper.CountSelectedTracks(0)
  a_SelTracks = {}
  SelectAll()
  reaper.Main_OnCommand(40376, 0)
  SelectItemsUnderEditCursor()
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("", 1)
 
end


Main()





