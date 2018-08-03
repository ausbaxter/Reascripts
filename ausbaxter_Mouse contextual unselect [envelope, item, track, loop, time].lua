local unsel_items = 40289
local unsel_tracks = 40297
local unsel_env_pts = 40331
local unsel_time_sel = 40635
local unsel_loop_sel = 40634

function UnselectLoopTimeSelection()
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local mouse = reaper.BR_GetMouseCursorContext_Position()
    if ts_start <= mouse and ts_end >= mouse then
        reaper.Main_OnCommand(unsel_time_sel, 0)
        return true
    else
        reaper.Main_OnCommand(unsel_loop_sel, 0)
        return true
    end
    return false
end

function UnselectEnvelopePoints()
    local env, is_take = reaper.BR_GetMouseCursorContext_Envelope()
    for i = 0, reaper.CountEnvelopePoints(env) - 1 do
        local retval, time, value, shape, tension = reaper.GetEnvelopePoint(env, i)
        reaper.SetEnvelopePoint(env, i, time, value, shape, tension, false, false)
    end
end

function main()
    local cc_window, cc_segment, cc_details = reaper.BR_GetMouseCursorContext()
    if cc_window == "arrange" then
        if cc_segment == "track" then       
            if cc_details == "item" or cc_details == "item_stretch_marker" then
                local item = reaper.BR_GetMouseCursorContext_Item()
                if item ~= nil then
                    if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then 
                        reaper.Main_OnCommand(unsel_items, 0)
                    else
                        UnselectLoopTimeSelection()
                    end
                end
            elseif cc_details == "env_point" or cc_details == "env_segment" then 
                --take envelope context
                UnselectEnvelopePoints()
            else
                UnselectLoopTimeSelection()
            end
        elseif cc_segment == "envelope" then
            UnselectEnvelopePoints()
        end
    elseif cc_window == "tcp" or cc_window == "mcp" then
        reaper.Main_OnCommand(unsel_tracks, 0)
    end

end

main()
