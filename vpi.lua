-- Copyright (C) 2019 Deyan Dobromirov
-- A common functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local vpi = require('vpi')`.")
  os.exit(1)
end

local common       = require("common")
local os           = os
local math         = math
local type         = type
local next         = next
local pcall        = pcall
local pairs        = pairs
local select       = select
local tonumber     = tonumber
local tostring     = tostring
local getmetatable = getmetatable
local vpi          = {}
local metaVpi      = {}
local isNil        = common.isNil
local logStatus    = common.logStatus
local getSign      = common.getSign
local stringTrim   = common.stringTrim
local metaData     = {}

metaData.__sepdc = "%." -- Decimal separator pattern
metaData.__sepch = "."  -- Decimal separator character
metaData.__filch = "0"  -- Decimal separator character
metaData.__divdg = 10   -- Decimal digits count

-- Gets decimal separator location
local function getDec(sS)
  return tostring(sS):find(metaData.__sepdc)
end

-- Adds decimal separator to the end in case of integer
local function setDec(sS)
  if(getDec(sS)) then sS = stringTrim(sS, metaData.__filch)
    if(sS:sub( 1, 1) == metaData.__sepch) then sS = "0"..sS end
    if(sS:sub(-1,-1) == metaData.__sepch) then sS = sS.."0" end
  else sS = sS..metaData.__sepch.."0" end; return sS
end

function vpi.isValid(vO)
  return (getmetatable(vO) == metaVpi)
end

metaVpi.__index    = metaVpi
metaVpi.__type     = "vpi.vpi"
metaVpi.__tostring = function(oV)
  return "["..metaVpi.__type.."]{"..oV:getDig().."}"..oV:getStr()
end
function vpi.getNew(vN, vA) local nV, nA
  if(vpi.isValid(vN)) then nV = vN:getStr()
    if(isNil(vA)) then nA = vN:getDig() end
  else nV, nA = vN, vA end
  local mN, mS = tonumber(nV), setDec(tostring(nV)); if(not mN) then 
    return logStatus(metaVpi.__type.."("..mS..") Not number") end
  local self = {}; setmetatable(self, metaVpi)
  local mA = math.floor(math.abs(tonumber(nA) or metaData.__divdg))
  function self:getDig() return mA end
  function self:getStr() return mS end
  function self:getNum() return mN end
  function self:setVal(vV)
    mN, mS = tonumber(nV), tostring(vV); if(not mN) then 
    return logStatus(metaVpi.__type.."("..mS..") Not number") end
    mS = setDec(mS); return self
  end
  function self:setDig(vA)
    mA = math.floor(math.abs(tonumber(vA) or 10)); return self
  end
  
  return self
end

function metaVpi:Print()
  print(tostring(self)); return self
end

function metaVpi:getDec()
  return self:getStr():find(metaData.__sepdc)
end

function metaVpi:isInt()
  local sS = stringTrim(self:getStr(),metaData.__filch)
  return (sS:sub(-1,-1) == metaData.__sepch)
end

function metaVpi:Shift(nN)
  local nN = math.floor(tonumber(nN) or 0)
  local cF = metaData.__filch
  if(nN ~= 0) then local sS = setDec(self:getStr())
    local iD, aD, iL = getSign(nN), math.abs(nN), sS:len() 
    local iS = (getDec(sS) or iL)
    local iB, iE = (aD - iS + 1), (iS + aD - iL)
    if(iB > 0) then sS = cF:rep(iB + 1)..sS end
    if(iE > 0) then sS = sS..cF:rep(iE + 1) end
    iL, iS = sS:len(), getDec(sS)
    iS, iL, sS = (iS + nN), (iL - 1), sS:gsub("%.", "")
    self:setVal(sS:sub(1, iS-1).."."..sS:sub(iS, iL))
  end; return self
end

function metaVpi:toInt()
  if(not self:isInt()) then
    local sS = self:getStr()
    local iP = self:getFrac()
  end; return self
end

function metaVpi:Div(vB)
  local sO, nn = "", (tonumber(n) or 0)
  local na, nb = tonumber(a), tonumber(b)
  if(na and nb and nn > 0) then local bt = false
    local sa, sb = tostring(na), tostring(nb)
    local iD = 0  -- Drop digit index
    local sD = "" -- The dropped digit
    local sT = "" -- The result during selected for division
    local nT = 0  -- Subtraction base number holder
    local nD = 0  -- Subtraction argument holder
    local nS = 0  -- Subtraction result
    local nK = 0  -- Reverse floor multiplication
    while(nT < nb) do
      iD = (iD + 1)
      sD = sa:sub(iD, iD)
      if(sD == "") then sD = "0"; nn = (nn - 1)
        if(sO == "") then sO, bt = sD..".", true
        else sO = sO..sD end
      end
      sT = sT..sD; nT = tonumber(sT)
    end
    nK = math.floor(nT/nb)
    sO = sO..tostring(nK)
    nD = nK * nb; nS = nT - nD
    sT, nT = tostring(nS), nS
    if(nS ~= 0) then
      if(not bt) then sO = sO.."." end
      while(nn >= 0) do
        while(nT < nb and nS ~= 0) do
          iD, nn = (iD + 1), (nn - 1)
          sD = sa:sub(iD, iD)
          if(sD == "") then sD = "0" end
          sT = sT..sD
          nT = tonumber(sT)
        end
        nK = math.floor(nT/nb)
        sO = sO..tostring(nK)
        nD = nK * nb; nS = nT - nD
        sT, nT = tostring(nS), nS
      end
    end
  end
  return sO
end

return vpi
