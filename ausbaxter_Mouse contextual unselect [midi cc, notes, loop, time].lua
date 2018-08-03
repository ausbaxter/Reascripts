local unsel_loop_sel = 40744
local unsel_time_sel = 40745
local unsel_events = 40214

function UnselectLoopTimeSelection(editor)
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local mouse = reaper.BR_GetMouseCursorContext_Position()
    if ts_start <= mouse and ts_end >= mouse then
        reaper.MIDIEditor_OnCommand(editor, unsel_time_sel)
        return true
    else
        reaper.MIDIEditor_OnCommand(editor, unsel_loop_sel)
        return true
    end
    return false
end

function main()
    local cc_window, cc_segment, cc_details = reaper.BR_GetMouseCursorContext()
    local active_editor = reaper.MIDIEditor_GetActive()
    if cc_window == "midi_editor" then
        if cc_segment == "notes" then
            reaper.MIDIEditor_OnCommand(active_editor, unsel_events)
        else
            UnselectLoopTimeSelection(active_editor)
        end 
    end
end

main()
