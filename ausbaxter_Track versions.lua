----------------------------------------------
-- Pickle.lua
--------------------------------------------
function pickle(t)
  return Pickle:clone():pickle_(t)
end

Pickle = { clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end }

function Pickle:pickle_(root)
  if type(root) ~= "table" then error("can only pickle tables, not ".. type(root).."s") end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  
  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end
----------------------------------------------
-- unpickle
----------------------------------------------
function unpickle(s)
  if type(s) ~= "string" then error("can't unpickle a "..type(s)..", only strings") end
  local gentables = load("return "..s)
  local tables = gentables()
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end

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
    --[[
        If update_? is set to true both ? and ?_offset values are used to calculate coordinates.
        Otherwise, ?_offset values are ignored.
    ]]
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

    self.elements = {} --This table must be master(hold all tracks and slots), use "track guid" to locate table elements, index to select version #. Pickle to save.
    self.update = true

    self.track_guid = nil --updated when track changes
    self.chunk = {} -- chunk = {tk,env,fx,item}
    self.sub_tracks = {} --used when getting and setting chunks to slots {guid,chunk}

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

    if self.elements[index] ~= nil then
        
        self.elements[index]:LeftClick(self.allow_multi_select)

        --self:CalculateElementHeight()

        Print(self.elements_height)

        -- --theres a better way to use tags, like on the display itself instead of every element
        -- if self.elements[index].tag == "version" and self.elements[index].selected == false then
    
        --     --Print(tostring(self.track_guid))

        --     if self.track_guid == nil then return end

        --     --Update The Previous Version Here-----------------------------------------------------------------

        --     --Print("load version chunks")

        --     local version_chunk = self.elements[index].chunk

        --     version_chunk = UpdateChunkTable(version_chunk, self.chunk) --check what to recall
    
        --     if version_chunk == -1 then Print("Must have 1 setting to recall. will implement a check during multiselection on display that prevents this altogether") return end
        --     --Print(version_chunk)

        --     local version_chunk_str = ConvertChunkToString(version_chunk) .. ">"

        --     reaper.PreventUIRefresh(1)

        --     reaper.SetTrackStateChunk(reaper.BR_GetMediaTrackByGUID(0, self.track_guid), version_chunk_str, false)
        --     --reflect active settings
        --     --Print("Recall Version: \n\n\n\n" .. version_chunk_str .. "\n")
        --     self.chunk = version_chunk

        --     if #self.elements[index].sub_tracks > 0 then
        --         --Print("load chunks into subtracks")
        --         --[TODO]
                
        --         --UPON LOADING FROM EXT STATE SUBTRACKS IS NIL HERE NOT SURE WHY.
                
        --         for i, tk_tbl in ipairs(self.elements[index].sub_tracks) do
        --             --Print("iterating through subtracks " .. i .. "\n: " .. tostring(self.sub_tracks[i]))
        --             local new_chunk_tbl = UpdateChunkTable(tk_tbl[2], self.sub_tracks[2])
        --             local str = ConvertChunkToString(new_chunk_tbl)
        --             -- Print(str..">")
        --             reaper.SetTrackStateChunk(reaper.BR_GetMediaTrackByGUID(0, tk_tbl[1]), str .. ">", false)
        --         end

        --         self.sub_tracks = self.elements[index].sub_tracks

        --         --Print("out of subtrack iteration")
        --         --iterate through sub_tracks
        --     end

        --     reaper.UpdateArrange()
        --     reaper.TrackList_AdjustWindows(false)
        --     reaper.PreventUIRefresh(-1)
        -- end

        -- if index ~= self.selected_index and self.allow_multi_select == false then
        --     for i, macro in pairs(self.elements) do macro.selected = false end
        -- end

        -- if self.allow_multi_select and self.elements[index].selected == true then 
        --     self.elements[index].selected = false
        -- else
        --     self.elements[index].selected = true
        -- end

        self.selected_index = index
        self.update = true
    end

end

