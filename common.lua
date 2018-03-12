local os           = os
local math         = math
local type         = type
local next         = next
local pcall        = pcall
local pairs        = pairs
local tonumber     = tonumber
local tostring     = tostring
local getmetatable = getmetatable
local common       = {}
local metaCommon   = {}
metaCommon.__time = 0
metaCommon.__func = {}
metaCommon.__type = {"number", "boolean", "string", "function", "table"}
metaCommon.__syms = "1234567890abcdefghijklmnopqrstuvwxyxABCDEFGHIJKLMNOPQRSTUVWXYZ"
metaCommon.__metatable = "common.lib"

metaCommon.__func["pi"] = {}
metaCommon.__func["pi"].foo = function (itr, top)
  if(top == itr) then return 1 end
  local bs, nu = ((2 * itr) + 1), ((itr + 1) ^ 2)
  return bs + nu / metaCommon.__func["pi"].foo(itr+1, top)
end
metaCommon.__func["pi"].out = function(itr)
  return (4 / metaCommon.__func["pi"].foo(0, itr))
end

metaCommon.__func["exp"] = {}
metaCommon.__func["exp"].foo = function (itr, top)
  if(top == itr) then return 1 end; local fac = 1
  for I = 1, itr do fac = fac * I end
  return (1/fac + metaCommon.__func["exp"].foo(itr+1, top))
end
metaCommon.__func["exp"].out = function(itr)
  return metaCommon.__func["exp"].foo(1, itr)
end

metaCommon.__func["phi"] = {}
metaCommon.__func["phi"].foo = function (itr, top)
  if(top == itr) then return 1 end
  return (1 + (1 / metaCommon.__func["phi"].foo(itr+1, top)))
end
metaCommon.__func["phi"].out = function(itr)
  return metaCommon.__func["phi"].foo(0, itr)
end

function common.logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

function common.logString(anyMsg, ...)
  io.write(tostring(anyMsg)); return ...
end

function common.isNil(nVal)
  return (nVal == nil)
end

function common.isNan(nVal)
  return (nVal ~= nVal)
end

function common.isInf(nVal)
  if(nVal ==  math.huge) then return true,  1 end
  if(nVal == -math.huge) then return true, -1 end
  return false
end

function common.isTable(tVal)
  return (type(tVal) == metaCommon.__type[5])
end

function common.isDryTable(tVal)
  if(not common.isTable(tVal)) then return false end
  return (next(tVal) == nil)
end

function common.isString(sVal)
  local sTy = metaCommon.__type[3]
  return (getmetatable(sTy) == getmetatable(sVal))
end

function common.isDryString(sVal)
  if(not common.isString(sVal)) then return false end
  return (sVal == "")
end

function common.isNumber(nVal)
  if(not tonumber(nVal)) then return false end
  if(nil ~= getmetatable(nVal)) then return false end
  return (type(nVal) == metaCommon.__type[1])
end

function common.isFunction(fVal)
  return (type(fVal) == metaCommon.__type[4])
end

function common.isBool(bVal)
  if(bVal == true ) then return true end
  if(bVal == false) then return true end
  return false
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

function common.randomGetNumber(nL, nU, vC)
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
    local rN = common.randomGetNumber(1, nL, iN)
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

