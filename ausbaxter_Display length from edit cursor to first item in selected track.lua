function main()
    if reaper.CountSelectedTracks(0) > 0 then
        sel_track = reaper.GetSelectedTrack(0, 0)
        _,track_name = reaper.GetTrackName(sel_track, "")
        
        if reaper.CountTrackMediaItems(sel_track) > 0 then
            first_item = reaper.GetTrackMediaItem(sel_track, 0)
            item_start = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
            cursor_position = reaper.GetCursorPosition()
            adjusted_time = reaper.format_timestr(cursor_position - item_start, "")
        else
            adjusted_time = ":("
        end
        
        if prev_time ~= adjusted_time then 
            
            gfx.line(20,45,length - 20,45)
            
            gfx.setfont(1, "Arial", 20)
            gfx.x = 0 gfx.y = 20
            gfx.drawstr(track_name,1, length, 80)
            
            gfx.setfont(1, "Arial", 25)
            gfx.x = 0 gfx. y = 55
            gfx.drawstr(adjusted_time,1, length, 80)
            
            gfx.update() 
        
        end
        
        prev_time = adjusted_time
    end
    
    reaper.defer(main)

end

reaper.atexit(function() gfx.quit() end)

x_pos, y_pos = reaper.GetMousePosition()
length = 400 height = 95
gfx.init("Length from cursor to first item on track",length, height, 0, x_pos - 250, y_pos - 40)

main()
