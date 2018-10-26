local record = 1013
local pause = 1008
local insert_marker = 40157
local edit_marker = 40614

local play_state = reaper.GetAllProjectPlayStates(0)

if play_state == 5 then --actively recording

    reaper.Main_OnCommand(record, 0)
    reaper.Main_OnCommand(pause, 0)
    reaper.Main_OnCommand(record, 0)
    reaper.Main_OnCommand(insert_marker, 0)
    reaper.SetProjExtState(0, "TalentCue", "Cue", "next")
    reaper.Main_OnCommand(edit_marker, 0)

end