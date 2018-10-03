--Saves first Item to use for concatenation (add randomize functionality)
function main()
    local item = reaper.GetSelectedMediaItem(0, 0)
    local item_guid = reaper.BR_GetMediaItemGUID(item)
    reaper.SetProjExtState(0, "AutoConcat", "Item_1", item_guid)
end

main()