selectedItem = {}

if reaper.CountSelectedMediaItems(0) > 0 then
  for i = 0, reaper.CountMediaItems(0)-1 do -- loop through all selected items
    selectedItem[i] = reaper.GetSelectedMediaItem(0, i) -- save item ID to table, so that they are accesible in a fixed order, when items are re-positioned
  end
  for i = 0, #selectedItem do -- loop through all selected items
    take = reaper.GetActiveTake(selectedItem[i])  -- get active take in item
    takeName = reaper.GetTakeName(take)  -- get take name
    timecodeDot = string.match(takeName, '%d*%.?%d*%.?%d+') -- match timecode
    if timecodeDot == nil then -- if there is no timecode in the filename, skip item
      i=i+1 -- if there is a timecode in the filename
    else
      timecode = string.gsub(timecodeDot, "%.", ":")  -- replace "." with ":"
      reaperTime = reaper.parse_timestr_len(timecode, 0, 0)  -- convert timecode to Reaper time
      projectStart = reaper.GetProjectTimeOffset(0, false) -- get project start
      item_snap = reaper.GetMediaItemInfo_Value(selectedItem[i], "D_SNAPOFFSET" )
      newPosition = reaperTime - projectStart - item_snap -- mind the project start and calculate new position!
      reaper.SetMediaItemPosition(selectedItem[i], newPosition, true)-- move item to timecode
    end
  end
end
