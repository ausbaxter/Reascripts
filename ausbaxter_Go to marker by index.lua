--@description Go to marker by index
--@version 1.0
--@author ausbaxter
--@about
--    # Similar recall method to pro tools.
--@changelog
--  + Initial release

--Gets user input
Retval, mk_input = reaper.GetUserInputs("Go To Marker", 1, "Index:", "")

--Checks for compatible input
numcheck = tonumber(mk_input)

if numcheck ~= nil then

  --Goes to Marker with same index as user  input
  reaper.GoToMarker(0, mk_input, false)
  
end

