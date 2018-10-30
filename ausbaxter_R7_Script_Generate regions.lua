dialog_column_name = "PHRASE DESCRIPTION"
region_length = 20

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

function main()
    local retval, file = reaper.GetUserFileNameForRead("C:\\Users\\ausba\\Desktop", "Browsing for R7-Script", ".csv")
    if string.find(file, ".csv") == nil then reaper.ReaScriptError("R7 Script import failed. Please import a csv file.") end

    local t_csv = {}
    for line in io.lines(file) do
        row = ParseCSVLine(line, ",")
        table.insert(t_csv, row)
    end

	local dialog_column = 1

	c_region_start = 0

    for i, row in ipairs(t_csv) do
        if i == 1 then
			for k, column in ipairs(row) do
				if column == dialog_column_name then
					dialog_column = k
					break
				end
			end
		else
			reaper.AddProjectMarker(0, true, c_region_start, c_region_start + region_length, row[dialog_column], -1)
			c_region_start = c_region_start + region_length
        end
    end
end

main()