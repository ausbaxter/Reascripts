function Msg(msg)
    reaper.ShowConsoleMsg(tostring(msg))
end

function ShallowTableCopy(t_table) --Allows passing of 1D tables by value instead of reference
  local t2 = {}
    for k,v in ipairs(t_table) do
      t2[k] = v
    end
    return t2
end

function GetSelectedMediaItemAndPos(index)
    local item = reaper.GetSelectedMediaItem(0, index)
    local i_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local i_end =  i_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return item, i_start, i_end
end

function GetUniqueTracks(this_item, t_compare)
    local this_track = reaper.GetMediaItemTrack(this_item)
    local unique_track = true
    for i, track in ipairs(t_compare) do
        if track == this_track then unique_track = false ; break end
    end
    if unique_track == true then table.insert(t_compare, this_track) end
end

function GetColumnTimes(items_table)--stores only column in-out times
    local c_table, column = {}, {}
    local c_start = 0
    local c_end = 0
    for i, item in ipairs(items_table) do
        --if i == 1 then c_end = item["end"] end --initialize column-end comparison variable
        
        if i == 1 then
            c_start = item["start"] ; c_end = item["end"]
        elseif item["start"] < c_end  then
            if item["end"] > c_end then c_end = item["end"] end     
        else
            table.insert(c_table, {["start"] = c_start, ["end"] = c_end})
            c_start = item["start"] ; c_end = item["end"]
        end   
    end
    table.insert(c_table, {["start"] = c_start, ["end"] = c_end})
    return c_table
end

--[[
function SortItemsIntoColumns(items_table)--stores item references in table organized by column
    local c_table, column = {}, {}
    local c_end = 0
    for i, item in ipairs(items_table) do
        --if i == 1 then c_end = item["end"] end --initialize column-end comparison variable
        
        if item["start"] < c_end or i == 1 then
            Msg("\nChecking item start: " .. i)
            table.insert(column, item)
            if item["end"] > c_end then c_end = item["end"] ; Msg("\tItem End update") end     
        else
            Msg("\nCreating new column: " .. i)
            table.insert(c_table, ShallowTableCopy(column)) ; column = {} --copy column over to column table, initialize column
            table.insert(column, item)--insert first item into new column
            c_end = item["end"]
        end   
    end
    table.insert(c_table, ShallowTableCopy(column))
    return c_table
end]]

function GetItemsAndTracks()
    local i_table, t_table, c_table = {}, {}, {}
    s_item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, s_item_count - 1 do
        local item, i_start, i_end = GetSelectedMediaItemAndPos(i)
        i_table[i + 1] = {["item"] = item , ["start"] = i_start, ["end"] = i_end}
        GetUniqueTracks(item, t_table)
    end
    table.sort(i_table, function(a,b) return a["start"] < b["start"] end)
    return i_table, t_table
end

items, tracks = GetItemsAndTracks()


t = GetColumnTimes(items)

--Todo
--Render function and cleanup

