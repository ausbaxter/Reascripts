--Smart Fade In, Will not operate on non selected items.

haveSelItems = reaper.CountSelectedMediaItems() > 0

if haveSelItems then
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(40509, 0)
  reaper.Undo_EndBlock("Smart Fade In", 0)
else
  return
end  
