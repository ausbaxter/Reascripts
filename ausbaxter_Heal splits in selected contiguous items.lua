--@description Heal splits in selected contiguous items
--@version 1.0
--@author ausbaxter
--@about
--    # Heal splits in selected contiguous items 
--    Heals any splits in selected items that can sometimes occur after using dynamic split or auto trim/split items.
--@changelog
--  + Initial release

function GetSelectedMediaItems(item_count)
    local media_items = {
      item = {},
      i_start = {},
      i_end = {}
    }
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        table.insert(media_items.item, item)
        local i_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local i_end = i_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        table.insert(media_items.i_start, i_start)
        table.insert(media_items["i_end"], i_end)
    end
    return media_items
end

function Heal(items)
    reaper.Main_OnCommand(40289,0) --unselect all items
    for i = 1, #items do
        reaper.SetMediaItemInfo_Value(items[i], "B_UISEL", 1)
    end
    reaper.Main_OnCommand(40548,0)
end

function Round(val)
    return tonumber(string.format("%.3f", val))
end

function SelectAffected(items)
    for i = 1, #items do
        reaper.SetMediaItemInfo_Value(items[i], "B_UISEL", 1)
    end
end

function Main()
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    item_count = reaper.CountSelectedMediaItems()
    media_items = GetSelectedMediaItems(item_count)
    connected_items = {}
    c_items_count = 0
    affected_items = {}
    
    for i = 2, item_count do
        if Round(media_items.i_end[i-1]) == Round(media_items.i_start[i]) then
            if #connected_items == 0 then
                c_items_count = c_items_count + 1
                table.insert(connected_items, media_items.item[i-1])
                
            end
            c_items_count = c_items_count + 1
            table.insert(connected_items, media_items.item[i])
        else
            Heal(connected_items)
            table.insert(affected_items, reaper.GetSelectedMediaItem(0,0))
            connected_items = {}
            c_items_count = 0
        end
        
    end
    
    Heal(connected_items)
    table.insert(affected_items, reaper.GetSelectedMediaItem(0,0))
    SelectAffected(affected_items)
    
    reaper.Undo_EndBlock("Heal splits in connected items", 0)
    reaper.UpdateArrange()
end

Main()
