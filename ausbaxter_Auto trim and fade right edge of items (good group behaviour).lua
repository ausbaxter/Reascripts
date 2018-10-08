--external library usage from Lokasenna, thanks!-----------------------------------
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local function req(fole)
    if missing_lib then return function () end end
    local ret, err = loadfile(script_path .. fole)
    if not ret then
        reaper.ShowMessageBox("Couldn't load "..fole.."\n\nError: "..tostring(err), "Library error", 0)
        missing_lib = true    
        return function () end
    else 
        return ret
    end  
end
------------------------------------------------------------------------------------

-------------------------USER VARIABLE (ms)----------------------------------------------
--Sets the nudge and fade length value when executed
local fade_length = 280
------------------------------------------------------------------------------------

--library requirement
req("ausbaxter_Helper_functions.lua")()

function RightTrim(fade_length)

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
                reaper.ApplyNudge(0, 1, 3, 0, cursor + fade_length, false, 0)
                reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade_length)
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
            end
        end

        if grp_state == 1 then reaper.Main_OnCommand(1156, 0) end --regroup

        for i, item in ipairs(sel_items) do reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) end

        reaper.Undo_EndBlock("Auto trim Right edge", -1)
        reaper.UpdateArrange()

    end

end

function main()
    RightTrim(fade_length/1000)
end

main()
