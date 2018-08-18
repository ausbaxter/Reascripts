---------------------------------------Scaling Object Base Class-----------------------------------------

ScalingObject = {}
ScalingObject.__index = ScalingObject

function ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer)
    local self = setmetatable({}, ScalingObject)
    self.x = math.floor(x)
    self.y = math.floor(y)
    self.w = math.floor(w)
    self.h = math.floor(h)

    self.x_offset = x_offset or 0
    self.y_offset = y_offset or 0
    self.w_offset = w_offset ~= nil and w_offset - self.x_offset or -self.x_offset
    self.h_offset = h_offset ~= nil and h_offset - self.y_offset or -self.y_offset

    self.x_scale = self.x / gfx.w
    self.y_scale = self.y / gfx.h
    self.w_scale = self.w / gfx.w
    self.h_scale = self.h / gfx.h
    self.w_abs = gfx.w - self.w
    self.h_abs = gfx.h - self.h
    self.min_w = 0
    self.min_h = 0
    self.update_x = true
    self.update_y = true
    self.update_w = true
    self.update_h = true

    self.lmdown = false
    self.rmdown = false

    if buffer == nil then --child classes must implement their own Draw(), can use this buffer
        self.buffer = AllocateNewBuffer()
    elseif buffer >= -1 then
        self.buffer = buffer
    end
    return self
end

function ScalingObject:UpdateDimensions()
    self.x = self.update_x and math.floor(self.x_scale * gfx.w) + self.x_offset or self.x
    self.w = self.update_w and math.floor(self.w_scale * gfx.w) + self.w_offset or self.w
    self.y = self.update_y and math.floor(self.y_scale * gfx.h) + self.y_offset or self.y
    self.h = self.update_h and math.floor(self.h_scale * gfx.h) + self.h_offset or self.h

    if self.w < self.min_w then self.w = self.min_w end
    if self.h < self.min_h then self.h = self.min_h end
end

--------------------------------Macro Display SubClass------------------------------- Can make this a more generic slotted class for macro and param display to inherit from

Slotted_Display = {}
Slotted_Display.__index = Slotted_Display

function Slotted_Display:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer, slot_height)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer), Slotted_Display)
    setmetatable(Slotted_Display, {__index = ScalingObject})

    self.slot_height = slot_height

    self.selected_index = -1

    self.scroll_offset = 0
    self.elements_height = 0

    self.scroll_bar_h = 0

    self.editable = true
    self.allow_multi_select = false
    self.sel_on_delete_btn = false

    self.elements = {}
    self.update = true

    self:UpdateDimensions()
    --Store the height of the entire macro set to uset
    --to check if scrolling is possible or not.
    --also set y
    return self
end

function Slotted_Display:LeftClick(index)
    if alt then
        if index == nil then index = -1 end
        self:DelSlot(index)
        return
    end
    if index ~= self.selected_index and self.allow_multi_select == false then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end

    if self.elements[index] ~= nil then
        self.elements[index]:LeftClick(self.allow_multi_select)
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
            macro.y_offset = new_y
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
    ScalingObject.UpdateDimensions(self)
    for i, elem in pairs(self.elements) do
        elem:UpdateDimensions()
    end
end

