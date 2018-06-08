media_items = {}
media_tracks = {}
media_item_positions = {}

iter = reaper.CountSelectedMediaItems(0) - 1

math.randomseed( os.time() )

local function ShuffleTable( t )
  local rand = math.random 
  
  local iterations = #t
  local w
  
  for z = iterations, 2, -1 do
    w = rand(z)
    t[z], t[w] = t[w], t[z]
  end
end

function main()
  
    if iter < 1 then 
        reaper.ReaScriptError("Must have selected more than 1 item selected.")
        return
    end
    
    reaper.Undo_BeginBlock()
    
    for i = 0, iter do
        local item = reaper.GetSelectedMediaItem(0,i)
        table.insert(media_items, item)
        table.insert(media_tracks, reaper.GetMediaItemTrack(item))
        table.insert(media_item_positions, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET"))
    end
    
    ShuffleTable(media_items)
    
    reaper.PreventUIRefresh(1)
    
    for i = 1, iter + 1 do
        reaper.MoveMediaItemToTrack(media_items[i], media_tracks[i])
        reaper.SetMediaItemInfo_Value(media_items[i], "D_POSITION", media_item_positions[i] - reaper.GetMediaItemInfo_Value(media_items[i], "D_SNAPOFFSET"))
    end
    
    reaper.Undo_EndBlock("Shuffle items ignoring parents", 0)
    reaper.UpdateArrange()
end

main()
