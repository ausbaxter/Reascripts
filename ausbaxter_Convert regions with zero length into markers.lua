function main()
  reaper.Undo_BeginBlock()
  local idx = 0
  while true do
    local retval, isrgn, pos, rgnend, name, mr_index = reaper.EnumProjectMarkers(idx)
    if retval == 0 then break end
    if isrgn and pos == rgnend  then 
      reaper.DeleteProjectMarkerByIndex(0, retval - 1)
      reaper.AddProjectMarker(0, false, pos, 0, name, mr_index)    
    end
    idx = idx + 1
  end
  reaper.Undo_EndBlock("Convert zero length regions to markers", -1)
end

main()
