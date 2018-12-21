--@description Add equal spacing between selected items
--@version 1.0
--@author ausbaxter
--@about
--    # Adds a user defined spacing of silence in between each selected media item. Each track is ordered sequentially: track 1 items will precede track 2 items etc.
--@changelog
--  + Initial release

function GetSelectedItems()
  local count = reaper.CountSelectedMediaItems(0)
  local t = {}
  for i = 0, count - 1 do
    sel_item = reaper.GetSelectedMediaItem(0,i)
    table.insert(t, sel_item)
  end
  return count, t
end

function Main()
  
  s_items_count, selected_items = GetSelectedItems()
 
  if s_items_count >= 2 then
    
      user_offset = 0
      
      for i = 2, s_items_count do
      
        local item_pos = reaper.GetMediaItemInfo_Value(selected_items[i - 1], "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value(selected_items[i - 1], "D_LENGTH")
        local item_end = item_pos + item_len
        local offset = item_end + user_offset
        reaper.SetMediaItemInfo_Value(selected_items[i], "D_POSITION", offset)
      
      end 
  else
  
    reaper.ReaScriptError("Select 2 or more items.")
    
  end

end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Add equal spacing between selected items", -1)
