ext_state = "ausbaxter_Treat empty items on folder tracks as regions"
region_items = {}
start_index = 100
region_indexes = {}
num_region_items = 0
prev_count = {}


ext_state_del = {}
st = 0
while true do
    retval, key, val = reaper.EnumProjExtState(0, ext_state, st)
    if retval == false then break end
    if key == "region_item_count" then region_item_count = val end
    local exists = reaper.ValidatePtr2(0, reaper.BR_GetMediaItemByGUID(0, key), "MediaItem*")
    if exists == false then 
        reaper.ShowConsoleMsg("pointer nonexistant deleting " .. val .. "\n")
        table.insert(ext_state_del, key)
        reaper.DeleteProjectMarker(0, val, true)
    else
        reaper.ShowConsoleMsg("Region index [" .. key .. "] = " .. val .. "\n")
        region_items[key] = val
    end
    st = st + 1
end

for i, key in ipairs(ext_state_del) do reaper.SetProjExtState(0, ext_state, key, "") end


function main()
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local track_guid = reaper.GetTrackGUID(track)
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            local item_count = reaper.CountTrackMediaItems(track)
            if  prev_count[track_guid] ~= nil and prev_count[track_guid] > item_count then
                for i, rgn in pairs(region_items) do
                    local item = reaper.BR_GetMediaItemByGUID(0, i)
                    local exists = reaper.ValidatePtr2(0, item, "MediaItem*")
                    if exists == false or reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(item), "I_FOLDERDEPTH") ~= 1 then
                        reaper.DeleteProjectMarker(0, rgn, true)
                        region_items[i] = nil
                        region_indexes[rgn] = false
                        num_region_items = num_region_items - 1
                    end
                end
            end
            for j = 0, item_count - 1 do
                local item = reaper.GetTrackMediaItem(track, j)
                local item_guid = reaper.BR_GetMediaItemGUID(item)
                if reaper.GetTake(item, 0) == nil then
                    local r_in = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local r_out = r_in + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    local r_name = reaper.ULT_GetMediaItemNote(item)
                    local r_col = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                    local _, c_marks, c_rgns = reaper.CountProjectMarkers(0)
                    if region_items[item_guid] ~= nil then
                        if reaper.BR_GetMediaItemByGUID(0, item_guid) == nil then
                            reaper.DeleteProjectMarker(0, region_items[item_guid], true)
                            region_items[item_guid] = nil
                        else
                            reaper.SetProjectMarker3(0, region_items[item_guid], true, r_in, r_out, r_name, r_col)
                        end
                    else
                        local index = start_index
                        for i = start_index, start_index+ num_region_items do
                            if region_indexes[i] == false or region_indexes[i] == nil then
                                index = i
                            end
                        end
                        region_items[item_guid] = reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, index, r_col)
                        region_indexes[index] = true
                        num_region_items = num_region_items + 1
                    end
                end
            end
            prev_count[track_guid] = item_count
        end
    end
    reaper.defer(main)
end

reaper.atexit(function()
    for i, rgn in pairs(region_items) do
        reaper.SetProjExtState(0, ext_state, i, rgn)
    end
    --reaper.SetProjExtState(0,ext_state,"region_item_count", region_item_count)
end
)

main()