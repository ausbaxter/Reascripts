function Show_Hide_Fx(is_show, track, fx_count)

  for i=0, fx_count - 1 do
  
    if is_show then
      if reaper.TrackFX_GetEnabled(track, i) then
        reaper.TrackFX_Show(track, i, 3)
      end
      
    elseif not is_show then
      reaper.TrackFX_Show(track, i, 2)
    end
    
  end
  
end

function OpenFXWindows(track, fx_count)

  for i=0, fx_count - 1 do if reaper.TrackFX_GetOpen(track, i) then 
    return true end 
  end
  
  return false

end

function AllFXWindowsOpen(track, fx_count)

  for i=0, fx_count - 1 do
    if reaper.TrackFX_GetEnabled(track, i) then
      if not reaper.TrackFX_GetOpen(track, i) or fx_count == 1 then return false end
    end
  end
  
  return true

end

function FloatFX(track, fx_count)

  Show_Hide_Fx(true, track, fx_count)
  curr_track_id = reaper.BR_GetMediaTrackGUID(track)
  reaper.SetProjExtState(0, "ausbaxter_float_fx", "previous_track", curr_track_id)
  reaper.SetProjExtState(0, "ausbaxter_float_fx", "is_floating", "true")

end

function Main()

  if reaper.CountSelectedTracks(0) == 1 then

    track = reaper.GetSelectedTrack(0,0)
    fx_count = reaper.TrackFX_GetCount(track)
    chain_open = reaper.TrackFX_GetChainVisible(track)
    
    if fx_count > 0 then
    
      retval, is_floating = reaper.GetProjExtState(0, "ausbaxter_float_fx", "is_floating")
      
      if is_floating == "true" then --need to unfloat fx
      
        --check if there are any floating fx on last track??? if there arent float track
        retval, prev_track_id = reaper.GetProjExtState(0, "ausbaxter_float_fx", "previous_track")
        prev_track = reaper.BR_GetMediaTrackByGUID(0, prev_track_id)
        
        --handles if prev track was deleted before script call
        if prev_track == nil then
            reaper.SetProjExtState(0, "ausbaxter_float_fx", "previous_track", "")
            reaper.SetProjExtState(0, "ausbaxter_float_fx", "is_floating", "false")
            Main()
            return
        end
        
        prev_fx_count = reaper.TrackFX_GetCount(prev_track)
        
        if OpenFXWindows(prev_track, prev_fx_count) then
        
          Show_Hide_Fx(false, prev_track, prev_fx_count)
          reaper.SetProjExtState(0, "ausbaxter_float_fx", "is_floating", "false")
          
          if track ~= prev_track then
            FloatFX(track, fx_count)    
          end
        
        else
          FloatFX(track, fx_count)
        end    
      
      elseif is_floating == "false" or is_floating == "" then --need to float fx
      
        if AllFXWindowsOpen(track, fx_count) then
          reaper.ShowConsoleMsg("false, all windows open")
          Show_Hide_Fx(false, track, fx_count)
          reaper.SetProjExtState(0, "ausbaxter_float_fx", "is_floating", "false")
      
        else
          FloatFX(track, fx_count)
          if chain_open == -2 or chain_open >= 0 then
              reaper.TrackFX_Show(track, 0, 0)
          end
        end
        
      end
      
    else
      --make sure any open fx are closed when executed on a track containing 0 fx
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_WNCLS3"),0)
     
    end
  else
  --make sure that any open fx are closed when executed with no track selection
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_WNCLS3"),0)
  
  end
end

Main()
