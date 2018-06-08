function msg(m)
  reaper.ShowConsoleMsg(tostring(m))
end

function GetSelectedMidiItems()
  local items = {}
  for i = 0, sel_count - 1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local take = reaper.GetTake(item,reaper.GetMediaItemInfo_Value(item,"I_CURTAKE"))
    local source = reaper.GetMediaItemTake_Source(take)
    local i_type = reaper.GetMediaSourceType(source, "")
    if i_type == "MIDI" then table.insert(items, {item = item,take = take}) end
  end
  return items
end

function SetSnapOffset()
  for i,item in ipairs(sel_items) do
    local _,n_count = reaper.MIDI_CountEvts(item.take)
    for n=0, n_count - 1 do
      _,_,muted,s_ppq = reaper.MIDI_GetNote(item.take, n)
      if muted then s_ppq = 0 
      else break
      end
    end
    if s_ppq ~= nil then
      start = reaper.MIDI_GetProjTimeFromPPQPos(item.take, s_ppq)
      item_pos = reaper.GetMediaItemInfo_Value(item.item,"D_POSITION")
      reaper.SetMediaItemInfo_Value(item.item,"D_SNAPOFFSET",start-item_pos)
    end
  end
end

function Main()
  sel_count = reaper.CountSelectedMediaItems(0)
  if sel_count == 0 then reaper.ReaScriptError("Must have items selected") return end
  sel_items = GetSelectedMidiItems()
  if #sel_items == 0 then reaper.ReaScriptError("No MIDI items selected")return  end
  reaper.Undo_BeginBlock()
  SetSnapOffset()
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Set snap offset to first note in selected midi items", -1)
end

Main()
