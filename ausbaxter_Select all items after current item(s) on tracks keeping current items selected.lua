
--[[function main()
    local item_count = reaper.CountSelectedMediaItems(0)
    prev_track = nil
    track_table = {}
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local cur_track = reaper.GetMediaItemTrack(item)
        
        if prev_track == nil or cur_track ~= prev_track then
            table.insert(track_table, {track = cur_track, idx_start = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER")})
        end
        
        prev_track = cur_track
    end
    
    for i = 1, #track_table do
        local count = reaper.CountTrackMediaItems(track_table[i].track)
        for j = track_table[i].idx_start, count - 1 do
            local item reaper.GetTrackMediaItem(prev_track, j)
            reaper.ShowConsoleMsg(tostring(item))
            --reaper.SetMediaItemInfo_Value(item, "B_UISEL", true)
        end
    end
end]]

--only works on one track right now :(

local f_item = reaper.GetSelectedMediaItem(0, 0)
local item_track = reaper.GetMediaItemTrack(f_item)
local idx = reaper.GetMediaItemInfo_Value(f_item, "IP_ITEMNUMBER")
local count = reaper.CountTrackMediaItems(item_track)

for i = idx, count - 1 do
    local item = reaper.GetTrackMediaItem(item_track, i)
    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
end

reaper.UpdateArrange()

--main()
