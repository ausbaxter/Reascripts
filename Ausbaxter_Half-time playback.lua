--[[
 * ReaScript Name: Half-time playback
 * Description: Sets playback rate to half and starts playback, waits for playback to stop and returns to original rate.
 * Instructions: Run script to half the speed of playback. Stop playback to return to original rate.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Half-time playback
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2015-11-27)
  + Initial Release
--]]

--global variables
rate = reaper.Master_GetPlayRate(0)
half_rate = rate / 2

--play
function Play ()
  
  reaper.CSurf_OnPlayRateChange(half_rate)
  reaper.OnPlayButton()
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

--reaper.Undo_BeginBlock()
Main()
reaper.CSurf_FlushUndo(true)--doesn't prevent undo block creation
--reaper.Undo_EndBlock("Halfspeed Playback", -1)
