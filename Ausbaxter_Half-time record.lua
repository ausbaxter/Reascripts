--[[
 * ReaScript Name: Half-time record
 * Description: Halfs playback rate and starts recording, useful for recording midi.
 * Instructions: Run this script as you would normally run the record action
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Half-time record.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-03)
  + Initial Release
--]]

--global variables
rate = reaper.Master_GetPlayRate(0)
half_rate = rate / 2

--play
function Play ()

  reaper.CSurf_OnPlayRateChange(half_rate)
  reaper.CSurf_OnRecord()
  playing = true

end

--Loop, wait for playback stop
function Update ()

  playstate = reaper.GetPlayState()
  
  if playstate == 0 then
    playing = false
    reaper.CSurf_OnPlayRateChange(rate) 
  end
  
  if playing then 
    reaper.defer(Update) -- Loop Start  
  end
  
end

function Main ()
  
  Play()  
  Update()
  
end

Main()
reaper.CSurf_FlushUndo(true)--does not work currently, undo points are still created
