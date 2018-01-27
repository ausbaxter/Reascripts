function Print(value)
  reaper.ShowConsoleMsg(tostring(value))
end
--boolean reaper.SetProjectMarker(integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name)
--integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber = reaper.EnumProjectMarkers(integer idx)

function ParseUserString(_userString)
  local res = {}
  local pos = 0
  
  retval, userString = reaper.GetUserInputs("Append String to Markers", 3, "Process By (time / name):,Appending String:,Marker Name to Append:", "time,,")
  
  while true do
    local startp,endp = string.find(userString,",",pos)
    if (startp) then
      table.insert(res,string.sub(userString,pos,startp-1))
      pos = endp + 1
    else
      table.insert(res,string.sub(userString,pos))
      break
    end
  end
  return res[1], res[2], res[3]
end

function AppendMarkers(mode, userString, matchName)
  if mode == "time" and userString ~= nil then
    
    tSStart, tSEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
    for i = 0, reaper.CountProjectMarkers() - 1 do
      retval, rgn, pos, rgnend, name, index = reaper.EnumProjectMarkers(i)
      if pos > tSStart and pos < tSEnd then
        reaper.SetProjectMarker(index, rgn, pos, rgnend, name .." " .. userString)
      end
    end
    
  elseif mode == "name" then
  
    for i = 0, reaper.CountProjectMarkers() - 1 do
          retval, rgn, pos, rgnend, name, index = reaper.EnumProjectMarkers(i)
          if name:find(matchName) ~= nil then
            reaper.SetProjectMarker(index, rgn, pos, rgnend, name .." " .. userString)
          end
        end
  end
end



function main()
  userMode, userString, markerMatch = ParseUserString(userString)
  AppendMarkers(userMode, userString, markerMatch)
end

main()