local function stringParseTableRec(sRc, fCnv, tInfo, nStg)
  local sIn = common.stringTrim(tostring(sRc or ""))
  if(sIn:sub(1,1)..sIn:sub(-1,-1) ~= "{}") then
    return common.logStatus("common.stringTable: Table format invalid <"..sIn..">", false) end
  local tIn, tOut = fCnv(common.stringExplode(sIn:sub(2,-2),","), ","), {}
  for ID = 1, #tIn do local sVal = common.stringTrim(tIn[ID])
    if(sVal ~= "") then
      local tVal = fCnv(common.stringExplode(sVal,"="), "=")
      local kVal, vVal = tVal[1], tVal[2]
      if(not vVal) then -- If no key is provided but just value use default integer keys
        if(not tInfo[nStg]) then tInfo[nStg] = 0 end
        tInfo[nStg] = tInfo[nStg] + 1
        kVal, vVal = tInfo[nStg], kVal
      end
      -- Handle keys
      if(kVal == "") then return common.logStatus("common.stringTable: Table key fail at <"..vVal..">", false) end
      if(tostring(kVal):sub(1,1)..tostring(kVal):sub(-1,-1) == "\"\"") then kVal = tostring(kVal):sub(2,-2)
      elseif(tonumber(kVal)) then kVal = tonumber(kVal)
      else kVal = tostring(kVal) end
      -- Handle values
      if(vVal == "") then vVal = nil
      elseif(vVal:sub(1,1)..vVal:sub(-1,-1) == "\"\"") then vVal = vVal:sub(2,-2)
      elseif(vVal:sub(1,1)..vVal:sub(-1,-1) == "{}")   then vVal = stringParseTableRec(vVal, fCnv, tInfo, nStg + 1)
      else vVal = (tonumber(vVal) or 0) end
      -- Write stuff
      tOut[kVal] = vVal
    end
  end; return tOut
end

function common.stringToTable(sRc)
  return stringParseTableRec(sRc,function(tIn, sCh)
    local aAr, aID, aIN = {}, 1, 0
    for ID = 1, #tIn do
      local sVal = common.stringTrim(tIn[ID])
      if(sVal:find("{")) then aIN = aIN + 1 end
      if(sVal:find("}")) then aIN = aIN - 1 end
      if(not aAr[aID]) then aAr[aID] = "" end
      if(aIN == 0) then
        aAr[aID] = aAr[aID]..sVal; aID = (aID + 1)
      else
        aAr[aID] = aAr[aID]..sVal..sCh
      end
    end; return aAr
  end, {}, 1)
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

function common.getSignNon(nVal)
  return ((nVal >= 0 and 1) or -1)
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

function common.getRoll(nN, nL, nH)
  if(nN < nL) then return nH end
  if(nN > nH) then return nL end
  return nN
end

function common.isAmong(nN, nL, nH)
  if(nN < nL) then return false end
  if(nN > nH) then return false end
  return true
end

function common.getRound(nE, nF)
  local dF = nF * common.getSign(nE)
  if(dF == 0) then return dF end
  local q, d = math.modf(nE/dF)
  return (dF * (q + (d > 0.5 and 1 or 0)))
end

function common.timeDelay(nD)
  if(nD) then local eT = (os.clock() + nD)
    while(os.clock() < eT) do end
  else while(true) do end end
end

function common.getCall(sNam, ...)
  if(not metaCommon.__func[sNam]) then
    return common.logStatus("common.getCall: Missed <"..tostring(sNam)..">", nil) end
  return pcall(metaCommon.__func[sNam].out, ...)
end

function common.setCall(sNam, fFoo, fOut)
  if(metaCommon.__func[sNam]) then
    common.logStatus("common.setCall: Replaced <"..tostring(sNam)..">") end
  if(not (type(fFoo) == "function")) then
    return common.logStatus("common.setCall: Main <"..tostring(sNam)..">", false) end
  if(not (type(fOut) == "function")) then
    return common.logStatus("common.setCall: Out <"..tostring(sNam)..">", false) end
  metaCommon.__func[sNam] = {}
  metaCommon.__func[sNam].foo = fFoo
  metaCommon.__func[sNam].out = fOut
end

