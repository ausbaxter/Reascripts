t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, 0)
cursor_pos = reaper.GetCursorPosition()
reaper.MoveEditCursor(t_start - cursor_pos, false)
