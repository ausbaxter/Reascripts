--[[
@version 1.0
@author ausbaxter
@description
    Trim Selected Items to Regions Bounds in Time Selection
@about
    ## Trim Selected Items to Regions Bounds in Time Selection
        Trims any selected items to the bounds of the closest region. Works in timeline order and doesn't split clips so any item overlapping multiple regions will be trimmed to the edges of the first region. 

    ### Future Update
    - Split items at region edges if necessary, removing out of region segments.

@changelog
    [1.0] - 2019-06-09
    + Initial release
@donation paypal.me/abaxtersound
]]

local unselect_items = 40289

function GetSelectedMediaItems()
    local c = reaper.CountSelectedMediaItems(0)
    if c < 1 then reaper.ReaScriptError("No items selected") return -1 end
    local t = {}
    for i = 0, c - 1 do 
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(t, item)
    end
    return t
end

function TrimItemsToRegionBounds(item_table)
    local retval, n_markers, n_regions = reaper.CountProjectMarkers(0)
    local ts, te = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    for i = 0, n_regions + n_markers - 1 do
        local retval, isrgn, r_pos, r_end, name, idx = reaper.EnumProjectMarkers(i)
        if isrgn and r_pos >= ts and te >= r_pos and te >= r_end then
            for j, item in ipairs(item_table) do
                local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                --if i_pos > r_end then break end --out of region
                local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")  
                if i_pos < r_pos and i_end > r_pos then -- trim start
                    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
                    reaper.ApplyNudge(0, 1, 2, 1, r_pos, false, 0)
                    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
                end
                if i_pos < r_end and i_end > r_end then -- trim end
                    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
                    reaper.ApplyNudge(0, 1, 3, 1, r_end, false, 0)
                    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
                end
            end
        end
    end
end

function ReselectItems(item_table)
    for i, item in ipairs(item_table) do
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
    end
end

function main()
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local item_table = GetSelectedMediaItems()
    if item_table == -1 then return end
    reaper.Main_OnCommand(unselect_items, 0)
    TrimItemsToRegionBounds(item_table)
    ReselectItems(item_table)
    reaper.Undo_EndBlock("Trim selected items to region bounds", 0)
    reaper.UpdateArrange()
end

main()