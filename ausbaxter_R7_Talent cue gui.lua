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

function GetLine(cur_pos)
    local n_mrks, n_rgns = reaper.CountProjectMarkers(0)

    for i = 0, n_mrks + n_rgns do
        local retval, is_rgn, r_pos, r_end, r_line, r_idx = reaper.EnumProjectMarkers(i)
        if cur_pos >= r_pos and cur_pos < r_end then
            return r_line
        end
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

function DrawDialog(str, margin) --take table
    if str == nil then return end
    local str_w, str_h = gfx.measurestr(str[1])
    gfx.set(255, 255, 255)
    if #str == 1 then
        gfx.x = (gfx.w / 2) - (str_w / 2)
        gfx.y = margin
        gfx.drawstr(str[1])
    else
        for i, line in ipairs(str) do
            gfx.x = margin
            gfx.y = margin + (str_h * (i-1))
            gfx.drawstr(line)
        end
    end
end

function DrawReadout(str)
    local str_w, str_h = gfx.measurestr(str)
    gfx.x = (gfx.w / 2) - (str_w / 2)
    gfx.y = (gfx.h * 0.81) - (str_h / 2)
    gfx.set(0, 0, 0)
    gfx.drawstr(str)
end

local init = true
function loop()

    local c = gfx.getchar()
    local cur_pos = reaper.GetCursorPosition()

    DrawRect(0.02, 0.05, 0.96, 0.6, reaper.ColorToNative(255, 255, 255), 0, true)

    if prev_cur_pos ~= cur_pos or init or gfx.w ~= prev_width then
        region_text = GetLine(cur_pos)
        local sep_table = MeasureString(region_text, margin)
        dialog = GenerateWordWrap(region_text, sep_table)
        init = false
    end

    local retval, cue_on = reaper.GetProjExtState(0, "TalentCue", "Cue")

    if cue_on == "next" then

        display_clock:Stop()
        rec_buffer_clock:Start()
        
        display_text = "Read"
        display_color = reaper.ColorToNative(0, 255, 0)

    elseif cue_on == "redo" then 

        display_clock:Stop()
        rec_buffer_clock:Start()

        display_text = "Redo"
        display_color = reaper.ColorToNative(255, 255, 0)

    end

    if rec_buffer_clock.running == false and rec_buffer_clock.complete then
        display_clock:Start()
        rec_buffer_clock.complete = false
    end

    display_clock:Run()
    rec_buffer_clock:Run()

    DrawDialog(dialog, margin)

    if display_clock.running then
        DrawRect(0, 0.71, 1, 0.2, display_color, 1)
        DrawReadout(display_text)
    else
        DrawRect(0.1, 0.1, 0.8, 0.8, 0, 1)
    end

    reaper.SetProjExtState(0, "TalentCue", "Cue", "")

    prev_cur_pos = cur_pos
    prev_width = gfx.w

    if c == 27 or c == -1 then
        gfx.quit()
    else
        reaper.defer(loop)
    end

end

function main()

    reaper.SetProjExtState(0, "TalentCue", "", "") --reset ext state

    width = 1600
    height = 500
    margin = 60

    gfx.init("Talent Cue", width, height, 0, 0, 0)

    gfx.setfont(1, "Arial", 70)

    display_clock = Clock:New(2)
    rec_buffer_clock = Clock:New(0.75)

    loop()

end

reaper.atexit(function() gfx.quit() end)

main()