function Slotted_Display:AddSlot(name, increment, sel, margin)
    local margin = margin or 4
    name = name or ""
    local slot = Slot:New(0, self.y - self.y_offset, gfx.w, self.slot_height - margin,
    self.x_offset + margin, self.y_offset + margin + (#self.elements * self.slot_height), -self.x_offset - margin)
    slot.update_h = false
    slot.editable = self.editable
    if sel then
        slot.selected = true
        self.selected_index = #self.elements + 1
    else
        slot.selected = false
    end
    if self.allow_multi_select == false then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end
    slot.text = increment and name .. " " .. tostring(#self.elements + 1) or name
    self.elements_height = (#self.elements + 1) * self.slot_height
    table.insert(self.elements, slot)
    self.update = true
    --save to project ex state??
end

function Slotted_Display:DelSlot(index)
    if self.editable == false then return end
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
            self.elements[i].y_offset = self.scroll_offset + base_y
            self.elements[i].orig_y = base_y
        end
    end

    if self.elements[index] ~= nil then
        if index == self.selected_index then
            if del_btn_clicked and self.sel_on_delete_btn then
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

        gfx.x = 0 gfx.y = 0

        gfx.setimgdim(self.buffer, -1, -1)
        gfx.setimgdim(self.buffer, self.x + self.w, self.y + self.h)

        gfx.dest = self.buffer

        SetColor(51,51,51)
        gfx.rect(self.x, self.y, self.w, self.h, true)
    
        for i, elem in pairs(self.elements) do
            elem:Draw()
        end

        SetColor(72,72,72)
        gfx.rect(self.x, self.y, self.w, self.h, false)


        SetColor(150,150,150)
        if self.scroll_bar_h > 0 then gfx.roundrect(self.x + self.w - 4, self.y + self.scroll_offset/(self.elements_height - self.h) * (self.scroll_bar_h - self.h), 4, self.scroll_bar_h-5, 2, true) end
        
        self.update = false
    end
    BlitBuffer(self.buffer, self.x, self.y, self.w, self.h)
    self.scroll = 0
    --gfx.blit(0,1,0,self.x, self.y, self.w + self.x, self.h + self.y, self.x, self.y, self.w + self.x, self.h + self.y)
end

---------------------------------------Macro-----------------------------------------
Slot = {}
Slot.__index = Slot

--TODO convert into scaling object child class in order to use update dimensions. (will need to update sub.elements dimensions in base class)

function Slot:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset), Slot)
    setmetatable(Slot, {__index = ScalingObject})
    self.orig_y = self.y_offset
    self.text = ""
    self.selected = false
    self.editable = true
    self.last_click = 0
    return self
end

--click function that stores current time and compares to last click in order to implement double click feature.

function Slot:LeftClick(allow_multi_selection)
    if allow_multi_selection and self.selected == true then 
        self.selected = false
    else
        self.selected = true
    end

    if self.last_click ~= nil and reaper.time_precise() - self.last_click < 0.4 then 
        self:DblClick() 
        self.last_click = 0 
    end
    self.last_click = reaper.time_precise()
end

function Slot:DblClick()
    if self.editable == false then return end
    local rval, input = reaper.GetUserInputs("Rename " .. self.text, 1, "New Name:", self.text)
    if rval then
        self.text = input
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

    gfx.setfont(1, "Arial", sm_font_size)

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

---------------------------------------Label--------------------------------------

Label = {}
Label.__index = Label

function Label:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer, text, text_size)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer), Label)
    setmetatable(Label, {__index = ScalingObject})
    self.text = text
    self.text_size = text_size
    self.update = false
    self:UpdateDimensions()
    return self
end

function Label:Draw()
    if self.update then
        gfx.dest = self.buffer
        gfx.setimgdim(self.buffer, -1, -1)
        gfx.setimgdim(self.buffer, self.x + self.w, self.y + self.h)
        --Print("drawing button")

        SetColor(36,43,43)
        gfx.rect(self.x+1, self.y+1, self.w-2, self.h-2, true)

        SetColor(170,170,170)
        gfx.setfont(1, "Arial", self.text_size)
        local str_w = gfx.measurestr(self.text)
        str_h = gfx.texth
        if str_w >= self.w then
            gfx.x = self.x
        else
            gfx.x = self.x + self.w / 2 - math.floor(str_w/2)
        end
        --gfx.x = self.x + self.w / 2 - (str_w/2)
        gfx.y = self.y + self.h / 2 - (str_h/2)
        gfx.drawstr(self.text)
        gfx.x = 0 gfx. y = 0

        SetColor(51,51,51)
        gfx.rect(self.x, self.y, self.w, self.h, false)

    end
    BlitBuffer(self.buffer, self.x, self.y, self.w - self.x, self.h, self.scroll)
end

--------------------------------------Button--------------------------------------

Button = {}
Button.__index = Button

function Button:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer, text, func, color, txt_color, bg_color)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, buffer), Button)
    setmetatable(Button, {__index = ScalingObject})

    if color == -1 or color == nil then
        self.r = 1 self.g = 1 self.b = 1
    else
        self.r, self.g, self.b = reaper.ColorFromNative(color)
    end

    self.LeftClick = func
    self.text = text
    self.has_dblclick = false
    self.update = false
    self.outline = true
    self.bg_color = bg_color or reaper.ColorToNative(120, 120, 120)
    self.txt_color = txt_color or reaper.ColorToNative(255, 255, 255)
    
    self:UpdateDimensions()
    return self
end

function Button:Draw()
    if self.update then
        gfx.dest = self.buffer
        gfx.setimgdim(self.buffer, -1, -1)
        gfx.setimgdim(self.buffer, self.x + self.w, self.y + self.h)
        --Print("drawing button")

        SetColor(self.bg_color)
        gfx.rect(self.x+1, self.y+1, self.w-2, self.h-2, true)

        gfx.setfont(1, "Arial", sm_font_size)
        SetColor(self.txt_color)
        local str_w = gfx.measurestr(self.text)
        str_h = gfx.texth
        if str_w >= self.w then
            gfx.x = self.x
        else
            gfx.x = self.x + self.w / 2 - math.floor(str_w/2)
        end
        --gfx.x = self.x + self.w / 2 - (str_w/2)
        gfx.y = self.y + self.h / 2 - (str_h/2)
        gfx.drawstr(self.text)
        gfx.x = 0 gfx. y = 0

        if self.outline then
            gfx.r = self.r gfx.g = self.g gfx.b = self.b
            gfx.rect(self.x, self.y, self.w, self.h, false)
        end

    end
    BlitBuffer(self.buffer, self.x, self.y, self.w - self.x, self.h, self.scroll)
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

