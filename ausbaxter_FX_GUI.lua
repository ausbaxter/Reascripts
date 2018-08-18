---------------------------------------Display-----------------------------------------

Display = {}
Display.__index = Display

function Display:New(m,scaling_func)
    local self = setmetatable({}, Display)
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
    self.margin = m == nil and 0 or m
    self.has_dblclick = true --move to individual elements to prevent double click bug
    self.elements = {}
    self.update = true
    self.scaling_func = scaling_func or nil --the graphical scaling function for the element.
    return self
end

function Display:Add(elem,x,y,w,h)
    local x2 = self.x + self.margin + x
    local y2 = self.y + self.margin + y
    local w2 = w + self.margin + x
    local h2 = h + self.margin + y
    table.insert(self.elements, elem.New(x2,y2,w2,h2))
end

function Display:UpdateDimensions()
    if self.scaling_func == nil then return end
    local x, y, w, h = self.scaling_func()
    self.x = x
    self.y = y
    self.w = w - self.x
    self.h = h - self.y
end

function Display:Draw()
    gfx.dest = self.buffer - 1
    SetColor(72,72,72)
    gfx.rect(self.x, self.y, self.w, self.h, false)

    gfx.dest = self.buffer
    SetColor(51,51,51)
    gfx.rect(self.x, self.y, self.w, self.h, true)
    for i, elem in pairs(self.elements) do
        elem:Draw()
    end
end

--------------------------------Macro Display SubClass------------------------------- Can make this a more generic slotted class for macro and param display to inherit from
Slotted_Display = {}
Slotted_Display.__index = Slotted_Display

function Slotted_Display:New(scaling_func, slot_height, buffer)
    local self = setmetatable(Display:New(0,scaling_func), Slotted_Display)

    self.slot_height = slot_height
    --self.scaling_func = scaling_func or nil

    self.track_guid = ""

    self.selected_index = -1

    self.buffer = buffer

    self.lmdown = false
    self.rmdown = false

    self.scroll_offset = 0
    self.elements_height = 0

    self.scroll_bar_h = 0

    --Store the height of the entire macro set to uset
    --to check if scrolling is possible or not.
    --also set y
    return self
end

setmetatable(Slotted_Display, Display)

function Slotted_Display:LeftClick(index)
    if alt then
        if index == nil then index = -1 end
        self:DelSlot(index)
        return
    end

    if index ~= self.selected_index then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end

    if self.elements[index] ~= nil then
        self.elements[index]:LeftClick()
        self.selected_index = index
        self.update = true
    end
end

function Slotted_Display:Scroll(scroll) --have to find out how to quantize the slot scrolling or better check the offset when inserting new slots
    --if scroll ~= 0 then Print("slot height: "..self.elements_height.." > than self: "..self.h.. " Offset: "..self.scroll_offset) end

    if scroll ~= 0 then
        self.scroll_offset = self.scroll_offset + scroll
        local scroll_limit = (self.h - self.elements_height) - 4 --bug here when scrolled and height becomes smaller than h
        for i, macro in pairs(self.elements) do
            local new_y = macro.orig_y + self.scroll_offset
            if self.scroll_offset > 0 then
                new_y = macro.orig_y
                self.scroll_offset = 0
            elseif self.scroll_offset < scroll_limit then 
                if (self.h - self.elements_height) - 4 < 0 then
                    new_y = macro.orig_y + scroll_limit
                    self.scroll_offset = scroll_limit
                elseif self.scroll_offset < 0 then --not complete
                    self.scroll_offset = 0
                    new_y = macro.orig_y
                end                    
            end
            macro.y = new_y
        end
    end
end

function Slotted_Display:UpdateDimensions()
    if self.elements_height > self.h then 
        self.scroll_bar_h = self.h - (self.elements_height - self.h)
        if self.scroll_bar_h <= 0 then self.scroll_bar_h = 20 end
    else
        self.scroll_bar_h = 0
    end
    Display.UpdateDimensions(self)
end

