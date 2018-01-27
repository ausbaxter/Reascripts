--[[
Script Notes:
    Make sure to use on an item selection and set your desired fade length in Reaper Preferences.
    Also set an appropriate threshold for the transient detection.
--]]

--Get Selected Items and store them in an array
selItemsCount = reaper.CountSelectedMediaItems(0)

selectedItems = {}
for i = 0, selItemsCount - 1 do
  selectedItems[i] = reaper.GetSelectedMediaItem(0,i)
end

reaper.Undo_BeginBlock()

--Unselect All Items
reaper.Main_OnCommand(40289, 0)--Unselect

--Operate on each Item
for i = 0, selItemsCount - 1 do
  reaper.SetMediaItemSelected(selectedItems[i], 1)
  
  reaper.Main_OnCommand(41051, 0)--Reverse
  
  reaper.Main_OnCommand(41173, 0)--move cursor to start of reversed items
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_MOVECURNEXT_TRANSMINUSFADE"), 0)
  reaper.Main_OnCommand(41305, 0)--trim left edge
  
  reaper.Main_OnCommand(41051, 0)--Reverse
  
  reaper.Main_OnCommand(41173, 0)--move cursor to start of reversed items
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_MOVECURNEXT_TRANSMINUSFADE"), 0)
  reaper.Main_OnCommand(41305, 0)--trim left edge
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_DEFAULTFADES"), 0)
  
  reaper.SetMediaItemSelected(selectedItems[i], 0)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock( "Auto Top and Tail", 0)
