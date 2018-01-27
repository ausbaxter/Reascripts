--Smart Fade In, Will not operate on non selected items.

reaper.Undo_BeginBlock()

haveSelItems = reaper.CountSelectedMediaItems() > 0

if haveSelItems then
  reaper.Main_OnCommand(40509, 0)
  reaper.Undo_EndBlock("Smart Fade In", 0)
else
  reaper.Undo_EndBlock("Test", 1)
  return
end  