function Slotted_Display:CalculateElementHeight()
    --should be recursive to handle nested parent track versions.
    self.elements_height = 0
    function CalculateHeight(slot)
        container = slot.elements or slot.slots
        for i, s in ipairs(container) do
            Print(i)
            if s.slots ~= nil then
                self.elements_height = self.elements_height + s.total_height
            else
                s.y = self.y + self.elements_height
                self.elements_height = self.elements_height + s.total_height
            end
        end
    end
    CalculateHeight(self)
    Print("Calculating element heights")
    -- for i, slot in ipairs(self.elements) do
    --     slot.y_offset = self.y + self.elements_height
    --     self.elements_height = self.elements_height + slot.total_height
    --     if slot.slots ~= nil then
    --         for j, sub in ipairs(slot.slots) do
    --             sub.y_offset = self.y + self.elements_height
    --             self.elements_height = self.elements_height + slot.total_height
    --         end
    --     end
    -- end

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
            Print(new_y)
            macro.y = new_y
            macro.update = true
            macro:UpdateDimensions()
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

function Slotted_Display:AddSlot(name, increment, sel, margin, tag, class)
    local margin = margin or 4
    name = name or ""
    s = class or Slot
    local slot = s:New(
        --[[x]]        0,
        --[[y]]        self.y - self.y_offset,
        --[[w]]        gfx.w,
        --[[h]]        self.slot_height - margin,
        --[[x_offset]] self.x_offset + margin,
        --[[y_offset]] self.y_offset + margin + (#self.elements * self.slot_height),
        --[[w_offset]] -self.x_offset - margin,
        --[[h_offset]] nil,
                       tag
    )
    slot.update_h = false
    slot.editable = self.editable
    if self.allow_multi_select == false then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end

    if sel then
        slot.selected = true
        self.selected_index = #self.elements + 1
    else
        slot.selected = false
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

---------------------------------Expandable Slot------------------------------------

Ex_Slot = {}
Ex_Slot.__index = Ex_Slot

function Ex_Slot:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, tag)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset), Ex_Slot)
    setmetatable(Ex_Slot, {__index = ScalingObject})
    self.orig_y = self.y_offset
    self.total_height = h
    self.text = ""
    self.tag = tag or ""
    self.slots = {}
    self.show = true
    self.slot_height = 25

    return self
end

