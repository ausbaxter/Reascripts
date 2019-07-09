track = reaper.GetSelectedTrack(0,0)
cursor_pos = reaper.GetCursorPosition()

i = 0
item = ""
while true do
    item = reaper.GetTrackMediaItem(track, i)
    if item == nil then return end
    i_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    i_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    i_end = i_start + i_length
    
    if prev_end == nil then prev_end = 0 end

    if i_start > cursor_pos and prev_end < cursor_pos then
        reaper.GetSet_LoopTimeRange(true, false, prev_end, i_start, false)
        reaper.MoveEditCursor(prev_end - cursor_pos, false)
        return
    end
    
    prev_end = i_end
    i = i + 1
end
