--@description script name
--@version 1.0
--@author ausbaxter
--@about
--    # description
--
--    more info
--@changelog
--  + Initial release

--------------------------------------------------------------------------------------------------------

--external library linking from Lokasenna, thanks!-----------------------------------
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local function req(file)
	if missing_lib then return function () end end
	local ret, err = loadfile(script_path .. file)
	if not ret then
		reaper.ShowMessageBox("Couldn't load "..file.."\n\nError: "..tostring(err), "Library error", 0)
		missing_lib = true		
		return function () end
	else 
		return ret
	end	
end
------------------------------------------------------------------------------------