function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

r_val, file = reaper.GetUserFileNameForRead("", "Import Pro Tools Memory Locations", ".txt")

tsv = false
tsv_idx = 1

if r_val then
    
    for line in io.lines(file) do --get line
        if tsv == true then
        
            if tsv_idx > 1 then
                
                num,loc,tr,unit,name = line:match("(%d+)%s+([%d:]+)%s+(%d+)%s+(%a+)%s+\t([%d%w%p%s]+)\t")
                name = trim(name)--no need for spaces
                reaper.AddProjectMarker(0, false, tr/sample_rate, 0, name, num)
                
            end
            tsv_idx = tsv_idx + 1
        end
        if line == "M A R K E R S  L I S T I N G" then tsv = true end
        
        if line:find("SAMPLE RATE:") then
            sample_rate = line:match("SAMPLE RATE:%s+([%d%p]+)")
            sample_rate = tonumber(sample_rate)
        end
        
    end

end
