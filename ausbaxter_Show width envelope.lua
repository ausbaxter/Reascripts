for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local track = reaper.GetSelectedTrack(0,i)
    env = reaper.GetTrackEnvelopeByChunkName(track,"<WIDTHENV")
    retval, chunk = reaper.GetEnvelopeStateChunk(env,"VIS", false)
    --get regex or parse for VIS(space) and read next value (if 0 then make 1 and vice versa)
    set = reaper.SetEnvelopeStateChunk(env, chunk:gsub(""), true) --must use gsub iguess
end
