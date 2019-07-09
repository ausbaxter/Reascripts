--[[
@version 1.0
@author ausbaxter
@description Auto trim and fade left edge of items (SWS Config B) (good group behaviour)
@about
    ## Auto trim and fade left edge of items (SWS Config B) (good group behaviour)
    Trims an item at the edit cursor - the SWS Config B fade in length, sets the fade in to the same length
@changelog
    [1.0] - 2019-07-09
    + Initial release
@donation paypal.me/abaxtersound
]]

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
retval, ini_fade_in = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEINTIMEB", "1.0", reaper_path)
local fade_length = tonumber(ini_fade_in) * 1000

--------------------------------------------------------------------------------------------

function LeftTrim(fade_length)

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
                reaper.ApplyNudge(0, 1, 1, 0, cursor-fade_length, false, 0)
                reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade_length)
                reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
            end
        end

        if grp_state == 1 then reaper.Main_OnCommand(1156, 0) end --regroup

        for i, item in ipairs(sel_items) do reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) end

        reaper.Undo_EndBlock("Trim left edge", -1)
        reaper.UpdateArrange()

    end

end

function main()
    LeftTrim(fade_length/1000)
end

main()
