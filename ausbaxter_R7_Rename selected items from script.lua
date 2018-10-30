NamingConvention = {"LINE_ID"}
--Enter the [COLUMN NAME]s in the desired order for naming. 

function ParseCSVLine (line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
        else
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

function GetNamingMap(csv)
    local lookuptable = {}
    for j, name in ipairs(NamingConvention) do
        for k, column in ipairs(csv[1]) do
            local strip_column = string.match(column, "[_%w]+")
            if strip_column == name then
                table.insert(lookuptable, k)
            end
        end
    end
    return lookuptable
end

function GetSelectedMediaItemsByTracks()
    local items = {}
    local tracks = {}
    local prev_track
    local init = true
    for i=0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        if track == prev_track or init then
            table.insert(items, item)
        else
            table.insert(tracks, items)
            items = {}
            table.insert(items, item)
        end
        prev_track = track
        init = false
    end
    table.insert(tracks, items)
    return tracks
end

function main()

    reaper.Undo_BeginBlock()

    local t_csv = {}

    local r, file = reaper.GetProjExtState(0, "R7-Script_Name_Source", "path")

    if r ~= 1 then
        retval, file = reaper.GetUserFileNameForRead("C:\\Users\\ausba\\Desktop", "Browsing for R7-Script", ".csv")
        if not retval then return end
        if string.find(file, ".csv") == nil then reaper.ReaScriptError("R7 Script import failed. Please import a csv file.") end
        reaper.SetProjExtState(0, "R7-Script_Name_Source", "path", file)
    end

    for line in io.lines(file) do
        row = ParseCSVLine(line, ",")
        table.insert(t_csv, row)
    end

    local lookuptable = GetNamingMap(t_csv)
    local tracks = GetSelectedMediaItemsByTracks()

    for i, track in ipairs(tracks) do

        for j, row in ipairs(t_csv) do

            local filename = ""

            if j > 1 then
    
                for k, idx in ipairs(lookuptable) do
                    if k == #lookuptable then delimiter = ""
                    else delimiter = "_" end
                    filename = filename .. row[idx] .. delimiter
                end

                local item = track[j-1]
                local take = reaper.GetTake(item, 0)
                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", filename, true)
            end
        end
    end

    reaper.Undo_EndBlock("Rename items from R7 script", -1)

end

main()