function GetTrackkItemHeadTail(track, idx)
    local item = reaper.GetTrackMediaItem(track, idx)
    local head = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local tail = head + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    return head, tail
end

function main()

    reaper.Undo_BeginBlock()
    
    reaper.PreventUIRefresh(1)

    local min = nil
    local max = nil
    local init = true

    local track_count = reaper.CountSelectedTracks(0)

    if track_count == 0 then return end

    for i = 0, track_count - 1 do
        
        local track = reaper.GetSelectedTrack(0, i)
        
        
        local fi_start,_ = GetTrackkItemHeadTail(track, 0)
        local _,li_end = GetTrackkItemHeadTail(track, reaper.CountTrackMediaItems(track) - 1)

        if init then
            min = fi_start
            max = li_end
        else
            if fi_start < min then min = fi_start end
            if li_end > max then max = li_end end
        end
        
        init = false

    end

    reaper.BR_SetArrangeView(0, min, max)

    reaper.Undo_EndBlock("Zoom out to items on selected track", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

end

main()