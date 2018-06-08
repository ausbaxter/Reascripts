function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

function main()

    is_new_value, name, sec, cmd, mode, res, val = reaper.get_action_context()
    msg(name .. " " .. sec .. " " .. cmd .. " " .. mode .. " " ..res .. " " ..val)
    reaper.defer(main)
    gfx.update()
end


gfx.init()

-------------------------------------------------------------------------------------
function exit() gfx.quit() end
reaper.atexit(exit)

main()
