local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
local logStatus    = function(anyMsg, ...) io.write(tostring(anyMsg).."\n"); return ... end
local pidloop      = {}

-- Defines what should return /false/ when converted to a boolean
local __toboolean = {
  [0]       = true,
  ["0"]     = true,
  ["false"] = true,
  [false]   = true
}

local function toboolean(anyVal) -- http://lua-users.org/lists/lua-l/2005-11/msg00207.html
  if(not anyVal) then return false end
  if(__toboolean[anyVal]) then return false end
  return true
end

local function getSign(anyVal)
  local nVal = (tonumber(anyVal) or 0)
  return ((nVal > 0 and 1) or (nVal < 0 and -1) or 0)
end

--[[
 * newInterval: Class that maps one interval onto another
 * sName > A porper name to be identified as
 * nL1   > Lower  value first border
 * nH1   > Higher value first border
 * nL2   > Lower  value second border
 * nH2   > Higher value second border
]]--
function pidloop.newInterval(sName, nL1, nH1, nL2, nH2)
  local self, mVal = {}, 0
  local mNam = tostring(sName or "")
  local mL1  = (tonumber(nL1) or 0)
  local mH1  = (tonumber(nH1) or 0)
  local mL2  = (tonumber(nL2) or 0)
  local mH2  = (tonumber(nH2) or 0)
  
  function self:getName() return mNam end
  function self:setName(sName) mNam = tostring(sName or "N/A") end
  function self:getValue() return mVal end
  function self:getBorderIn() return mL1, mH1 end
  function self:setBorderIn(nL1, nH1) mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0) end
  function self:getBorderOut() return mL2, mH2 end
  function self:setBorderOut(nL2, nH2) mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0) end
  
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
function pidloop.newTracer(sName)
  local self = {}
  local mName = tostring(sName or "")
  local mValO, mValN = 0, 0
  local mTimO, mTimN = 0, 0
  local mPntN = {x=0,y=0}
  local mPntO = {x=0,y=0}
  local mMatX, mMatY
  local enDraw = false
  
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

--[[
* newControl: Class maglev state processing manager
* nTo   > Controller sampling time in seconds
* arPar > Parameter array {Kp, Ti, Td, satD, satU}
]]
local metaControl = {}
      metaControl.__index = metaControl
      metaControl.__type  = "Control"
function pidloop.newControl(nTo, sName)
  local mTo = (tonumber(nTo) or 0); if(mTo <= 0) then -- Sampling time [s]
    return logStatus(nil, "newControl: Sampling time <"..tostring(nTo).."> invalid") end
  local self  = {}                 -- Place to store the methods
  local mfAbs = math and math.abs  -- Function used for error absolute
  local mfSgn = getSign            -- Function used for error sign
  local mErrO, mErrN  = 0, 0       -- Error state values
  local mvCon, meInt  = 0, true    -- Control value and integral enabled
  local mvP, mvI, mvD = 0, 0, 0    -- Term values
  local mkP, mkI, mkD = 0, 0, 0    -- P, I and D term gains
  local mpP, mpI, mpD = 1, 1, 1    -- Raise the error to power of that much
  local mbCmb, mbInv, mSatD, mSatU = true, false -- Saturation limits and settings
  local mName, mType, mUser = (sName and tostring(sName) or "N/A"), "", {}

  setmetatable(self, metaControl)

  local function getTerm(kV,eV,pV) return (kV*mfSgn(eV)*mfAbs(eV)^pV) end

  function self:getGains() return mkP, mkI, mkD end
  function self:setEnIntegral(bEn) meInt = toboolean(bEn); return self end
  function self:getEnIntegral() return meInt end
  function self:getError() return mErrO, mErrN end
  function self:getControl() return mvCon end
  function self:getUser() return mUser end
  function self:getType() return mType end
  function self:getPeriod() return mTo end
  function self:setPower(pP, pI, pD)
    mpP, mpI, mpD = (tonumber(pP) or 0), (tonumber(pI) or 0), (tonumber(pD) or 0); return self end
  function self:setClamp(sD, sU) mSatD, mSatU = (tonumber(sD) or 0), (tonumber(sU) or 0); return self end
  function self:setStruct(bCmb, bInv) mbCmb, mbInv = toboolean(bCmb), toboolean(bInv); return self end

  function self:Reset()
    mErrO, mErrN  = 0, 0
    mvP, mvI, mvD = 0, 0, 0
    mvCon, meInt  = 0, true
    return self
  end

  function self:Process(vRef,vOut)
    mErrO = mErrN -- Refresh error state sample
    mErrN = (mbInv and (vOut-vRef) or (vRef-vOut))
    if(mkP > 0) then -- P-Term
      mvP = getTerm(mkP, mErrN, mpP) end
    if((mkI > 0) and (mErrN ~= 0) and meInt) then -- I-Term
      mvI = getTerm(mkI, mErrN + mErrO, mpI) + mvI end
    if((mkD > 0) and (mErrN ~= mErrO)) then -- D-Term
      mvD = getTerm(mkD, mErrN - mErrO, mpD) end
    mvCon = mvP + mvI + mvD  -- Calculate the control signal
    if(mSatD and mSatU) then -- Apply anti-windup effect
      if    (mvCon < mSatD) then mvCon, meInt = mSatD, false
      elseif(mvCon > mSatU) then mvCon, meInt = mSatU, false
      else meInt = true end
    end; return self
  end

  function self:Setup(arParam)
    if(type(arParam) ~= "table") then
      return logStatus("newControl.Setup: Params table <"..type(arParam).."> invalid") end

    if(arParam[1] and (tonumber(arParam[1] or 0) > 0)) then
      mkP = (tonumber(arParam[1] or 0))
    else return logStatus("newControl.Setup: P-gain <"..tostring(arParam[1]).."> invalid") end

    if(arParam[2] and (tonumber(arParam[2] or 0) > 0)) then
      mkI = (mTo / (2 * (tonumber(arParam[2] or 0)))) -- Discrete integral approximation
      if(mbCmb) then mkI = mkI * mkP end
    else logStatus("newControl.Setup: I-gain <"..tostring(arParam[2]).."> skipped") end

    if(arParam[3] and (tonumber(arParam[3] or 0) > 0)) then
      mkD = (tonumber(arParam[3] or 0) * mTo)  -- Discrete derivative approximation
      if(mbCmb) then mkD = mkD * mkP end
    else logStatus("newControl.Setup: D-gain <"..tostring(arParam[3]).."> skipped") end

    if(arParam[4] and arParam[5] and ((tonumber(arParam[4]) or 0) < (tonumber(arParam[5]) or 0))) then
      mSatD, mSatU = (tonumber(arParam[4]) or 0), (tonumber(arParam[5]) or 0)
    else logStatus("newControl.Setup: Saturation skipped <"..tostring(arParam[4]).."<"..tostring(arParam[5]).."> skipped") end
    mType = ((mkP > 0) and "P" or "")..((mkI > 0) and "I" or "")..((mkD > 0) and "D" or "")
    for ID = 1, 5, 1 do mUser[ID] = arParam[ID] end; return self -- Init multiple states using the table
  end

  function self:Mul(nMul)
    local nMul = (tonumber(nMul) or 0)
    if(nMul <= 0) then return self end
    for ID = 1, 5, 1 do mUser[ID] = mUser[ID] * nMul end
    self:Setup(mUser); return self -- Init multiple states using the table
  end

  function self:Dump()
    local sType = (mType ~= "") and (mType.."-") or mType
    logStatus("["..sType..metaControl.__type.."] Properties:")
    logStatus("  Name : "..mName.." ["..tostring(mTo).."]s")
    logStatus("  Param: {"..tostring(mUser[1])..", "..tostring(mUser[2])..", "
     ..tostring(mUser[3])..", "..tostring(mUser[4])..", "..tostring(mUser[5]).."}")
    logStatus("  Gains: {P="..tostring(mkP)..", I="..tostring(mkI)..", D="..tostring(mkD).."}")
    logStatus("  Power: {P="..tostring(mpP)..", I="..tostring(mpI)..", D="..tostring(mpD).."}")
    logStatus("  Limit: {D="..tostring(mSatD)..",U="..tostring(mSatU).."}")
    logStatus("  Error: {"..tostring(mErrO)..", "..tostring(mErrN).."}")
    logStatus("  Value: ["..tostring(mvCon).."] {P="..tostring(mvP)..", I="..tostring(mvI)..", D="..tostring(mvD).."}\n")
    return self
  end; return self
