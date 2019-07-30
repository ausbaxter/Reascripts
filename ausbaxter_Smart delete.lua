-- TODO if no items are selected still apply crossfading to resulting edits if ripple editing enabled

function SaveSelectedItems()

	media_items = {}

	for i = 0, reaper.CountSelectedMediaItems(0) do
		table.insert(media_items, reaper.GetSelectedMediaItem(0, i))
	end

	return media_items

end

function RestoreSelectedItems(media_items)
	for i, item in ipairs(media_items) do
		reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
	end
end

function IsItemContiguous(first_item, second_item)

	local fi_track = reaper.GetMediaItem_Track(first_item)
	local si_track = reaper.GetMediaItem_Track(second_item)

	local fi_end = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(first_item, "D_LENGTH")
	local si_start = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")

	if fi_end >= si_start and fi_track == si_track then return true end

	return false

end

function CrossfadeRippledItems(media_items)

	local fade_len = 0.02

	for i = 2, #media_items do

		local earlier_item = media_items[i-1]
		local this_item = media_items[i]

		if IsItemContiguous(earlier_item, this_item) then

			reaper.SetMediaItemInfo_Value(earlier_item, "D_FADEOUTLEN_AUTO", fade_len)
			reaper.SetMediaItemInfo_Value(earlier_item, "C_FADEOUTSHAPE", 1)

			reaper.SetMediaItemInfo_Value(this_item, "B_UISEL", 1)
			reaper.ApplyNudge(0, 0, 1, 1, -fade_len, false, 0)
			reaper.SetMediaItemInfo_Value(this_item, "B_UISEL", 0)

			reaper.SetMediaItemInfo_Value(this_item, "D_FADEINLEN_AUTO", fade_len)
			reaper.SetMediaItemInfo_Value(this_item, "C_FADEINSHAPE", 1)

		end
	
	end

end

function Main()

	local context = reaper.GetCursorContext()
	local equal_power = 41529
	local save_item_sel = reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1")
	local load_item_sel = reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1")
	local unselect_items = 40289

	selectedItems = reaper.CountSelectedMediaItems()
	reaper.Undo_BeginBlock()

	tSStart, tSEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

	if (tSEnd - tSStart) == 0 or context == 0 then
		reaper.Main_OnCommand(40697, 0)

	else
		reaper.Main_OnCommand(40312, 0)
		reaper.Main_OnCommand(40635, 0)
		if reaper.GetToggleCommandState(41990) == 1 then

			selected_media_items = SaveSelectedItems()
			reaper.Main_OnCommand(unselect_items, 0)
			CrossfadeRippledItems(selected_media_items)
			RestoreSelectedItems(selected_media_items)

		end
	end

	reaper.Undo_EndBlock("Smart Delete", 0)

end

Main()