local os         = os
local math       = math
local common     = {}
local metaCommon = {
  __time = 0,
  __syms = "1234567890abcdefghijklmnopqrstuvwxyxABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

function common.logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

function common.logConcat(anyMsg,aDel, ...)
  local sDel, tDat = tostring(aDel or ","), {...}
  io.write(tostring(anyMsg)..": ")
  for ID = 1, #tDat do
    io.write(tostring(tDat[ID] or ""))
    if(tDat[ID+1]) then io.write(sDel) end
  end; io.write("\n")
end

-- http://lua-users.org/wiki/MathLibraryTutorial
function common.randomSetSeed(bL)
  local nT = os.time()
  if((nT - metaCommon.__time) > 0) then
    local nS = tonumber(tostring(nT):reverse():sub(1,6))
    if(bL) then common.logStatus("common.randomSetSeed: #"..nS) end
    math.randomseed(nS); metaCommon.__seed = nS
    metaCommon.__time = nT; return nS
  end; return 0
end

function common.randomGetSeed(sS)
  return (metaCommon.__seed or 0)
end

function common.randomSetString(sS)
  metaCommon.__syms = tostring(sS or "")
end

function common.randomGetNumber(vC, nL, nU)
  local iC = math.floor(tonumber(vC) or 0)
  for iD = 1, iC do math.random() end
  if(nL and nU) then return math.random(nL, nU)
  elseif(nL and not nU) then return math.random(nL) end
  return math.random()
end

function common.randomGetString(vE, vN)
  local iN = math.floor(tonumber(vN) or 0)
  local iE = math.floor(tonumber(vE) or 0)
  local sS = metaCommon.__syms
  local sR, nL = "", sS:len()
  for iD = 1, iE do
    local rN = common.randomGetNumber(iN, 1, nL)
    sR = sR..sS:sub(rN, rN)
  end; return sR
end

function common.stringImplode(tLst,sDel)
  local ID, sStr, sDel = 1, "", tostring(sDel or "")
  while(tLst and tLst[ID]) do sStr = sStr..tLst[ID]; ID = ID + 1
    if(tLst[ID] and sDel ~= "") then sStr = sStr..sDel end
  end; return sStr
end

function common.stringExplode(sStr,sDel)
  local tLst, sCh, iDx, ID, dL = {""}, "", 1, 1, (sDel:len()-1)
  while(sCh) do sCh = sStr:sub(iDx,iDx+dL)
    if    (sCh ==  "" ) then return tLst
    elseif(sCh == sDel) then ID = ID + 1; tLst[ID], iDx = "", (iDx + dL)
    else tLst[ID] = tLst[ID]..sCh:sub(1,1) end; iDx = iDx + 1
  end; return tLst
end

function common.stringTrim(sStr, sCh)
  local sCh = tostring(sCh or "%s")
	return sStr:match("^"..sCh.."*(.-)"..sCh.."*$" ) or sStr
end

function common.fileGetLine(pF)
  if(not pF) then return common.logStatus("common.fileGetLine: No file", ""), true end
  local sCh, sLn = "X", "" -- Use a value to start cycle with
  while(sCh) do sCh = pF:read(1); if(not sCh) then break end
    if(sCh == "\n") then return common.stringTrim(sLn), false else sLn = sLn..sCh end
  end; return common.stringTrim(sLn), true -- EOF has been reached. Return the last data
end

function common.getSign(nVal)
  return ((nVal > 0 and 1) or (nVal < 0 and -1) or 0)
end

function common.getType(o)
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
function common.toBool(anyVal)
  if(not anyVal) then return false end
  if(__tobool[anyVal]) then return false end
  return true
end

function common.getPick(bC, vT, vF)
  if(bC) then return vT end; return vF
end

function common.getValueKeys(tTab, tKeys, aKey)
  if(aKey) then return tTab[aKey] end
  local out; for ID = 1, #tKeys do
    local key = tKeys[ID]; out = (tTab[key] or out)
    if(out) then return out end
  end; return nil
end

function common.getClamp(nN, nL, nH)
  if(nN < nL) then return nL end
  if(nN > nH) then return nH end; return nN
end

function common.getRound(nE, nF)
  local dF = nF * common.getSign(nE)
  if(dF == 0) then return dF end
  local q, d = math.modf(nE/dF)
  return (dF * (q + (d > 0.5 and 1 or 0)))
end

function common.timeDelay(nD)
  if(nD) then
    local eT = (os.clock() + nD)
    while(os.clock() < eT) do end
  else while(true) do end end
end

common.randomSetSeed()

return common
