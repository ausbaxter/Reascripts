local record = 1013
local stop_delete_media = 40668

local play_state = reaper.GetAllProjectPlayStates(0)

if play_state == 5 then --actively recording

    reaper.Main_OnCommand(stop_delete_media, 0)
    reaper.Main_OnCommand(record, 0)
    reaper.SetProjExtState(0, "TalentCue", "Cue", "redo")

end