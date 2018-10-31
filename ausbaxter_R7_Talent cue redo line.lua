local record = 1013
local stop_delete_media = 40668

local play_state = reaper.GetAllProjectPlayStates(0)

if play_state == 5 then --actively recording

    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(stop_delete_media, 0)
    reaper.Main_OnCommand(record, 0)
    reaper.SetProjExtState(0, "TalentCue", "Cue", "redo")
    reaper.Undo_EndBlock("Cue Redo Line", -1)
else
    reaper.SetProjExtState(0, "TalentLineDisplay", "ListUpdate", "prev")
end