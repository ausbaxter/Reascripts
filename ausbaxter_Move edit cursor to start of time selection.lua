--@description Mouse contextual unselect [envelope, item, track, loop, time]
--@version 1.0
--@author ausbaxter
--@about
--    # Moves edit cursor to start of time selection, useful when unlinked.
--@changelog
--  + Initial release

t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, 0)
cursor_pos = reaper.GetCursorPosition()
reaper.MoveEditCursor(t_start - cursor_pos, false)