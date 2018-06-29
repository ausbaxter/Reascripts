function Show_Hide_Fx(is_show, take, fx_count)

  for i=0, fx_count - 1 do
  
    if is_show then
      if reaper.TakeFX_GetEnabled(take, i) then
        reaper.TakeFX_Show(take, i, 3)
      end
      
    elseif not is_show then
      reaper.TakeFX_Show(take, i, 2)
    end
    
  end
  
end

function OpenFXWindows(take, fx_count)

  for i=0, fx_count - 1 do if reaper.TakeFX_GetOpen(take, i) then 
    return true end 
  end
  
  return false

end

function AllFXWindowsOpen(take, fx_count)

  for i=0, fx_count - 1 do
    if reaper.TakeFX_GetEnabled(take, i) then
      if not reaper.TakeFX_GetOpen(take, i)  --[[or fx_count == 1]] then return false end
    end
  end
  
  return true

end

function CloseAllFloatingTakeFX()
  for i = 0, reaper.CountMediaItems(0) - 1 do
      local item = reaper.GetMediaItem(0, i)
      for j = 0, reaper.GetMediaItemNumTakes(item) - 1 do
          local take = reaper.GetTake(item, j)
          local fx_count = reaper.TakeFX_GetCount(take)
          if fx_count > 0 then 
              for k = 0, fx_count - 1 do
                  reaper.TakeFX_Show(take, k, 2)
              end
          end
      end
  end
end

function FloatFX(take, fx_count)

  Show_Hide_Fx(true, take, fx_count)
  curr_take_id = reaper.BR_GetMediaItemTakeGUID(take)
  reaper.SetProjExtState(0, "ausbaxter_float_fx", "previous_take", curr_take_id)
  reaper.SetProjExtState(0, "ausbaxter_float_fx", "take_is_floating", "true")

end

function Main()

  if reaper.CountSelectedMediaItems(0) == 1 then
    local item = reaper.GetSelectedMediaItem(0,0)
    local take_idx = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
    local take = reaper.GetTake(item, take_idx)
    local fx_count = reaper.TakeFX_GetCount(take)
    local chain_open = reaper.TakeFX_GetChainVisible(take)
    
    if fx_count > 0 then
    
      local retval, is_floating = reaper.GetProjExtState(0, "ausbaxter_float_fx", "take_is_floating")
      
      if is_floating == "true" then --need to unfloat fx
      
        --check if there are any floating fx on last track??? if there arent float track
        retval, prev_take_id = reaper.GetProjExtState(0, "ausbaxter_float_fx", "previous_take")
        prev_take = reaper.GetMediaItemTakeByGUID(0, prev_take_id)
        
        --handles if prev track was deleted before script call
        if prev_take == nil then
            reaper.SetProjExtState(0, "ausbaxter_float_fx", "previous_take", "")
            reaper.SetProjExtState(0, "ausbaxter_float_fx", "take_is_floating", "false")
            Main()
            return
        end
        
        prev_fx_count = reaper.TakeFX_GetCount(prev_take)
        
        if OpenFXWindows(prev_take, prev_fx_count) then
        
          Show_Hide_Fx(false, prev_take, prev_fx_count)
          reaper.SetProjExtState(0, "ausbaxter_float_fx", "take_is_floating", "false")
          
          if take ~= prev_take then
            FloatFX(take, fx_count)    
          end
        
        else
          FloatFX(take, fx_count)
        end    
      
      elseif is_floating == "false" or is_floating == "" then --need to float fx
      
        if AllFXWindowsOpen(take, fx_count) then
          Show_Hide_Fx(false, take, fx_count)
          reaper.SetProjExtState(0, "ausbaxter_float_fx", "take_is_floating", "false")
      
        else
          FloatFX(take, fx_count)
          if chain_open == -2 or chain_open >= 0 then
              reaper.TakeFX_Show(take, 0, 0)
          end
        end
        
      end
      
    else
      --make sure any open fx are closed when executed on a take containing 0 fx (need unfloat take fx function)
      CloseAllFloatingTakeFX()
     
    end
  else
  --make sure that any open fx are closed when executed with no take selection (need unfloat take fx)
  CloseAllFloatingTakeFX()
  
  end
end

Main()
