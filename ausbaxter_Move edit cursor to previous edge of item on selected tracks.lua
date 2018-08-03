function main()
    local cursor = reaper.GetCursorPosition()
    local no_edge = -1
    local previous_edge = no_edge
    reaper.ShowConsoleMsg("\n\n")
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for j = reaper.CountTrackMediaItems(track) - 1, 0, -1 do
            local item = reaper.GetTrackMediaItem(track, j)
            local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            reaper.ShowConsoleMsg("cursor: " .. cursor .. "\t i_pos: " .. i_pos .. "\ti_end: " .. i_end .. "\n")

            if i_pos < cursor and i_pos > previous_edge then
                previous_edge = i_pos
                if i_end < cursor then
                    previous_edge = i_end
                end
            end

            -- if i_end < cursor and i_end > previous_edge then
            --     previous_edge = i_end
            --     reaper.ShowConsoleMsg("move to end edge\n")
            -- elseif i_end >= cursor and i_pos < cursor - 0.005 and i_pos > previous_edge then
            --     previous_edge = i_pos
            --     reaper.ShowConsoleMsg("move to start edge\n")
            -- end
        end
    end
    if previous_edge == no_edge then 
        reaper.ShowConsoleMsg("no edge\n")
        return
    else
        reaper.ShowConsoleMsg("Edge: " .. cursor + previous_edge - cursor .. "\n")
        reaper.ApplyNudge(0, 1, 6, 1, cursor + previous_edge - cursor, 0, 0)
    end
end

main()