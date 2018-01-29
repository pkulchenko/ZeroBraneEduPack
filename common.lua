local common = {}

function common.LogStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

function common.StringImplode(tLst,sDel)
  local ID, sStr, sDel = 1, "", tostring(sDel or "")
  while(tLst and tLst[ID]) do sStr = sStr..tLst[ID]; ID = ID + 1
    if(tLst[ID] and sDel ~= "") then sStr = sStr..sDel end
  end; return sStr
end

function common.StringExplode(sStr,sDel)
  local tLst, sCh, iDx, ID, dL = {""}, "", 1, 1, (sDel:len()-1)
  while(sCh) do sCh = sStr:sub(iDx,iDx+dL)
    if    (sCh ==  "" ) then return tLst
    elseif(sCh == sDel) then ID = ID + 1; tLst[ID], iDx = "", (iDx + dL)
    else tLst[ID] = tLst[ID]..sCh:sub(1,1) end; iDx = iDx + 1
  end; return tLst
end

function common.StringTrim(sStr, sCh)
  local sCh = tostring(sCh or "%s")
	return sStr:match("^"..sCh.."*(.-)"..sCh.."*$" ) or sStr
end

function common.GetLineFile(pF)
  if(not pF) then return logStatus("common.getLine: No file", ""), true end
  local sCh, sLn = "X", "" -- Use a value to start cycle with
  while(sCh) do sCh = pF:read(1); if(not sCh) then break end
    if(sCh == "\n") then return common.StringTrim(sLn), false else sLn = sLn..sCh end
  end; return common.StringTrim(sLn), true -- EOF has been reached. Return the last data
end

function common.GetSign(anyVal)
  local nVal = (tonumber(anyVal) or 0)
  return ((nVal > 0 and 1) or (nVal < 0 and -1) or 0)
end

function common.GetType(o)
  local mt = getmetatable(o)
  if(mt and mt.__type) then
    return tostring(mt.__type)
  end; return type(o)
end

-- Defines what should return /false/ when converted to a boolean
local __tobool = {
  [0]       = true,
  ["0"]     = true,
  ["false"] = true,
  [false]   = true
}

-- http://lua-users.org/lists/lua-l/2005-11/msg00207.html
function common.ToBool(anyVal)
  if(not anyVal) then return false end
  if(__tobool[anyVal]) then return false end
  return true
end

function common.IfGet(bC, vT, vF)
  if(bC) then return vT end
  return vF
end

return common
