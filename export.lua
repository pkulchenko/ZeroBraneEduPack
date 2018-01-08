local export = {}

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

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

function export.Table(tT, sS)
  local sS, tP = tostring(sS or "Data"), {}
  logTable(tT, sS, {[tT] = sS}); return tP
end

return export
