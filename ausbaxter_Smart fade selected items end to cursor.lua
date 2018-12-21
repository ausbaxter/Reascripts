--Smart Fade Out, Will not operate on non selected items.

haveSelItems = reaper.CountSelectedMediaItems() > 0

if haveSelItems then
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(40510, 0)
  reaper.Undo_EndBlock("Smart Fade Out", 0)
else
  return
end  
