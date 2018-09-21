function IsMuted(track)
    if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then return true end
    local track_check = reaper.GetParentTrack(track)
    while(track_check ~= nil) do
        if reaper.GetMediaTrackInfo_Value(track_check, "B_MUTE") == 1 then return true end
        track_check = reaper.GetParentTrack(track_check)
    end
    return false
end

function DeleteInvalidRegions(full)
    for i, rgn in pairs(region_items) do
        local item = reaper.BR_GetMediaItemByGUID(0, i)
        local exists = reaper.ValidatePtr2(0, item, "MediaItem*")
        if exists == false or reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(item), "I_FOLDERDEPTH") ~= 1 then
            reaper.DeleteProjectMarker(0, rgn, true)
            if full then
                region_items[i] = nil
                region_indexes[rgn] = false
            end
            num_region_items = num_region_items - 1
        end
    end
end

function main()
    local state = reaper.GetProjectStateChangeCount(0)
    if prev_state == nil or prev_state ~= state then
        num_tracks = reaper.CountTracks(0)
        if prev_num_tracks ~= nil and prev_num_tracks > num_tracks then
            DeleteInvalidRegions(false)
        end
        for i = 0, num_tracks - 1 do
            local track = reaper.GetTrack(0, i)
            local track_guid = reaper.GetTrackGUID(track)
            if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
                local item_count = reaper.CountTrackMediaItems(track)
                if  prev_count[track_guid] ~= nil and prev_count[track_guid] > item_count then
                    DeleteInvalidRegions(true)
                end
                for j = 0, item_count - 1 do
                    local item = reaper.GetTrackMediaItem(track, j)
                    local item_guid = reaper.BR_GetMediaItemGUID(item)
                    if reaper.GetTake(item, 0) == nil then
                        local r_in = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                        local r_out = r_in + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                        local r_name = reaper.ULT_GetMediaItemNote(item)
                        if r_name == "" then r_name = " " end
                        local r_col = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                        local _, c_marks, c_rgns = reaper.CountProjectMarkers(0)
                        if region_items[item_guid] ~= nil then
                            local retval = reaper.SetProjectMarker3(0, region_items[item_guid], true, r_in, r_out, r_name, r_col)
                            if not retval then
                                reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, region_items[item_guid], r_col)
                            end
                        else
                            local index = start_index
                            for i = start_index, start_index + num_region_items do
                                --reaper.ShowConsoleMsg("Checking : " .. i .. " is " .. tostring(region_indexes[i]) .. "\n")
                                if region_indexes[i] == false or region_indexes[i] == nil then
                                    index = i
                                    break
                                end
                            end
                            reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, index, r_col)
                            region_items[item_guid] = index
                            region_indexes[index] = true
                            num_region_items = num_region_items + 1
                        end
                    end
                end

                if IsMuted(track) then
                    for j = 0, item_count - 1 do
                        local item = reaper.GetTrackMediaItem(track, j)
                        local item_guid = reaper.BR_GetMediaItemGUID(item)
                        if region_items[item_guid] ~= nil then
                            reaper.DeleteProjectMarker(0, region_items[item_guid], true)
                        end
                    end
                end
                prev_count[track_guid] = item_count
            end
        end
    end
    prev_num_tracks = num_tracks
    prev_state = state
    reaper.defer(main)
end

reaper.atexit(function()
    for i, rgn in pairs(region_items) do
        reaper.SetProjExtState(0, ext_state, i, rgn)
    end
    
    local indexes = ""
    for i = start_index, start_index + num_region_items - 1 do
        --reaper.ShowConsoleMsg("Serializing : " .. i .. " = " .. tostring(region_indexes[i]) .. "\n")
        local s = "-1"
        if region_indexes[i] == false then
            s = "0"
        elseif region_indexes[i] == true then
            s = "1"
        end
        indexes = indexes .. i .. "," .. s .. "|"
    end
    reaper.SetProjExtState(0, ext_state, "INDEXES", indexes)

    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    gfx.quit()
end
)

ext_state = "ausbaxter_Treat empty items on folder tracks as regions"
region_items = {}
start_index = 100
region_indexes = {}
num_region_items = 0
prev_count = {}


ext_state_del = {}
st = 0

--reaper.SetProjExtState(0, ext_state, "", "")

while true do
    retval, key, val = reaper.EnumProjExtState(0, ext_state, st)
    if retval == false then break end
    --deserialize used marker id's
    if key == "INDEXES" then
        for t in string.gmatch(val, "%d+,%-?%d|") do
            local id = tonumber(string.match(t, "(%d+),"))
            local s = tonumber(string.match(t, ",(%d+)"))
            if s == -1 then s = nil
            elseif s == 0 then s = false
            elseif s == 1 then s = true end
            region_indexes[id] = s
            num_region_items = num_region_items + 1
            --reaper.ShowConsoleMsg("Deserializing : " .. id .. " is " .. tostring(region_indexes[id]) .. "\n")
        end
    else
        local exists = reaper.ValidatePtr2(0, reaper.BR_GetMediaItemByGUID(0, key), "MediaItem*")
        if exists == false then 
            --reaper.ShowConsoleMsg("pointer nonexistant deleting " .. val .. "\n")
            table.insert(ext_state_del, key)
            reaper.DeleteProjectMarker(0, val, true)
        else
            --reaper.ShowConsoleMsg("Region index [" .. key .. "] = " .. val .. "\n")
            region_items[key] = val
        end
    end
    st = st + 1
end

for i, key in ipairs(ext_state_del) do reaper.SetProjExtState(0, ext_state, key, "") end
    
is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

main()