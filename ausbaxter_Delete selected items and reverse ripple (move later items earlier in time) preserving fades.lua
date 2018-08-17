function msg(m)
    reaper.ShowConsoleMsg(tostring(m))
end

ripple_all_tracks_check = reaper.GetToggleCommandState(40311) --ripple all tracks check
ripple_one_track_check = reaper.GetToggleCommandState(40310) --ripple all tracks check
ripple_one_track = 40310
ripple_all_tracks = 40311
ripple_off = 40309

function RestoreRippleState()
    local cmd_id
    if ripple_all_tracks_check == 1 then cmd_id = ripple_all_tracks
    elseif ripple_one_track_check == 1 then cmd_id = ripple_one_track
    elseif ripple_all_tracks_check == 0 and ripple_one_track_check == 0 then cmd_id = ripple_off end
    
    reaper.Main_OnCommand(cmd_id, 0)
end

function GetMediaItemIndexes()
    local t_full = {}
    local t_track = {}
    local t_temp = {}
    local prev_item_idx
    local curr_item_idx
    local curr_track
    local prev_track

    item_count = reaper.CountSelectedMediaItems(0)

    for i = 0, item_count - 1 do
        local curr_item = reaper.GetSelectedMediaItem(0,i)
        curr_track = reaper.GetMediaItem_Track(curr_item)
        curr_item_idx = reaper.GetMediaItemInfo_Value(curr_item,"IP_ITEMNUMBER")

        if i == 0 then t_temp["first"] = curr_item_idx end --set first item index

        if prev_track ~= nil and curr_track ~= prev_track then

            t_temp["last"] = prev_item_idx
            table.insert(t_track,t_temp)
            table.insert(t_full,{track = prev_track, itemtable = t_track})

            t_temp = {}
            t_track = {}
            t_temp["first"] = curr_item_idx

        elseif prev_item_idx ~= nil and curr_item_idx ~= prev_item_idx + 1.0  then

            t_temp["last"] = prev_item_idx
            table.insert(t_track, t_temp)

            t_temp = {}
            t_temp["first"] = curr_item_idx

        end

        prev_item_idx = curr_item_idx
        prev_track = curr_track

        if i == item_count - 1 then
            t_temp["last"] = curr_item_idx
            table.insert(t_track,t_temp)
            table.insert(t_full,{track = prev_track, itemtable = t_track})
        end

    end

    return t_full
end

function count(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

function GetFadeLength(item, info_val_string)

    auto_string = info_val_string:gsub("LEN", "LEN_AUTO")
    local fade_in = reaper.GetMediaItemInfo_Value(item, auto_string)
    if fade_in > 0 then reaper.ShowConsoleMsg(fade_in.."\n") return fade_in
    else return reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN") end

end

function main()
    
    --[[TODO
        Need to handle when item after selected item is not connected, currently it snaps to the previous item (should be space in between)
        Should take the fade in and out shape of one of the deleted items edges.
    ]]

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    reaper.Main_OnCommand(ripple_off,0)
    f_item = reaper.GetSelectedMediaItem(0, 0)
    track = reaper.GetMediaItemTrack(f_item)
    f_item_pos = reaper.GetMediaItemInfo_Value(f_item, "D_POSITION")
    f_item_idx = reaper.GetMediaItemInfo_Value(f_item, "IP_ITEMNUMBER")
    f_item_fadein = GetFadeLength(f_item, "D_FADEINLEN")--reaper.GetMediaItemInfo_Value(f_item, "D_FADEINLEN")
    f_item_fadeout = GetFadeLength(f_item, "D_FADEOUTLEN")--reaper.GetMediaItemInfo_Value(f_item, "D_FADEOUTLEN")
    l_item = reaper.GetSelectedMediaItem(0, reaper.CountSelectedMediaItems(0)-1)
    l_item_pos = reaper.GetMediaItemInfo_Value(l_item, "D_POSITION")
    l_item_end = l_item_pos + reaper.GetMediaItemInfo_Value(l_item, "D_LENGTH")
    l_item_idx = reaper.GetMediaItemInfo_Value(l_item, "IP_ITEMNUMBER")

    n_item = reaper.GetTrackMediaItem(track,l_item_idx+1)
    n_item_pos = reaper.GetMediaItemInfo_Value(n_item, "D_POSITION")
    p_item = reaper.GetTrackMediaItem(track,f_item_idx-1)
    p_item_end = p_item ~= nil and reaper.GetMediaItemInfo_Value(p_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(p_item, "D_LENGTH") or 0

    if n_item == nil or f_item_pos > p_item_end or p_item == nil or n_item_pos > l_item_end then --only need to ripple if no overlapping items, first item, or last item
        reaper.Main_OnCommand(ripple_one_track,0)
        reaper.Main_OnCommand(40006,0)--remove items
        reaper.ShowConsoleMsg("only need to ripple\n")
    else

        n_item_fadein = GetFadeLength(n_item, "D_FADEINLEN")--reaper.GetMediaItemInfo_Value(n_item, "D_FADEINLEN")

        --reaper.ShowConsoleMsg(reaper.GetTakeName(reaper.GetTake(p_item, 0)))

        offset = reaper.GetMediaItemInfo_Value(n_item, "D_POSITION") - p_item_end
        
        reaper.Main_OnCommand(40006,0)--remove items
        
        for i = f_item_idx, reaper.CountTrackMediaItems(track) -  1 do
            item_edit = reaper.GetTrackMediaItem(track,i)
            reaper.SetMediaItemInfo_Value(item_edit, "D_POSITION", reaper.GetMediaItemInfo_Value(item_edit, "D_POSITION") - offset - n_item_fadein)
        end
        reaper.SetMediaItemInfo_Value(p_item, "C_FADEOUTSHAPE", 1)
        reaper.SetMediaItemInfo_Value(p_item, "D_FADEOUTLEN_AUTO", n_item_fadein)
        reaper.SetMediaItemInfo_Value(n_item, "C_FADEINSHAPE", 1)
        reaper.SetMediaItemInfo_Value(n_item, "D_FADEINLEN_AUTO", n_item_fadein)
        reaper.SetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,f_item_idx), "C_FADEINSHAPE", 1)
        reaper.ShowConsoleMsg("excecuted, Fade In: " .. n_item_fadein .. "\n")

    end
    
    RestoreRippleState()
    reaper.Undo_EndBlock("Delete items and reverse ripple",-1)
end

main()