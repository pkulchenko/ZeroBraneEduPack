-- Copyright (C) 2017 Deyan Dobromirov
-- Implements matrix manipulations

if not debug.getinfo(3) then
  print("This is a module to load with `local matrix = require('matrix')`.")
  os.exit(1)
end

local common       = require("common")
local tostring     = tostring
local tonumber     = tonumber
local matrix       = {}
local metaMatrix   = {}
local isNumber     = common.isNumber
metaMatrix.__type  = "matrix.matrix"
metaMatrix.__index = metaMatrix

function matrix.isValid(oM)
  return (getmetatable(oM) == metaMatrix)
end

function matrix.getType(oM)
  if(not oM) then return metaMatrix.__type end
  local tM = getmetatable(oM)
  return ((tM and tM.__type) and tostring(tM.__type) or type(oM))
end

function matrix.convNew(vIn,...)
  if(matrix.isValid(vIn)) then return vIn:getNew(vIn) end
  local tyIn, tArg = type(vIn), {...}
  if(isType(tyIn, 5)) then -- Table
    
  end
end

function matrix.getNew(tM)
  local self, mtData = {}, {}; setmetatable(self, metaMatrix)
  if(matrix.isValid(tM)) then mtData = tM:getData()
  else mtData = common.copyItem(tM) end
  local mnR, mnC = #mtData, #mtData[1]
  for iR = 1, mnR do for iC = 1, mnC do
    mtData[iR][iC] = (tonumber(mtData[iR][iC]) or 0)
  end; end
  function self:getData() return mtData end
  function self:cpyData() return common.copyItem(mtData) end
  function self:getSize() return mnR, mnC end
  function self:setData(tA)
    mtData = tA; mnR, mnC = #tA, #tA[1]
    for iR = 1, mnR do for iC = 1, mnC do
      mtData[iR][iC] = (tonumber(mtData[iR][iC]) or 0)
    end; end; return self
  end; return self
end

function metaMatrix:Apply(fC, ...)
  local tData = self:getData()
  local nR, nC = self:getSize()
  for iR = 1, nR do
    for iC = 1, nC do local bS, nC = pcall(tC, ...)
      if(not bS) then return logStatus("matrix.Apply: Failed: "..nC, nil) end
      if(not isNumber(nC)) then return logStatus("matrix.Apply: NaN: "..tostring(nC), nil) end
      tData[iR][iC] = nC
    end
  end; return self
end

function metaMatrix:Print(nS)
  local tData, nR, nC = self:cpyData(), self:getSize()
  common.logStatus("Matrix ["..nR.." x "..nC.."]")
  local nS = common.getClamp(tonumber(nS) or 0,0)
  for iR = 1, nR do if(nS > 0) then
    for iC = 1, nC do tData[iR][iC] = common.stringPadL(tostring(tData[iR][iC]), nS) end; end
    common.logStatus("{"..table.concat(tData[iR],", ").."}")
  end; return self
end

function metaMatrix:getNew(tM)
  return (tM and matrix.getNew(tM) or matrix.getNew(self:cpyData()))
end

function metaMatrix:Scratch(nR,nC)
  local tData = self:getData()
  local tO, cR, cC, eR, eC = {}, 1, 1, self:getSize()
  for iR = 1, eR do for iC = 1, eC do
    if(not (iR == nR or iC == nC)) then
      if(not tO[cR]) then tO[cR] = {} end
      tO[cR][cC] = tData[iR][iC]; cC = (cC + 1)
  end end; if(not (iR == nR or iC == nC)) then
  cC, cR = 1, (cR + 1); end; end; return self:setData(tO)
end

function metaMatrix:getScratch(nR,nC)
  return self:getNew():Scratch(nR,nC)
end

function metaMatrix:getDet(vR)
  local tData, nR, nC = self:getData(), self:getSize(); if(nR ~= nC) then
    return common.logStatus("matrix.getDet: Rectangle ["..nR.." x "..nC.."]", 0) end
  if(isNumber(tData)) then return tData end
  if(nR == 1 and nC == 1) then return tData[1][1] end
  if(nR == 2 and nC == 2) then return ((tData[1][1]*tData[2][2]) - (tData[2][1]*tData[1][2])) end
  local vR = common.getClamp(tonumber(vR) or 1, 1)
  local tR, iR, nD = tData[vR], 1, 0
  for iC = 1, nC do local nV = tR[iC]
    nD = nD + nV*(-1)^(vR+iC)*(self:getScratch(vR,iC):getDet())
  end; return nD
