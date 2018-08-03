--@description script name
--@version 1.0
--@author ausbaxter
--@about
--  # {Package Title}
--  {Any Documentation}
--@changelog
--  + Initial release

--------------------------------------------------------------------------------------------------------

--[[
    TODO
    - read reascale files to get new scales
    - have project setting allowing for extended chords to be created.
    - using this as a template allow the user to create different chords based on hovered mouse note augmented, sus, major, minor, diminished, etc.
]]

local snap = "snap_enabled"
local def_vel = "default_note_vel"
local def_chan = "default_note_chan"
local def_len = "default_note_len"
local scale_on = "scale_enabled"
local default_scales = {"Major","Natural minor","Melodic minor","Harmonic minor","Pentatonic","Blues"}
local default_scale_notes = {"102034050607","102304056070","102304050067","102304050607","102030040500","100304450070"}
local scale_index = 6

function DefaultScaleSelected(scale)
    for i, scale_check in ipairs(default_scales) do
        if scale_check == scale then return true end
    end
    return false
end

function SearchScale(s, degree)
    for i = 1, s:len() do
        local index = s:sub(i,i)
        if degree == tonumber(index) then return i end
    end
    return -1
end

function GetDefaultScale(name)
    for i, s in ipairs(default_scales) do
        if name == s then return default_scale_notes[i] end
    end
    return nil
end

function Main()
    local editor = reaper.MIDIEditor_GetActive()
    local take = reaper.MIDIEditor_GetTake(editor)
    local setting_strings = {snap,def_vel,def_chan,def_len,scale_on}
    local settings = {}

    reaper.ShowConsoleMsg("==============Default Settings=============\n")
    for i, s in ipairs(setting_strings) do
        settings[s] = reaper.MIDIEditor_GetSetting_int(editor, s)
        --reaper.ShowConsoleMsg(s ..": " ..settings[s].."\n")
    end

    local retval, root, scale, name = reaper.MIDI_GetScale(take, 0, 0, 0)
    settings["scale_root"] = root
    settings["scale"] = scale
    settings["scale_name"] = name
    --reaper.ShowConsoleMsg("root: "..root.."\tscale: "..scale.."\tname: "..name.."\n")

    cc_window, cc_segment = reaper.BR_GetMouseCursorContext()
    if cc_window == "midi_editor" and cc_segment == "notes" then
        local retval, inline, note_row = reaper.BR_GetMouseCursorContext_MIDI()
        local grid, swing, note_size = reaper.MIDI_GetGrid(take) --0 if following grid size
        
        --item position obeys grid (clean up later)
        local cursor = reaper.BR_GetMouseCursorContext_Position()
        local cursor_location = reaper.MIDI_GetPPQPosFromProjTime(take, cursor)
        local cursor_end = reaper.MIDI_GetPPQPosFromProjQN(take, grid + reaper.MIDI_GetProjQNFromPPQPos(take, cursor_location))
        local measure_start = reaper.MIDI_GetPPQPos_StartOfMeasure(take, cursor_location)
        local tick_offset = cursor_end - cursor_location
        local note_start = math.floor((cursor_location - measure_start) / tick_offset) * tick_offset + measure_start
        local note_end = reaper.MIDI_GetPPQPosFromProjQN(take, grid + reaper.MIDI_GetProjQNFromPPQPos(take, note_start))
        if inline == 1 then reaper.ReaScriptError("Inserting chords does not work with inline editors.") return end
        local desired_octave = math.floor((note_row - root)/12)
        --reaper.ShowConsoleMsg("note pitch: "..note_row.."\n".."desired octave: "..desired_octave.."\n".."cursor position: "..cursor_location.."\n".."note end: "..note_end.." ticks\n".."grid: "..grid.."\n".."note start: "..note_start.."\n".."tick offset: "..tick_offset.."\n")

        if settings[scale_on] == 1 then
            scale_string = GetDefaultScale(name)
            if scale_string == nil then
                --reaper.ShowConsoleMsg("\nDefault Scale not found, searching reascale files\n")
                return
            end
        else
            scale_string = default_scale_notes[1]
        end
        --need to read reapeaks files in user directory to get missing scales.

        local base_note = desired_octave * 12 + root
        local root_index = SearchScale(scale_string, scale_index) - 1
        --reaper.ShowConsoleMsg("root offset = "..root_index.."\n")
        if root_index == -1 then --[[reaper.ShowConsoleMsg("root N/A\n")]] return end
        for i = 0, 2 do
            local note_offset = scale_index + 2 * i
            local wrap = 0
            if note_offset > 7 then 
                note_offset = note_offset - 7 
                wrap = 12 
            end
            local next_index = SearchScale(scale_string, note_offset) - 1 - root_index + wrap
            local note = base_note + root_index + next_index
            --reaper.ShowConsoleMsg("Note: " .. note.."\n")
            reaper.MIDI_InsertNote(take, true, false, note_start+1, note_end-1, settings[def_chan], note, settings[def_vel], false)
        end

        reaper.MIDI_Sort(take)
    end

    
end

Main()
