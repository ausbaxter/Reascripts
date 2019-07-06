--[[
@version 1.0
@author ausbaxter
@description
  Ausbaxter library functions
@changelog
  initial release
@donation paypal.me/abaxtersound
@noindex true
]]

local err_self = "Error: Missing self object"

local function c_type(object)
    if object.type then return object.type 
    else return type(object)
    end
end

local function t_assert(condition, message)
    -- Throws error from level 3 in the call stack
    -- (3) - Failed Function()
    -- (2) -    t_assert() check in Failed function definition
    -- (1) -        t_assert error line
    if not condition then error(message, 3) end
end

--Data Structures
Queue = {}
Queue.__index = Queue
--[[

]]

function Queue.New()
  self = setmetatable({}, Queue)
  self.type = "queue"
  self.index = 1
  return self
end

function Queue:Enqueue(element)
    t_assert(not self, err_self)
    table.insert(self, element)
end

function Queue:Dequeue()
    t_assert(not self, err_self)
    -- if self.index == 1
end

----------------Debugging---------------------------------------------------
function Log(msg)--Logs messages to the reaper console

  reaper.ShowConsoleMsg(tostring(msg) .. "\n")

end

function LogTrackDepths()
    for i = 0, reaper.CountTracks(0) - 1 do
        local tk = reaper.GetTrack(0,i)
        local f_depth = reaper.GetMediaTrackInfo_Value(tk, "I_FOLDERDEPTH")
        local retval, name = reaper.GetSetMediaTrackInfo_String(tk, "P_NAME", "", false)
        Log(name.. "\t" .. f_depth)
    end
end

function GetItemTakeName(item,take)
    if take == nil then take = 0 end
    local temp_take = reaper.GetMediaItemTake(item,take)
    local retval, name = reaper.GetSetMediaItemTakeInfo_String(temp_take, "P_NAME", "", false)
    return name
end

function PrintColumns(columns)
    for i, column in ipairs(columns) do
        Log("column: " .. i)
        for j, item in ipairs(column) do
            local tn = GetItemTakeName(item.item)
            Log(tn)
        end
    end
end

function PrintTrackName(track)
    local retval, str = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    Print(str)
end

----------------Item Functions----------------------------------------------
--[[
function GetSelectedItems(retval, func)--Returns a table of selected items in per track chronological order.

  local item_count = reaper.CountSelectedMediaItems(0)
  local item_table = {}
  
  if item_count > 0 then
  
    for i = 0, item_count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      func(item)
      table.insert(item_table, item)
    end
    
    return item_table
    
  else
    reaper.ReaScriptError("No items selected!")
  end
  
end
]]

function GetSelectedItems(t_info_values) --Returns a table of selected items with or without item info values.
  
  local item_count = reaper.CountSelectedMediaItems(0)
  
  local sel_items ={}
  local item_value_table = {} 
  local t_info_values = t_info_values or nil
  
  if item_count > 0 then
  
    for i = 0, item_count - 1 do
      
      item = reaper.GetSelectedMediaItem(0, i)
      
      if t_info_values == nil then
      
        --return only selected items  
        table.insert(sel_items, item)  
         
      else
      
        item_value_table["ITEM"] = item
        
        for j, value in ipairs(t_info_values) do
        
          local rval = reaper.GetMediaItemInfo_Value(item, value)            
          item_value_table[value] = rval
          
        end
        
        table.insert(sel_items, ShallowTableCopy(item_value_table))
        
      end
        
    end
    
    return item_count, sel_items
    
  else
    reaper.ReaScriptError("No items selected!")
    return item_count --send item count to enable program flow (ReaScriptError does not end script)
  end
  
end

--add ability to specify which values you want to return, currently no instances in scripts
function GetItemPositionInfo(item)--Returns item start, item length and item end 

  local item_start = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
  local item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  local item_end = item_start + item_length
  
  return item_start, item_length, item_end
  
end

