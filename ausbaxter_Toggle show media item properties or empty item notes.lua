function Exit()

    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    gfx.quit()

end

function Is_OpenProperties()

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do

        item = reaper.GetSelectedMediaItem(0, 0)
        _, chunk = reaper.GetItemStateChunk(item, "", false)
        
        for line in string.gmatch(chunk, "[^\n\r]+") do
            if string.find(line, "^NAME") then 
                return true
            end
        end

    end

    return false

end

function Main()

    OPEN_PROPERTIES = 41589
    OPEN_NOTES = 40850
    
    if reaper.CountSelectedMediaItems(0) == 0 then return end
    
    if Is_OpenProperties() then
        reaper.Main_OnCommand(OPEN_PROPERTIES, 0)
    else
        reaper.Main_OnCommand(OPEN_NOTES, 0)
    end

end

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

reaper.atexit(Exit)

Main()