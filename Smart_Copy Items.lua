function Print(value)
  reaper.ShowConsoleMsg(value)
end

reaper.Undo_BeginBlock()

function PointSelect()
  for i = 1, selEnvPointCount do
    retval, timeOut, value, shape, tensionOut, selected = reaper.GetEnvelopePoint(selectedEnvelope, i - 1)
    if selected then 
      return true
    end
  end
end

selectedItems = reaper.CountSelectedMediaItems(0)

selectedEnvelope = reaper.GetSelectedEnvelope(0)

if selectedEnvelope ~= nil then
  selEnvPointCount = reaper.CountEnvelopePoints(selectedEnvelope)
  pointSelected = PointSelect()
end


if selectedItems > 0 or pointSelected then

  tSStart, tSEnd = 
  reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
  if (tSEnd - tSStart) == 0 then -- No TS
    reaper.Main_OnCommand(40057, 0)
  else -- Yes TS
    reaper.Main_OnCommand(41383, 0)
  end

  reaper.Undo_EndBlock("Smart Copy", 0)
  
else
  reaper.Undo_EndBlock("", 1)
end
