UNSELECT_ITEMS = 40289

function main()
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    reaper.Main_OnCommand(UNSELECT_ITEMS, 0)

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