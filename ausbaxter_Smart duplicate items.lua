function Print(value)
  reaper.ShowConsoleMsg(value)
end

selectedItems = reaper.CountSelectedMediaItems()
reaper.Undo_BeginBlock()

if selectedItems > 0 then

  tSStart, tSEnd = 
  reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
  if (tSEnd - tSStart) == 0 then -- No TS
    reaper.Main_OnCommand(41295, 0)
  else -- Yes TS
    reaper.Main_OnCommand(41296, 0)
  end
  
  reaper.Undo_EndBlock("Smart Duplicate", 0)
  
else
  reaper.Undo_EndBlock("", 1)
end
