---------------------------------------Display-----------------------------------------

Display = {}
Display.__index = Display

function Display.New(m,scaling_func)
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

function Display.Add(self,elem,x,y,w,h)
    local x2 = self.x + self.margin + x
    local y2 = self.y + self.margin + y
    local w2 = w + self.margin + x
    local h2 = h + self.margin + y
    table.insert(self.elements, elem.New(x2,y2,w2,h2))
end

function Display.UpdateDimensions(self)
    if self.scaling_func == nil then return end
    local x, y, w, h = self.scaling_func()
    self.x = x
    self.y = y
    self.w = w - self.x
    self.h = h - self.y
end

function Display:Draw()
    gfx.dest = 0
    SetColor(72,72,72)
    gfx.rect(self.x, self.y, self.w, self.h, false)

    gfx.dest = 1
    SetColor(51,51,51)
    gfx.rect(self.x, self.y, self.w, self.h, true)
    for i, elem in pairs(self.elements) do
        elem:Draw()
    end
end

--------------------------------Macro Display SubClass------------------------------- Can make this a more generic slotted class for macro and param display to inherit from
Macro_Display = Display.New()

function Macro_Display:New(scaling_func, slot_height)
    self.slot_height = slot_height
    self.scaling_func = scaling_func

    self.track_guid = ""

    self.selected_index = -1

    self.buffer = 1

    self.scroll_offset = 0
    self.elements_height = 0

    self.scroll_bar_h = 0

    --Store the height of the entire macro set to uset
    --to check if scrolling is possible or not.
    --also set y
    return self
end

function Macro_Display:LeftClick(index) 
    if index ~= self.selected_index then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end
    if self.elements[index] ~= nil then
        self.elements[index]:LeftClick()
        self.selected_index = index
        self.update = true
    end
end

function Macro_Display:OptionLeft(index)
    if index == nil then index = -1 end
    self:DelSlot(index)
end

function Macro_Display:Scroll(scroll) --have to find out how to quantize the slot scrolling or better check the offset when inserting new slots
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

function Macro_Display:UpdateDimensions()
    if self.elements_height > self.h then 
        self.scroll_bar_h = self.h - (self.elements_height - self.h)
        if self.scroll_bar_h <= 0 then self.scroll_bar_h = 20 end
    else
        self.scroll_bar_h = 0
    end
    Display.UpdateDimensions(self)
end

