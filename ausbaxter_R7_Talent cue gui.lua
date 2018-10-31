--Color Presets
white = {255, 255, 255, 255}
red = {255, 0, 0, 255}
yellow = {255, 255, 0, 255}
black = {0, 0, 0, 255}
green = {0, 128, 0, 255}

Clock = {}
Clock.__index = Clock

function Clock:New(duration)
    local self = setmetatable({},Clock)
    self.running = false
    self.complete = false
    self.duration = duration
    self.start_time = -1
    self.current_time = -1
    return self
end

function Clock:Start()
    if self.running == false then 
        self.start_time = reaper.time_precise()
        self.running = true
        self.complete = false
    end
end

function Clock:Run()
    if self.running then
        self.current_time = reaper.time_precise()
        if self.current_time - self.start_time > self.duration then
            self.running = false
            self.complete = true
            self.start_time = -1
            self.current_time = -1
        end
    end
end

function Clock:Stop()
    if self.running then
        self.running = false
        self.complete = true
        self.start_time = -1
        self.current_time = -1  
    end
end

function DrawRect(x,y,w,h,color, fill, round)
    local r, g, b = reaper.ColorFromNative(color)
    gfx.set(r, g, b, 1, 1)
    if round then
        gfx.roundrect(gfx.w * x, gfx.h * y, gfx.w * w, gfx.h * h, 50, 1)
    else
        gfx.rect(gfx.w * x, gfx.h * y, gfx.w * w, gfx.h * h, fill)
    end
end

function GetLineFromRegion(cur_pos)
    local n_mrks, n_rgns = reaper.CountProjectMarkers(0)

    for i = 0, n_mrks + n_rgns do
        local retval, is_rgn, r_pos, r_end, r_line, r_idx = reaper.EnumProjectMarkers(i)
        if cur_pos >= r_pos and cur_pos < r_end then
            return r_line
        end
    end

    local r_val, question = reaper.GetProjExtState(0, "TalentLineDisplay", "FFQuestion")
    --reaper.ShowConsoleMsg(tostring(question).."\n")
    if r_val then
        return question
    end

    return ""
end

function GetLineFromExtState()
    local r_val, line = reaper.GetProjExtState(0, "TalentLineDisplay", "LineDisplay")
    local override, o_line = reaper.GetProjExtState(0, "TalentLineDisplay", "FreeLineDisplay")
    if o_line ~= "" then
        return o_line
    elseif r_val then
        return line
    end
    return ""
end

function MeasureString(str, margin)
    local str_measure = margin
    local word_location = 0
    local wrap_string = ""
    local sep_table = {}
    local wrap_count = 0
    for i = 1, #str do
        local c = string.sub(str, i, i)

        str_measure = str_measure + gfx.measurechar(string.byte(c))

        if c == " " then
            word_location = i
        end

        if str_measure >= gfx.w - margin then
            table.insert(sep_table, word_location)
            wrap_count = wrap_count + 1

            str_measure = gfx.measurechar(string.byte(" ")) * wrap_count

            if wrap_count > 0 then
                for k = word_location, i do
                    local n = string.sub(str, k, k)
                    str_measure = str_measure + gfx.measurechar(string.byte(n))
                end
            end
            
            word_location = 0
            
        end

    end

    return sep_table
end

function GenerateWordWrap(str, sep_table)
    if #sep_table == 0 then return {str}
    else
        local t = {}
        local last_idx = 0
        for i, idx in ipairs(sep_table) do
            if i == 1 then
                table.insert(t, string.sub(str,1,idx))
            else
                table.insert(t, string.sub(str,sep_table[i-1]+1,idx))
            end
            last_idx = idx
        end
        table.insert(t, string.sub(str,last_idx+1))
        return t
    end
end

function SetColor(col)
  -- If we're given a table of color values, just pass it right along
  if type(col) == "table" then
    gfx.set(col[1], col[2], col[3], col[4] or 1)
  end     
end

