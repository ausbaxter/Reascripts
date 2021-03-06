--[[
@version 1.0
@author ausbaxter
@description
  ausbaxter library functions
@changelog
  initial release
@donation paypal.me/abaxtersound
@noindex true
]]

OS = reaper.GetOS()
DELIM = string.find(OS, "Win") and "\\" or "/"

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

function table.contains(t,match) --returns if the second parameter matches a table element
  for i, elem in ipairs(t) do if elem == match then return true end end
  return false
end

function GetAllSelectedItemsInTable()
--Returns all selected items in table
  local t_items = {}
  for i = 0, reaper.CountSelectedMediaItems() - 1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      table.insert(t_items,item)
  end
  return t_items
end

function GetGroupedItemsInTable()
--Returns selected items and the members of each of the selected item's group.
  local t_items = {}
  local t_grp_nums = {}
  --loop through selected items getting groups
  for i = 0, reaper.CountSelectedMediaItems() - 1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      local group_num = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
      if not table.contains(t_grp_nums, group_num) and group_num ~= 0 then table.insert(t_grp_nums,group_num) end
  end
  --loop through all items considering all groups
  for i = 0, reaper.CountMediaItems(0) - 1 do
      local item = reaper.GetMediaItem(0,i)
      for j, g in ipairs(t_grp_nums) do
          if reaper.GetMediaItemInfo_Value(item, "I_GROUPID") == g then table.insert(t_items,item) end
      end
  end
  return t_items
end

function GetAllSelectedTracksInTable()
--Returns all selected tracks in table
  local t_tracks = {}
  for i = 0, reaper.CountSelectedTracks(0) - 1 do
      local track = reaper.GetSelectedTrack(0,i)
      table.insert(t_tracks,track)
  end
  return t_tracks
end

function TableFromCSV(csv, keys, pattern)
--Converts a csv string into a lua table
  local value_table = {}
  local count = 1
  local keys = keys or nil
  local pattern = pattern or "%w*"
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

function TableToCSV(keys, endstring)
--Converts a lua table into a csv string
  local table_string = {}
  for i, key in ipairs(keys) do
      local newKey = key .. endstring
      table.insert(table_string, newKey)
  end
  local user_key_csv = table.concat(table_string, ",")
  return user_key_csv
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

function CommandParametersExist()

  reaper_path = reaper.GetResourcePath() .. DELIM .. "Xenakios_Commands.ini"
  if not reaper.file_exists(reaper_path) then 
      error("SWS Extension is required for this script.", "SWS Not Installed", 2)
      return false
  end

  return true, reaper_path

end

function GetCommandParameterFades()

  local exists, path = CommandParametersExist()

  if exists then

    local command_parameters = { A = {}, B = {} }

    retval, ini_A_fade_in_len = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEINTIMEA", "5.0", path)
    retval, ini_A_fade_out_len = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEOUTTIMEA", "1.0", path)
    retval, ini_B_fade_in_len = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEINTIMEB", "1.0", path)
    retval, ini_B_fade_out_len = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEOUTTIMEB", "1.0", path)

    retval, ini_A_fade_in_shape = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEINSHAPEA", "2", path)
    retval, ini_A_fade_out_shape = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEOUTSHAPEA", "2", path)
    retval, ini_B_fade_in_shape = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEINSHAPEB", "2", path)
    retval, ini_B_fade_out_shape = reaper.BR_Win32_GetPrivateProfileString("XENAKIOSCOMMANDS", "FADEOUTSHAPEB", "2", path)

    command_parameters.A.fade_in_len = tonumber(ini_A_fade_in_len) * 1000
    command_parameters.A.fade_out_len = tonumber(ini_A_fade_out_len) * 1000
    command_parameters.B.fade_in_len = tonumber(ini_B_fade_in_len) * 1000
    command_parameters.B.fade_out_len = tonumber(ini_B_fade_out_len) * 1000

    command_parameters.A.fade_in_shape = tonumber(ini_A_fade_in_len)
    command_parameters.A.fade_out_shape = tonumber(ini_A_fade_out_len)
    command_parameters.B.fade_in_shape = tonumber(ini_B_fade_in_len)
    command_parameters.B.fade_out_shape = tonumber(ini_B_fade_out_len)
    
    return command_parameters
  
  end

end

--[[ MULTIACTION FUNCTIONS ]]

--ausbaxter_Insert n degree chord in mouse octave (key snap overrides c major default) Source

