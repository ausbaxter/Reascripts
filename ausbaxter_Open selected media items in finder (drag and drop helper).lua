function FormatPath(p)
  reaper.ShowConsoleMsg(#p)
  for i=1, #p do
    reaper.ShowConsoleMsg(tostring(p[i]))
  end
  reaper.ShowConsoleMsg(p)
  return path
end
item = reaper.GetSelectedMediaItem(0,0)
take = reaper.GetMediaItemTake(item,0)
source = reaper.GetMediaItemTake_Source(take)
name = reaper.GetMediaSourceFileName(source, "")
--reaper.ShowConsoleMsg(name)

FormatPath("C:\\Users\\Austin\\Desktop\\Problems.xlsx,C:\\Users\\Austin\\Desktop\\Original SFX.csv")

--Names will become console arguments :)
--Names will need to be reformatted with \\ for slash escapes!

--os.execute("explorer.exe /select,C:\\Users\\Austin\\Desktop\\Problems.xlsx,C:\\Users\\Austin\\Desktop\\Original SFX.csv")

