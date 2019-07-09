--------------------------------------------------------------------------------------------
--[[                                  Load Lib Functions                                  ]]
--------------------------------------------------------------------------------------------
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
local p_delim = string.find(reaper.GetOS(), "Win") and "\\" or "/"
local base_directory = string.match(filename, ".*" .. p_delim)
loadfile(base_directory .. "ausbaxter_Functions.lua")()
--------------------------------------------------------------------------------------------
--[[                                                                                      ]]
--------------------------------------------------------------------------------------------

function main()

    if reaper.CountSelectedMediaItems(0) > 0 then

        sel_items = GetAllSelectedItemsInTable()
        cursor = reaper.GetCursorPosition()

        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()

        local grp_state = reaper.GetToggleCommandState(1156) --group override
        if grp_state == 1 then reaper.Main_OnCommand(1156, 0) end --ungroup

        reaper.Main_OnCommand(40289,0)--unselect items

        for i, item in ipairs(sel_items) do
            local i_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local i_end = i_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if i_pos < cursor and i_end > cursor then
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
                local fi = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
                if cursor < i_pos + fi then reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fi - (cursor - i_pos)) 
                else reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0) end
                reaper.ApplyNudge(0, 1, 1, 0, cursor, false, 0)
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
            end
        end

        if grp_state == 1 then reaper.Main_OnCommand(1156, 0) end --regroup

        for i, item in ipairs(sel_items) do reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) end

        reaper.Undo_EndBlock("Trim left edge", -1)
        reaper.UpdateArrange()

    end

end

main()