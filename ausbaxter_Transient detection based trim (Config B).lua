--[[
@version 1.0
@author ausbaxter
@description Transient Detection Based Trim (Using Command Parameters Config B)
@about
    ## Transient Detection Based Trim (Using Command Parameters Config B)
    Trims selected items based on the first detected transient from the start of the clip and the first detected 'transient' from the end of the clip.

    SWS command parameter fade lengths from config B are used to buffer the edit points.

@changelog
    [1.0] - 2019-07-09
    + Initial release

@donation paypal.me/abaxtersound

@screenshot
    https://i.gyazo.com/f8124fa40be1ddfffc588da94edcea20.gif
]]

--------------------------------------------------------------------------------------------
--[[                                   Load Functions                                     ]]
--------------------------------------------------------------------------------------------
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
local p_delim = string.find(reaper.GetOS(), "Win") and "\\" or "/"
local base_directory = string.match(filename, ".*" .. p_delim)
loadfile(base_directory .. "ausbaxter_Functions.lua")()
--------------------------------------------------------------------------------------------
--[[                                                                                      ]]
--------------------------------------------------------------------------------------------

local lower_transient_threshold = 40219
local raise_transient_threshold = 40218

local next_transient = 40375
local reverse_item = 41051

local nudge_left = 41250
local trim_left = 41305

local unselect_all = 40289

local command_parameters = GetCommandParameterFades()
local fade_in_len = command_parameters.B.fade_in_len
local fade_out_len = command_parameters.B.fade_out_len

function getitems()
    local t = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(t, item)
    end
    return t
end

function raise_lower_threshold(is_raise, amount)
    local command = is_raise == true and raise_transient_threshold or lower_transient_threshold
    for i = 0, amount do
        reaper.Main_OnCommand(command, 0)
    end
end

function Reselect_Items(t)
    for i, item in ipairs(t) do
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
    end
end

function main()
    local i_tbl = getitems()
    local orig_cursor_pos = reaper.GetCursorPosition()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(2)

    reaper.Main_OnCommand(unselect_all, 0)

    for i, item in ipairs(i_tbl) do

        cursor = reaper.GetCursorPosition()
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)


        reaper.MoveEditCursor(item_pos - cursor, false)

        reaper.Main_OnCommand(next_transient, 0)
        reaper.ApplyNudge(0, 0, 6, 0, -fade_in_len, false, 0) 
        reaper.Main_OnCommand(trim_left, 0)
        

        local orig_pos = reaper.GetCursorPosition()

        reaper.Main_OnCommand(reverse_item, 0)

        raise_lower_threshold(false, 15)

        reaper.Main_OnCommand(next_transient, 0)
        reaper.ApplyNudge(0, 0, 6, 0, -fade_out_len, false, 0)
        reaper.Main_OnCommand(trim_left, 0)    

        reaper.Main_OnCommand(reverse_item, 0)

        reaper.ApplyNudge(0, 1, 0, 1, orig_pos, false, 0)

        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)

        raise_lower_threshold(true, 15)

        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.02)
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.02)

    end

    end_cursor_pos = reaper.GetCursorPosition()
    reaper.MoveEditCursor(orig_cursor_pos - end_cursor_pos, false)

    Reselect_Items(i_tbl)

    reaper.Undo_EndBlock("Transient based trim", -1)
    reaper.UpdateArrange()

end

main()