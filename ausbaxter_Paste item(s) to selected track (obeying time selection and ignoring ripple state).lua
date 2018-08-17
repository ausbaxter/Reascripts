----------------------------User Parameter----------------------------
create_fades = true

--Use SWS command parameters to get fade shape and time
use_command_parameters = true
cmd_param_fade = "B" --use "A" or "B" to correspond to command parameters fade settings

--if use_command_parameters you can use the following variables to specify fade settings. If you do not have SWS installed these values are automatically used.
--fade times are in seconds
--shapes: 1 = linear, 2 = log, 3 = exp, 4 = 2log, 5 = 2exp, 6 = mellow s-curve, 7 = steep s-curve
fade_in_time = 0.100
fade_in_shape = 1
fade_out_time = 0.100
fade_out_shape = 1

--create options for fade pre/post/center???
----------------------------------------------------------------------

ripple_all_tracks_check = reaper.GetToggleCommandState(40311) --ripple all tracks check
ripple_one_track_check = reaper.GetToggleCommandState(40310) --ripple all tracks check
ripple_one_track = 40310
ripple_all_tracks = 40311
ripple_off = 40309

x_start, x_end = reaper.GetSet_ArrangeView2(0, false, 0, 0)

ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

path = reaper.GetResourcePath()

cp_file = io.open(path.."\\Xenakios_Commands.ini")
if cp_file == nil and create_fades and use_command_parameters then reaper.ReaScriptError("This script uses Xenakios' Command Parameters to create fades, are you sure you have the SWS Extension installed?") end

function RestoreRippleState()
    local cmd_id
    if ripple_all_tracks_check == 1 then cmd_id = ripple_all_tracks
    elseif ripple_one_track_check == 1 then cmd_id = ripple_one_track
    elseif ripple_all_tracks_check == 0 and ripple_one_track_check == 0 then cmd_id = ripple_off end
    
    reaper.Main_OnCommand(cmd_id, 0)
end

function GetFadeSpec()
    
    local fit
    local fot
    local fis
    local fos
    
    if use_command_parameters == false or cp_file == nil then
        reaper.ShowConsoleMsg("In user fade settings")
        fit = fade_in_time
        fis = fade_in_shape
        fot = fade_out_time
        fos = fade_out_shape

    elseif use_command_parameters == true then

        for line in cp_file:lines() do
            local r_fit = "FADEINTIME" .. cmd_param_fade .. "=([0-9.]*)"
            local r_fot = "FADEOUTTIME" .. cmd_param_fade .. "=([0-9.]*)"
            local r_fis = "FADEINSHAPE" .. cmd_param_fade .. "=([0-9.]*)"
            local r_fos = "FADEOUTSHAPE" .. cmd_param_fade .. "=([0-9.]*)"
            
            if string.find(line,r_fit) then fit = tonumber(string.match(line,r_fit))
            elseif string.find(line,r_fot) then fot = tonumber(string.match(line,r_fot))
            elseif string.find(line,r_fis)then fis = tonumber(string.match(line,r_fis))
            elseif string.find(line,r_fos) then fos = tonumber(string.match(line,r_fos)) end
            
        end
    
    end
    
    return fit, fot, fis, fos
    
end

function DoFades(fi_time, fo_time, fi_shape, fo_shape, do_fin, do_fout)--Have fades read user config for fade in/out length and type. preferences not useful, would be cool to get command parameters    
    
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local idx = reaper.GetMediaItemInfo_Value(item,"IP_ITEMNUMBER")
        local track = reaper.GetMediaItemTrack(item)
        local prev_item = reaper.GetTrackMediaItem(track, idx - 1)
        local next_item = reaper.GetTrackMediaItem(track, idx + 1)
        
        --trim edges
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", reaper.GetMediaItemInfo_Value(item,"D_LENGTH") + fo_time)
        
        if prev_item ~= nil and do_fin then
            --create fade in
            reaper.SetMediaItemInfo_Value(prev_item, "D_LENGTH", reaper.GetMediaItemInfo_Value(prev_item,"D_LENGTH") + fi_time)
            reaper.SetMediaItemInfo_Value(prev_item, "D_FADEOUTLEN", fi_time)
            reaper.SetMediaItemInfo_Value(prev_item, "C_FADEOUTSHAPE", fo_shape)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fi_time)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", fi_shape)
        end
        
        if next_item ~= nil and do_fout then

            if ts_end == reaper.GetMediaItemInfo_Value(next_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(next_item,"D_LENGTH") then
                reaper.DeleteTrackMediaItem(track, next_item)
                break
            end
            --create fade out
            reaper.SetMediaItemInfo_Value(next_item, "D_FADEINLEN", fo_time)
            reaper.SetMediaItemInfo_Value(next_item, "C_FADEINSHAPE", fi_shape)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fo_time)
            reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", fo_shape)
        end
    end
end

function PasteIsOverItem()
    local track = reaper.GetSelectedTrack(0, 0)
    local overlap_start = false
    local overlap_end = false
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        if item_start <= ts_end and item_start >= ts_start then overlap_end = true end
        if item_end >= ts_start and item_end <= ts_end then overlap_start = true end
        if item_start <= ts_start and item_end >= ts_end then overlap_end = true overlap_start = true end
        if overlap_end and overlap_start then return overlap_start, overlap_end end
    end
    return overlap_start, overlap_end
end

function main()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    cursor_pos = reaper.GetCursorPosition()

    reaper.Main_OnCommand(ripple_off,0)
    
    if ts_start ~= ts_end then
        
        if reaper.CountSelectedTracks(0) == 0 then reaper.ReaScriptError("Need at least one track selected. No destination.") return end
        
        local fi_time, fo_time, fi_shape, fo_shape = GetFadeSpec()
        local do_fin, do_fout = PasteIsOverItem()

        count_pre_paste = reaper.CountTrackMediaItems(reaper.GetSelectedTrack(0, 0))
        reaper.Main_OnCommand(40058,0)--paste command
        count_post_paste = reaper.CountTrackMediaItems(reaper.GetSelectedTrack(0, 0))
        if count_pre_paste == count_post_paste then reaper.ReaScriptError("No item in clipboard") return end
    
        --reaper.ShowConsoleMsg("fin: "..tostring(do_fin).."\tfout: "..tostring(do_fout).."\n")

        for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
        
            item = reaper.GetSelectedMediaItem(0,i)
            track = reaper.GetMediaItemTrack(item)
            i_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
            i_end = i_pos + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
            
            if do_fout == false or create_fades == false then fo_time = 0 end

            paste_length = ts_end - i_pos - fo_time
            
            if i_pos < ts_end then 
                if i_end > ts_end then
                    reaper.SetMediaItemInfo_Value(item,"D_LENGTH",paste_length)
                end
            else
                reaper.DeleteTrackMediaItem(track, item)
            end
            
        end
    
        reaper.Main_OnCommand(40930,0)--trim contents behind
    
        reaper.SetEditCurPos(cursor_pos,true,false)
        reaper.BR_SetArrangeView(0, x_start, x_end)--getsetarrangeview2 does not work when setting, need to use this

        DoFades(fi_time, fo_time, fi_shape, fo_shape, do_fin, do_fout)
        
        RestoreRippleState()
    
    end 
    
    reaper.Undo_EndBlock("Paste item(s) obeying time selection",-1)
    reaper.UpdateArrange()

end

main()
