function main()

    reaper.Undo_BeginBlock()

    local zm_in = 1012
    local zm_on_cursor = reaper.NamedCommandLookup("_WOL_SETHZOOMC_EDITPLAYCUR")
    local zm_center = reaper.NamedCommandLookup("_WOL_SETHZOOMC_CENTERVIEW")

    local arr_start, arr_end = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local cur_loc = reaper.GetCursorPosition()

    if cur_loc >= arr_start and cur_loc <= arr_end then

        reaper.Main_OnCommand(zm_on_cursor, 0)
        reaper.Main_OnCommand(zm_in, 0)

    else
        
        reaper.Main_OnCommand(zm_center, 0)
        reaper.Main_OnCommand(zm_in, 0)

    end

    reaper.Undo_EndBlock("PT style zoom in", 2)

end

main()