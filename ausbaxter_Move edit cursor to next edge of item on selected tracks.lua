function main()
    local cursor = reaper.GetCursorPosition()
    local no_edge = 100000
    local next_edge = no_edge
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for j = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if i_end > cursor and i_pos <= cursor + 1 and i_end < next_edge then
                next_edge = i_end
                reaper.ShowConsoleMsg("move to end\n")
            elseif i_pos > cursor and i_pos < next_edge then
                next_edge = i_pos
                reaper.ShowConsoleMsg("move to start\n")
            end
        end
    end
    if next_edge == no_edge then 
        reaper.ShowConsoleMsg("no edge\n")
        return
    else
        reaper.ShowConsoleMsg(reaper.parse_timestr_pos(tostring(next_edge-cursor), 0, 3), 0)
        reaper.MoveEditCursor(reaper.parse_timestr_pos(tostring(next_edge-cursor), 0, 4), 0)
    end
end

main()