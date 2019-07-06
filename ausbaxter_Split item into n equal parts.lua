--@description Divide item(s) into n equal parts
--@version 1.0
--@author ausbaxter
--@about
--    # Divide item(s) into n equal parts
--@changelog
--  + Initial release

function SplitItem(div, item)
  
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local offset = item_length / div
  
  for i = 1, div - 1 do
  
    item_pos = item_pos + offset   
    item = reaper.SplitMediaItem(item, item_pos)
  
  end
  
end

function Main()

  local cursor_pos = reaper.GetCursorPosition()
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 0 then
    reaper.ReaScriptError("Must select one item to divide.")
    return
  end
  
  local retval, input = reaper.GetUserInputs("Divide item into n equal parts", 1, "n: ", "")
  
  if retval == true then
  
    local num = tonumber(input)
    local sel_items = {}

    for i = 0, item_count - 1 do
      table.insert(sel_items, reaper.GetSelectedMediaItem(0, i))
    end

    if num ~= nil then
      for i, item in ipairs(sel_items) do
        SplitItem(num, item)
      end
    else
      reaper.ReaScriptError("Must enter a number.")
    end
    
  end
  
end

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Divide Items", -1)
