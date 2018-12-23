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

local default_scales = {"Major","Natural minor","Melodic minor","Harmonic minor","Pentatonic","Blues"}
local default_scale_notes = {"102034050607","102304056070","102304050067","102304050607","102030040500","100304450070"}

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

--------------------
function ConvertScaleStringToTable(scale_string)

    local t = {}

    for i = 1, #scale_string do
        local d = tonumber(scale_string:sub(i,i))
        table.insert(t, d)
    end

    return t

end

function IndexWrap(idx, table)
    if idx % #table == 0 then 
        return #table
    elseif idx > 0 then
        return idx % #table
    elseif idx <= 0 then
        return #table - math.abs(idx)
    end
end

function GetScaleDegree(note, scale) --scale is table of nums

    function LookForDegreeAhead(start, distance, table)
        for i = start, distance - 1 do
            local v = table[IndexWrap(i, table)]
            if v ~= 0 then
                return v, i - start
            end
        end
    end

    local degree
    local new_note_base = note
    local adj_note = (note % 12) + 1
    local last_deg = -1
    local last_deg_position = 0
    local last_deg_distance = 0
    local scale_map = {}

    if scale[adj_note] ~= 0 then degree = scale[adj_note] end

    for n, d in ipairs(scale) do
        
        if not degree then

            if n < adj_note 
            and d ~= 0 then
                last_deg_position = n
                last_deg = d
            end

            if adj_note == n
            and d == 0 then

                last_deg_distance = adj_note - last_deg_position
                degree, fwd_deg_distance = LookForDegreeAhead(n, last_deg_distance, scale)
                
                if not degree then 
                    degree = last_deg
                    new_note_base = note - last_deg_distance
                else
                    new_note_base = note + fwd_deg_distance
                end

            end

        end

        if d ~= 0 then scale_map[d] = n - 1 end

    end
    -- reaper.ShowConsoleMsg("Incoming Note: " .. note .. "\n" ..
    -- "Outgoing Note: " .. new_note_base .. "\n" ..
    -- "Scale Degree: " .. degree .. "\n")
    return degree, new_note_base, scale_map

end

--------------------
function GetMidiEditorCursorContext(take, root)
    local _, inline, note_row = reaper.BR_GetMouseCursorContext_MIDI()
    if inline == 1 then reaper.ReaScriptError("Inserting chords does not work with inline editors.") return end

    local grid_setting, swing, note_size = reaper.MIDI_GetGrid(take) --0 if following grid size
    
    --item position obeys grid (clean up later)
    local mouse = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
    local grid_edge = reaper.MIDI_GetPPQPosFromProjQN(take, grid_setting + reaper.MIDI_GetProjQNFromPPQPos(take, mouse))
    local measure_start = reaper.MIDI_GetPPQPos_StartOfMeasure(take, mouse)
    local tick_offset = grid_edge - mouse
    local note_start = math.floor((mouse - measure_start) / tick_offset) * tick_offset + measure_start
    local note_end = reaper.MIDI_GetPPQPosFromProjQN(take, grid_setting + reaper.MIDI_GetProjQNFromPPQPos(take, note_start))
    local desired_octave = math.floor((note_row - root)/12)
    local note = note_row % 12

    --reaper.ShowConsoleMsg("note pitch: "..note_row.."\n".."desired octave: "..desired_octave.."\n".."cursor position: "..mouse.."\n".."note end: "..note_end.." ticks\n".."grid: "..grid_setting.."\n".."note start: "..note_start.."\n".."tick offset: "..tick_offset.."\n")
    return note_row, note_start, note_end
end

function DeselectMidiNotes(take)
    i = 0
    while(true) do
        local retval, selected, muted, start_pos, end_pos, chan, pitch, vel =  reaper.MIDI_GetNote(take, i)
        if not retval then break end
        reaper.MIDI_SetNote(take, i, false, muted, start_pos, end_pos, chan, pitch, vel, false)
        i = i + 1
    end
end

