function Print(value)
  reaper.ShowConsoleMsg(value)
end

selectedItems = reaper.CountSelectedMediaItems()
reaper.Undo_BeginBlock()

if selectedItems > 0 then
  
  reaper.Main_OnCommand(40757, 0)
  
  reaper.Undo_EndBlock("Smart Split", 0)
  
else
  reaper.Undo_EndBlock("", 1)
end



