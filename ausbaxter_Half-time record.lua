--@description Half-time record
--@version 1.0
--@author ausbaxter
--@about
--    # Half-time record
--    Allows half time recording. Once started, waits for playback to stop to reset playrate.
--@changelog
--  + Initial release

rate = reaper.Master_GetPlayRate(0)
half_rate = rate / 2

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

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Half-time record", -1)