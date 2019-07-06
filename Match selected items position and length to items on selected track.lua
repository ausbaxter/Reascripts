src_track = reaper.GetSelectedTrack(0, 0)
track_item_count = reaper.CountTrackMediaItems(track)

pool={}
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    track = reaper.GetMediaItemTrack(item)
    take = reaper.GetTake(item, 0)
    name = reaper.GetTakeName(take)
    

    if not pool[track] then
        pool[track] = {}
    else
        pool[track][name] = item
    end

end

for dest_track in pool do
    for i = 0, track_item_count-1 do
        item = reaper.GetTrackMediaItem(src_track, i)
        take = reaper.GetTake(item, 0)
        name = reaper.GetTakeName(take)
        pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        new_item = 
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len)
    end
end

