-----------------Default Length Value (Optional overrides using current item length as default field entry)-----------------
default_length = 0
-----------------------------------------------------------------

function main()

    sel_item = reaper.BR_ItemAtMouseCursor()

    --get rounded current length for dialog box default value
    local current_length = default_length > 0 and default_length or reaper.GetMediaItemInfo_Value(sel_item,"D_LENGTH")

    local rval, new_length = reaper.GetUserInputs("Set Selected Item Length Ripple Editing Later Items",1,"Item Length (sec):",string.format("%.3f",current_length))
    new_length = tonumber(new_length)--convert to number type

    if not rval then return end --exit if user cancels
    if new_length <= 0 then reaper.ReaScriptError("Lengths of 0 and below are invalid.") return end --no negative (or zero) lengths

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    local item_index = reaper.GetMediaItemInfo_Value(sel_item, "IP_ITEMNUMBER")
    local track = reaper.GetMediaItemTrack(sel_item)
    local track_items_offset = new_length - current_length

    if track_items_offset > 0 then
        --adjust item positions
        for i = reaper.CountTrackMediaItems(track) - 1, item_index + 1, -1 do
            local tk_item = reaper.GetTrackMediaItem(track, i)
            local current_position = reaper.GetMediaItemInfo_Value(tk_item,"D_POSITION")
            reaper.SetMediaItemInfo_Value(tk_item,"D_POSITION",current_position + track_items_offset)
        end
    else
        for i = item_index + 1, reaper.CountTrackMediaItems(track) - 1 do
            local tk_item = reaper.GetTrackMediaItem(track, i)
            local current_position = reaper.GetMediaItemInfo_Value(tk_item,"D_POSITION")
            reaper.SetMediaItemInfo_Value(tk_item,"D_POSITION",current_position + track_items_offset)
        end
    end
    reaper.SetMediaItemInfo_Value(sel_item,"D_LENGTH",new_length)

    reaper.Undo_EndBlock("Set selected item length rippling later items",-1)

end

main()
