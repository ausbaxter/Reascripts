--@description script name
--@version 1.0
--@author ausbaxter
--@about
--  # {Package Title}
--	{Any Documentation}
--@changelog
--  + Initial release

--------------------------------------------------------------------------------------------------------

function SetPoolID()

    local starting_pool_id = 1000
    local retval, last_pool_id = reaper.GetProjExtState(0, "AB_AUTOITEM", "LASTPOOLID")

    local pool_id = retval == 0 and starting_pool_id or tonumber(last_pool_id) + 1

    reaper.SetProjExtState(0, "AB_AUTOITEM", "LASTPOOLID", pool_id)

    return pool_id

end

function IsGoodTrackEnvelope(envelope)
    -- Returns true if selected envelope is on a track containing a selected item, false otherwise.

    local tk = reaper.Envelope_GetParentTrack(envelope)

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local i_tk = reaper.GetMediaItemTrack(item)
        if i_tk == tk then return true end
    end

    return false

end

function GetItemSize(source_media_item)
    local s = reaper.GetMediaItemInfo_Value(source_media_item, "D_POSITION")
    local l = reaper.GetMediaItemInfo_Value(source_media_item, "D_LENGTH")
    return s, l
end

function GetSelectedItemsTracks(env_track)
    -- Returns table {Track, ItemTable} ensuring that env_track is at index 1.

    local dl_tbl = {}
    local sorted = {}

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        if not dl_tbl[track] then 
            dl_tbl[track] = {item}
        else
            table.insert(dl_tbl[track], item)
        end
    end

    local c = 2
    for t, i in pairs(dl_tbl) do
        if env_track and env_track == track then
            sorted[1] = {track = t, items = i}
        else
            sorted[c] = {track = t, items = i}
            c = c + 1
        end
    end

    return sorted

end

function GetFxOfSelectedEnvelope(envelope_track, envelope)
    
    local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    local parm_idx = string.match( chunk, "<PARMENV (%d+)" )

    for i = 0, reaper.TrackFX_GetCount(envelope_track) - 1 do

        for j = 0, reaper.TrackFX_GetNumParams(envelope_track, i) - 1 do
            local env = reaper.GetFXEnvelope(envelope_track, i, j, false)
            if env == envelope then
                local _, fx = reaper.BR_TrackFX_GetFXModuleName(envelope_track, i, "", 20)
                return fx, parm_idx
            end
        end

    end

    return nil

end

function GetEnvelope(track)
    if source_fx then
        for fx_idx = 0, reaper.TrackFX_GetCount(track) - 1 do
            local retval, fx = reaper.BR_TrackFX_GetFXModuleName(track, fx_idx, "", 20) -- API doc specs 2 args, but 4 are req, Check 'C' reference
            if fx == source_fx then return reaper.GetFXEnvelope(track, fx_idx, source_fx_parm_id, false) end
        end
    else
        return reaper.GetTrackEnvelopeByChunkName(track, env_chunk)
    end
end

function InsertAutomationItems(item_tracks)

    local is_first = true
    local base_length = 0

    for i, t in pairs(item_tracks) do

        local dest_envelope = GetEnvelope(t.track)

        for _, item in ipairs(t.items) do

            if dest_envelope then

                local start, length = GetItemSize(item)
                local ai_index = reaper.InsertAutomationItem(dest_envelope, pool_id, start, length)
            
                if is_first then 
                    is_first = false
                    base_length = length
                else
                    reaper.GetSetAutomationItemInfo(dest_envelope, ai_index, "D_PLAYRATE", base_length / length, true)
                end

            end

        end

    end

end

function Main()

    local envelope = reaper.GetSelectedEnvelope(0)

    if not envelope then
        reaper.ShowMessageBox("No Envelope Selected", "Error: No Selected Envelope", 0)
        return
    end

    local env_track = reaper.Envelope_GetParentTrack(envelope)

    if not IsGoodTrackEnvelope(envelope) then 
        reaper.ShowMessageBox("Selected envelope is not on a track with selected items.", "Error: Selected Envelope", 0) 
        return 
    end

    local item_tracks = GetSelectedItemsTracks()

    local _, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    env_chunk = string.match(chunk, "<%w+ENV%w*")

    if env_chunk == "<PARMENV" then 
        source_fx, source_fx_parm_id = GetFxOfSelectedEnvelope(env_track, envelope) 
    end

    reaper.Undo_BeginBlock()

    pool_id = SetPoolID()

    InsertAutomationItems(item_tracks)

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Insert pooled automation items for selected envelope on selected items", -1)

end

Main()