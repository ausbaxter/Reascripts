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

function main()
    

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    reaper.Main_OnCommand(ripple_off,0)
    
    item_table = GetMediaItemIndexes()

    for i, t_track in ipairs(item_table) do

        for j = count(t_track["itemtable"]), 1, -1 do

            local curr_start = t_track["itemtable"][j]["first"]
            local curr_end = t_track["itemtable"][j]["last"]
            local first_item = reaper.GetTrackMediaItem(t_track["track"],curr_start)
            local first_item_pos = reaper.GetMediaItemInfo_Value(first_item,"D_POSITION")
            local end_item = reaper.GetTrackMediaItem(t_track["track"],curr_end)
            local end_item_end = reaper.GetMediaItemInfo_Value(end_item,"D_POSITION") + reaper.GetMediaItemInfo_Value(end_item,"D_LENGTH")
            local item_after_end = reaper.GetTrackMediaItem(t_track["track"],curr_end + 1)
            local item_before_start = reaper.GetTrackMediaItem(t_track["track"],curr_start - 1)

            local len = end_item_end - first_item_pos

            local offset
            if item_after_end ~= nil then 
                offset = reaper.GetMediaItemInfo_Value(item_after_end,"D_POSITION") - end_item_end
            else
                if reaper.GetMediaItemInfo_Value(item_before_start,"D_POSITION") + reaper.GetMediaItemInfo_Value(item_before_start,"D_LENGTH") < first_item_pos then
                    offset = 0
                else
                    offset = first_item_pos - (reaper.GetMediaItemInfo_Value(item_before_start,"D_POSITION") + reaper.GetMediaItemInfo_Value(item_before_start,"D_LENGTH"))
                end

            end

            for l = curr_start - 1, 0, -1 do
                local item = reaper.GetTrackMediaItem(t_track["track"],l)
                local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
                reaper.SetMediaItemInfo_Value(item,"D_POSITION", pos + len + offset)
            end

        end

    end

    reaper.Main_OnCommand(40006,-1)
    RestoreRippleState()
    reaper.Undo_EndBlock("Delete items and reverse ripple",-1)
end

main()
