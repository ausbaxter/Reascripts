local function Main()

  local char = gfx.getchar()
  if char ~= 27 and char ~= -1 then
    reaper.defer(Main)
  end
  gfx.update()

end

gfx.clear = 01200--bg color
gfx.init("My Window", 640, 480, 0, 200, 200)
Main()
