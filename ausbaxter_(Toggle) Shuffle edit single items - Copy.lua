--@description Toggle shuffle editing for single items
--@version 1.0
--@author ausbaxter
--@about
--    # Toggle shuffle editing for single items
--
--    This package provides a togglable action allowing pro tools style shuffle editing (ripple + edge edit)
--@provides
--    do i need this?
--@changelog
--  + Initial release

reverse_ripple = false

--When Calculating reverse ripple (may apply to normal as well) idx is not reliable way of getting correct items. User can move item over previous item boundaries and will

--Main_OnCommand stuff
ripple_all_tracks_check = reaper.GetToggleCommandState(40311)
ripple_one_track_check = reaper.GetToggleCommandState(40310)
auto_fade_toggle = 40041
auto_cross_fade_check = reaper.GetToggleCommandState(auto_fade_toggle)
auto_cross_fade_off = 41119
auto_cross_fade_on = 41118
ripple_one_track = 40310
ripple_all_tracks = 40311
ripple_off = 40309
remove_item = 40006
deselect_items = 40289

function msg(m) reaper.ShowConsoleMsg(tostring(m)) end

function HandleItemMovement()
        
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    
    mu_item = reaper.BR_GetMediaItemByGUID(0, gui_id)
    new_pos = reaper.GetMediaItemInfo_Value(mu_item, "D_POSITION")
    length = reaper.GetMediaItemInfo_Value(mu_item, "D_LENGTH")
    snap = reaper.GetMediaItemInfo_Value(mu_item, "D_SNAPOFFSET")
    offset = new_pos - original_pos
    offset_length = offset + length

    if reverse_ripple then

        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length - offset)

        if offset < 0 then
            for i = 1, #rr_item_table do
                shuff_item = rr_item_table[i]
                if shuff_item ~= item then
                    reaper.SetMediaItemInfo_Value(shuff_item, "D_POSITION", reaper.GetMediaItemInfo_Value(shuff_item,"D_POSITION") + offset)
                end
            end
        else
            if original_pos + length < new_pos then --delete (when deleting, should adjust fades to a desired setting
                
                f_in = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
                reaper.Main_OnCommand(remove_item,0)
                offset = length - f_in
                
            end
                
            for i = #rr_item_table, 1, -1 do
                shuff_item = rr_item_table[i]
                if shuff_item ~= item then
                    reaper.SetMediaItemInfo_Value(shuff_item, "D_POSITION", reaper.GetMediaItemInfo_Value(shuff_item,"D_POSITION") + offset)
                end
            end
            
        end             

    else

        reaper.SetMediaItemInfo_Value(mu_item, "D_POSITION", original_pos)
        reaper.SetMediaItemInfo_Value(mu_item, "D_LENGTH", offset_length)
        if snap ~= 0 then reaper.SetMediaItemInfo_Value(mu_item, "D_SNAPOFFSET", offset + snap) end --adjust snap offset if set
        reaper.SetMediaItemInfo_Value(mu_item, "B_LOOPSRC", 1)
        reaper.ApplyNudge(0,0,4,1,offset,false,0)
        
        if new_pos + length < original_pos then --delete
            reaper.Undo_DoUndo2(0)
            reaper.Main_OnCommand(deselect_items,0)
            reaper.SetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,idx), "B_UISEL", 1)
            reaper.Main_OnCommand(remove_item,0)
        end

    end

    reaper.Undo_EndBlock("Shuffle Item",-1)
    reaper.UpdateArrange()
    
end

--[[function GetAllItems()
    for i = 0, reaper.CountItems()
end]]

function main()
   
    ------------------------Edit states:    0 = no edit   1 = edge edit   2 = fade edit   4 = item move------------------------
    t,s,current_edit = reaper.GetItemEditingTime2()
    
    if current_edit == 4 and prev_edit == 0 then
        item = reaper.GetSelectedMediaItem(0,0)
        gui_id = reaper.BR_GetMediaItemGUID(item)
        original_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
        track = reaper.GetMediaItemTrack(item)
        if reverse_ripple then 
            --store earlier items
            rr_item_table = {}
            for i = 0, idx do
                local r_item = reaper.GetTrackMediaItem(track, i)
                table.insert(rr_item_table, r_item)
            end 
        end --check this item when reverse ripple
    
    elseif current_edit == 0 and prev_edit == 4 then
    
        HandleItemMovement()
    
    end
    
    prev_edit = current_edit
    
    reaper.defer(main)
end

--don't force ripple state when script is toggled off
function RestoreRippleState()
    local cmd_id
    if ripple_all_tracks_check == 1 then cmd_id = ripple_all_tracks
    elseif ripple_one_track_check == 1 then cmd_id = ripple_one_track
    elseif ripple_all_tracks_check == 0 and ripple_one_track_check == 0 then cmd_id = ripple_off end
    
    reaper.Main_OnCommand(cmd_id, 0)
end

function RestoreAutoFades()
    if auto_cross_fade_check == 1 then reaper.Main_OnCommand(auto_cross_fade_on,0)
    else reaper.Main_OnCommand(auto_cross_fade_off,0) end
end

--ran when toggle is off
function exitnow()

    RestoreRippleState()
    RestoreAutoFades()
    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    gfx.quit()

end

reaper.atexit(exitnow)

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

reaper.Main_OnCommand(auto_cross_fade_off,0)
if reverse_ripple then reaper.Main_OnCommand(ripple_off,0)
else reaper.Main_OnCommand(ripple_one_track,0) end

main()
