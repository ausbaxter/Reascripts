--[[
@version 1.0
@author ausbaxter
@description Add All Tracks Below Current to Selection
@changelog
    [1.0] - 2019-07-09
    + Initial release
@donation paypal.me/abaxtersound
]]

tk_count = reaper.CountSelectedTracks(0)
if tk_count == 0 then return end

track = reaper.GetSelectedTrack(0, tk_count-1)

start_index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
to_select = reaper.GetTrack(0, start_index)

while to_select do
    reaper.SetMediaTrackInfo_Value(to_select, "I_SELECTED", 1)
    start_index = start_index + 1
    to_select = reaper.GetTrack(0, start_index)
end

reaper.UpdateArrange()