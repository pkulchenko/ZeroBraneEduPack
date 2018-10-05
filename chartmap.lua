-- Copyright (C) 2017 Deyan Dobromirov
-- A chart mapping functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local chartmap = require('chartmap')`.")
  os.exit(1)
end

local common       = require("common")
local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
local isNil        = common.isNil
local getPick      = common.getPick
local isTable      = common.isTable
local getClamp     = common.getClamp
local logStatus    = common.logStatus
local chartmap     = {}

--[[
 * newInterval: Class that maps one interval onto another
 * sName > A proper name to be identified as
 * nL1   > Lower  value first border
 * nH1   > Higher value first border
 * nL2   > Lower  value second border
 * nH2   > Higher value second border
]]--
local metaInterval = {}
      metaInterval.__index = metaInterval
      metaInterval.__type  = "chartmap.interval"
      metaInterval.__tostring = function(oInterval) return oInterval:getString() end
local function newInterval(sName, nL1, nH1, nL2, nH2)
  local self, mVal, mNm = {}, 0, tostring(sName or "")
  local mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0)
  local mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0)
  if(mL1 == mH1) then
    return logStatus("newInterval("..mNm.."): Bad input bounds", self) end
  if(mL2 == mH2) then
    return logStatus("newInterval("..mNm.."): Bad output bounds", self) end
  setmetatable(self, metaInterval)
  function self:getName() return mNm end
  function self:setName(sName) mNm = tostring(sName or "N/A") end
  function self:getValue() return mVal end
  function self:getBorderIn() return mL1, mH1 end
  function self:setBorderIn(nL1, nH1) mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0) end
  function self:getBorderOut() return mL2, mH2 end
  function self:setBorderOut(nL2, nH2) mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0) end
  function self:getString() return "["..metaInterval.__type.."] "..mNm.." {"..mL1..","..mH1.."} >> {"..mL2..","..mH2.."}" end
  function self:Convert(nVal, bRev)
    local val = tonumber(nVal); if(not val) then
      return logStatus("newInterval.Convert("..mNm.."): Source <"..tostring(nVal).."> NaN", self) end
    if(bRev) then local kf = ((val - mL2) / (mH2 - mL2)); mVal = (kf * (mH1 - mL1) + mL1)
    else          local kf = ((val - mL1) / (mH1 - mL1)); mVal = (kf * (mH2 - mL2) + mL2) end
    return self
  end

  return self
end

--[[
 * newTracer: Class that plots a process variable
 * sName > A proper name to be identified as
]]--
local metaTracer = {}
      metaTracer.__index = metaTracer
      metaTracer.__type  = "chartmap.tracer"
      metaTracer.__tostring = function(oTracer) return oTracer:getString() end
local function newTracer(sName)
  local self = {}; setmetatable(self, metaTracer)
  local mName = tostring(sName or "")
  local mValO, mValN = 0, 0
  local mTimO, mTimN = 0, 0
  local mPntN = {x=0,y=0}
  local mPntO = {x=0,y=0}
  local mMatX, mMatY
  local enDraw = false
  function self:getString() return "["..metaTracer.__type.."] "..mName end
  function self:getValue() return mTimN, mValN end
  function self:getChart() return mPntN.x, mPntN.y end
  function self:setInterval(oIntX, oIntY)
    mMatX, mMatY = oIntX, oIntY
    return self
  end
  function self:Reset()
    mPntN.x, mPntN.y, mPntO.x, mPntO.y = 0,0,0,0
    enDraw, mValO, mValN = false,0,0
    return self
  end
  function self:putValue(nTime, nVal)
    mValO, mValN = mValN, nVal
    mTimO, mTimN = mTimN, nTime
    mPntO.x, mPntO.y = mPntN.x, mPntN.y
    if(mMatX) then mPntN.x = mMatX:Convert(nTime):getValue()
    else mPntN.x = nTime end;
    if(mMatY) then mPntN.y = mMatY:Convert(mValN):getValue()
    else mPntN.y = mValN end; return self
  end

  function self:Draw(cCol, vSz)
    if(enDraw) then pncl(cCol)
      local nSz = math.floor(tonumber(vSz) or 2)
      line(mPntO.x,mPntO.y,mPntN.x,mPntN.y)
      if(nSz > 0) then local nsE = ((2 * nSz) + 1)
        rect(mPntO.x-nSz,mPntO.y-nSz,nsE,nsE) end
    else enDraw = true end; return self
  end

  return self
end

--[[
 * CoordSys: Class that plots coordinate axises by scale
 * sName > A proper name to be identified as
]]--
local metaScope = {}
      metaScope.__index = metaScope
      metaScope.__type  = "chartmap.scope"
      metaScope.__tostring = function(oCoordSys) return CoordSys:getString() end
local function newScope(sName)
  local mName, mnPs = tostring(sName or ""), 2
  local self = {}; setmetatable(self, metaScope)
  local mdX, mdY, mnW, mnH, minX, maxX, minY, maxY, midX, midY, moiX, moiY
  local mclMid, mcldXY, pxX, pxY = colr(0,0,0), colr(200,200,200)
  local mclPos, mclOrg, mclDir = colr(255,0,0), colr(0,255,0), colr(0,0,255)
  function self:setSizeVtx(vS)
    mnPs = math.floor(tonumber(vS) or 0)
    if(mnPs <= 0) then mnPs = 0 end; return self
  end
  function self:setDelta(nX, nY)
    mdX, mdY = (tonumber(nX) or 0), (tonumber(nY) or 0)
    if(isNil(minX) and isNil(maxX) and isNil(minY) and isNil(maxY)) then
      return logStatus("newCoordSys.setDelta: Call /setBorder/ before /setDelta/", nil)
    else
      if(isNil(mnW) or isNil(mnH)) then
        return logStatus("newCoordSys.setDelta: Call /setSize/ before /setDelta/", nil)
      else
        pxX = mnW / (math.abs(maxX - minX) / mdX)
        pxY = mnH / (math.abs(maxY - minY) / mdY)
      end
    end
    if(mdX == 0 or mdY == 0) then
      return logStatus("newCoordSys.setDelta: Delta invalid", nil) end
    return self
  end
  function self:setBorder(nX, xX, nY, xY)
    minX, maxX = (tonumber(nX) or 0), (tonumber(xX) or 0)
    minY, maxY = (tonumber(nY) or 0), (tonumber(xY) or 0)
    if(isNil(nX) and isNil(xX) and isNil(nY) and isNil(xY)) then
      logStatus("newCoordSys.setBorder: Using intervals")
      if(isNil(moiX) or isNil(moiY)) then
        return logStatus("newCoordSys.setBorder: Call /setInterval/ before /setBorder/", nil)
      else
        minX, maxX = moiX:getBorderIn()
        minY, maxY = moiY:getBorderIn()
      end
    end
    if(minX == maxX or minY == maxY) then
      return logStatus("newCoordSys.setBorder: Border invalid", nil) end
    midX, midY = (minX + ((maxX - minX) / 2)), (minY + ((maxY - minY) / 2))
    return self
  end
  function self:setSize(nW, nH)
    mnW, mnH = (tonumber(nW) or 0), (tonumber(nH) or 0)
    if(isNil(nW) and isNil(nH)) then
      logStatus("newCoordSys.setSize: Using intervals")
      if(isNil(moiX) or isNil(moiY)) then
        return logStatus("newCoordSys.setSize: Call /setInterval/ before /setSize/", nil)
      else
        mnW = math.max(moiX:getBorderOut())
        mnH = math.max(moiY:getBorderOut())
      end
    end
    if(mnW <= 0 or mnH <= 0) then
      return logStatus("newCoordSys.setSize: Size invalid", nil) end; return self
  end
  function self:setUpdate()
    if(isNil(moiX) or isNil(moiY)) then
      return logStatus("newCoordSys.UpdateInt: Skip", nil) end
    return self:setBorder():setSize()
  end
  function self:setInterval(intX, intY)
    moiX = intX; if(getmetatable(moiX) ~= metaInterval) then
      return logStatus("newCoordSys.setInterval: X object invalid", nil) end
    moiY = intY; if(getmetatable(moiY) ~= metaInterval) then
      return logStatus("newCoordSys.setInterval: Y object invalid", nil) end
    return self
  end
  function self:setColorAxis(clMid) mclMid = (clMid or colr(0,0,0)); return self end
  function self:setColorDXY(clDXY) mcldXY = (clDXY or colr(200,200,200)); return self end
  function self:setColorPos(clPos) mclPos = (clPos or colr(255,0,0)); return self end
  function self:setColorOrg(clOrg) mclOrg = (clOrg or colr(0,255,0)); return self end
  function self:setColorDir(clDir) mclDir = (clDir or colr(0,0,255)); return self end
  function self:setColor(clMid, clDXY, clPos, clOrg, clDir)
    mclMid, mcldXY = (clMid or colr(0,0,0)), (clDXY or colr(200,200,200))
    mclPos = (clPos or colr(255,0,0))
    mclOrg = (clOrg or colr(0,255,0))
    mclDir = (clDir or colr(0,0,255))
    return self
  end
  function self:Draw(bMx, bMy, bGrd)
    local xe = moiX:Convert(midX):getValue()
    local ye = moiY:Convert(midY):getValue()
    if(bGrd) then pncl(mcldXY); local nK
      nK = 0; for x = midX, maxX, mdX do
        local xp = moiX:Convert(midX + nK * mdX):getValue()
        local xm = moiX:Convert(midX - nK * mdX):getValue()
        nK = nK + 1; if(not bMy or x ~= midX) then
          line(xp, 0, xp, mnH); line(xm, 0, xm, mnH) end
      end
      nK = 0; for y = midY, maxY, mdY do
        local yp = moiY:Convert(midY + nK * mdY):getValue()
        local ym = moiY:Convert(midY - nK * mdY):getValue()
        nK = nK + 1; if(not bMx or y ~= midY) then
          pncl(mcldXY); line(0, yp, mnW, yp); line(0, ym, mnW, ym) end
      end
    end
    if(xe and bMx) then pncl(mclMid); line(0, ye, mnW, ye) end
    if(ye and bMy) then pncl(mclMid); line(xe, 0, xe, mnH) end
    return self
  end
  function self:drawComplex(xyP, xyO, bTx, clP, clO)
    local ox, oy, px, py = 0, 0, 0, 0
    if(xyO) then ox, oy = xyO:getParts() end
    px, py = xyP:getParts()
    ox = moiX:Convert(ox):getValue()
    oy = moiY:Convert(oy):getValue()
    px = moiX:Convert(px):getValue()
    py = moiY:Convert(py):getValue()
    if(mnPs > 0) then local sz = 2*mnPs+1
      pncl(clO or mclOrg); rect(ox-mnPs,oy-mnPs,sz,sz)
      pncl(clP or mclPos); rect(px-mnPs,py-mnPs,sz,sz)
    end
    pncl(mclDir); line(px, py, ox, oy)
    if(bTx) then pncl(mclDir);
      local nA = xyP:getSub(xyO):getAngDeg()+90
      text(tostring(xyP:getRound(0.001)),nA,px,py)
    end return self
  end
  function self:drawComplexLine(xyS, xyE, bTx)
    return self:drawComplex(xyS, xyE, bTx, mclOrg, mclOrg)
  end
  function self:drawComplexText(xyP, sTx, bSp, vA)
    local sMs, cP = tostring(sTx), xyP:getRound(0.001)
    local px, py = cP:getParts()
    local nA = xyP:getSub(0,0):getAngDeg()
    nA = getPick(vA, tonumber(vA), nA)
    px = moiX:Convert(px):getValue()
    py = moiY:Convert(py):getValue()
    sMs = sMs..getPick(bSp, tostring(cP), "")
    text(sMs,nA,px,py); return self
  end
  function self:drawComplexPoint(xyP, clNew, bTx)
    local px, py = xyP:getParts()
    px = moiX:Convert(px):getValue()
    py = moiY:Convert(py):getValue()
    if(mnPs > 0) then local sz = 2*mnPs+1
      pncl(clNew or mclPos); rect(px-mnPs,py-mnPs,sz,sz) end
    return self
  end
  function self:drawComplexPolygon(tV, bTx, clP, clO, nN, bO)
    if(not isTable(tV)) then
      return logStatus("newCoordSys.drawComplexPolygon: Skip", self) end
    local nL = #tV -- Store the length to avoid counting again
    local nE = getClamp(math.floor(tonumber(nN) or nL), 1, nL)
    for iD = 1, nE do local cS, cE = (tV[iD+1] or tV[1]), tV[iD]
      self:drawComplex(cS, cE, bTx, clP, clO)
    end;
    if(not bO and nE < nL) then
      self:drawComplex(tV[1], tV[nE+1], bTx, clP, clO) end
    return self
  end
  function self:drawPointXY(nX, nY, clNew)
    local px = moiX:Convert(nX):getValue()
    local py = moiY:Convert(nY):getValue()
    if(mnPs > 0) then local sz = 2*mnPs+1
      pncl(clNew or mclPos); rect(px-mnPs,py-mnPs,sz,sz) end
    return self
  end
  function self:drawGraph(tY, tX)
    if(not isTable(tY)) then
      return logStatus("newCoordSys.plotGraph: Skip", self) end
    local ntY, bX, ntX, toP = #tY, false
    if(isTable(tX)) then ntX, bX = #tX, true
      if(ntX ~= ntY) then
        logStatus("newCoordSys.plotGraph: Shorter <" ..ntX..","..ntY..">")
        toP = math.min(ntX, ntY) else toP = ntY end
    else toP, bX = ntY, false end
    local trA, vX = newTracer("plotGraph"):setInterval(moiX, moiY)
    for iD = 1, toP do
      vX = getPick(bX, tX and tX[iD], iD)
      trA:putValue(vX, tY[iD]):Draw(mclDir, mnPs)
    end; self:drawPointXY(vX, tY[toP], mclDir)
    return self
  end
  function self:drawStem(tY, tX)
    if(not isTable(tY)) then
      return logStatus("newCoordSys.plotGraph: Skip", self) end
    local ntY, bX, ntX, toP = #tY, false
    if(isTable(tX)) then ntX, bX = #tX, true
      if(ntX ~= ntY) then
        logStatus("newCoordSys.plotGraph: Shorter <" ..ntX..","..ntY..">")
        toP = math.min(ntX, ntY) else toP = ntY end
    else toP, bX = ntY, false end; local vX
    local zY = moiY:Convert(0):getValue()
    for iD = 1, toP do
      vX = getPick(bX, tX and tX[iD], iD)
      local nX = moiX:Convert(vX):getValue()
      local nY = moiY:Convert(tY[iD]):getValue()
      pncl(mclDir); line(nX, nY, nX, zY)
      if(mnPs > 0) then local sz = 2*mnPs+1
        pncl(mclPos) rect(nX-mnPs,nY-mnPs,sz,sz) end
    end; self:drawPointXY(vX, tY[toP], mclPos)
    return self
  end
  function self:drawOval(xyP, rX, rY)
    local px, py = xyP:getParts()
    px = moiX:Convert(px):getValue()
    py = moiY:Convert(py):getValue()
    local rx, ry = (tonumber(rX) or 0), (tonumber(rY) or 0)
          rx, ry = (rX * (pxX / mdX)), (rY * (pxY / mdY))
    if(mnPs > 0) then local sz = 2*mnPs+1
      pncl(mclOrg); rect(px-mnPs,py-mnPs,sz,sz) end
    pncl(mclDir); oval(px, py, rx, ry); return self
  end
  function self:drawCircle(xyP, rR)
    return self:drawOval(xyP, rR, rR)
  end
  function self:getString() return "["..metaScope.__type.."] "..mName end
  return self
end

function chartmap.New(sType, ...)
  local sType = "chartmap."..tostring(sType or "")
  if(sType == metaInterval.__type) then return newInterval(...) end
  if(sType == metaTracer.__type) then return newTracer(...) end
  if(sType == metaScope.__type) then return newScope(...) end
  return logStatus("chartmap.New: Object invalid <"..sType..">",nil)
end

return chartmap
