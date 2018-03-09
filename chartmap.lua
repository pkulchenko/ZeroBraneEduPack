local common       = require("common")
local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
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
      metaInterval.__metatable = metaInterval.__type
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
      metaTracer.__metatable = metaTracer.__type
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
    if(enDraw) then
      local nSz = (tonumber(vSz) or 2)
            nSz = (nSz < 2) and 2 or nSz
      local nsE = ((2 * nSz) + 1); pncl(cCol)
      line(mPntO.x,mPntO.y,mPntN.x,mPntN.y)
      rect(mPntO.x-nSz,mPntO.y-nSz,nsE,nsE)
    else enDraw = true end; return self
  end

  return self
end

function chartmap.New(sType, ...)
  local sType = "chartmap."..tostring(sType or "")
  if(sType == metaInterval.__type) then return newInterval(...) end
  if(sType == metaTracer.__type) then return newTracer(...) end
end

return chartmap
