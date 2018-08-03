function msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

function table.contains(t,match) --returns if the second parameter matches a table element
    for i, elem in ipairs(t) do if elem == match then return true end end
    return false
end

function GetAllSelectedItemsInTable()
--Returns all selected items in table
    local t_items = {}
    for i = 0, reaper.CountSelectedMediaItems() - 1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        table.insert(t_items,item)
    end
    return t_items
end

function GetGroupedItemsInTable()
--Returns selected items and the members of each of the selected item's group.
    local t_items = {}
    local t_grp_nums = {}
    --loop through selected items getting groups
    for i = 0, reaper.CountSelectedMediaItems() - 1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local group_num = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
        if not table.contains(t_grp_nums, group_num) and group_num ~= 0 then table.insert(t_grp_nums,group_num) end
    end
    --loop through all items considering all groups
    for i = 0, reaper.CountMediaItems(0) - 1 do
        local item = reaper.GetMediaItem(0,i)
        for j, g in ipairs(t_grp_nums) do
            if reaper.GetMediaItemInfo_Value(item, "I_GROUPID") == g then table.insert(t_items,item) end
        end
    end
    return t_items
end

function GetAllSelectedTracksInTable()
--Returns all selected tracks in table
    local t_tracks = {}
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0,i)
        table.insert(t_tracks,track)
    end
    return t_tracks
end

function TableFromCSV(csv, keys, pattern)
--Converts a csv string into a lua table
    local value_table = {}
    local count = 1
    local keys = keys or nil
    local pattern = pattern or "%w*"
    if keys ~= nil then --handles key input for table
        for i in string.gmatch(csv, pattern) do
        value_table[keys[count]] = i
        count = count + 1
        end
    else --handles simple csv parsing to table
        for i in string.gmatch(csv, pattern) do
        value_table[count] = i
        count = count + 1
        end
    end
    return value_table
end

function TableToCSV(keys, endstring)
--Converts a lua table into a csv string
    local table_string = {}
    for i, key in ipairs(keys) do
        local newKey = key .. endstring
        table.insert(table_string, newKey)
    end
    local user_key_csv = table.concat(table_string, ",")
    return user_key_csv
end