function GetScaleFromFile(file_path, name_match)
    io.input(file_path)
    while true do
        local line = io.read()
        if line == nil then break end
        local found_name, scale_string = line:match("0%s+\"([%w%d%s]+)\"%s+(%d+)")
        if found_name ~= nil then 
            if name_match == found_name then
                reaper.ShowConsoleMsg("found: \"".. tostring(found_name) .. "\"\tmatch: \"" .. name_match .. "\"\nString: " .. scale_string .. "\n")
                return true, scale_string
            end
        end
    end
    return false, nil
end

function SearchDirectoryForScale(path, name) --path will be created for both mac and windows systems separately outside this function
    local i = 0
    while(true) do
        local folder = reaper.EnumerateSubdirectories(path, i)
        if folder == nil then break end
        local j = 0
        --reaper.ShowConsoleMsg(path .. folder.."\n")
        while(true) do
            local file = reaper.EnumerateFiles(tostring(path .. folder), j)
            if file == nil then break 
            elseif string.find(file, "reascale") ~= nil then
                --reaper.ShowConsoleMsg("Reascale file found in: " .. path .. folder .. "\nFile: " .. file .. "\n")
                local retval, temp_string = GetScaleFromFile(tostring(path..folder..file), name)
                if retval then return temp_string end
            end
            j = j + 1
        end
        i = i + 1
    end

    local k = 0
    while(true) do
        local file = reaper.EnumerateFiles(path, k)
        if file == nil then break
        elseif string.find(file, "reascale") ~= nil then
            --reaper.ShowConsoleMsg("Reascale file found in: " .. path .. "\nFile: " .. file .. "\n" .. string.find(file, "reascale"))
            local retval, temp_string = GetScaleFromFile(tostring(path..file), name)
            if retval then return temp_string end
        end
        k = k + 1
    end
    return nil
end

--deselect all notes function.

function Main()
    local editor = reaper.MIDIEditor_GetActive()
    local take = reaper.MIDIEditor_GetTake(editor)
    local snap = reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")
    local def_vel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_vel")
    local def_chan = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
    local def_len = reaper.MIDIEditor_GetSetting_int(editor, "default_note_len")
    local scale_on = reaper.MIDIEditor_GetSetting_int(editor, "scale_enabled")
    local _, root, _, name = reaper.MIDI_GetScale(take, 0, 0, 0)
    local scale_degree = 1

    --reaper.ShowConsoleMsg("root: "..root.."\tscale: "..scale.."\tname: "..name.."\n")

    cc_window, cc_segment = reaper.BR_GetMouseCursorContext()
    if cc_window == "midi_editor" and cc_segment == "notes" then
        
        note_row, note_on, note_off = GetMidiEditorCursorContext(take, root)

        if scale_on == 1 then
            scale_string = GetDefaultScale(name)
            if scale_string == nil then
                local os = reaper.GetOS()
                if os == "Win64" then
                    --reaper.GetResourcePath() instead
                    path = "C:\\Users\\ausba\\AppData\\Roaming\\REAPER\\Data\\"
                    scale_string = SearchDirectoryForScale(path, name)
                    if scale_string == nil then reaper.ReaScriptError("No matching scale. These actions do not work when key snap to chords") return end

                elseif os == "OSX64" then
                    reaper.ShowConsoleMsg("No scale found... looking for osx scale path\n")
                end

            end
        else
            scale_string = default_scale_notes[1]
        end
        --need to read reascale files in user directory to get missing scales.

        scale_table = ConvertScaleStringToTable(scale_string)

        scale_degree, base_note, scale_degree_map = GetScaleDegree(note_row, scale_table)

        DeselectMidiNotes(take)

        num_notes = 4

        ignore = {}
        ignore[0] = true

        offset = scale_degree_map[IndexWrap(scale_degree,scale_degree_map)]

        note_num = 1
        for i = scale_degree, scale_degree + (num_notes-1) * 2, 2 do
            local scale = math.floor((i-1)/#scale_degree_map)
            local index = IndexWrap(i,scale_degree_map)
            if ignore[note_num] == nil then
                local note = base_note + scale_degree_map[index] - offset + (12 * scale)
                reaper.MIDI_InsertNote(take, true, false, note_on, note_off-1, def_chan, note, def_vel, false)
            end
            note_num = note_num + 1
        end
        
        reaper.MIDI_Sort(take)
    end

    
end

Main()
