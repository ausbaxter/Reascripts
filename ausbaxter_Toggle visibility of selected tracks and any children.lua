--[[
@version 1.0
@author ausbaxter
@description Toggle visibility of selected tracks and any children
@about
    ## Toggle visibility of selected tracks and any children
    My default show/hide shortcut, will recursively show/hide the selected track and any children.
@changelog
    [1.0] - 2019-06-09
    + Initial release
]]

--------------------------------------------------------------------------------------------------------

function ShowTracks(is_show)
    local visible = 0
    if is_show then visible = 1 end

    local function ShowChildTracks(idx)
        while true do
            local child_track = reaper.GetTrack(0,idx)
            if child_track == nil then return idx end

            local state = reaper.GetMediaTrackInfo_Value(child_track, "I_FOLDERDEPTH")

            reaper.SetMediaTrackInfo_Value(child_track, "B_SHOWINTCP", visible)
            reaper.SetMediaTrackInfo_Value(child_track, "B_SHOWINMIXER", visible)

            idx = idx + 1

            if state < 0 then 
                return idx
            elseif state == 1 then
                idx = ShowChildTracks(idx)
            end
        end
    end

    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        local track = reaper.GetSelectedTrack(0, i)

        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then --parent
            local idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
            ShowChildTracks(idx)

            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", visible)
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", visible)
        else
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", visible)
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", visible)
        end
    end
end

function Main()
    local base_track = reaper.GetSelectedTrack(0, 0)

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    if reaper.GetMediaTrackInfo_Value(base_track, "B_SHOWINTCP") == 1 then
        ShowTracks(false)
    else
        ShowTracks(true)
    end

    reaper.UpdateArrange()
    reaper.TrackList_AdjustWindows(false)
    reaper.Undo_EndBlock("Toggle visibility of selected tracks and any children", -1)
end

Main()