function Ex_Slot:LeftClick(parent)
    if self.show then
        self.show = false
        self.total_height = self.slot_height
    else
        self.show = true
        self.total_height = (#self.slots + 1) * self.slot_height
    end
    Print("Expand or Contract ExSlot " .. self.text)
    parent:CalculateElementHeight()
    --return self.total_height
end

function Ex_Slot:RightClick()
    Print("right click")
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local sel = gfx.showmenu("Add Slot|Add Folder")
    if sel == 1 then
        self:AddSlot("Test", false, false, 4)
    elseif sel == 2 then
        self:AddSlot("Test", false, false, 4, Ex_Slot)
    end

end

function Ex_Slot:GetSlotHeight()
    function GetSlotHeight(slot)
        local total_height = self.slot_height
        for i, s in ipairs(slot.slots) do
            local h = 0
            if s.slots ~= nil and s.show then
                h = GetSlotHeight(s)
            else
                h = self.slot_height
            end
            total_height = total_height + h
        end
        return total_height
    end

    return GetSlotHeight(self)
end

function Ex_Slot:AddSlot(name, increment, sel, margin, class) --Needs to be able to add Ex_Slot to itself and update slot positions correctly.
    local margin = margin or 4
    class = class or Slot
    name = name or ""
    local x = 0
    local y = 0
    local w = gfx.w
    local h = self.slot_height - margin
    local x_offset = self.x_offset + (2*margin)
    local y_offset = 0

    if self.show then
        self.total_height = self:GetSlotHeight()
    end

    Print(name .. " og total height: " .. self.total_height .. " > og slot height: " .. self.slot_height)


    if self.total_height > self.slot_height then
        y_offset = self.y + self.total_height
        Print("inserting respecting total height: " .. self.y .. " + " .. self.total_height)
    else
        y_offset = self.y + ((#self.slots + 1) * self.slot_height)
        Print("inserting respecting slot height sum: " .. self.y .. " + " .. ((#self.slots + 1) * self.slot_height))
    end

    local w_offset = -self.x_offset - (2*margin)
    local h_offset = 0
    --local slot = class:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, tag)
    local slot = class:New(0,y_offset, w, h, x_offset, 0, w_offset, 0, tag)
    slot.update_y = false
    slot.update_h = false
    
    -- Print("New Slot at Position: \nX: " .. x .. "\nY: " .. y .. "\nW: " .. w .. "\nH: "
    -- .. h .. "\nX Offset: " .. x_offset .. "\nY Offset: " .. y_offset .. "\n")

    if self.allow_multi_select == false then
        for i, macro in pairs(self.elements) do macro.selected = false end
    end

    if sel then
        slot.selected = true
        self.selected_index = #self.slots + 1
    else
        slot.selected = false
    end
    
    slot.text = increment and name .. " " .. tostring(#self.slots + 1) or name
    table.insert(self.slots, slot)
    self.update = true

    --GUI_Elements["DISP_TK_VERSIONS"]:CalculateElementHeight()


    Print("Inserting at: " .. y_offset .. "\nTotal Height: " .. self.total_height)

    -- GUI_Elements["DISP_TK_VERSIONS"].elements_height = 0
    -- for i, slot in ipairs(GUI_Elements["DISP_TK_VERSIONS"].elements) do
    --     slot.y_offset = GUI_Elements["DISP_TK_VERSIONS"].y + GUI_Elements["DISP_TK_VERSIONS"].elements_height + 4
    --     GUI_Elements["DISP_TK_VERSIONS"].elements_height = GUI_Elements["DISP_TK_VERSIONS"].elements_height + slot.total_height
    -- end

    --save to project ex state??
end

function Ex_Slot:UpdateDimensions()
    ScalingObject.UpdateDimensions(self)
    for i, elem in pairs(self.slots) do
        elem:UpdateDimensions()
       --elem.y = self.y + (i * self.slot_height)
    end
end

function Ex_Slot:Draw()
    local text_r, text_g, text_b
    local slot_r, slot_g, slot_b
    text_r = 170 text_g = 170 text_b = 170
    slot_r = 36 slot_g = 43 slot_b = 43

    SetColor(slot_r,slot_g,slot_b)
    gfx.rect(self.x, self.y, self.w, self.h, true)

    SetColor(text_r,text_g,text_b)
    gfx.rect(self.x, self.y, self.w, self.h, false)

    local r_edge = self.x+self.w
    local b_edge = self.y+(self.h/2)
    
    if self.show then
        gfx.triangle(r_edge-15, b_edge-2, r_edge-10, b_edge+3, r_edge-5, b_edge-2)
        for i, slot in ipairs(self.slots) do slot:Draw() end
    else
        gfx.triangle(r_edge-15, b_edge+3, r_edge-10, b_edge-2, r_edge-5, b_edge+3)
    end

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

---------------------------------------Slot-----------------------------------------
Slot = {}
Slot.__index = Slot

function Slot:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset, tag)
    local self = setmetatable(ScalingObject:New(x, y, w, h, x_offset, y_offset, w_offset, h_offset), Slot)
    setmetatable(Slot, {__index = ScalingObject})
    self.orig_y = self.y_offset
    self.text = ""
    self.selected = false
    self.editable = true
    self.last_click = 0
    self.tag = tag or ""
    self.update_h = false
    self.total_height = self.h

    self.chunk = {}
    self.sub_tracks = {}

    return self
end

--click function that stores current time and compares to last click in order to implement double click feature.

function Slot:LeftClick(allow_multi_selection)

    --will have to do renaming in right click menu most likely
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

function MouseIsOverlapping(element)
    local function Overlap(elem)
        return gfx.mouse_x >= elem.x and gfx.mouse_x <= elem.x+elem.w and gfx.mouse_y >= elem.y and gfx.mouse_y <= elem.y+elem.h
    end

    local function GetOverlappedElement(element) --TODO -create recursive overlap check to activate nested sub elements (need to handle things that aren't shown)
        for i, sub_elem in ipairs(element) do
            if Overlap(sub_elem) then return true, sub_elem end
            if sub_elem.slots ~= nil and sub_elem.show then 
                --Print("in slot table")
                retval, elem = GetOverlappedElement(sub_elem.slots)
                if retval then return retval, elem end
            end
        end
        return false, nil
    end

    if Overlap(element) then
        if element.elements ~= nil then
            retval, elem = GetOverlappedElement(element.elements)
            return retval, elem, element
        else
            return true, element
        end
    else
        return false, nil
    end
end

function GetTrackChunkSeparated(chunk)

    local function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
    end

    local in_envelope = false
    local in_track = true
    local in_fx_chain = false
    local in_items = false

    local track_string = ""
    local envelope_string = ""
    local fx_string = ""
    local item_string = ""

    local first_line = true
    local carrot_count = 0
    for line in magiclines(chunk) do
        if in_items or line:find("<ITEM") ~= nil then
            if line:find(">") ~= nil then
                carrot_count = carrot_count + 1
            else
                carrot_count = 0
            end
            in_items = true
            in_fx_chain = false
            in_envelope = false
            in_track = false
            item_string = item_string .. "\n" .. line
        elseif in_fx_chain or line:find("<FXCHAIN") ~= nil then
            in_fx_chain = true
            in_envelope = false
            in_track = false
            fx_string = fx_string .. "\n" .. line
        elseif in_envelope or line:find("<.+ENV") ~= nil then
            in_envelope = true
            in_track = false
            envelope_string = envelope_string .. "\n" .. line
        elseif in_track then
            if first_line then 
                track_string = line 
                first_line = false
            else
                track_string = track_string .. "\n" .. line
            end
        end
    end
    if carrot_count == 3 then 
        item_string = item_string:sub(1,-2)
        --Print("fixed 3rd ending carrot")
    end

    --Print("Track \n\n" .. track_string .. "\n\n envelope string: \n\n" .. envelope_string .. "\n\nfx_string:\n\n" .. fx_string .. "\n\nitem_string:\n\n" .. item_string .. "\n\n")

    return {track_string, envelope_string, fx_string, item_string}
end

-- function SaveTrackVersions()
--     local count = 0
--     local csv = ""
--     for i, elem in ipairs(GUI_Elements["DISP_TK_VERSIONS"].elements) do -- save all versions
--         local idx = elem.selected and 1 or 0
--         local name = elem.text
--         local chunk = ConvertChunkToString(elem.chunk)
--         Print("Save Chunk: \n\n\n\n" .. name .. "\n\n" .. chunk .. "\n\nEnd Save Chunk\n\n\n\n")
--         local subtracks = ""
--         subtracks = "["
--         if elem.sub_tracks ~= nil and #elem.sub_tracks > 0 then
--             for k, tk in pairs(elem.sub_tracks) do
--                 --Print("Saving Subtrack: " ..  tk[1] .. "\n\n" .. ConvertChunkToString(tk[2]))
--                 subtracks = subtracks .. "[" .. tk[1] .. ";" .. ConvertChunkToString(tk[2])
--             end
--         end
--         Print("Saving idx: " .. idx .. "\n\n")
--         csv = csv .. "[" .. idx .. ";" .. name .. ";" .. chunk .. subtracks .. "]|"
--         count = count + 1
--     end
--     --Print(csv)
--     reaper.SetProjExtState(0, "ausbaxter_Track Versions", GUI_Elements["DISP_TK_VERSIONS"].track_guid, csv, true)
-- end

-- function LoadTrackVersions(ext_state) -- "|" delimits versions
--     local i = 1
--     local version_table = {}
--     for version in string.gmatch(ext_state, "%[[^%|]+") do
--         --Print("loading version !")
--         version = version:sub(1, -2)
--         version = version:sub(2)
--         local k = 1
--         local idx = 0
--         local last_sel = false
--         local name = ""
--         local chunk = "" --csv
--         local sub_tracks = {} --table of guid/csv
--         --Print(version)
--         for substring in string.gmatch(version, "[^;%[%]]+") do
--             --reaper.ShowConsoleMsg(substring .. "\n\n\n")
--             if k == 1 then
--                 if substring == "1" then last_sel = true end
--                 Print("Loading, is selected: " .. tostring(last_sel) .. "\n\n")
--             elseif k == 2 then
--                 name = substring
--             elseif k == 3 then
--                 chunk = GetTrackChunkSeparated(substring)
--                 --Print("Load Chunk: \n\n\n\n" .. name .. "\n\n" .. chunk[4] .. "\n\nEnd Load Chunk\n\n\n\n")
--             elseif k > 3 and k % 2 == 0 then
--                 idx = substring
--             elseif k > 3 and k % 2 ~= 0 then
--                 --Print("Subtracks Key: \n\n\n\n" .. idx .. "\n\n\n\n" .. "Subtracks Value:\n\n\n\n" .. substring)
--                 --Print("Loading Track Versions Call:\n\n" .. substring .. "\n\n")
--                 local tbl = GetTrackChunkSeparated(substring)
--                 table.insert(sub_tracks, {idx, tbl})
--                 --Print("Subtrack table " .. sub_tracks[idx][1])
--             end
--             k = k + 1
--         end
--         version_table[i] = {sel = last_sel, name = name, chunk = chunk, sub_tracks = sub_tracks} --this will be stored in the slot class
--         i = i + 1
--     end
--     return version_table
-- end

function UpdateTrackFocus()
    current_track = reaper.GetSelectedTrack(0, 0)
    current_track_count = reaper.CountTracks(0)

    if current_track ~= previous_track then --Print("Changed Track Selection") 
        --where you should check if a subfolder of a track that already has versions available.

        if current_track == nil then
            GUI_Elements["TRACK"].text = "None"
            --SaveTrackVersions()
            --save just to main table, if auto save is on
            --GUI_Elements["DISP_TK_VERSIONS"].track_guid = nil
            --GUI_Elements["DISP_TK_VERSIONS"].elements = {}
            if current_track_count < previous_track_count then --user deleted tracks
                Print("Deleted tracks")
                --check track GUID's for deleted tracks... actually i guess you should store them in case user undos
            end
        else

            local rval, name = reaper.GetTrackName(current_track, "")
            GUI_Elements["TRACK"].text = name

            local track =  reaper.GetParentTrack(current_track)
            local current_track_guid = reaper.GetTrackGUID(current_track)
            while track ~= nil do
                local parent_track_guid = reaper.GetTrackGUID(track)
                
                if TK_VERSIONS[parent_track_guid] ~= nil then

                    Print("Found Versions")
                    --add Expandable Slot Classes to Display for parent track versions

                end
                track = reaper.GetParentTrack(track)
            end

            if TK_VERSIONS[current_track_guid] ~= nil then
                Print("Found versions for current track")
            end
           

            -- Print("On track : " .. GUI_Elements["DISP_TK_VERSIONS"].track_guid .. "\n\n")

            
        end
        GUI_Elements["TRACK"].update = true
    end

    previous_track = current_track
    previous_track_count = current_track_count
end

function AddVersion()

    if current_track == nil then return end

    local _,chunk = reaper.GetTrackStateChunk(current_track, "", false)
    
    local track_guid = reaper.GetTrackGUID(current_track)

    local folder_state = reaper.GetMediaTrackInfo_Value(current_track, "I_FOLDERDEPTH")
    local sub_tracks = {}
    
    --Currently does not store nested sub folders... need to refactor this
    if folder_state == 1 then --track is folder, store subtracks

        function GetNestedFolderStates(i)
            local sub_tracks = {}
            while true do --Currently does not save nested folders
                local track = reaper.GetTrack(0, i)
                if track == nil then break end
                local guid = reaper.GetTrackGUID(track)
                local state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
                local _,chunk = reaper.GetTrackStateChunk(track, "", false)
                local _, name = reaper.GetTrackName(track, "")
                --Print("looking at track: " .. name)
                if state == 1 then
                    local return_state, idx, nested_tracks = GetNestedFolderStates(i+1)
                    sub_tracks[guid] = nested_tracks
                    i = idx
                    if return_state < -1 then 
                        return return_state + 1, i, sub_tracks
                    end
                elseif state < 0 then
                    sub_tracks[guid] = GetTrackChunkSeparated(chunk)
                    return state, i, sub_tracks
                else
                   sub_tracks[guid] = GetTrackChunkSeparated(chunk)
                end
                i = i + 1
            end
        end

        local root = reaper.GetMediaTrackInfo_Value(current_track, "IP_TRACKNUMBER")
        _,_,sub_tracks = GetNestedFolderStates(root)
        --PrintTable(sub_tracks)

    end

    --GUI_Elements["DISP_TK_VERSIONS"]:AddSlot("Version", true, true, nil, "version") --add gui element
    GUI_Elements["DISP_TK_VERSIONS"].elements[2]:AddSlot("Test", false, false, 4, Ex_Slot)
    for i = 1, 5 do
        GUI_Elements["DISP_TK_VERSIONS"].elements[2].slots[#GUI_Elements["DISP_TK_VERSIONS"].elements[2].slots]:AddSlot("Sub", false, false, 4)
    end

    if TK_VERSIONS[track_guid] == nil then TK_VERSIONS[track_guid] = {} end --make sure TK_VERSIONS track is a table

    table.insert(TK_VERSIONS[track_guid], {name = "version", selected = true, chunk = chunk, sub_tracks = sub_tracks})

    reaper.MarkProjectDirty(0)

end

function PrintTable(t,n)
    local c = n or 1
    for i, k in pairs(t) do
        if type(k) == "table" then
            PrintTable(k,c+1)
        end
        local tab = ""
        for k = 1, c do tab = tab .. "\t" end
        local track = reaper.BR_GetMediaTrackByGUID(0, i)
        if track ~= nil then
            local _,name = reaper.GetTrackName(track,"")
            Print(tab .. name)
        end
    end
end

function ShallowTableCopy(t_table) --Allows passing of 1D tables by value instead of reference
    --Print(t_table)
    local t2 = {}
      for k,v in pairs(t_table) do
        t2[k] = v
      end
      return t2
  
  end

function UpdateChunkTable(version_chunk, compare_table)
    --Creates string based on user recall options
    --Print("Creating chunk string")
    local table = ShallowTableCopy(version_chunk)
    local count = 0
    for i, opt in ipairs(GUI_Elements["DISP_RECALL"].elements) do
        if opt.selected == false then
            count = count + 1
            --Print("option " .. i .. " is set to not use new version settings")
            table[i] = compare_table[i]
        end
    end

    if count == 4 then return -1 end

    return table
end

function ConvertChunkToString(chunk)
    local str = ""
    for i = 1, #chunk do
        str = str .. chunk[i]
    end
    return str
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
        
        local over, element, parent = MouseIsOverlapping(elem)

        if mouse_update and over then

            if elem.Scroll ~= nil and mouse_wheel ~= 0 then elem:Scroll(mouse_wheel) end

            if left_mouse_down then 
                last_clicked_element = element
            elseif right_mouse_down then 
                last_clicked_element = element

            elseif left_mouse_up and element == last_clicked_element 
            and element.LeftClick ~= nil then
                element:LeftClick(parent)

            elseif right_mouse_up and element == last_clicked_element 
            and element.RightClick ~= nil then
                element:RightClick(parent)
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


--temp delete ext state
local c = 0
while true do
    local r, key, val = reaper.EnumProjExtState(0, "ausbaxter_Track Versions", c)
    if r == false then break end
    reaper.SetProjExtState(0, "ausbaxter_Track Versions", key, "")
    Print("Deleting: " .. key)
    c = c + 1
end
reaper.ShowConsoleMsg("")

TK_VERSIONS = {} --main version table

gfx.init("Track Versions", global_w, global_h, 0, global_x, global_y)

GUI_Elements["DISP_TK_VERSIONS"] = Slotted_Display:New(0, 0, global_w, global_h, 10, 85, -10, -180, nil, 25)
GUI_Elements["DISP_TK_VERSIONS"]:AddSlot("Parent Tracks",false, false, 4, "parent", Ex_Slot)
GUI_Elements["DISP_TK_VERSIONS"]:AddSlot("Current Track",false, false, 4, "current", Ex_Slot)

GUI_Elements["DISP_RECALL"] = Slotted_Display:New(0, global_h, global_w, 0, 10, -115, -10, -10, nil, 25)
GUI_Elements["DISP_RECALL"].editable = false
GUI_Elements["DISP_RECALL"].update_h = false
GUI_Elements["DISP_RECALL"].allow_multi_select = true

--will want to store last gui selection states when opening and closing version gui
-- GUI_Elements["DISP_RECALL"]:AddSlot("Track", false, true, nil, "setting")
-- GUI_Elements["DISP_RECALL"]:AddSlot("Envelopes", false, true, nil, "setting")
-- GUI_Elements["DISP_RECALL"]:AddSlot("Track FX", false, true, nil, "setting")
-- GUI_Elements["DISP_RECALL"]:AddSlot("Items", false, true, nil, "setting")


GUI_Elements["BUT_ADD_VERSION"] = Button:New(0, 0, global_w/2, 0, 10, 60, -2, 80, nil, "Add Version", AddVersion, reaper.ColorToNative(0, 0, 0))
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
