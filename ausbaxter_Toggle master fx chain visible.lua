local m_track = reaper.GetMasterTrack(0)
local chain_open = reaper.TrackFX_GetChainVisible(m_track)
if chain_open == -2 or chain_open >= 0 then reaper.TrackFX_Show(m_track, 0, 0)
else reaper.TrackFX_Show(m_track, 0, 1) end