----------------Track Functions--------------------------------------------
function GetSelectedTracks(t_info_values)--Returns a table of selected tracks

  local track_count = reaper.CountSelectedTracks(0)
  local sel_tracks = {}
  local track_value_table = {}
  local t_info_values = t_info_values or nil
  
    if track_count > 0 then
    
    for i = 0, track_count - 1 do
          
          local track = reaper.GetSelectedTrack(0, i)
          
          if t_info_values == nil then
          
            --return only selected items  
            table.insert(sel_tracks, track)  
             
          else
          
            track_value_table["TRACK"] = track
            
            for j, value in ipairs(t_info_values) do
              
              if value == "P_NAME" then --handle track name cases
              
                local _, rval = reaper.GetSetMediaTrackInfo_String(track, value, "", false)
                track_value_table[value] = rval
                
              else
              
                local rval = reaper.GetMediaTrackInfo_Value(track, value)
                track_value_table[value] = rval
                
              end
              
            end
            
            table.insert(sel_tracks, ShallowTableCopy(track_value_table))
            
          end
            
        end
        
        return track_count, sel_tracks
        
      else
        reaper.ReaScriptError("No tracks selected!")
        return track_count --send item count to enable program flow (ReaScriptError does not end script)
      end
   
   --[[
     for i = 0, track_count - 1 do
       local track = reaper.GetSelectedTrack(0, i)
       local retval, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
       local index = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1)
       table.insert(track_table, {["track"] = track, ["name"] = name, ["index"] = index})
     end]]
     
     return track_table
   
end

----------------Marker/Region Functions------------------------------------
function GetMarkers()
  
  local mark_reg_count = reaper.CountProjectMarkers(0)
  local marker_table = {}
  
  for i = 0, mark_reg_count - 1 do
    
    local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    
      if isrgn == false then
      
        table.insert(marker_table, {["index"] = idx, ["name"] = name, ["position"] = pos})
      
      end
  end
  
  table.sort(marker_table, function(a,b) return a["index"] < b["index"] end)
  
  return marker_table
  
end

function GetRegions()--returns a table of all regions in the session including name, position start and end as named elements
  
  local mark_reg_count = reaper.CountProjectMarkers(0)
  local region_table = {}
  
  for i = 0, mark_reg_count - 1 do
    
    local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    
      if isrgn == true then
      
        table.insert(region_table, {["index"] = idx, ["name"] = name, ["start"] = pos, ["end"] = rgnend})
      
      end
  end
  
  table.sort(region_table, function(a,b) return a["index"] < b["index"] end)
  
  return region_table
  
end

----------------Envelope Functions-----------------------------------------


----------------Utility Functions------------------------------------------

function GetInput(s_title, i_num_inputs, t_input_names, pattern)--user-friendly input getter. Returns a table whos indexes are named after your inputs.
  
  pattern = pattern or nil

  local retval, return_csv = reaper.GetUserInputs(s_title, i_num_inputs, TableToCSV(t_input_names, ": "), "")
  
  local table = TableFromCSV(return_csv, t_input_names, pattern)
  
  return retval, table

end

function SortItemsByStart(item_table)--Sorts an existing table by item start value. Does not return anything

  table.sort(item_table, function(a,b) return reaper.GetMediaItemInfo_Value(a,"D_POSITION") < reaper.GetMediaItemInfo_Value(b,"D_POSITION") end)
  
end

function LogItemNamesInTable(table)--Use to log item take names for Debugging
  for i, item in ipairs(table) do
    local take = reaper.GetTake(item,0)
    local retval, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    Log(name .. "\n")
  end
end

function LogTable(table)--log the first element in a table
  for i, thing in ipairs(table) do
    Log(thing .. "\n")
  end
end

function TableFromCSV(csv, keys, pattern)--Converts a csv string into a lua table

  local value_table = {}
  local count = 1
  keys = keys or nil
  pattern = pattern or "%w*"
  
  if keys ~= nil then --handles key input for table
    for i in string.gmatch(csv, pattern) do
      value_table[keys[count]] = i
      count = count + 1
    end
    
  else --handles simple csv parsing to table
    for i in string.gmatch(csv, pattern) do
      value_table[count] = i
      count = count + 1
    end
  end
  
  return value_table
  
end

function TableToCSV(keys, endstring)--Converts a lua table into a csv string

  local table_string = {}
  
  for i, key in ipairs(keys) do
    local newKey = key .. endstring
    table.insert(table_string, newKey)
  end
  
  local user_key_csv = table.concat(table_string, ",")
  return user_key_csv
  
end

function ParseTableKey(t_table, key_name)
  
  local t_new_table = {}
  
  for i, thing in ipairs(t_table) do
    local string = tostring(thing[key_name])
    table.insert(t_new_table, string)
  end
  
  return t_new_table

end

function GetTableLength(t_table)

  local count = 0
  
  for i in pairs(t_table) do count = count + 1 end
  
  return count

end

function ShallowTableCopy(t_table) --Allows passing of 1D tables by value instead of reference

  local t2 = {}
    for k,v in pairs(t_table) do
      t2[k] = v
    end
    return t2

end

function Main()
-- Run this script within Reaper to execute the following code for testing purposes. 



end

Main()