function InsertChordFromScaleDegree(degree)

	--[[
		TODO
		- read reascale files to get new scales
		- have project setting allowing for extended chords to be created. (use separate function that scans a chord and modifies it based on the scan ie make triad, make augmented 2nd make diminished etc)
		- have user settings for a how the extensions should be created (gui required, save/load required)
		- using this as a template allow the user to create different chords based on hovered mouse note augmented, sus, major, minor, diminished, etc.
	]]

	local snap = "snap_enabled"
	local def_vel = "default_note_vel"
	local def_chan = "default_note_chan"
	local def_len = "default_note_len"
	local scale_on = "scale_enabled"
	local default_scales = {"Major","Natural minor","Melodic minor","Harmonic minor","Pentatonic","Blues"}
	local default_scale_notes = {"102034050607","102304056070","102304050067","102304050607","102030040500","100304450070"}
	local scale_index = degree

	function DefaultScaleSelected(scale)
		for i, scale_check in ipairs(default_scales) do
			if scale_check == scale then return true end
		end
		return false
	end

	function SearchScale(s, degree)
		for i = 1, s:len() do
			local index = s:sub(i,i)
			if degree == tonumber(index) then return i end
		end
		return -1
	end

	function GetDefaultScale(name)
		for i, s in ipairs(default_scales) do
			if name == s then return default_scale_notes[i] end
		end
		return nil
	end

	function Main()
		local editor = reaper.MIDIEditor_GetActive()
		local take = reaper.MIDIEditor_GetTake(editor)
		local setting_strings = {snap,def_vel,def_chan,def_len,scale_on}
		local settings = {}

		-- reaper.ShowConsoleMsg("==============Default Settings=============\n")
		for i, s in ipairs(setting_strings) do
			settings[s] = reaper.MIDIEditor_GetSetting_int(editor, s)
			-- reaper.ShowConsoleMsg(s ..": " ..settings[s].."\n")
		end

		local retval, root, scale, name = reaper.MIDI_GetScale(take, 0, 0, 0)
		settings["scale_root"] = root
		settings["scale"] = scale
		settings["scale_name"] = name
		--reaper.ShowConsoleMsg("root: "..root.."\tscale: "..scale.."\tname: "..name.."\n")

		cc_window, cc_segment = reaper.BR_GetMouseCursorContext()
		if cc_window == "midi_editor" and cc_segment == "notes" then
			local retval, inline, note_row = reaper.BR_GetMouseCursorContext_MIDI()
			local grid, swing, note_size = reaper.MIDI_GetGrid(take) --0 if following grid size
			
			--item position obeys grid (clean up later)
			local cursor = reaper.BR_GetMouseCursorContext_Position()
			local cursor_location = reaper.MIDI_GetPPQPosFromProjTime(take, cursor)
			local cursor_end = reaper.MIDI_GetPPQPosFromProjQN(take, grid + reaper.MIDI_GetProjQNFromPPQPos(take, cursor_location))
			local measure_start = reaper.MIDI_GetPPQPos_StartOfMeasure(take, cursor_location)
			local tick_offset = cursor_end - cursor_location
			local note_start = math.floor((cursor_location - measure_start) / tick_offset) * tick_offset + measure_start
			local note_end = reaper.MIDI_GetPPQPosFromProjQN(take, grid + reaper.MIDI_GetProjQNFromPPQPos(take, note_start))
			if inline == 1 then reaper.ReaScriptError("Inserting chords does not work with inline editors.") return end
			local desired_octave = math.floor((note_row - root)/12)
			--reaper.ShowConsoleMsg("note pitch: "..note_row.."\n".."desired octave: "..desired_octave.."\n".."cursor position: "..cursor_location.."\n".."note end: "..note_end.." ticks\n".."grid: "..grid.."\n".."note start: "..note_start.."\n".."tick offset: "..tick_offset.."\n")

			if settings[scale_on] == 1 then
				scale_string = GetDefaultScale(name)
				if scale_string == nil then
					--reaper.ShowConsoleMsg("\nDefault Scale not found, searching reascale files\n")
					return
				end
			else
				scale_string = default_scale_notes[1]
			end
			--need to read reapeaks files in user directory to get missing scales.

			local base_note = desired_octave * 12 + root
			local root_index = SearchScale(scale_string, scale_index) - 1
			-- reaper.ShowConsoleMsg("root offset = "..root_index.."\n")
			if root_index == -1 then --[[reaper.ShowConsoleMsg("root N/A\n")]] return end
			for i = 0, 2 do
				local note_offset = scale_index + 2 * i
				local wrap = 0
				if note_offset > 7 then 
					note_offset = note_offset - 7 
					wrap = 12 
				end
				local next_index = SearchScale(scale_string, note_offset) - 1 - root_index + wrap
				local note = base_note + root_index + next_index
				-- reaper.ShowConsoleMsg("Note: " .. note.."\n")
				reaper.MIDI_InsertNote(take, true, false, note_start+1, note_end-1, settings[def_chan], note, settings[def_vel], false)
			end

			reaper.MIDI_Sort(take)
		end
	end  

	Main()

end