function Macro_Display:AddSlot(slot)
    local m = 4
    local slot = Macro.New(self.x + m, --[[self.scroll_offset +]] self.y + (#self.elements * self.slot_height + m), self.x + self.w - m, self.slot_height - 2)
    slot.text = "Macro " .. #self.elements + 1
    self.elements_height = (#self.elements + 1) * self.slot_height
    table.insert(self.elements, slot)
    self.update = true
    --save to project ex state??
end

function Macro_Display:DelSlot(index)
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

function Macro_Display:Draw()
    if self.update then
        gfx.setimgdim(0, -1, -1)
        gfx.setimgdim(1, -1, -1)
        gfx.setimgdim(0, self.x + self.w, self.y + self.h)
        gfx.setimgdim(1, self.x + self.w, self.y + self.h)
        --draw scroll bar

        gfx.x = 0 gfx.y = 0
        Display.Draw(self) --call parent draw method, with any added shtuff
        if self.scroll_bar_h > 0 then gfx.roundrect(self.x + self.w - 4, self.y + self.scroll_offset/(self.elements_height - self.h) * (self.scroll_bar_h - self.h), 4, self.scroll_bar_h-5, 2) end
        self.update = false
    end
    BlitBuffer(1, self.x, self.y, self.w, self.h)
    BlitBuffer(0, self.x, self.y, self.w, self.h)
    self.scroll = 0
    --gfx.blit(0,1,0,self.x, self.y, self.w + self.x, self.h + self.y, self.x, self.y, self.w + self.x, self.h + self.y)
end

---------------------------------------Macro-----------------------------------------
Macro = {}
Macro.__index = Macro

function Macro.New(x,y,w,h)
    local self = setmetatable({}, Macro)
    self.x = x
    self.y = y
    self.w = w - self.x
    self.h = h
    self.orig_y = self.y
    self.fader = MacroFader:New(x,y,w,h)
    self.parameters = {}
    self.text = ""
    self.selected = false
    self.last_click = 0
    return self
end

--click function that stores current time and compares to last click in order to implement double click feature.

function Macro:LeftClick()
    self.selected = true
    if self.last_click ~= nil and reaper.time_precise() - self.last_click < 0.4 then 
        self:DblClick() 
        self.last_click = 0 
    end
    self.last_click = reaper.time_precise()
end

function Macro:DblClick()
    local rval, input = reaper.GetUserInputs("Rename " .. self.text, 1, "New Name:", self.text)
    if rval then
        self.text = input
        Print("True")
    end
end

function Macro:Draw()
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

-------------------------------------MacroFader---------------------------------------

MacroFader = {}
MacroFader.__index = MacroFader

function MacroFader.New(x,y,w,h)
    local self = setmetatable({}, MacroFader)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.val = 0
    self.text = "Macro Control"
    return self
end

function MacroFader.UpdateValue(self, val)
    self.val = (val - self.x) / self.w
    if self.val > 1 then self.val = 1 end
    --reaper.ShowConsoleMsg(self.val.."\n")
end

function MacroFader.Draw(self)
    gfx.rect(self.x, self.y, self.w, self.h, false) --param fader outline
    gfx.rect(self.x, self.y, self.w * self.val, self.h, true) --param fader
end

-----------------------------------Parameter-----------------------------------------
ParamControl = {}
ParamControl.__index = ParamControl

function ParamControl.new(idx,x,y,w,h,linkparam)
    local self = setmetatable({}, ParamControl)
    self.idx = idx
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.val = 0
    self.linkparam = linkparam
    self.selected = false
    return self
end

function ParamControl.UpdateValue(self, val)
    self.val = (val - self.x) / self.w
    if self.val > 1 then self.val = 1 end
    --track will need to be updated in a different way
    reaper.TrackFX_SetParamNormalized(track, self.linkparam.fx_index, self.linkparam.param_index, self.val)
    _,self.linkparam.param_val = reaper.TrackFX_GetFormattedParamValue(track, self.linkparam.fx_index, self.linkparam.param_index, "")
    --reaper.ShowConsoleMsg(self.val.."\n")
end

function ParamControl.Select(self)
    for i, p in ipairs(gui_elements.parameter_table) do
        p.selected = false
    end
    self.selected = true
end

function ParamControl.Draw(self)

    if self.selected then
        gfx.r = 0 gfx.g = .5 gfx.b = .5
    else
        gfx.r = 1 gfx.g = 1 gfx.b = 1
    end

    c_h = 7
    c_x = self.x + self.w / 20
    c_y = self.y + self.h - c_h - 7
    c_w = self.w - 2*(self.w / 20)
    gfx.rect(c_x, c_y, c_w, c_h, false) --param fader outline
    gfx.rect(c_x, c_y, c_w * self.val, c_h, true) --param fader
    gfx.rect(self.x, self.y, self.w, self.h, false) --param outline

    --values

    local p_header = self.linkparam.fx_name .. " | " .. self.linkparam.param_name
    gfx.x = self.x + (self.w/2) - (gfx.measurestr(p_header)/2)
    gfx.y = self.y + 10
    gfx.drawstr(p_header)

    gfx.x =  self.x + (self.w/2) - (gfx.measurestr(self.linkparam.param_name)/2)
    gfx.y = self.y + 25
    gfx.drawstr(self.linkparam.param_val)
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
        gfx.setfont(1, "Arial", 11)
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

    local function SetModifierBool(mod)
        if mod == nil then
            command_held = false
            shift_held = false
            option_held = false
            control_held = false
            no_modifier = true
        else
            if      mod == command  then command_held = true
            elseif  mod == shift    then shift_held = true
            elseif  mod == option   then option_held = true
            elseif  mod == control  then control_held = true end
            no_modifier = false
        end
    end

    local function EvaluateMouseBitfield(cap,mod)
        check = cap - mod
        if check == 0 then 
            SetModifierBool(mod)
            return check
        elseif check < 0 then
            return EvaluateMouseBitfield(cap, mod / 2)
        else
            if check == 1 or check == 2 then
                return check
            else
                SetModifierBool(mod)
                return EvaluateMouseBitfield(check, mod / 2)
            end
        end
    end

    local function GetMouseState(mouse_cap)
        if mouse_cap > 3 and mouse_cap <= 60 then
            return EvaluateMouseBitfield(mouse_cap, control)
        else
            SetModifierBool()
            return mouse_cap
        end
    end

    current_mouse_cap = GetMouseState(gfx.mouse_cap)

    --if current_mouse_cap ~= previous_mouse_cap then Print("Mouse Cap: " .. current_mouse_cap) end

    if left_mouse_down then
        left_mouse_hold = true
        left_mouse_down = false
    elseif current_mouse_cap == left_mouse and not left_mouse_hold then
        left_mouse_down = true
    elseif current_mouse_cap == right_mouse then
        if not right_mouse_hold then right_mouse_down = true end
        right_mouse_hold = true
    end

    if previous_mouse_cap == left_mouse and current_mouse_cap == no_mouse then
        if left_mouse_hold then left_mouse_up = true end
        left_mouse_hold = false
    elseif previous_mouse_cap == right_mouse and current_mouse_cap == no_mouse then
        if right_mouse_hold then right_mouse_up = true end
        right_mouse_hold = false
    end
    
    previous_mouse_cap = current_mouse_cap
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

        --[[
            When checking elements, since there isn't any overlap and only one element (besides a display) can be hovered over at once
            return when the overlapped element is known, and nil if its an empty part of a display. Return the Object String so you can reference it
            and the object substring for elements within a display.
        ]]
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

function LearnParameter()
    if not already_mapped then
        local param = {fx_name = fx_name, fx_index = fxnum, param_name = param_name, param_index = parnum, param_val = f_val_form}
        par_index = #gui_elements.parameter_table
        reaper.ShowConsoleMsg("FXName = "..fx_name.."\tFX Index = "..fxnum.."\tParam Name = "..param_name.."\tParam Index = "..parnum.."\tparm num: "..tostring(par_index).."\n")
        table.insert(gui_elements.parameter_table, ParamControl(par_index+1, 25, par_index*55+20, 300, 55, param))
        gui_elements.parameter_table[par_index+1].val = f_val --initialize parameter value
    end
end

function BlitBuffer(buffer,x,y,w,h,scroll)
    gfx.dest = -1
    scroll = scroll or 0
    gfx.blit(buffer, 1, 0, x, y, w + x, h + y, x, y, w + x, h + y)
end

function ScrollElement(element)
    if element.Scroll ~= nil then
        local mouse_wheel = gfx.mouse_wheel / 5
        --if mouse_wheel ~= 0 then Print(mouse_wheel)end
        element:Scroll(mouse_wheel)
        gfx.mouse_wheel = 0
    end
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

GUI_Elements = {}

Macros = {}

mouse_down_param_idx = 0

function Main()
    current_width = gfx.w
    current_height = gfx.h

    --Get current Mouse and Char
    char = gfx.getchar()

    --Check current selected (first) track
    current_track = reaper.GetSelectedTrack(0, 0)
    if current_track ~= previous_track then Print("Changed Track Selection") track_selection_changed = true end
    previous_track = current_track

    --Update Mouse States
    --mouse behavior should be expected, will have to handle button states in the following for loop so we can track the element?
    UpdateMouseStates()

    --Update Display Dimensions
    for idx, elem in pairs(GUI_Elements) do
        local over, element, sub_element = MouseIsOverlaping(elem, idx)
        if over then
            if element ~= nil then ScrollElement(elem) end
            if not left_mouse_hold  and left_mouse_down then elem.lmdown = true
            elseif not right_mouse_hold and right_mouse_down then elem.rmdown = true
            elseif left_mouse_up and elem.lmdown then
                if      elem.LeftClick ~= nil and no_modifier then elem:LeftClick(sub_element)
                elseif  option_held and elem.OptionLeft ~= nil then elem:OptionLeft(sub_element) end
                elem.lmdown = false      
            elseif right_mouse_up and elem.rmdown then
                --right click element function
                elem.rmdown = false
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
    --GUI_Elements["Macro_Display"]:Draw()

    -- Macro_Display:UpdateDimensions()
    -- Param_Display:UpdateDimensions()
    -- Scale_Display:UpdateDimensions()
    -- Node_Display:UpdateDimensions()
    -- Macro_Add_Button:UpdateDimensions()
    -- Macro_Del_Button:UpdateDimensions()
    -- Param_Add_Button:UpdateDimensions()
    -- Param_Del_Button:UpdateDimensions()

    -- Macro_Add_Button:UpdateDimensions(Macro_Display_Dimensions[1]+5,Macro_Display_Dimensions[2] - 20, 35, button_height)
    -- Macro_Del_Button:UpdateDimensions(60,Macro_Display_Dimensions[2] - 20, 35, button_height)
    -- Param_Add_Button:UpdateDimensions(Param_Display_Dimensions[1]+5,Param_Display_Dimensions[2]-20, (Param_Display_Dimensions[3] - Param_Display_Dimensions[1])*0.5 - 10, 15)
    -- Param_Del_Button:UpdateDimensions((Param_Display_Dimensions[3]-(Param_Display_Dimensions[3] - Param_Display_Dimensions[1])*0.5), Param_Display_Dimensions[2]-20, (Param_Display_Dimensions[3] - Param_Display_Dimensions[1])*0.5 - 5, 15)

    --Check Mouse Overlap
    --MouseIsOverlaping(Macro_Display)
    --gfx.blit(0,1,0,GUI_Elements["Macro_Display"].x, GUI_Elements["Macro_Display"].y, GUI_Elements["Macro_Display"].w + GUI_Elements["Macro_Display"].x, GUI_Elements["Macro_Display"].h + GUI_Elements["Macro_Display"].y,GUI_Elements["Macro_Display"].x, GUI_Elements["Macro_Display"].y, GUI_Elements["Macro_Display"].w + GUI_Elements["Macro_Display"].x, GUI_Elements["Macro_Display"].h + GUI_Elements["Macro_Display"].y)
    --Draw

    -- SetColor(255, 100, 100)
    -- Macro_Display:Draw()
    -- Param_Display:Draw()
    -- Scale_Display:Draw()
    -- Node_Display:Draw()

    -- Macro_Add_Button:Draw()
    -- Macro_Del_Button:Draw()

    -- Param_Add_Button:Draw()
    -- Param_Del_Button:Draw()

    -- for i, m in ipairs(Macro_Display.elements) do
    --     print(m.text)
    --     m:Draw()
    -- end

--[[

    if init then
        --p1 = ParamControl.new(1,25,20,300,75)
        --p2 = ParamControl.new(2,25,60,150,20)
        --table.insert(gui_elements.parameter_table,p1)
        --table.insert(gui_elements.parameter_table,p2)
        macro = MacroFader.new(400, 300, 400, 25)
        b1 = Button(25, 330, 90, 25, "Add Parameter", LearnParameter, "add")
        b2 = Button(25, 360, 90, 25, "Del Parameter", function()reaper.ShowConsoleMsg("Delete Parameter Execute\n")end)
        table.insert(gui_elements.button_table,b1)
        table.insert(gui_elements.button_table,b2)
        init = false
    end

    --Get Last Touched FX Parameter and check if it is available for learning!
    rval, tnum, fxnum, parnum = reaper.GetLastTouchedFX()

    --check if parameter is already mapped.
    for i, p in ipairs(gui_elements.parameter_table) do
        if p.linkparam.fx_index == fxnum and p.linkparam.param_index == parnum then already_mapped = true
        else already_mapped = false end
    end

    if rval then
        if p_parnum == nil or p_parnum ~= parnum then
            track = GetTrack(tnum)
            track_index = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))
            rval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            rval, min, max = reaper.TrackFX_GetParam(track, fxnum, parnum)
            rval, param_name = reaper.TrackFX_GetParamName(track, fxnum, parnum, "")
            rval, fx_name = reaper.TrackFX_GetFXName(track, fxnum, "")
            reaper.ShowConsoleMsg("track num: " .. tnum
            .. " fx num: " .. fxnum .. " parnum: " .. parnum .. "\nMin: "
            .. min .. " Max: " .. max .. "\nName: " .. param_name .. "\n")
        end

        f_val = reaper.TrackFX_GetParamNormalized(track, fxnum, parnum)
        _,f_val_form = reaper.TrackFX_GetFormattedParamValue(track, fxnum, parnum, "")
        if p_f_val == nil or p_f_val ~= f_val then
            --reaper.ShowConsoleMsg(param_name .. " = " .. f_val .. "\t" .. f_val_form .. "\n")
        end

        p_f_val = f_val
        p_parnum = parnum
    end

    --reaper.ShowConsoleMsg("mouse_down: "..tostring(mouse_down).."\tmouse_hold: "..tostring(mouse_hold).."\tmouse_up: "..tostring(mouse_up).."\n")

    --Hover...

    for i, button in ipairs(gui_elements.button_table) do
        if mouse_up then
            if gfx.mouse_x >= button.x and gfx.mouse_x <= button.x+button.w and gfx.mouse_y >= button.y and gfx.mouse_y <= button.y+button.h then
                button.func()
            end
        end
    end

    for i, parameter in ipairs(gui_elements.parameter_table) do
        if mouse_down then -- mousedown
            if gfx.mouse_x >= parameter.x and gfx.mouse_x <= parameter.x+parameter.w and gfx.mouse_y >= parameter.y and gfx.mouse_y <= parameter.y+parameter.h then --mouse over parameter
                mouse_down_param_idx = i
                parameter:Select()
            end
        elseif mouse_up then
            mouse_down_param_idx = -1
        elseif mouse_hold then
            if mouse_down_param_idx ~= -1 then
                if parameter.idx == mouse_down_param_idx then
                    parameter:UpdateValue(gfx.mouse_x)
                end
            end
        end
        parameter:Draw()
    end

    if mouse_down then -- mousedown
        if gfx.mouse_x >= macro.x and gfx.mouse_x <= macro.x+macro.w and gfx.mouse_y >= macro.y and gfx.mouse_y <= macro.y+macro.h then --mouse over parameter
            macro_controlled = true
        end
    elseif mouse_up then
        macro_controlled = false
    elseif mouse_hold then
        if macro_controlled then
            macro:UpdateValue(gfx.mouse_x)
        end
    end

    gfx.r = 1 gfx.g = 1 gfx.b = 1
    --Learn Text readout temp
    learn_y = 335
    gfx.setfont(1, "Arial", 10)
    gfx.x = 125
    gfx.y = learn_y
    gfx.drawstr("Track ".. tostring(track_index) .. ":" .. tostring(track_name))
    gfx.x = 125
    gfx.y = learn_y + 10
    gfx.drawstr("Effect:\t"..tostring(fx_name))
    gfx.x = 125
    gfx.y = learn_y + 20
    gfx.drawstr("Parameter:\t"..tostring(param_name))
    gfx.x = 125
    gfx.y = learn_y + 30
    gfx.drawstr("Value:\t"..tostring(f_val_form))

    macro:Draw()

    for i, button in ipairs(gui_elements.button_table) do
        if button.tag == "add" and already_mapped then gfx.r = .2 gfx.g = .2 gfx.b = .2
        else
            gfx.r = 1 gfx.g = 1 gfx.b = 1
        end
        button:Draw()
    end
    for i, parameter in ipairs(gui_elements.parameter_table) do
        parameter:Draw()
    end

]]

    --previous_mouse_cap = current_mouse_cap
    prev_track_name = track_name
    previous_width = current_height
    previous_height = current_height

    --left_mouse_down = false
    left_mouse_up = false
    right_mouse_down = false
    right_mouse_up = false
    double_click = false

    if initialize then initialize = false end

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

initialize = true
left_mouse_down = false
left_mouse_hold = false
left_mouse_up = false
left_mouse = 1
right_mouse_down = false
right_mouse_hold = false
right_mouse_up = false
right_mouse = 2
no_mouse = 0
command = 4
shift = 8
option = 16
control = 32

button_height = 15

gfx.clear = reaper.ColorToNative(51, 51, 51)

gfx.init("Macro Control", global_w, global_h, 0, global_x, global_y)

GUI_Elements["Macro_Display"] = Macro_Display:New(Macro_Display_Dimensions, 20)
GUI_Elements["Macro_Add_Button"] = Button.New("Add", function() GUI_Elements["Macro_Display"]:AddSlot() end, Macro_Add_Button_Dimensions, reaper.ColorToNative(0, 0, 0),2)
GUI_Elements["Macro_Del_Button"] = Button.New("Del", function() GUI_Elements["Macro_Display"]:DelSlot() end, Macro_Del_Button_Dimensions, reaper.ColorToNative(0, 0, 0),2)

--GUI_Elements["Param_Display"] = Display.New(0, Param_Display_Dimensions)
--GUI_Elements["Scale_Display"] = Display.New(0, Scale_Display_Dimensions)
--GUI_Elements["Node_Display"] = Display.New(0, Node_Display_Dimensions)

--GUI_Elements["Param_Add_Button"] = Button.New("Add", function()Print("AddParam\n")end, Param_Add_Button_Dimensions, reaper.ColorToNative(0, 0, 0))
--GUI_Elements["Param_Del_Button"] = Button.New("Del", function()Print("DelParam\n")end, Param_Del_Button_Dimensions, reaper.ColorToNative(0, 0, 0))

Main()