end

-- https://www.mathworks.com/help/simulink/slref/discretefilter.html
local metaUnit = {}
      metaUnit.__index    = metaUnit
      metaUnit.__type     = "Unit"
      metaUnit.__tostring = function(oUnit) return "["..metaUnit.__type.."]" end
function pidloop.newUnit(nTo, tNum, tDen, sName)
  local mOrd = #tDen; if(mOrd < #tNum) then
    return logStatus("Unit physically impossible") end
  if(tDen[1] == 0) then
    return logStatus("Unit denominator invalid") end
    
  local self  = {}
  local mTo   = tDen[1] -- Store (1/ao)
  local mName, mOut = tostring(sName or "Unit plant"), nil
  local mSta, mDen, mNum = {}, {}, {}
  
  for ik = 1, mOrd , 1 do mSta[ik] = 0 end
  for iK = 1, mOrd , 1 do mDen[iK] = (tonumber(tDen[iK]) or 0) / mTo end
  for iK = 1, #tNum, 1 do mNum[iK] = (tonumber(tNum[iK]) or 0) / mTo end
  for iK = 1, (mOrd - #mNum), 1 do table.insert(mNum,1,0) end
  
  mTo = nTo -- Refresh the sampling time
  
  function self:getOutput() return mOut end
  
  local function getBeta()
    local vOut, iK = 0, mOrd
    while(iK > 0) do
      vOut = vOut + mSta[iK] * (mNum[iK] or 0)
      iK = iK - 1 -- Get next state
    end; return vOut
  end
    
  local function getAlpha()
    local vOut, iK = 0, mOrd
    while(iK > 1) do
      vOut = vOut + mSta[iK] * (mDen[iK] or 0)
      iK = iK - 1 -- Get next state
    end; return vOut
  end
    
  local function putState(vX)
    local iK = mOrd
    while(iK > 0 and mSta[iK] and mSta[iK-1]) do
      mSta[iK] = mSta[iK-1]; iK = iK - 1 -- Get next state
    end; mSta[1] = vX
  end
  
  function self:Process(vU)
    putState(((tonumber(vU) or 0) - getAlpha()) / mDen[1])
    mOut = getBeta(false); return self
  end
  
  function self:Reset()
    for iK = 1, #mSta, 1 do mSta[iK] = 0 end; mOut = 0; return self
  end
  
  function self:Dump()
    logStatus(metaUnit.__tostring(self).." Properties:")
    logStatus("  Name       : "..mName.."^"..tostring(mOrd).." ["..tostring(mTo).."]s")
    logStatus("  Numenator  : {"..table.concat(mNum,", ").."}")
    logStatus("  Denumenator: {"..table.concat(mDen,", ").."}")
    logStatus("  States     : {"..table.concat(mSta,", ").."}\n") 
    return self
  end
  
  return self
end

return pidloop