function Slotted_Display:AddSlot(name)
    local m = 4
    name = name or ""
    local slot = Slot:New(self.x + m, --[[self.scroll_offset +]] self.y + (#self.elements * self.slot_height + m), self.x + self.w - m, self.slot_height - 2)
    slot.text = name .. #self.elements + 1
    self.elements_height = (#self.elements + 1) * self.slot_height
    table.insert(self.elements, slot)
    self.update = true
    --save to project ex state??
end

function Slotted_Display:DelSlot(index)
    local m = 4
    local del_btn_clicked = false

    if index == nil then
        index = self.selected_index
        del_btn_clicked = true
    end
    
    if index == -1 then return end

    self.update = true

    if index <= #self.elements then
        table.remove(self.elements, index)
        self:Scroll(self.slot_height)
        self.elements_height = self.elements_height - self.slot_height
        for i = index, #self.elements do
            local base_y = self.y + ((i-1) * self.slot_height + m)
            self.elements[i].y = self.scroll_offset + base_y
            self.elements[i].orig_y = base_y
        end
    end

    if self.elements[index] ~= nil then
        if index == self.selected_index then
            if del_btn_clicked then
                self.elements[self.selected_index].selected = true
            else
                self.elements[self.selected_index].selected = false
                self.selected_index = -1
            end
        elseif index < self.selected_index then
            self.selected_index = self.selected_index - 1
        end
    else
        if index == #self.elements + 1 and index ~= self.selected_index then return end
        self.selected_index = -1
    end
end

function Slotted_Display:Draw()
    if self.update then
        gfx.setimgdim(self.buffer - 1, -1, -1)
        gfx.setimgdim(self.buffer, -1, -1)
        gfx.setimgdim(self.buffer - 1, self.x + self.w, self.y + self.h)
        gfx.setimgdim(self.buffer, self.x + self.w, self.y + self.h)
        --draw scroll bar

        gfx.x = 0 gfx.y = 0
        Display.Draw(self) --call parent draw method, with any added shtuff
        if self.scroll_bar_h > 0 then gfx.roundrect(self.x + self.w - 4, self.y + self.scroll_offset/(self.elements_height - self.h) * (self.scroll_bar_h - self.h), 4, self.scroll_bar_h-5, 2) end
        self.update = false
    end
    BlitBuffer(self.buffer, self.x, self.y, self.w, self.h)
    BlitBuffer(self.buffer-1, self.x, self.y, self.w, self.h)
    self.scroll = 0
    --gfx.blit(0,1,0,self.x, self.y, self.w + self.x, self.h + self.y, self.x, self.y, self.w + self.x, self.h + self.y)
end

---------------------------------------Macro-----------------------------------------
Slot = {}
Slot.__index = Slot

function Slot:New(x,y,w,h)
    local self = setmetatable({}, Slot)
    self.x = x
    self.y = y
    self.w = w - self.x
    self.h = h
    self.orig_y = self.y
    self.text = ""
    self.selected = false
    self.last_click = 0
    return self
end

--click function that stores current time and compares to last click in order to implement double click feature.

function Slot:LeftClick()
    self.selected = true
    if self.last_click ~= nil and reaper.time_precise() - self.last_click < 0.4 then 
        self:DblClick() 
        self.last_click = 0 
    end
    self.last_click = reaper.time_precise()
end

function Slot:DblClick()
    local rval, input = reaper.GetUserInputs("Rename " .. self.text, 1, "New Name:", self.text)
    if rval then
        self.text = input
        Print("True")
    end
end

function Slot:Draw()
    local text_r, text_g, text_b
    local slot_r, slot_g, slot_b
    if self.selected then
        slot_r = 170 slot_g = 170 slot_b = 170
        text_r = 36 text_g = 43 text_b = 43
    else
        text_r = 170 text_g = 170 text_b = 170
        slot_r = 36 slot_g = 43 slot_b = 43
    end
    SetColor(slot_r,slot_g,slot_b)
    gfx.rect(self.x, self.y, self.w, self.h, true)

    local text_width, text_height = gfx.measurestr(self.text)

    if text_width >= self.w then
        gfx.x = self.x
    else
        gfx.x = self.x + self.w / 2 - math.floor(text_width/2)
    end
    gfx.y = self.y + self.h / 2 - math.floor(text_height/2)
    SetColor(text_r,text_g,text_b)
    gfx.drawstr(self.text)
    gfx.x = 0 gfx.y = 0
end

--------------------------------------Button--------------------------------------

Button = {}
Button.__index = Button

function Button.New(text,func,scaling_func,color,buffer)
    local self = setmetatable({}, Button)
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
    if color == -1 or color == nil then
        self.r = 1 self.g = 1 self.b = 1
    else
        self.r, self.g, self.b = reaper.ColorFromNative(color)
    end
    self.LeftClick = func
    self.scaling_func = scaling_func
    self.text = text
    self.buffer = buffer
    self.lmdown = false
    self.rmdown = false
    self.has_dblclick = false
    self.update = false
    return self
end

function Button.UpdateDimensions(self)
    local x, y, w, h = self.scaling_func()
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function Button.Draw(self)
    if self.update then
        gfx.dest = self.buffer
        gfx.setimgdim(self.buffer, -1, -1)
        gfx.setimgdim(self.buffer, gfx.w, 50)
        --Print("drawing button")
        gfx.r = self.r gfx.g = self.g gfx.b = self.b
        gfx.rect(self.x, self.y, self.w, self.h, false)

        gfx.r = 0.4 gfx.g = 0.4 gfx.b = 0.4
        gfx.rect(self.x+1, self.y+1, self.w-2, self.h-2, true)

        gfx.r = 1 gfx.g = 1 gfx.b = 1
        local str_w = gfx.measurestr(self.text)
        str_h = gfx.texth
        gfx.x = self.x + self.w / 2 - (str_w/2)
        gfx.y = self.y + self.h / 2 - (str_h/2)
        gfx.drawstr(self.text)
        gfx.x = 0 gfx. y = 0
    end
    BlitBuffer(self.buffer, self.x, self.y, self.w, self.h, self.scroll)
end
----------------------------------------------------------------------------

function UpdateMouseStates()

    mouse_update = false
    left_mouse_down = false
    left_mouse_up = false
    right_mouse_down = false
    right_mouse_up = false

    current_mouse_cap = gfx.mouse_cap
    mouse_wheel = gfx.mouse_wheel/5

    if mouse_wheel ~= 0 then mouse_update = true end

    if previous_mouse_cap ~= nil then
        if current_mouse_cap&1==1 and previous_mouse_cap&1==0 then
            left_mouse_down = true
            left_mouse_hold = true
            mouse_update = true
        elseif current_mouse_cap&1==0 and previous_mouse_cap&1==1 then
            left_mouse_up = true
            left_mouse_hold = false
            mouse_update = true
        elseif current_mouse_cap&2==2 and previous_mouse_cap&2==0 then
            right_mouse_down = true
            right_mouse_hold = true
            mouse_update = true
        elseif current_mouse_cap&2==0 and previous_mouse_cap&2==2 then
            right_mouse_up = true
            right_mouse_hold = false
            mouse_update = true
        end
    end

    ctrl = current_mouse_cap&4==4
    shift = current_mouse_cap&8==8
    alt = current_mouse_cap&16==16
    
    previous_mouse_cap = current_mouse_cap
    gfx.mouse_wheel = 0
end

function MouseIsOverlaping(element,idx)
    local function Overlap(elem)
        return gfx.mouse_x >= elem.x and gfx.mouse_x <= elem.x+elem.w and gfx.mouse_y >= elem.y and gfx.mouse_y <= elem.y+elem.h
    end

    if Overlap(element) then
        if element.elements ~= nil then
            for i, sub_elem in pairs(element.elements) do
                if Overlap(sub_elem) then
                    return true, idx, i
                end
            end
            return true, idx, nil
        else
            return true, idx, nil
        end
    else
        return false, nil, nil
    end
end

function GetTrack(idx)
    if idx == 0 then
        return reaper.GetMasterTrack(0)
    else
        return reaper.GetTrack(0,idx-1)
    end
end

function BlitBuffer(buffer,x,y,w,h,scroll)
    gfx.dest = -1
    scroll = scroll or 0
    gfx.blit(buffer, 1, 0, x, y, w + x, h + y, x, y, w + x, h + y)
end

function SetColor(r,g,b)
    gfx.r, gfx.g, gfx.b = r/255,g/255,b/255
end

--Element Scaling Functions
function Macro_Display_Dimensions() return 10, 50, 100, gfx.h - 10 end
function Macro_Add_Button_Dimensions()
    local p_x, p_y, p_w, p_h = Macro_Display_Dimensions()
    return p_x + 5, p_y - 20, 35, button_height
end
function Macro_Del_Button_Dimensions()
    local p_x, p_y, p_w, p_h = Macro_Display_Dimensions()
    return 60, p_y - 20, 35, button_height
end

function Param_Display_Dimensions() return 99, 50, gfx.w / 2 - 10, gfx.h - 10 end
function Param_Add_Button_Dimensions()
    local p_x, p_y, p_w, p_h = Param_Display_Dimensions()
    return p_x + 5, p_y - 20, (p_w - p_x) * 0.5 - 10, button_height
end
function Param_Del_Button_Dimensions()
    local p_x, p_y, p_w, p_h = Param_Display_Dimensions()
    return (p_w - (p_w - p_x) * 0.5), p_y - 20, (p_w - p_x) * 0.5 - 5, button_height
end

function Scale_Display_Dimensions() return gfx.w / 2, 50, gfx.w - 10, 2 * gfx.h / 3 - 10 end
function Node_Display_Dimensions() return gfx.w / 2, 2 * gfx.h / 3, gfx.w -10, gfx.h - 10 end

function Print(s,reset)
    if reset ~= nil and reset then reaper.ShowConsoleMsg("") end
    reaper.ShowConsoleMsg(tostring(s).."\n")
end


function Main()
    current_width = gfx.w
    current_height = gfx.h

    --Get current Mouse and Char
    char = gfx.getchar()

    --Check current selected (first) track
    current_track = reaper.GetSelectedTrack(0, 0)
    if current_track ~= previous_track then Print("Changed Track Selection") track_selection_changed = true end
    previous_track = current_track

    UpdateMouseStates()

    for idx, elem in pairs(GUI_Elements) do
        
        local over, element, sub_element = MouseIsOverlaping(elem, idx)

        if mouse_update and over then

            if elem.Scroll ~= nil and mouse_wheel ~= 0 then elem:Scroll(mouse_wheel) end

            if left_mouse_down then 
                last_clicked_element = element
                last_clicked_sub_element = sub_element
            elseif right_mouse_down then 
                last_clicked_element = element
                last_clicked_sub_element = sub_element

            elseif left_mouse_up and element == last_clicked_element 
            and sub_element == last_clicked_sub_element 
            and elem.LeftClick ~= nil then
                elem:LeftClick(sub_element)

            elseif right_mouse_up and element == last_clicked_element 
            and sub_element == last_clicked_sub_element
            and elem.RightClick ~= nil then
                elem:RightClick(sub_element)
            end
        end

        --Update dimensions on window resize
        if previous_height ~= current_height or previous_width ~= current_width then
            elem:UpdateDimensions()
            elem.update = true
        end

        --Draw or blit GUI elements
        elem:Draw()
    end

    if init then 
        GUI_Elements["Test"]:AddSlot("Track")
        GUI_Elements["Test"]:AddSlot("Items")
        GUI_Elements["Test"]:AddSlot("Envelopes")
    end

    prev_track_name = track_name
    previous_width = current_height
    previous_height = current_height
    init = false
    if char ~= -1 then
        gfx.update()
        reaper.defer(Main)
    end
end

reaper.atexit(function()gfx.quit()end)

global_w = 650
global_h = 200
global_x = 400
global_y = 400

init = true
left_mouse_down = false
left_mouse_hold = false
left_mouse_up = false
right_mouse_down = false
right_mouse_hold = false
right_mouse_up = false
last_clicked_element = nil
last_clicked_sub_element = nil

GUI_Elements = {}

button_height = 15

gfx.clear = reaper.ColorToNative(51, 51, 51)

os = reaper.GetOS()
if os == "Win32" or os == "Win64" then font_size = 13 else font_size = 11 end

gfx.setfont(1, "Arial", font_size)

gfx.init("Macro Control", global_w, global_h, 0, global_x, global_y)

GUI_Elements["Macro_Display"] = Slotted_Display:New(Macro_Display_Dimensions, 20, 1)
GUI_Elements["Macro_Add_Button"] = Button.New("Add", function() GUI_Elements["Macro_Display"]:AddSlot() end, Macro_Add_Button_Dimensions, reaper.ColorToNative(0, 0, 0),2)
GUI_Elements["Macro_Del_Button"] = Button.New("Del", function() GUI_Elements["Macro_Display"]:DelSlot() end, Macro_Del_Button_Dimensions, reaper.ColorToNative(0, 0, 0),2)
GUI_Elements["Test"] = Slotted_Display:New(function() return 150, 50, 300, 150 end, 25, 5)

--GUI_Elements["Param_Display"] = Display.New(0, Param_Display_Dimensions)
--GUI_Elements["Scale_Display"] = Display.New(0, Scale_Display_Dimensions)
--GUI_Elements["Node_Display"] = Display.New(0, Node_Display_Dimensions)

--GUI_Elements["Param_Add_Button"] = Button.New("Add", function()Print("AddParam\n")end, Param_Add_Button_Dimensions, reaper.ColorToNative(0, 0, 0))
--GUI_Elements["Param_Del_Button"] = Button.New("Del", function()Print("DelParam\n")end, Param_Del_Button_Dimensions, reaper.ColorToNative(0, 0, 0))

Main()