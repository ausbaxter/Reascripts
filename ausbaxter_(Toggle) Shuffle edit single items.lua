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

function HandleItemMovement()
    
    current_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    current_state = reaper.GetProjectStateChangeCount(0) --used to apply shuffle offset
    t,s,current_edit = reaper.GetItemEditingTime2()
    
    if init == false then
        
        ------------------------Edit states:    0 = no edit   1 = edge edit   2 = fade edit   4 = item move------------------------
        
        if current_edit == 0 and previous_edit == 1 then original_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") end --item edge edit, update original position
        
        if current_edit == 0 and previous_edit == 4 and item == previous_item and current_pos ~= original_pos and reaper.GetToggleCommandState(auto_fade_toggle) == 0 then
        
            reaper.PreventUIRefresh(1)
            reaper.Undo_BeginBlock()
            
            not_moving = true
            new_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            snap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
            offset = new_pos - original_pos
            offset_length = offset + length
            
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", original_pos)
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", offset_length)
            if snap ~= 0 then reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", offset + snap) end --adjust snap offset if set
            reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)
            reaper.ApplyNudge(0,0,4,1,offset,false,0)
            
            reaper.UpdateItemInProject(item)
            new_pos = original_pos
            
            --delete item that would have negative length
            if current_pos + length < original_pos then --delete
            
                reaper.Undo_DoUndo2(0)
                item_idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")
                reaper.Main_OnCommand(deselect_items,0)
                reaper.SetMediaItemInfo_Value(reaper.GetTrackMediaItem(reaper.GetMediaItemTrack(item),item_idx-1), "B_UISEL", 1)
                reaper.Main_OnCommand(remove_item,0)
                
            end
            
            reaper.Undo_EndBlock("Shuffle Item",-1)
            reaper.UpdateArrange()
        end
        
        --allows user to edit item
        if current_pos ~= original_pos and current_state ~= previous_state then
            original_pos = current_pos
        end

    end
    
    previous_item = item
    previous_pos = current_pos
    previous_state = current_state
    previous_edit = current_edit
    
    --init is set to false here as at this point all variables have been initialized
    init = false
    
end

init = true
function main()
   
    win,seg,det = reaper.BR_GetMouseCursorContext()
    
    if det == "item" then
        
        item = reaper.BR_GetMouseCursorContext_Item()
        if prev_item ~= item then
            original_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        end
    
    end
    
    if item ~= nil and reaper.CountSelectedMediaItems(0) == 1 then
        HandleItemMovement()
        prev_item = item
    end
    
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
reaper.Main_OnCommand(ripple_one_track,0)

main()
