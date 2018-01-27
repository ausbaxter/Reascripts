--[[
Instant-Take Chain Selector
Dialog Box allows you to enter the number of a saved instant take track to bring up the fx chain for that track.
Allows Saving under your own "Preset Name and recalling the same way" Writes Preset Names to Project Notes
For use with Instant-Take
]]--

function Print(m) 
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

--Global Variables--
numTracks = reaper.CountTracks(0)

--returns an array containing each Instant-Take Preset Track where each index stores the track [0] and name [1]
local function GetInstantTakeTracks()
  local array = {}
  for i = 0, numTracks-1 do
    local track = reaper.GetTrack(0,i)
    local tname = reaper.GetTrackState(track)
    
    if tname:find("Instant.Take FX (.*)") ~= nil then
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMCP", 0)
      table.insert(array, {track, tname})
    end
  end
  return array
end

local function GetUserInput()
  local retval, userInputs = reaper.GetUserInputs("Instant Take Chain Selector", 1, "Open Preset FX:", "1")
  presetName = userInputs
  return presetName
end

local function ShowTrackFX(track)
  reaper.TrackFX_Show(track,0,1)
end

local function GetUserTrackChoice(presetName, instantTakeTracks)
  local found = false
  for i in ipairs(instantTakeTracks) do
    local track = instantTakeTracks[i]
    if track[2]:find(presetName) ~= nil then
      reaper.SetMediaTrackInfo_Value(track[1], "B_SHOWINTCP", 1)
      reaper.SetMediaTrackInfo_Value(track[1], "B_SHOWINMCP", 1)
      ShowTrackFX(track[1])
      found = true
      break
    end
  end
  if not found then
    Print("No Preset by that name was found") --better error reading
  end
end


function Main()
  instantTakeTracks = GetInstantTakeTracks()
  presetName, newPreset = GetUserInput()
  
  if presetName ~= "" then
    GetUserTrackChoice(presetName, instantTakeTracks)
  end  
    
end


Main()


