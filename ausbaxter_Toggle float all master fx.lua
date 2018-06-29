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


local m_track = reaper.GetMasterTrack(0)
local fx_count = reaper.TrackFX_GetCount(m_track)
local m_track = reaper.GetMasterTrack(0)
local chain_open = reaper.TrackFX_GetChainVisible(m_track)

if OpenFXWindows(m_track, fx_count) then
  Show_Hide_Fx(false, m_track, fx_count)
else
  Show_Hide_Fx(true, m_track, fx_count)
end


if chain_open == -2 or chain_open >= 0 then 
    reaper.TrackFX_Show(m_track, 0, 0)
    if fx_count > 0 then Show_Hide_Fx(true, m_track, fx_count) end
end
