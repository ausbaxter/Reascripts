disc = "This action will fill the gaps of your currently selected items using the clipboard. "
    .. "If the desired item, or item area is not in the clipboard click cancel and copy the desired fill item first."
disc_title = "Fill gaps in selected media items"

function main()
    
    if reaper.ShowMessageBox(disc, disc_title, 1) == 2 then return end
    
    num_items = reaper.CountSelectedMediaItems(0)
    item_table = {}
    cursor_pos = reaper.GetCursorPosition()
    prev_end = 0
    trim_toggle_state = reaper.GetToggleCommandState(41117)
    
    if num_items < 1 then reaper.ReaScriptError("No items selected") return end
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    if trim_toggle_state == 1 then
        reaper.Main_OnCommand(41117,0)
    end
    
    for i = 0, num_items - 1 do
        table.insert(item_table, reaper.GetSelectedMediaItem(0, i))
    end
    
    for i = 1, #item_table do
    
        local item = item_table[i]
        i_track = reaper.GetMediaItemTrack(item)
        i_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        i_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        i_end = i_start + i_length
        
        i_fadein_len = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        i_fadein_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
        
        s_length = i_start - prev_end
        
        if i ~= 1 and prev_end < i_start then
            paste_start = prev_end - prev_fadeout_len
            paste_length = s_length + prev_fadeout_len + i_fadein_len
            reaper.SetEditCurPos(paste_start, false, false)
            
            --ensure paste is occuring on correct track track
            reaper.Main_OnCommand(40297,0)
            reaper.SetMediaTrackInfo_Value(i_track, "I_SELECTED", 1)
            
            reaper.Main_OnCommand(40058,0) --paste
            
            rt_item = reaper.GetSelectedMediaItem(0,0)
            reaper.SetMediaItemInfo_Value(rt_item, "C_FADEINSHAPE", 3)
            reaper.SetMediaItemInfo_Value(rt_item, "D_FADEINLEN", prev_fadeout_len)
            reaper.SetMediaItemInfo_Value(rt_item, "D_FADEOUTLEN", i_fadein_len)
            reaper.SetMediaItemInfo_Value(rt_item, "C_FADEOUTSHAPE", 3)
            reaper.SetMediaItemInfo_Value(rt_item, "B_LOOPSRC", 3)
            reaper.SetMediaItemInfo_Value(rt_item, "D_LENGTH", paste_length)
            reaper.SetMediaItemInfo_Value(prev_item, "C_FADEOUTSHAPE", 2)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", 2)
            reaper.ApplyNudge(0, 0, 4, 1, paste_length, true, 0)
        end
        
        
        prev_fadeout_len = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        prev_fadeout_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
        prev_item = item
        prev_end = i_end
    end
    
    if trim_toggle_state == 1 then
        reaper.Main_OnCommand(41117,0)
    end
    
    reaper.SetEditCurPos(cursor_pos, true, false) --restore previous edit cursor position
    
    reaper.Undo_EndBlock("Room Tone Edit", 0)
    reaper.UpdateArrange()

end

main()
