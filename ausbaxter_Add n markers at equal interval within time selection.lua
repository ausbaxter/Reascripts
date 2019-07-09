--[[
@version 1.0
@author ausbaxter
@description Add number of markers at equal interval within time selection
@changelog
  [1.0] - 2019-07-09
  + Initial release
@donation paypal.me/abaxtersound
]]

--parses csv inputs from reaper.GetUserInputs()
function Split(user_string, keys)

  local value_table = {}
  local count = 1
  
  for i in string.gmatch(user_string, "(%w+)") do
    value_table[keys[count]] = i
    count = count + 1
  end
  
  return value_table
  
end

--returns csv string for use in reaper.GetUserInput()'s field names.
function ConcatKeys(keys, endstring)

  local table_string = {}
  
  for i, key in ipairs(keys) do
    local newKey = key .. endstring
    table.insert(table_string, newKey)
  end
  
  local user_key_csv = table.concat(table_string, ",")
  return user_key_csv
  
end

--create markers
function CreateMarkers(name, start, interval, n)

  local insertion_point = start
  
  for i = 1, n do
    reaper.AddProjectMarker(0, false, insertion_point, 0, name, -1, reaper.ColorToNative(0,0,0))
    insertion_point = insertion_point + interval
  end 
  
end

function Main()
  
  reaper.Undo_BeginBlock()
  
  local user_keys = {"n", "Name"}
  local num_inputs = 2
  local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, 0)
  local ts_length = ts_end - ts_start
  
  if ts_start ~= ts_end then
  
    retval, user_input = reaper.GetUserInputs("Add number of markers at equal interval within time selection", num_inputs, ConcatKeys(user_keys, ": "), "")
    input_result = Split(user_input,user_keys)
    
    marker_num = tonumber(input_result["n"])
    marker_name = input_result["Name"]
    
    if retval ~= 1 then --if user doesn't cancel
    
      if marker_num ~= nil and marker_name ~= nil then -- check if user input values
      
        marker_interval = ts_length / marker_num
        CreateMarkers(marker_name, ts_start, marker_interval, marker_num)
        
      else --if user did not enter useful values throw error
        
        reaper.ReaScriptError("Error: Must enter proper input values. 'n' is number of desired markers, 'name' is the name of those markers.")
        
      end
      
    end
    
  else --if user does not have a time selection throw error
    
    
    reaper.ReaScriptError("Error: Must specify a time selection.")
    
  end
  
  reaper.Undo_EndBlock("Add number of markers at equal interval within time selection", -1)
  
end

Main()
