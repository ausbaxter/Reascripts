--[[
 * ReaScript Name: Add equal spacing between selected items
 * Description: Adds a user defined spacing of silence in between each selected media item. Each track is ordered sequentially: track 1 items will precede track 2 items etc.
 * Instructions: Select 2 or more items. Make sure items are on a single track. Run script.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Add equal spacing between selected items.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-06)
  + Initial Release
--]]
------------------------------Required--------------------------------------

directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(directory .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------

function Main()
  
  s_items_count, selected_items = GetSelectedItems()
  
  if s_items_count >= 2 then
  
    retval, t_user_offset = GetInput("Add equal spacing between selected items", 1, {"Spacing (seconds)"}, "%d*[.]*%d*") --string pattern at end enables handling of floats
    
    if retval == true then --if user presses okay 
    
      user_offset = t_user_offset["Spacing (seconds)"]
      
      for i = 2, s_items_count do
      
        local item_pos = reaper.GetMediaItemInfo_Value(selected_items[i - 1], "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value(selected_items[i - 1], "D_LENGTH")
        local item_end = item_pos + item_len
        local offset = item_end + user_offset
        
        reaper.SetMediaItemInfo_Value(selected_items[i], "D_POSITION", offset)
      
      end
      
    end
    
  else
  
    reaper.ReaScriptError("Select 2 or more items.")
    
  end

end

reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Add equal spacing between selected items", -1)
