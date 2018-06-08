function msg(m)
  reaper.ShowConsoleMsg(tostring(m))
end

sel_items = {}
name = "Spot selected items snap offset to markers using items as pools"

function GetSelectedItems()
  for i = 0, count_selitems - 1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    table.insert(sel_items,item)
  end
end

function KeepOnlyItemSelected(idx)
  for i = 1, #sel_items do
    if i ~= idx then
      reaper.SetMediaItemInfo_Value(sel_items[i],"B_UISEL",0)
    else
      reaper.SetMediaItemInfo_Value(sel_items[i],"B_UISEL",1)
    end
  end
end

function RestoreSelection()
  for i = 0, reaper.CountMediaItems(0) - 1 do
    reaper.SetMediaItemInfo_Value(reaper.GetMediaItem(0,i),"B_UISEL",0)
  end
end

function GetMarkers(input)
  markers = {}
  for i = 0, reaper.CountProjectMarkers(0) - 1 do
    local _,isrgn,pos,rgnend,name,idx = reaper.EnumProjectMarkers(i)
    if pos > ts and te > pos and not isrgn then
      if string.find(string.lower(name),string.lower(input)) then
        table.insert(markers,{idx = idx, pos = pos})
      end
    end
  end
  return markers
end

function GetItemIdx()
  min = 1;
  max = #sel_items;
  if max == 1 then return 1 end
  if lastRandom == nil then
    random = math.floor(math.random() * (max - min + 1)) + min
  else
    random = math.floor(math.random() * (max - min    )) + min
    if random >= lastRandom then random = random + 1 end
  end
  lastRandom = random
  return random
end

function Spot(markers)
  for i,m in ipairs(markers) do
    local idx = GetItemIdx()
    KeepOnlyItemSelected(idx)
    reaper.ApplyNudge(0,1,5,1,m.pos,0,1)
  end
end

function Main()
  count_selitems = reaper.CountSelectedMediaItems(0)
  ts,te = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts == te then reaper.ReaScriptError("Must have time selection to choose markers.") return end
  if count_selitems == 0 then reaper.ReaScriptError("Must have items selected to use as pool") return end  
  local ret,input = reaper.GetUserInputs(name,1,"Marker String:","")
  if not ret then return end  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)  
  GetSelectedItems()
  local markers = GetMarkers(input)
  Spot(markers)
  RestoreSelection()  
  reaper.Undo_EndBlock(name,-1)
  reaper.UpdateArrange()
end

Main()
