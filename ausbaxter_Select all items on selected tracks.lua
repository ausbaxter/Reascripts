function UnselectItems()
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local item_count = reaper.CountTrackMediaItems(track)
        for j = 0, item_count - 1 do 
            local item = reaper.GetTrackMediaItem(track, j)
            reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
        end
    end
end

function main()
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    UnselectItems()
    local track_count = reaper.CountSelectedTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        for j = 0, reaper.CountTrackMediaItems(track) - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
        end
    end
    reaper.SetCursorContext(1, "NULL")
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Select all items on track", -1)
end

main()