width = 600
height = 500
timer = -1
timer_start = 0
hold_length = 2
init = true

function DrawRect(x,y,w,h,r,g,b)
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

function main()

    local c = gfx.getchar()

    local retval, cue_on = reaper.GetProjExtState(0, "TalentCue", "Cue")

    if cue_on ~= "nil" and init then
        timer_start = reaper.time_precise()
        init = false
    end

    timer = reaper.time_precise() - timer_start

    if timer >= 0 and hold_length > timer then
        if cue_on == "next" then
            DrawRect(0.1, 0.1, 0.8, 0.8, 0, 1, 0)
            DrawReadout("Read Next Line")
        elseif cue_on == "redo" then
            DrawRect(0.1, 0.1, 0.8, 0.8, 1, 1, 0)
            DrawReadout("Redo Line")
        end
    else
        DrawRect(0.1, 0.1, 0.8, 0.8, 0, 0, 0)
        cue_on = "nil"
        reaper.SetProjExtState(0, "TalentCue", "Cue", cue_on)
        init = true
    end

    if c ~= 27 then
        reaper.defer(main)
    else
        gfx.quit()
    end

end

reaper.atexit(function() gfx.quit() end)

gfx.init("Talent Cue", 600, 500, 0, 0, 0)

gfx.setfont(1, "Arial", 65)

main()