function DrawDialog(str, margin) --take table

    function GetWrappedWidth(str)
        local max_w = 0
        local max_h = 0
        for i, s in ipairs(str) do
            local str_w, str_h = gfx.measurestr(str[1])
            if str_w > max_w then max_w = str_w end
            if str_h > max_h then max_h = str_h end
        end
        return max_w, max_h
    end

    if str == nil then return end
    gfx.setfont(1)
    gfx.set(255, 255, 255)
    if #str == 1 then
        local str_w, str_h = gfx.measurestr(str[1])
        gfx.x = (gfx.w / 2) - (str_w / 2)
        gfx.y = (gfx.h / 2) - (str_h * #str / 2)
        gfx.drawstr(str[1])
    else
        for i, line in ipairs(str) do
            local str_w, str_h = gfx.measurestr(line)
            gfx.x = (gfx.w / 2) - (str_w / 2)
            gfx.y = (gfx.h / 2) - (str_h * #str / 2) + (str_h * (i-1))
            gfx.drawstr(line)
        end 
    end
end

function NormalizeRGB(r,g,b)
    return r/255, g/255, b/255
end

function DrawReadout(str, color)
    local str_w, str_h = gfx.measurestr(str)
    gfx.setfont(1)
    gfx.x = (gfx.w / 2) - (str_w / 2)
    gfx.y = (gfx.h * 0.1) - (str_h / 2)
    SetColor(yellow)
    gfx.drawstr(str)
end

function OnRecord(play_state)
    --reaper.ShowConsoleMsg("PS: " .. play_state .. "\t" .. tostring(last_state) .. "\n")
    
    if last_state ~= nil and play_state ~= last_state and play_state == 5 then
        last_state = play_state
        return true
    end

    last_state = play_state
    return false
end

function DisplayStopLight(count_down, str)
    local color_map = {yellow, yellow, red}
    SetColor(color_map[count_down])
    gfx.setfont(2)
    if count_down == 0 then
        local str_w, str_h = gfx.measurestr(str)
        SetColor(green)
        gfx.x = (gfx.w) / 2 - (str_w / 2)
        gfx.y = (gfx.h * 0.2) - (str_h / 2)
        gfx.drawstr(str)
    else
        local str_w, str_h = gfx.measurestr(count_down)
        gfx.x = (gfx.w) / 2 - (str_w / 2)
        gfx.y = (gfx.h * 0.2) - (str_h / 2)
        gfx.drawstr(count_down)
    end
    gfx.setfont(1)
end

local init = true
function loop()

    local c = gfx.getchar()
    local cur_pos = reaper.GetCursorPosition()
    local play_state = reaper.GetPlayState()

    --if prev_cur_pos ~= cur_pos or init or gfx.w ~= prev_width then
        --text = GetLineFromRegion(cur_pos)
        text = GetLineFromExtState()
        sep_table, line_height = MeasureString(text, margin)
        dialog = GenerateWordWrap(text, sep_table)
        init = false
    --end

    local retval, cue_on = reaper.GetProjExtState(0, "TalentCue", "Cue")

    if cue_on == "next" or OnRecord(play_state) then -- cue_on ~= "" use "read" and "redo" itself

        display_line = false
        redo = false
        display_clock:Stop()
        rec_buffer_clock:Start()
        count_down = 4
        display_text = "Go!"
        display_color = reaper.ColorToNative(0, 255, 0)

    elseif cue_on == "redo" then

        count_down = 4
        display_line = false
        display_clock:Stop()
        rec_buffer_clock:Start()
        redo = true

        display_text = "Go!"
        display_color = reaper.ColorToNative(255, 255, 0)

    end

    if rec_buffer_clock.running == false and rec_buffer_clock.complete then
        display_line = true
        rec_buffer_clock.complete = false
        count_down = count_down - 1
        if count_down >= 0 then
            rec_buffer_clock:Start()
        else
            count_down = 0
        end
    end

    display_clock:Run()
    rec_buffer_clock:Run()

    if play_state == 0 then display_line = false redo = false end

    DrawDialog(dialog, margin)

    if display_line and dialog[1] ~= "" then
        DisplayStopLight(count_down, display_text)
        if redo and count_down > 0 then DrawReadout("redo in:") end
    else
        DrawRect(0.1, 0.1, 0.8, 0.8, 0, 1)
    end

    reaper.SetProjExtState(0, "TalentCue", "Cue", "")

    prev_cur_pos = cur_pos
    prev_width = gfx.w

    gfx.update()

    if c == 27 or c == -1 then
        gfx.quit()
    else
        reaper.defer(loop)
    end

end

function main()

    reaper.SetProjExtState(0, "TalentCue", "", "") --reset ext state

    x = 1080
    y = 0

    width = 800
    height = 1000
    
    margin = 60
    count_down = 4

    gfx.init("Talent Cue", width, height, 0, x, y)

    gfx.setfont(1, "Arial", 40)
    gfx.setfont(2, "Arial", 100)

    display_clock = Clock:New(2)
    rec_buffer_clock = Clock:New(1)

    loop()

end

reaper.atexit(function()
    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    gfx.quit() 
end)

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

main()
