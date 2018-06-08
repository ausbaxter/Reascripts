----------------------------User Parameter----------------------------
create_fades = true
cmd_param_fade = "B" --use "A" or "B" to correspond to command parameters fade settings

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
if cp_file == nil and create_fades then reaper.ReaScriptError("This script uses Xenakios' Command Parameters to create fades, are you sure you have the SWS Extension installed?") end

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
    
    return fit, fot, fis, fos
    
end

function DoFades(fi_time, fo_time, fi_shape, fo_shape)--Have fades read user config for fade in/out length and type. preferences not useful, would be cool to get command parameters    
    
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local idx = reaper.GetMediaItemInfo_Value(item,"IP_ITEMNUMBER")
        local track = reaper.GetMediaItemTrack(item)
        local prev_item = reaper.GetTrackMediaItem(track, idx - 1)
        local next_item = reaper.GetTrackMediaItem(track, idx + 1)
        
        --trim edges
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", reaper.GetMediaItemInfo_Value(item,"D_LENGTH") + fo_time)
        
        if prev_item ~= nil then
            --create fade in
            reaper.SetMediaItemInfo_Value(prev_item, "D_LENGTH", reaper.GetMediaItemInfo_Value(prev_item,"D_LENGTH") + fi_time)
            reaper.SetMediaItemInfo_Value(prev_item, "D_FADEOUTLEN", fi_time)
            reaper.SetMediaItemInfo_Value(prev_item, "C_FADEOUTSHAPE", fo_shape)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fi_time)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", fi_shape)
        end
        
        if next_item ~= nil then

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

function main()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    cursor_pos = reaper.GetCursorPosition()
    
    reaper.Main_OnCommand(ripple_off,0)
    
    if ts_start ~= ts_end then
        
        if reaper.CountSelectedTracks(0) == 0 then reaper.ReaScriptError("Need at least one track selected. No destination.") return end
        
        local fi_time, fo_time, fi_shape, fo_shape = GetFadeSpec()
        
        reaper.Main_OnCommand(40058,0)--paste command
    
        for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
        
            item = reaper.GetSelectedMediaItem(0,i)
            track = reaper.GetMediaItemTrack(item)
            i_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
            i_end = i_pos + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
            
            paste_length = create_fades and ts_end - i_pos - fo_time or ts_end - i_pos
            
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
        
        DoFades(fi_time, fo_time, fi_shape, fo_shape)
        
        RestoreRippleState()
    
    end 
    
    reaper.Undo_EndBlock("Paste item(s) obeying time selection",-1)
    reaper.UpdateArrange()

end

main()