function common.copyItem(obj, ccpy, seen)
  if(type(obj) ~= "table") then return obj end
  if(seen and seen[obj]) then return seen[obj] end
  local c, mt = (ccpy or {}), getmetatable(obj)
  -- Copy-constructor linked to the meta table
  if(mt) then
    if(type(c[mt]) == "function") then
      local suc, out = pcall(c[mt], obj); if(suc) then return out end
      return common.logStatus("common.copyItem("..tostring(mt).."): "..tostring(out), nil)
    elseif(mt.__type) then local mtt = mt.__type
      if(type(mtt) == "string" and type(c[mtt]) == "function") then
        local suc, out = pcall(c[mtt], obj); if(suc) then return out end
        common.logStatus("common.copyItem("..mtt.."): "..tostring(out), nil)
      end
    end
  end
  local s, res = (seen or {}), setmetatable({}, mt)
  local f = common.copyItem; s[obj] = res
  for k, v in pairs(obj) do res[f(k, c, s)] = f(v, c, s) end
  return res
end

local function logTableRec(tT,sS,tP)
  local sS, tP = tostring(sS or "Data"), (tP or {})
  local vS, vT, vK = type(sS), type(tT), ""
  if(vT ~= "table") then
    return common.logStatus("{"..vT.."}["..tostring(sS or "Data").."] = <"..tostring(tT)..">",nil) end
  if(next(tT) == nil) then
    return common.logStatus(sS.." = {}") end; common.logStatus(sS.." = {}",nil)
  for k,v in pairs(tT) do
    if(type(k) == "string") then
      vK = sS.."[\""..k.."\"]"
    else sK = tostring(k)
      if(tP[k]) then sK = tostring(tP[k]) end
      vK = sS.."["..sK.."]"
    end
    if(type(v) ~= "table") then
      if(type(v) == "string") then
        common.logStatus(vK.." = \""..v.."\"")
      else sK = tostring(v)
        if(tP[v]) then sK = tostring(tP[v]) end
        common.logStatus(vK.." = "..sK)
      end
    else
      if(v == tT) then
        common.logStatus(vK.." = "..sS)
      elseif(tP[v]) then
        common.logStatus(vK.." = "..tostring(tP[v]))
      else
        if(not tP[v]) then tP[v] = vK end
        logTableRec(v,vK,tP)
      end
    end
  end
end

function common.addPathLibrary(sB, sE)
  local bas = tostring(sB or "")
  if(bas == "") then common.logStatus("common.addPathLibrary: Missing path") return end
  bas = ((bas:sub(-1,-1) == "/") and bas or (bas.."/"))
  local ext = tostring(sE or ""):gsub("%*",""):gsub("%.","")
  if(ext == "") then common.logStatus("common.addPathLibrary: Missing extension") return end
  local pad = (bas.."*."..ext):match("(.-)[^\\/]+$").."?."..ext
  package.path = package.path..";"..pad
end

function common.logTable(tT, sS, tP)
  local lS, lP = tostring(sS or "Data")
  if(tT ~= nil) then lP = {[tT] = lS} end
  if(type(tP) == "table" and lP) then
    for ptr, abr in pairs(tP) do lP[ptr] = abr end end
  logTableRec(tT, lS, lP); return lP
end

function common.arMalloc2D(w,h)
  local tArr = {}
  for y=1,h do tArr[y] = {}
    for x=1,w do tArr[y][x] = 0 end
  end; return tArr
end

--[[
 * Converts linear array to a 2D array
 * arLin -> Linear array in format {1,2,3,4,w=2,h=2}
 * w,h   -> Custom array size
]]
function common.arConvert2D(arLin,w,h)
  if(not arLin) then return false end
  local nW, nH = (w or arLin.w), (h or arLin.h)
  if(not (nW and nH)) then return false end
  if(not (nW > 0 and nH > 0)) then return false end
  arRez = common.arMalloc2D(nW, nH)
  for i = 0, (nH-1) do for j = 0, (nW-1) do
      arRez[i+1][j+1] = (tonumber(arLin[i*w+j+1]) or 0)
  end end; return arRez
end

