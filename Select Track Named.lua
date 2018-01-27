--[[------------------------------------------------------

By Austin Baxter

----------------------------------------------------------

Primary use: Prevents scrolling of large sessions when 
using "Item As Region" custom script. 

]]--------------------------------------------------------


--------------------User Config---------------------------
match_name = "Regions"

----------------------------------------------------------

--Select Matched Tracks
function SelectMatchTrack()

track_count = reaper.CountTracks(0)

  for i = 0, track_count - 1 do
    --Get n track of reaper session
    track = reaper.GetTrack(0,i)
    
    --Get name of track n
    retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    
    --Compare name of track to match value, and select matched track
    if string.match(track_name , match_name) then
    
      reaper.SetTrackSelected(track,true)
      
      return
      
    end
    
  end
  
end





--main execute function
function Main()

  --Unselects Tracks
  reaper.Main_OnCommand(40297,0)
  
  SelectMatchTrack()
    
end

Main()
