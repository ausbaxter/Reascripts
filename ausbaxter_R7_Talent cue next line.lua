local record = 1013
local pause = 1008
local insert_marker = 40157
local edit_marker = 40614

local play_state = reaper.GetAllProjectPlayStates(0)

if play_state == 5 then --actively recording

    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(record, 0)

    pos = reaper.GetCursorPosition()
    
    i=0
	repeat
		iRetval, bIsrgnOut, iPosOut, iRgnendOut, sNameOut, iMarkrgnindexnumberOut, iColorOur = reaper.EnumProjectMarkers3(0,i)
		if iRetval >= 1 then
			if bIsrgnOut == true and iPosOut > pos then
				reaper.SetEditCurPos(iPosOut,true,true)
				break
			end
			i = i+1
		end
	until iRetval == 0

    reaper.Main_OnCommand(record, 0)
    --reaper.Main_OnCommand(insert_marker, 0)
    reaper.SetProjExtState(0, "TalentCue", "Cue", "next")
    --reaper.Main_OnCommand(edit_marker, 0)
    reaper.Undo_EndBlock("Cue Next Line", -1)

end