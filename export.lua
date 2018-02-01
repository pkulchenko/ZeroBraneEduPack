local common    = require("common")
local logStatus = common.logStatus
local export    = {}

local function logTable(tT,sS,tP)
  local sS, tP = tostring(sS or "Data"), (tP or {})
  local vS, vT, vK = type(sS), type(tT), ""
  if(vT ~= "table") then
    return logStatus("{"..vT.."}["..tostring(sS or "Data").."] = <"..tostring(tT)..">",nil) end
  if(next(tT) == nil) then
    return logStatus(sS.." = {}") end; logStatus(sS.." = {}",nil)
  for k,v in pairs(tT) do
    if(type(k) == "string") then
      vK = sS.."[\""..k.."\"]"
    else sK = tostring(k)
      if(tP[k]) then sK = tostring(tP[k]) end
      vK = sS.."["..sK.."]"
    end
    if(type(v) ~= "table") then
      if(type(v) == "string") then
        logStatus(vK.." = \""..v.."\"")
      else sK = tostring(v)
        if(tP[v]) then sK = tostring(tP[v]) end
        logStatus(vK.." = "..sK)
      end
    else
      if(v == tT) then
        logStatus(vK.." = "..sS)
      elseif(tP[v]) then
        logStatus(vK.." = "..tostring(tP[v]))
      else
        if(not tP[v]) then tP[v] = vK end
        logTable(v,vK,tP)
      end
    end
  end
end

function export.tableString(tT, sS, tP)
  local lS, lP = tostring(sS or "Data")
  if(tT ~= nil) then lP = {[tT] = lS} end
  if(type(tP) == "table" and lP) then
    for ptr, abr in pairs(tP) do lP[ptr] = abr end end
  logTable(tT, lS, lP); return lP
end

local function concatInternal(tIn, sCh)
  local aAr, aID, aIN = {}, 1, 0
  for ID = 1, #tIn do
    local sVal = common.StringTrim(tIn[ID])
    if(sVal:find("{")) then aIN = aIN + 1 end
    if(sVal:find("}")) then aIN = aIN - 1 end
    if(not aAr[aID]) then aAr[aID] = "" end
    if(aIN == 0) then
      aAr[aID] = aAr[aID]..sVal; aID = (aID + 1)
    else
      aAr[aID] = aAr[aID]..sVal..sCh
    end
  end; return aAr
end

function export.stringTable(sRc)
  local sIn = common.StringTrim(tostring(sRc or ""))
  if(sIn:sub(1,1)..sIn:sub(-1,-1) ~= "{}") then
    return logStatus("export.stringTable: Table format invalid <"..sIn..">", false) end
  local aIn, tOut = common.StringExplode(sIn:sub(2,-2),","), {}
  local tIn = concatInternal(aIn, ",")
  for ID = 1, #tIn do local sVal = common.StringTrim(tIn[ID])
    if(sVal ~= "") then
      local aVal = common.StringExplode(sVal,"=")
      local tVal = concatInternal(aVal, "=")
      local kVal, vVal = tVal[1], tVal[2]
      -- Handle keys
      if(kVal == "") then return logStatus("export.stringTable: Table key fail at <"..vVal..">", false) end
      if(kVal:sub(1,1)..kVal:sub(-1,-1) == "\"\"") then kVal = tostring(kVal):sub(2,-2)
      elseif(tonumber(kVal)) then kVal = tonumber(kVal)
      else kVal = tostring(kVal) end
      -- Handle values
      if(vVal == "") then vVal = nil
      elseif(vVal:sub(1,1)..vVal:sub(-1,-1) == "\"\"") then vVal = vVal:sub(2,-2)
      elseif(vVal:sub(1,1)..vVal:sub(-1,-1) == "{}")   then vVal = export.stringTable(vVal)
      else vVal = (tonumber(vVal) or 0) end
      -- Write stuff
      tOut[kVal] = vVal
    end
  end; return tOut
end

return export