function UpdateTrackFocus()
    current_track = reaper.GetSelectedTrack(0, 0)
    current_track_count = reaper.CountTracks(0)

    if current_track ~= previous_track then --Print("Changed Track Selection")
        if current_track == nil then
            GUI_Elements["TRACK"].text = "None"
            if current_track_count < previous_track_count then --user deleted tracks
                Print("Deleted tracks")
                --check track GUID's for deleted tracks... actually i guess you should store them in case user undos
            end
        else
            local rval, name = reaper.GetTrackName(current_track, "")
            GUI_Elements["TRACK"].text = name
        end
        GUI_Elements["TRACK"].update = true
    end

    previous_track = current_track
    previous_track_count = current_track_count
end

function ScrollToTrack()
    reaper.SetMixerScroll(current_track)
    reaper.Main_OnCommand(40913, 0)
end

function BlitBuffer(buffer,x,y,w,h,scroll)
    gfx.dest = -1
    scroll = scroll or 0
    gfx.blit(buffer, 1, 0, x, y, w + x, h + y, x, y, w + x, h + y)
end

function AllocateNewBuffer()
    local buffer_limit = 1024
    for i = 0, buffer_limit - 1 do
        if Buffer_List[i] == nil then
            Buffer_List[i] = true
            return i
        end
    end
end

function SetColor(r,g,b)
    if g == nil and b == nil then
        r, g, b = reaper.ColorFromNative(r)
    end
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
    UpdateTrackFocus()

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
        elem.update = false
    end

    -- if init then 
    --     GUI_Elements["Test"]:AddSlot("Track")
    --     GUI_Elements["Test"]:AddSlot("Items")
    --     GUI_Elements["Test"]:AddSlot("Envelopes")
    -- end

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

global_w = 150
global_h = 800
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
Buffer_List = {} --stores currently used buffers

button_height = 15

gfx.clear = reaper.ColorToNative(51, 51, 51)

os = reaper.GetOS()
if os == "Win32" or os == "Win64" then sm_font_size = 13 lg_font_size = 16 else sm_font_size = 11 lg_font_size = 14 end



gfx.init("Track Versions", global_w, global_h, 0, global_x, global_y)

GUI_Elements["DISP_TK_VERSIONS"] = Slotted_Display:New(0, 0, global_w, global_h, 10, 85, -10, -180, nil, 25)

GUI_Elements["DISP_RECALL"] = Slotted_Display:New(0, global_h, global_w, 0, 10, -115, -10, -10, nil, 25)
GUI_Elements["DISP_RECALL"].editable = false
GUI_Elements["DISP_RECALL"].update_h = false
GUI_Elements["DISP_RECALL"].allow_multi_select = true

--will want to store last gui selection states when opening and closing version gui
GUI_Elements["DISP_RECALL"]:AddSlot("Track", false, true)
GUI_Elements["DISP_RECALL"]:AddSlot("Track FX", false, true)
GUI_Elements["DISP_RECALL"]:AddSlot("Items", false, true)
GUI_Elements["DISP_RECALL"]:AddSlot("Envelopes", false, true)

GUI_Elements["BUT_ADD_VERSION"] = Button:New(0, 0, global_w/2, 0, 10, 60, -2, 80, nil, "Add Version", function() GUI_Elements["DISP_TK_VERSIONS"]:AddSlot("Version", true, true) end, reaper.ColorToNative(0, 0, 0))
GUI_Elements["BUT_DEL_VERSION"] = Button:New(global_w/2, 0, global_w/2, 0, 2, 60, -10, 80, nil, "Del Version", function() GUI_Elements["DISP_TK_VERSIONS"]:DelSlot() end, reaper.ColorToNative(0, 0, 0))

GUI_Elements["HEADER"] = Label:New(0, 0, global_w, 5, 10, 10, -10, 30, nil, "Track Versions", lg_font_size)
GUI_Elements["TRACK"] = Button:New(0, 0, global_w, 5, 10, 35, -10, 52, nil, "", ScrollToTrack, reaper.ColorToNative(0, 0, 0), reaper.ColorToNative(170, 170, 170),reaper.ColorToNative(34, 43, 43))
GUI_Elements["TRACK"].outline = false
UpdateTrackFocus()

--GUI_Elements["Param_Display"] = Display.New(0, Param_Display_Dimensions)
--GUI_Elements["Scale_Display"] = Display.New(0, Scale_Display_Dimensions)
--GUI_Elements["Node_Display"] = Display.New(0, Node_Display_Dimensions)

--GUI_Elements["Param_Add_Button"] = Button.New("Add", function()Print("AddParam\n")end, Param_Add_Button_Dimensions, reaper.ColorToNative(0, 0, 0))
--GUI_Elements["Param_Del_Button"] = Button.New("Del", function()Print("DelParam\n")end, Param_Del_Button_Dimensions, reaper.ColorToNative(0, 0, 0))

Main()