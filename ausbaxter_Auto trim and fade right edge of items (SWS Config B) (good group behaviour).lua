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

reaper_path = reaper.GetResourcePath() .. "/Xenakios_Commands.ini"
if not reaper.file_exists(reaper_path) then 
    reaper.ShowMessageBox("SWS Extension is required for this script.", "SWS Not Installed", 0)
    return
end
retval, ini_fade_out = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEOUTTIMEB", "1.0", reaper_path)
local fade_length = tonumber(ini_fade_out) * 1000

--------------------------------------------------------------------------------------------

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
