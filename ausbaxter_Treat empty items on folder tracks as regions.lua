--[[
@version 1.0
@author ausbaxter
@description Treat Empty Items on Folder Tracks as Regions
@about
    ## Treat Empty Items on Folder Tracks as Regions
    While running, any empty items on parent folder tracks will be synced to newly created markers starting from the script's start index.

        - Markers will be named according to the empty item notes
        - Region indexes will be saved with the project as long as the item associated with the region exists.
        - Regions are colored according to their linked folder item
        - Track Muting and turning off the script will remove the created regions temporarily.
        - Script is togglable and active state is shown in menu's and toolbars

### Known Issues:

        - Since indexes are recycled if you delete an item, deactivate then activate the script again, the region index for that item is flushed. If you undo to bring the item back, the first available index will be used for the region, and may not be identical to the original.
        - Changing start index when empty items exist in project can break the original items links.

@changelog
    [1.0] - 2019-06-09
    + Initial release

@donation paypal.me/abaxtersound

@screenshot
    https://i.gyazo.com/3dbcb866237bb98778f65803abd972ea.gif
]]

ext_state = "ausbaxter_Treat empty items on folder tracks as regions"
previous_state = 0
track_count = 0
prev_track_count = {}

Regions = {
    --------------------------------------------------------------------------------------------
    --[[                 Change Start Index To Set The Starting Region's Indexes              ]]
    --------------------------------------------------------------------------------------------
    start_index = 1000
    --------------------------------------------------------------------------------------------
    --[[                                                                                      ]]
    --------------------------------------------------------------------------------------------
}

function Regions:ConvertToRegionIndex(t_index, offset)
    -- Allows using Regions table with for ... ipairs
    offset = offset or self.start_index
    return t_index + offset - 1
end

function Regions:ConvertToTableIndex(r_index, offset)
    -- Allows using Regions table with for ... ipairs
    offset = offset or self.start_index
    return r_index - offset + 1
end

function Regions:Get(idx_or_guid)

    if type(idx_or_guid) == "string" then
        return self[idx_or_guid]
    end

    return idx_or_guid - start_index + 1

end

function Regions:Set(idx_or_guid, value)

    if type(idx_or_guid) == "string" then
        if type(value) ~= "number" then error("Regions:Set(guid) requires a numeric value", 2) end
        self[idx_or_guid] = value
    end

    if type(value) ~= "string" then error("Regions:Set(idx) requires a string (guid) value", 2) end
    self[idx_or_guid] = value

end

function Regions:Add(guid, r_in, r_out, r_name, r_col)
    -- Adds a region from an item guid, automatically picks the first available index.

    function IndexAvailable(i)
        return self[i] == false or self[i] == nil
    end

    local r_index = self.start_index
    local t_index = 1

    for i = 1, #self + 1 do
        if IndexAvailable(i) then
            r_index = self:ConvertToRegionIndex(i)
            t_index = i
            break
        end
    end

    reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, r_index, r_col)

    self[t_index] = guid
    self[guid] = r_index

    reaper.UpdateArrange()

end

function Regions:Update(idx_or_guid, r_in, r_out, r_name, r_col)

    if type(idx_or_guid) == "string" then 
        r_index = self[idx_or_guid]
    end

    local retval = reaper.SetProjectMarker3(0, r_index, true, r_in, r_out, r_name, r_col)

    if not retval then
        reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, r_index, r_col)
    end

    reaper.UpdateArrange()

end

function Regions:DeleteInvalidRegions()

    for t_index, guid in ipairs(Regions) do

        if guid then

            local item = reaper.BR_GetMediaItemByGUID(0, guid)
  
            if not ItemExists(item) then

                reaper.DeleteProjectMarker(0, Regions:ConvertToRegionIndex(t_index), true)
                if t_index >= #self then   
                    Regions[t_index] = nil
                else
                    Regions[t_index] = false
                end
                Regions[guid] = nil

            elseif not ItemIsOnFolderTrack(item) then
                reaper.DeleteProjectMarker(0, Regions:ConvertToRegionIndex(t_index), true)
            end

        end
    end

end

function Regions:Save()

    for t_index, guid in ipairs(self) do

        if guid then
            r_index = self:ConvertToRegionIndex(t_index)
            reaper.DeleteProjectMarker(0, r_index, true) 
            reaper.SetProjExtState(0, ext_state, guid, r_index)
        end

    end

    reaper.SetProjExtState(0, ext_state, "Previous Start Index", self.start_index)

end

function Regions:RemapIndex(prev_start, loaded_index)

    local temp_t_index = Regions:ConvertToTableIndex(loaded_index, tonumber(prev_start))
    return Regions:ConvertToRegionIndex(temp_t_index)

end

function Regions:FillSkippedIndexes(max_r_index)
    -- Ensures any nil values between first region idx and last are false filled to enable ipairs iteration

    local max_t_index = Regions:ConvertToTableIndex(max_r_index)
    for i = 1, max_t_index do
        if not self[i] then self[i] = false end
    end

