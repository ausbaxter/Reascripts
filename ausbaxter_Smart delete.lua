function Print(value)
	reaper.ShowConsoleMsg(value)
end

function GetPostEditItem(tSStart)

	local first_item
	local second_item

	for i = 0, reaper.CountSelectedTracks(0) - 1 do
		
		local track = reaper.GetSelectedTrack(0, i)
		
		for j = 0, reaper.CountTrackMediaItems(track) - 1 do

			local item = reaper.GetTrackMediaItem(track, j)
			local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
			local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

			if tSStart == item_end then 
				first_item = item
				second_item = reaper.GetTrackMediaItem(track, j + 1)
				return first_item, second_item
			end

		end
	end
end

local context = reaper.GetCursorContext()
local equal_power = 41529
local save_item_sel = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1")
local load_item_sel = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1")
local unselect_items = 40289
local fade_len = 0.02

selectedItems = reaper.CountSelectedMediaItems()
reaper.Undo_BeginBlock()

tSStart, tSEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
if (tSEnd - tSStart) == 0 or context == 0 then -- No TS
	reaper.Main_OnCommand(40697, 0)

else -- Yes TS
	reaper.Main_OnCommand(40312, 0)
	reaper.Main_OnCommand(40635, 0)
	if reaper.GetToggleCommandState(41990) == 1 then --shuffle edit?

		reaper.Main_OnCommand(save_item_sel, 0)
		reaper.Main_OnCommand(unselect_items, 0)

		local first_item, second_item = GetPostEditItem(tSStart)

		reaper.SetMediaItemInfo_Value(first_item, "D_FADEOUTLEN_AUTO", fade_len)
		reaper.SetMediaItemInfo_Value(first_item, "C_FADEOUTSHAPE", 1)

		reaper.SetMediaItemInfo_Value(second_item, "B_UISEL", 1)
		reaper.ApplyNudge(0, 0, 1, 1, -fade_len, false, 0)

		reaper.SetMediaItemInfo_Value(second_item, "D_FADEINLEN_AUTO", fade_len)
		reaper.SetMediaItemInfo_Value(second_item, "C_FADEINSHAPE", 1)
		
		reaper.Main_OnCommand(load_item_sel, 0)

	end
end

reaper.Undo_EndBlock("Smart Delete", 0)