function common.arRotateR(tArr,sX,sY)
  local ii, jj, tTmp = 1, 1, common.arMalloc2D(sY,sX)
  for j = 1, sX, 1 do for i = sY, 1, -1  do
      if(jj > sY) then ii, jj = (ii + 1), 1 end
      tTmp[ii][jj] = tArr[i][j]
      tArr[i][j]   = nil; jj = (jj + 1)
  end end
  for i = 1, sX do tArr[i] = {}
    for j = 1, sY do tArr[i][j] = tTmp[i][j] end
  end
end

function common.arRotateL(tArr,sX,sY)
  local ii, jj, tTmp = 1, 1, common.arMalloc2D(sY,sX)
  for j = sX, 1, -1 do for i = 1, sY, 1  do
      if(jj > sY) then ii, jj = (ii + 1), 1 end
      tTmp[ii][jj] = tArr[i][j]
      tArr[i][j]   = nil; jj = (jj + 1)
  end end
  for i = 1, sX do tArr[i] = {}
    for j = 1, sY do tArr[i][j] = tTmp[i][j] end
  end
end

-- Getting a start end and delta used in a for loop
function common.getValuesSED(nVal,nMin,nMax)
  local s = (nVal > 0) and nMin or nMax
  local e = (nVal > 0) and nMax or nMin
  local d = getSign(e - s)
  return s, e, d
end

function common.arShift2D(tArr,sX,sY,nX,nY)
  if(not (sX > 0 and sY > 0)) then return end
  local x = math.floor(nX or 0)
  local y = math.floor(nY or 0)
  if(x ~= 0) then local M
    local sx,ex,dx = common.getValuesSED(x,sX,1)
    for i = 1,sY do for j = sx,ex,dx do
        M = (j-x); if(M >= 1 and M <= sX) then
          tArr[i][j] = tArr[i][M]
        else tArr[i][j] = 0 end
    end end
  end
  if(y ~= 0) then local M
    local sy,ey,dy = common.getValuesSED(y,sY,1)
    for i = sy,ey,dy do for j = 1,sX do
        M = (i-y); if(M >= 1 and M <= sY) then
          tArr[i][j] = tArr[M][j]
        else tArr[i][j] = 0 end
    end end
  end
end

function common.arRoll2D(tArr,sX,sY,nX,nY)
  if( not( sX > 0 and sY > 0) ) then return end
  local x, y = math.floor(nX or 0), math.floor(nY or 0)
  if(y ~= 0) then
    local MaxY = (y > 0) and sY or 1
    local MinY = (y > 0) and 1 or sY
    local siY, y, arTmp  = getSign(y), (y * siY), {}
    while(y > 0) do
      for i = 1,sX do arTmp[i] = tArr[MaxY][i] end
      common.arShift2D(tArr,sX,sY,0,siY)
      for i = 1,sX do tArr[MinY][i] = arTmp[i] end
      y = y - 1
    end
  end
  if(x ~= 0) then
    local MaxX = (x > 0) and sX or 1
    local MinX = (x > 0) and 1 or sX
    local siX, x, arTmp  = getSign(x), (x * siX), {}
    while(x > 0) do
      for i = 1,sY do arTmp[i] = tArr[i][MaxX] end
      common.arShift2D(tArr,sX,sY,siX)
      for i = 1,sY do tArr[i][MinX] = arTmp[i] end
      x = x - 1
    end
  end
end

function common.arMirror2D(tArr,sX,sY,fX,fY)
  local tTmp, s = 0, 1
  if(fY) then local e = sY
    while(s < e) do for k = 1,sX do
      tTmp       = tArr[s][k]
      tArr[s][k] = tArr[e][k]
      tArr[e][k] = tTmp end
      s, e = (s + 1), (e - 1)
    end
  end
  if(fX) then local e = sX
    while(s < e) do for k = 1,sY do
      tTmp       = tArr[k][s]
      tArr[k][s] = tArr[k][e]
      tArr[k][e] = tTmp
      end
      s, e = (s + 1), (e - 1)
    end
  end
end

common.randomSetSeed()

return common
