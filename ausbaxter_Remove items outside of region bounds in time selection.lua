function GetSelectedItems()
    local t = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        table.insert(t, reaper.GetSelectedMediaItem(0, i))
    end
    return t
end

function RemoveItemsFromTable(source_tbl, remove_tbl)
    for i, r in ipairs(source_tbl) do
        table.remove(remove_tbl, r)
    end
    return remove_tbl
end

function SelectItems(table)
    for i, to_select in ipairs(table) do
        reaper.SetMediaItemInfo_Value(to_select, "B_UISEL", 1)
    end
end

function DeleteItems(table)
    for i, to_delete in ipairs(table) do
        reaper.SetMediaItemInfo_Value(to_delete, "B_UISEL", 1)
        reaper.Main_OnCommand(40006, 0) --remove item
    end
end



function main()

    reaper.Undo_BeginBlock()

    reaper.PreventUIRefresh(1)

    local sel_items = GetSelectedItems()
    local to_remove = {}
    local reselect = {}

    local ts,te = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local retval, nm, nr = reaper.CountProjectMarkers(0)

    for i = 0, nm + nr do
        local retval, is_rgn, rgn_pos, rgn_end, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if is_rgn then
            for j, item in ipairs(sel_items) do
                local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local i_end = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + i_pos
                if i_end <= rgn_end and rgn_pos <= i_pos then --within region
                    reaper.ShowConsoleMsg(i_pos .. " <= " .. rgn_end .. "\t" .. rgn_pos .. " <= " .. i_pos .. " #items2delete: " .. #sel_items .. "\n")
                    table.insert(to_remove, j)
                    table.insert(reselect, item)
                end
            end
        end
    end

    reaper.Main_OnCommand(40289, 0) --unselect items

    to_delete = RemoveItemsFromTable(to_remove, sel_items)

    DeleteItems(sel_items)

    --SelectItems(reselect)

    reaper.Undo_EndBlock("Remove selected items outside of region bouds", -1)

    reaper.UpdateArrange()

end

main()