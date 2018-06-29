--external library usage from Lokasenna, thanks!-----------------------------------
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local function req(file)
  if missing_lib then return function () end end
  local ret, err = loadfile(script_path .. file)
  if not ret then
    reaper.ShowMessageBox("Couldn't load "..file.."\n\nError: "..tostring(err), "Library error", 0)
    missing_lib = true    
    return function () end
  else 
    return ret
  end  
end
------------------------------------------------------------------------------------

--library requirement
req("ausbaxter_Helper_functions.lua")()

function CursorOverlapsItem(table,cursor)
    for i, item in ipairs(table) do
        local is = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local il = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if is < cursor and is + il > cursor then return true end
    end
    return false
end

item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    grp_state = reaper.GetToggleCommandState(1156) --group override
    if grp_state == 1 then 
        reaper.Main_OnCommand(1156, 0) 
        item_table = GetGroupedItemsInTable()
        sel_item_table = GetAllSelectedItemsInTable()
    else 
        item_table = GetAllSelectedItemsInTable()
        sel_item_table = item_table
    end
    reaper.Main_OnCommand(40289,0)--unselect itemss

    cursor = reaper.GetCursorPosition()
    overlap = CursorOverlapsItem(item_table,cursor)
    items_to_keep = {}
    items_to_delete = {}
    for i, item in ipairs(item_table) do
        local is = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local il = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local ie = is + il
        if is > cursor and overlap then
            table.insert(items_to_delete, item)
        else
            if cursor > is and ie > cursor then
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
                local fo = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                if cursor > ie - fo then reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fo - (ie - cursor)) 
                else reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0) end
                reaper.ApplyNudge(0, 1, 3, 0, cursor, false, 0)
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
            end
            table.insert(items_to_keep, item)
        end
    end

    for i, item in ipairs(sel_item_table) do reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) end --restore selected items    
    for i, item in ipairs(items_to_delete) do reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item) end

    if grp_state == 1 then reaper.Main_OnCommand(1156, 0) end --toggle group override
    
    reaper.Undo_EndBlock("Trim left edge", -1)
    reaper.UpdateArrange()
    
end