end

function metaMatrix:Rand(nR, nC, nL, nU, vC) local tM = {}
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  for iR = 1, nR do tM[iR] = {}; for iC = 1, nC do
    tM[iR][iC] = common.randomGetNumber(nL, nU, vC)
  end; end; return self:setData(tM)
end

function metaMatrix:getRand(nR, nC, nL, nU, vC)
  return self:getNew():Rand(nR, nC, nL, nU, vC)
end

function metaMatrix:Zero(nR, nC) local tM = {}
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  for iR = 1, nR do tM[iR] = {}; for iC = 1, nC do tM[iR][iC] = 0
  end; end; return self:setData(tM)
end

function metaMatrix:getZero(nR, nC)
  return self:getNew():Zero(nR, nC)
end

function metaMatrix:Unit(nR, nC)
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  self:Zero(nR, nC); local tData, iI = self:getData(), 1
  while(tData[iI] and tData[iI][iI]) do
    tData[iI][iI] = 1; iI = (iI + 1) end; return self
end

function metaMatrix:getUnit(nR, nC)
  return self:getNew():Unit(nR, nC)
end

function metaMatrix:Mul(oM)
  if(matrix.isValid(oM)) then
    local rA, cA = self:getSize()
    local rB, cB = oM:getSize(); if(cA ~= rB) then
      return common.logStatus("matrix.Mul: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
    local tA, tB, tO = self:getData(), oM:getData(), {}
    for i = 1, rA do if(not tO[i]) then tO[i] = {} end
      for j = 1, cB do local nV = 0
        for k = 1, rB do nV = nV + tA[i][k] * tB[k][j] end
        tO[i][j] = nV
      end
    end; return self:setData(tO)
  else local tA, nR, nC = self:getData(), self:getSize()
    local nN = (tonumber(oM) or 0)
    for iR = 1, nR do for iC = 1, nC do
      tA[iR][iC] = tA[iR][iC] * nN
    end end; return self
  end
end

function metaMatrix:getMul(oM)
  return self:getNew():Mul(oM)
end

function metaMatrix:Trans()
  local tO, tData, nR, nC = {}, self:getData(), self:getSize()
  for iC = 1, nC do if(not tO[iC]) then tO[iC] = {} end
    for iR = 1, nR do tO[iC][iR] = tData[iR][iC] end
  end; return self:setData(tO)
end

function metaMatrix:getTrans()
  return self:getNew():Trans()
end

function metaMatrix:Adj()
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return common.logStatus("matrix.Adj: Rectangle ["..nR.." x "..nC.."]",nil) end
  local tData, tO = self:getData(), {}
  for iR = 1, nR do for iC = 1, nC do
    if(not tO[iR]) then tO[iR] = {} end
    tO[iR][iC] = (-1)^(iR+iC)*self:getScratch(iR,iC):getDet()
  end end; return self:setData(tO)
end

function metaMatrix:getAdj()
  return self:getNew():Adj()
end

function metaMatrix:Inv()
  local nD = self:getDet(); if(nD ~= 0) then
    return self:Adj():Trans():Mul(1/nD)
  else return common.logStatus("matrix.Inv: Not inverted",self) end
end

function metaMatrix:getInv()
  return self:getNew():Inv()
end

function metaMatrix:Div(oM)
  local rA, cA = self:getSize()
  local rB, cB = oM:getSize(); if(cA ~= rB) then
    return common.logStatus("matrix.Div: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
  if(matrix.isValid(oM)) then
    return self:Mul(oM:getInv())
  else
    return self:Mul(tonumber(oM) or 0)
  end
end

function metaMatrix:getDiv(oM)
  return self:getNew():Div(oM)
end

metaMatrix.__call = function(oM, nR, nC)
  local tData = oM:getData()
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  local tR = tData[nR]; if(not tR) then
    return common.logStatus("matrix.Call: Missing row ["..nR.." x "..nC.."]",nil) end
  local nV = tR[nC]; if(not nV) then
    return common.logStatus("matrix.Call: Missing col ["..nR.." x "..nC.."]",nil) end
  return nV -- Return the indexed column. Null if not found
end

return matrix
