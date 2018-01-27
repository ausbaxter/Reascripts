--Functions as a Parameter Load for Nudge Values without performing said nudge. Can save nudge settings and recall in future.

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(41280, 0)

reaper.Main_OnCommand(41276, 0)

reaper.Undo_EndBlock("Set Nudge Settings to 2", 8)