end

function Regions:Load()

    local _, previous_start_index = reaper.GetProjExtState(0, ext_state, "Previous Start Index")
    
    local st = 0
    local max_r_index = 0

    while true do

        retval, key, val = reaper.EnumProjExtState(0, ext_state, st)
    
        if retval == false then break end
        
        val = tonumber(val)
        previous_start_index = tonumber(previous_start_index)
    
        if ItemExists(key) then
            
            if previous_start_index ~= self.start_index then
                val = self:RemapIndex(previous_start_index, val)
            end

            if val > max_r_index then max_r_index = val end

            self[key] = val
            self[self:ConvertToTableIndex(val)] = key
            local r_in, r_out, r_name, r_col = GetItemData(key)

            if ItemIsOnFolderTrack(key) then
                reaper.AddProjectMarker2(0, true, r_in, r_out, r_name, val, r_col)
            end

        end

        self:FillSkippedIndexes(max_r_index)
    
        st = st + 1
        
    end

end

function TrackIsMuted(track)

    if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then return true end
    local track_check = reaper.GetParentTrack(track)

    while(track_check ~= nil) do
        if reaper.GetMediaTrackInfo_Value(track_check, "B_MUTE") == 1 then return true end
        track_check = reaper.GetParentTrack(track_check)
    end

    return false

end

function StateChanged()

    local state = reaper.GetProjectStateChangeCount(0)
    local changed = false

    if previous_state ~= state then 
        changed = true
    end

    previous_state = state
    return changed

end

function TrackDeleted()

    local current_track_count = reaper.CountTracks(0)
    local deleted = false

    if track_count > current_track_count then 
        deleted = true
    end

    track_count = current_track_count
    return deleted

end

function TrackItemDeleted(item_count, track_guid)

    local deleted = false

    if prev_track_count[track_guid] ~= nil and prev_track_count[track_guid] > item_count then
        deleted = true
    end
    
    prev_track_count[track_guid] = item_count
    return deleted

end

function IsEmptyItem(item)
    
    return reaper.GetTake(item, 0) == nil

end

function ItemExists(item_or_guid)
    
    if type(item_or_guid) == "string" then
        item_or_guid = reaper.BR_GetMediaItemByGUID(0, item_or_guid)
    end

    return reaper.ValidatePtr2(0, item_or_guid, "MediaItem*")

end

function ItemIsOnFolderTrack(item_or_guid)

    if type(item_or_guid) == "string" then
        item_or_guid = reaper.BR_GetMediaItemByGUID(0, item_or_guid)
    end
    
    local track = reaper.GetMediaItem_Track(item_or_guid)
    return reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1

end

function GetItemData(item)

    if type(item) == "string" then
        item = reaper.BR_GetMediaItemByGUID(0, item)
    end

    local r_in = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local r_out = r_in + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    local r_name = reaper.ULT_GetMediaItemNote(item)
    if r_name == "" then r_name = " " end

    local r_col = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")

    return r_in, r_out, r_name, r_col

end

function SetToggle(state)
    -- off = 0, on = 1

    _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, state)
    reaper.RefreshToolbar2(sectionID, cmdID)

end

function HandleFolderTrackItems(track)

    local item_count = reaper.CountTrackMediaItems(track)
    local track_guid = reaper.GetTrackGUID(track)

    if TrackItemDeleted(item_count, track_guid) then
        Regions:DeleteInvalidRegions()
    end

    for j = 0, item_count - 1 do

        local item = reaper.GetTrackMediaItem(track, j)
        local item_guid = reaper.BR_GetMediaItemGUID(item)

        if IsEmptyItem(item) then

            local r_in, r_out, r_name, r_col = GetItemData(item)

            if Regions[item_guid] ~= nil then
                Regions:Update(item_guid, r_in, r_out, r_name, r_col)
            else
                Regions:Add(item_guid, r_in, r_out, r_name, r_col)
            end

        end

    end

end

function HandleMutedTrackItems(track)

    if TrackIsMuted(track) then

        local item_count = reaper.CountTrackMediaItems(track)

        for j = 0, item_count - 1 do

            local item = reaper.GetTrackMediaItem(track, j)
            local item_guid = reaper.BR_GetMediaItemGUID(item)

            if Regions[item_guid] ~= nil then
                reaper.DeleteProjectMarker(0, Regions[item_guid], true)
            end
        
        end

    end

end

function CheckAndHandleProjectFolderTracks()

    for i = 0, track_count - 1 do

        local track = reaper.GetTrack(0, i)

        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then

            HandleFolderTrackItems(track)
            HandleMutedTrackItems(track)

        end

    end

end

function main()

    if StateChanged() then

        if TrackDeleted() then
            Regions:DeleteInvalidRegions()
        end

        CheckAndHandleProjectFolderTracks()

    end

    reaper.defer(main)

end

reaper.atexit(function()
    
    Regions:Save()
    SetToggle(0)
    gfx.quit()

end)

Regions:Load()
SetToggle(1)
main()