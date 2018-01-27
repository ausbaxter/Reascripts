--Smart Fade Out, Will not operate on non selected items.

haveSelItems = reaper.CountSelectedMediaItems() > 0

reaper.Undo_BeginBlock()

if haveSelItems then
  reaper.Main_OnCommand(40510, 0)
  reaper.Undo_EndBlock("Smart Fade Out", 0)
else
  reaper.Undo_EndBlock("Test", 1)
  return
end  
