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

function DrawRect(x,y,w,h,color)
    local r, g, b = reaper.ColorFromNative(color)
    gfx.set(r, g, b, 1, 1)
    gfx.rect(gfx.w * x, gfx.h * y, gfx.w * w, gfx.h * h, 1)
end

function DrawReadout(str)
    local str_w, str_h = gfx.measurestr(str)
    gfx.x = (gfx.w / 2) - (str_w / 2)
    gfx.y = (gfx.h / 2) - (str_h / 2)
    gfx.set(0, 0, 0)
    gfx.drawstr(str)
end

function loop()

    local c = gfx.getchar()

    local retval, cue_on = reaper.GetProjExtState(0, "TalentCue", "Cue")

    if cue_on == "next" then

        rec_buffer_clock:Start()
        
        display_text = "Next Line"
        display_color = reaper.ColorToNative(0, 255, 0)

    elseif cue_on == "redo" then 

        rec_buffer_clock:Start()

        display_text = "Redo Line"
        display_color = reaper.ColorToNative(255, 255, 0)

    end

    if rec_buffer_clock.running == false and rec_buffer_clock.complete then
        display_clock:Start()
        rec_buffer_clock.complete = false
    end

    display_clock:Run()
    rec_buffer_clock:Run()

    if display_clock.running then
        DrawRect(0.1, 0.1, 0.8, 0.8, display_color)
        DrawReadout(display_text)
    else
        DrawRect(0.1, 0.1, 0.8, 0.8, 0)
    end

    reaper.SetProjExtState(0, "TalentCue", "Cue", "")

    if c == 27 or c == -1 then
        gfx.quit()
    else
        reaper.defer(loop)
    end

end

function main()

    reaper.SetProjExtState(0, "TalentCue", "", "") --reset ext state

    width = 600
    height = 500

    gfx.init("Talent Cue", width, height, 0, 0, 0)

    gfx.setfont(1, "Arial", 65)

    display_clock = Clock:New(2)
    rec_buffer_clock = Clock:New(0.75)

    loop()

end

reaper.atexit(function() gfx.quit() end)

main()