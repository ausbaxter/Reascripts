function msg(m)
  reaper.ShowConsoleMsg(tostring(m))
end

Button = {}
function Button:new(x,y,w,h,txt,func)
  local self = {}
  setmetatable(self,Button)
  Button.__index = Button
  
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.txt = txt
  self.func = func
  
  return self
end

function Button:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end

function Button:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end

function Button:mouseClick()
  return MouseClick() and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)  
end

function Button:draw()
  local x,y,w,h = self.x, self.y, self.w, self.h
  
  if self:mouseIN() then
    gfx.set(.5)
  else
    gfx.set(1) 
  end
  
  if self:mouseClick() then self:func() end
  
  gfx.rect(x,y,w,h,false)
  gfx.x,gfx.y = x+3,y+2
  gfx.setfont(1,"Arial",12)
  gfx.drawstr(self.txt)
end

Envelope = {}
function Envelope:new(env,str)
  local self = {}
  setmetatable(self,Envelope)
  Envelope.__index = Envelope
  
  self.env = env
  self.str = str
  
  return self
end

function MouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1
end

function Init()
  local title = "Multi-envelope Editing"
  local x,y = reaper.GetMousePosition()
  w,h = 200, 100
  t_envs = {}
  
  b_reset = Button:new(85,8,40,15,"reset",ResetEnvs)
  b_add = Button:new(140,8,40,15,"add env",AddEnv)
  
  last_mouse_cap = 0
  mouse_ox, mouse_oy = -1, -1
  
  gfx.init(title,w,h,0,x,y)
end

function DrawEnv()
  gfx.y = 30
  for i, env in ipairs(t_envs) do
    gfx.x = 15
    gfx.setfont(1,"Arial",12)
    gfx.drawstr(env.str)
    gfx.y = 30 +  i * 15
  end
end

function Draw()
  w,h = gfx.w,gfx.h
  gfx.set(1)
  
  DrawEnv()
  
  --Title
  gfx.line(10,25,w - 10, 25)
  gfx.x,gfx.y = 10,8
  gfx.setfont(1,"Arial",15)
  gfx.drawstr("Envelopes")
  
  b_reset:draw()
  b_add:draw()
  
end

function EnvExist(env2chk)
  for i, env in ipairs(t_envs) do
    if env2chk == env.env then return true end
  end
  return false
end

function AddEnv()
  local env = reaper.GetSelectedEnvelope(0)
  if EnvExist(env) then return end
  
  local _,trk = reaper.GetTrackName(reaper.Envelope_GetParentTrack(env),"")
  local _,e_name = reaper.GetEnvelopeName(env, "")
  local str = trk .. " | " .. e_name
  table.insert(t_envs,Envelope:new(env,str))
end

function ResetEnvs()
  t_envs = {}
end

function NewPoint(det)
  if det ~= "env_point" then pnt = false end
  if MouseClick() then
    msg("click")
    if det == "env_point" and pnt == false then
      pnt = true
      return true
    end
  end
end

function MonitorEnv()
  local win,seg,det = reaper.BR_GetMouseCursorContext()
  if win == "arrange" and seg == "envelope" then
    local f_env = reaper.BR_GetMouseCursorContext_Envelope()
      if EnvExist(f_env) then
        if NewPoint(det) then msg("newpoint") end
      end
  end
  if MouseClick() then
    msg("click")
  end
end

function Main()
  mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y
   
  Draw()
  MonitorEnv()
  
  last_mouse_cap = gfx.mouse_cap
  
  local char = gfx.getchar()
  if char ~= -1 then reaper.defer(Main)
  else gfx.quit()end
  
  gfx.update()
end

Init()
Main()

