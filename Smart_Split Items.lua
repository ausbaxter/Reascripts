function Print(value)
  reaper.ShowConsoleMsg(value)
end

selectedItems = reaper.CountSelectedMediaItems(0)

reaper.Undo_BeginBlock()

if selectedItems > 0 then

  tSStart, tSEnd = 
  reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
  if (tSEnd - tSStart) ~= 0 then -- No TS
    reaper.Main_OnCommand(40061, 0)
  else
    reaper.Main_OnCommand(40757, 0)
  end

  reaper.Undo_EndBlock("Split selected items at time selection", 0)
  
else
  reaper.Undo_EndBlock("", 1)
end
