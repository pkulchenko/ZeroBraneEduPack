local common       = require("common")
local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
local logStatus    = common.logStatus
local toBool       = common.toBool
local getSign      = common.getSign
local pidloop      = {}

--[[
* newControl: Class state processing manager
* nTo   > Controller sampling time in seconds
* arPar > Parameter array {Kp, Ti, Td, satD, satU}
]]
local metaControl = {}
      metaControl.__index = metaControl
      metaControl.__type  = "pidloop.control"
      metaControl.__tostring = function(oControl) return oControl:getString() end
local function newControl(nTo, sName)
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

  function self:getTerm(kV,eV,pV) return (kV*mfSgn(eV)*mfAbs(eV)^pV) end
  function self:Dump() return logStatus(self:getString(), self) end
  function self:getGains() return mkP, mkI, mkD end
  function self:getTerms() return mvP, mvI, mvD end
  function self:setEnIntegral(bEn) meInt = toBool(bEn); return self end
  function self:getEnIntegral() return meInt end
  function self:getError() return mErrO, mErrN end
  function self:getControl() return mvCon end
  function self:getUser() return mUser end
  function self:getType() return mType end
  function self:getPeriod() return mTo end
  function self:setPower(pP, pI, pD)
    mpP, mpI, mpD = (tonumber(pP) or 0), (tonumber(pI) or 0), (tonumber(pD) or 0); return self end
  function self:setClamp(sD, sU) mSatD, mSatU = (tonumber(sD) or 0), (tonumber(sU) or 0); return self end
  function self:setStruct(bCmb, bInv) mbCmb, mbInv = toBool(bCmb), toBool(bInv); return self end

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
      mvP = self:getTerm(mkP, mErrN, mpP) end
    if((mkI > 0) and (mErrN ~= 0) and meInt) then -- I-Term
      mvI = self:getTerm(mkI, mErrN + mErrO, mpI) + mvI end
    if((mkD ~= 0) and (mErrN ~= mErrO)) then -- D-Term
      mvD = self:getTerm(mkD, mErrN - mErrO, mpD) end
    mvCon = mvP + mvI + mvD  -- Calculate the control signal
    if(mSatD and mSatU) then -- Apply anti-windup effect
      if    (mvCon < mSatD) then mvCon, meInt = mSatD, false
      elseif(mvCon > mSatU) then mvCon, meInt = mSatU, false
      else meInt = true end
    end; return self
  end

  function self:getString()
    local sInfo = (mType ~= "") and (mType.."-") or mType
          sInfo = "["..sInfo..metaControl.__type.."] Properties:\n"
          sInfo = sInfo.."  Name : "..mName.." ["..tostring(mTo).."]s\n"
          sInfo = sInfo.."  Param: {"..tostring(mUser[1])..", "..tostring(mUser[2])..", "
          sInfo = sInfo..tostring(mUser[3])..", "..tostring(mUser[4])..", "..tostring(mUser[5]).."}\n"
          sInfo = sInfo.."  Gains: {P="..tostring(mkP)..", I="..tostring(mkI)..", D="..tostring(mkD).."}\n"
          sInfo = sInfo.."  Power: {P="..tostring(mpP)..", I="..tostring(mpI)..", D="..tostring(mpD).."}\n"
          sInfo = sInfo.."  Limit: {D="..tostring(mSatD)..",U="..tostring(mSatU).."}\n"
          sInfo = sInfo.."  Error: {"..tostring(mErrO)..", "..tostring(mErrN).."}\n"
          sInfo = sInfo.."  Value: ["..tostring(mvCon).."] {P="..tostring(mvP)
          sInfo = sInfo..", I="..tostring(mvI)..", D="..tostring(mvD).."}\n"; return sInfo
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

    if(arParam[3] and (tonumber(arParam[3] or 0) ~= 0)) then
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
    local Mul = (tonumber(nMul) or 0)
    if(Mul <= 0) then return self end
    for ID = 1, 5, 1 do mUser[ID] = mUser[ID] * Mul end
    self:Setup(mUser); return self -- Init multiple states using the table
  end

  return self
end

-- https://www.mathworks.com/help/simulink/slref/discretefilter.html
local metaUnit = {}
      metaUnit.__index    = metaUnit
      metaUnit.__type     = "pidloop.unit"
      metaUnit.__tostring = function(oUnit) return oUnit:getString() end
local function newUnit(nTo, tNum, tDen, sName)
  local mOrd = #tDen; if(mOrd < #tNum) then
    return logStatus("Unit physically impossible") end
  if(tDen[1] == 0) then
    return logStatus("Unit denominator invalid") end
  local self, mTo  = {}, (tonumber(nTo) or 0)
  if(mTo <= 0) then return logStatus("Unit sampling time <"..tostring(nTo).."> invalid") end
  local mName, mOut = tostring(sName or "Unit plant"), nil
  local mSta, mDen, mNum = {}, {}, {}

  for ik = 1, mOrd, 1 do mSta[ik] = 0 end
  for iK = 1, mOrd, 1 do mDen[iK] = (tonumber(tDen[iK]) or 0) end
  for iK = 1, mOrd, 1 do mNum[iK] = (tonumber(tNum[iK]) or 0) end
  for iK = 1, (mOrd - #tNum), 1 do table.insert(mNum,1,0); mNum[#mNum] = nil end

  function self:Scale()
    local nK = mDen[1]
    for iK = 1, mOrd do
      mNum[iK] = (mNum[iK] / nK)
      mDen[iK] = (mDen[iK] / nK)
    end; return self
  end

  function self:getString()
    local sInfo = "["..metaUnit.__type.."] Properties:\n"
    sInfo = sInfo.."  Name       : "..mName.."^"..tostring(mOrd).." ["..tostring(mTo).."]s\n"
    sInfo = sInfo.."  Numenator  : {"..table.concat(mNum,", ").."}\n"
    sInfo = sInfo.."  Denumenator: {"..table.concat(mDen,", ").."}\n"
    sInfo = sInfo.."  States     : {"..table.concat(mSta,", ").."}\n"; return sInfo
  end
  function self:Dump() return logStatus(self:getString(), self)  end
  function self:getOutput() return mOut end

  function self:getBeta()
    local nOut, iK = 0, mOrd
    while(iK > 0) do
      nOut = nOut + (mNum[iK] or 0) * mSta[iK]
      iK = iK - 1 -- Get next state
    end; return nOut
  end

  function self:getAlpha()
    local nOut, iK = 0, mOrd
    while(iK > 1) do
      nOut = nOut - (mDen[iK] or 0) * mSta[iK]
      iK = iK - 1 -- Get next state
    end; return nOut
  end

  function self:putState(vX)
    local iK, nX = mOrd, (tonumber(vX) or 0)
    while(iK > 0 and mSta[iK]) do
      mSta[iK] = (mSta[iK-1] or 0); iK = iK - 1 -- Get next state
    end; mSta[1] = nX; return self
  end

  function self:Process(vU)
    local nU, nA = (tonumber(vU) or 0), self:getAlpha()
    self:putState((nU + nA) / mDen[1]); mOut = self:getBeta(); return self
  end

  function self:Reset()
    for iK = 1, #mSta, 1 do mSta[iK] = 0 end; mOut = 0; return self
  end

  return self
end

function pidloop.New(sType, ...)
  local sType = "pidloop."..tostring(sType or "")
  if(sType == metaControl.__type) then return newControl(...) end
  if(sType == metaUnit.__type) then return newUnit(...) end
end

return pidloop
