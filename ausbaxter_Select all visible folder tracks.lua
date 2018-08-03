function main()
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        if (reaper.GetMediaTrackInfo_Value(track, "B_SHOWINMIXER") == 1.0 or reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1.0) and reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
        else
            reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
        end
    end
end

main()
