------------------------------------------------------Config Area---------------------------------------------------------------------

--bank of toggle buttons that will be treated exclusively.
--index is the numerical index of the toggle, duplicate script and increment this variable to increase the amount of toggles in a bank

exclusive_toggle_bank = 1           exclusive_toggle_index = 7

--------------------------------------------------------------------------------------------------------------------------------------

ext_state_name = "ausbaxter_MoreExclusiveToggles_Bank_" .. exclusive_toggle_bank

function Msg(str)
  reaper.ShowConsoleMsg(tostring(str).."\n")
end

function GetPESToggles()
    local state_idx = 0
    toggles = {}
    local retval = true
    
    while retval == true do --fix this loop it is not elegant, will do n + 1
      retval, toggle_idx, id = reaper.EnumProjExtState(0, ext_state_name, state_idx)
      if retval then 
          local s_tog = {idx = toggle_idx, cmd = id}
          table.insert(toggles, s_tog)
      end
          state_idx = state_idx + 1
    end
    return toggles
end

function EnsureOtherTogglesOff(sectionID, cmdID)

    local toggles = GetPESToggles()
    
    for i = 1, #toggles do
        if toggles[i]["idx"] ~= tostring(exclusive_toggle_index) then
            reaper.SetToggleCommandState(sectionID, toggles[i]["cmd"], 0)
            reaper.RefreshToolbar2(sectionID, toggles[i]["cmd"])
        end
    end
    
end

function Main()

    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    
    if reaper.GetToggleCommandState(cmdID)==0 or reaper.GetToggleCommandState(cmdID) == -1 then
        
        local retval = reaper.SetToggleCommandState(sectionID, cmdID, 1)
        if retval then 
            reaper.SetProjExtState(0, ext_state_name, tostring(exclusive_toggle_index), cmdID)
            EnsureOtherTogglesOff(sectionID,cmdID)
        else reaper.ReaScriptError("Something went wrong, unable to toggle command " .. cmdID .. " from file : " .. filename) end
        
        reaper.RefreshToolbar2(sectionID, cmdID)
        
    end

end

Main()
