-- TODO duplicate envelope points if no item selected (smart copy has implementation for looking up envelope points)

selectedItems = reaper.CountSelectedMediaItems()
disableTrimBehind = 41121
enableTrimBehind = 41120

reaper.Undo_BeginBlock()

if selectedItems > 0 then

  reaper.Main_OnCommand(enableTrimBehind, 0)

  tSStart, tSEnd = 
  reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
  if (tSEnd - tSStart) == 0 then -- No TS
    reaper.Main_OnCommand(41295, 0)
  else -- Yes TS
    reaper.Main_OnCommand(41296, 0)
  end
  
  reaper.Main_OnCommand(disableTrimBehind, 0)

  reaper.Undo_EndBlock("Smart Duplicate", 0)
  
else

  reaper.Undo_EndBlock("", 1)

end