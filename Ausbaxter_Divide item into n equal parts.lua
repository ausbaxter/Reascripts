--[[
 * ReaScript Name: Divide item into n equal parts
 * Description: Divides a selected item into n equal parts.
 * Instructions: Select one item, run script. Enter in the amount of items of equal length you desire.
 * Author: Ausbaxter
 * Author URI: https//:austinbaxtersound.com
 * Repository: GitHub > Ausbaxter
 * Repository URL: https://github.com/ausbaxter/Reascripts
 * File URI: https://github.com/ausbaxter/Reascripts/Ausbaxter_Divide item into n equal parts.lua
 * Licence: GPL v3
 * REAPER: 5.xx
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-11-04)
  + InitialRelease
--]]
------------------------------Required--------------------------------------

directory = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
dofile(directory .. 'Ausbaxter_Lua functions.lua')

----------------------------------------------------------------------------

function SplitItem(div)
  
  local item = reaper.GetSelectedMediaItem(0, 0)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local offset = item_length / div
  
  for i = 1, div - 1 do
  
    item_pos = item_pos + offset   
    item = reaper.SplitMediaItem(item, item_pos)
  
  end
  
end

function Main()

  local cursor_pos = reaper.GetCursorPosition()
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 1 then
  
    local retval, input = GetInput("Divide item into n equal parts", 1, {"n"})
    
    if retval == true then
    
      local num = tonumber(input["n"])
      
      if num ~= nil then 
        SplitItem(num)
      else
        reaper.ReaScriptError("Must enter a number.")
      end
      
    end
    
  elseif item_count == 0 then
    reaper.ReaScriptError("Must select one item to divide.")
  else
    reaper.ReaScriptError("Too many items selected. Select only one item to divide.")
  end
  
end

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Divide Items", -1)
