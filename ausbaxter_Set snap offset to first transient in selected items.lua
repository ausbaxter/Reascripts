item_tbl = {}
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
  table.insert(item_tbl, reaper.GetSelectedMediaItem(0,i))
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

cursor_origin = reaper.GetCursorPosition()

for i, item in ipairs(item_tbl) do
  local cur_pos = reaper.GetCursorPosition()
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local offset = item_pos - cur_pos
  reaper.MoveEditCursor(offset, false)
  reaper.Main_OnCommand(40375,0)
  reaper.Main_OnCommand(40541,0)
end

last_position = reaper.GetCursorPosition()
reaper.MoveEditCursor(cursor_origin - last_position, false)

reaper.UpdateArrange()
reaper.Undo_EndBlock("Set snap offset to first transient in items", -1)
