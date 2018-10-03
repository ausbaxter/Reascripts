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

-------------------------------------------------

function main()
    rval, first_item_guid = reaper.GetProjExtState(0, "AutoConcat", "Item_1")
    rval, second_item_string = reaper.GetProjExtState(0, "AutoConcat", "Item_2")
    second_item_table = unpickle(second_item_string)
    rval, third_item_guid = reaper.GetProjExtState(0, "AutoConcat", "Item_3")

    item_spacing = 1 --second
    cursor = reaper.GetCursorPosition()
    reaper.Main_OnCommand(40289, 0)--clear item selection

    for i, concat_item_guid in ipairs(second_item_table) do

        if new_cursor ~= nil then
            reaper.SetEditCurPos(new_cursor + item_spacing, false, false)
        end

        first_item = reaper.BR_GetMediaItemByGUID(0, first_item_guid)
        reaper.SetMediaItemInfo_Value(first_item, "B_UISEL", 1)

        reaper.Main_OnCommand(40698, 0) --copy item
        reaper.Main_OnCommand(40058, 0) --paste item
        reaper.Main_OnCommand(40289, 0)--clear item selection

        ------------------------------------------------------------------

        concat_item = reaper.BR_GetMediaItemByGUID(0, concat_item_guid)
        reaper.SetMediaItemInfo_Value(concat_item, "B_UISEL", 1)

        reaper.Main_OnCommand(40698, 0) --copy item
        reaper.Main_OnCommand(40058, 0) --paste item

        reaper.Main_OnCommand(40289, 0)--clear item selection

        ------------------------------------------------------------------

        third_item = reaper.BR_GetMediaItemByGUID(0, third_item_guid)
        
        if third_item ~= nil then
        reaper.SetMediaItemInfo_Value(third_item, "B_UISEL", 1)

        reaper.Main_OnCommand(40698, 0) --copy item
        reaper.Main_OnCommand(40058, 0) --paste item

        reaper.Main_OnCommand(40289, 0)--clear item selection

        end

        new_cursor = reaper.GetCursorPosition()
    end

end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Auto Concatenate", -1)