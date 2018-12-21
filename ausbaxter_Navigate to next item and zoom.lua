function GetItemAfterCursor(cursor_location, track)

    local item_count = reaper.CountTrackMediaItems(track)
    
    for i = 0, item_count - 1 do

        local item = reaper.GetTrackMediaItem(track, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

        if item_start > cursor_location then return item end

    end

end

function DeselectAllItems()

    local item_count = reaper.CountSelectedMediaItems(0)

    for i = 0, item_count - 1 do
    
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
    
    end

end

function ZoomToItem(item, move_cursor)
    
    reaper.PreventUIRefresh(1)

    local max_height = 40113

    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    if move_cursor then reaper.SetEditCurPos(item_start, false, false) end
    reaper.BR_SetArrangeView(0, item_start, item_end)

    local max_height_state = reaper.GetToggleCommandState(max_height)
    if max_height_state == 0 then
        reaper.Main_OnCommand(max_height, 0)
    end

    --reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_VZOOMIITEMS"), 0)
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

function main()
    
    reaper.Undo_BeginBlock()

    local item_count = reaper.CountSelectedMediaItems(0)
    local item = reaper.GetSelectedMediaItem(0, item_count - 1)


    local track = reaper.GetSelectedTrack(0, 0)
    local cursor_location = reaper.GetCursorPosition()

    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 624)
    reaper.TrackList_AdjustWindows(false)

    local next_item = GetItemAfterCursor(cursor_location, track)
    
    if next_item then

        DeselectAllItems()
        reaper.SetMediaItemInfo_Value(next_item, "B_UISEL", 1)
        ZoomToItem(next_item, true)
    
    end

    reaper.Undo_EndBlock("Navigate to next item and zoom", 1)

end

main()