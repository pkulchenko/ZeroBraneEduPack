local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
local chartmap     = {}
local logStatus    = function(anyMsg, ...) io.write(tostring(anyMsg).."\n"); return ... end
--[[
 * newInterval: Class that maps one interval onto another
 * sName > A porper name to be identified as
 * nL1   > Lower  value first border
 * nH1   > Higher value first border
 * nL2   > Lower  value second border
 * nH2   > Higher value second border
]]--
local metaInterval = {}
      metaInterval.__index = metaInterval
      metaInterval.__type  = "chartmap.Interval"
      metaInterval.__tostring = function(oInterval) return oInterval:getString() end
function chartmap.newInterval(sName, nL1, nH1, nL2, nH2)
  local self, mVal = {}, 0
  local mNam = tostring(sName or "")
  local mL1  = (tonumber(nL1) or 0)
  local mH1  = (tonumber(nH1) or 0)
  local mL2  = (tonumber(nL2) or 0)
  local mH2  = (tonumber(nH2) or 0)
  setmetatable(self, metaInterval)
  function self:getName() return mNam end
  function self:setName(sName) mNam = tostring(sName or "N/A") end
  function self:getValue() return mVal end
  function self:getBorderIn() return mL1, mH1 end
  function self:setBorderIn(nL1, nH1) mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0) end
  function self:getBorderOut() return mL2, mH2 end
  function self:setBorderOut(nL2, nH2) mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0) end
  function self:getString() return "["..metaInterval.__type.."] "..mNam.." {"..mL1..","..mH1.."} >> {"..mL2..","..mH2.."}" end
  function self:Convert(nVal)
    local val = tonumber(nVal); if(not val) then
      return logStatus("newInterval.Convert("..mNam.."): Source <"..tostring(nVal).."> NaN", self) end
    if(val < mL1 or val > mH1) then
      return logStatus("newInterval.Convert("..mNam.."): Source <"..tostring(val).."> out of border", self) end
    local kf = ((val - mL1) / (mH1 - mL1)); mVal = (kf * (mH2 - mL2) + mL2); return self
  end
    
  return self
end

--[[
 * newTracer: Class that plots a process variable
 * sName > A porper name to be identified as
]]--
local metaTracer = {}
      metaTracer.__index = metaTracer
      metaTracer.__type  = "chartmap.Tracer"
      metaTracer.__tostring = function(oTracer) return oTracer:getString() end
function chartmap.newTracer(sName)
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
  function self:setInterval(oIntX, oIntY)
    mMatX, mMatY = oIntX, oIntY; return self end
  function self:Reset()
    mPntN.x, mPntN.y, mPntO.x, mPntO.y = 0,0,0,0
    enDraw, mValO, mValN = false,0,0; return self end
      
  function self:putValue(nTime, nVal)
    mValO, nValN = nValN, nVal
    mTimO, mTimN = mTimN, nTime
    mPntO.x, mPntO.y = mPntN.x, mPntN.y
    if(mMatX) then
      mPntN.x = mMatX:Convert(nTime):getValue()
    else mPntN.x = nTime end;
    if(mMatY) then
      mPntN.y = mMatY:Convert(nValN):getValue()
    else mPntN.y = nValN end; return self
  end
    
  function self:Draw(cCol)
    if(enDraw) then
      pncl(cCol);
      line(mPntO.x,mPntO.y,mPntN.x,mPntN.y)
      rect(mPntO.x-2,mPntO.y-2,5,5)
    else enDraw = true end; return self
  end
  
  return self
end

return chartmap
