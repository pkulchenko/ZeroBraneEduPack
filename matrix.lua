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

function matrix.extend()
  metaMatrix.__extlb = require("extensions").matrix; return matrix
end

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
  local mnR, mnC mtData = 0, 0, nil
  local self, mtData = setmetatable({}, metaMatrix)
  local extlb = metaMatrix.__extlb
  function self:getData() return mtData end
  function self:cpyData() return common.copyItem(mtData) end
  function self:getSize() return mnR, mnC end
  function self:setData(oM)
    if(matrix.isValid(oM)) then mtData = oM:getData()
    else mtData = common.copyItem(oM) end
    mnR, mnC = #mtData, #mtData[1]
    for iR = 1, mnR do for iC = 1, mnC do
      if(extlb) then
        mtData[iR][iC] = extlb.complexNew(mtData[iR][iC])
      else
        mtData[iR][iC] = (tonumber(mtData[iR][iC]) or 0)
      end
    end; end; return self
  end; return self:setData(tM)
end

function metaMatrix:Apply(fC, ...)
  local tData, nR, nC = self:getData(), self:getSize()
  for iR = 1, nR do
    for iC = 1, nC do local bS, nC = pcall(tC, ...)
      if(not bS) then return logStatus("matrix.Apply: Failed: "..nC, nil) end
      if(not isNumber(nC)) then return logStatus("matrix.Apply: NaN: "..tostring(nC), nil) end
      tData[iR][iC] = nC
    end
  end; return self
end

function metaMatrix:Print(nS, sM)
  local sM = (sM and " "..tostring(sM) or "")
  local tData, nR, nC = self:getData(), self:getSize()
  common.logStatus("Matrix ["..nR.." x "..nC.."]"..sM)
  local nS = common.getClamp(tonumber(nS) or 0,0)
  for iR = 1, nR do local sL = ""
    for iC = 1, nC do
      sL = sL..", "..common.stringPadL(tostring(tData[iR][iC]), nS)
    end; common.logStatus("[ "..sL:sub(2,-1).." ]")
  end; return self
end

function metaMatrix:getNew(tM)
  return (tM and matrix.getNew(tM) or matrix.getNew(self:cpyData()))
end

function metaMatrix:Scratch(nR,nC)
  local tData = self:getData()
  local tM, cR, cC, eR, eC = {}, 1, 1, self:getSize()
  for iR = 1, eR do for iC = 1, eC do
    if(not (iR == nR or iC == nC)) then
      if(not tM[cR]) then tM[cR] = {} end
      tM[cR][cC] = tData[iR][iC]; cC = (cC + 1)
  end end; if(not (iR == nR or iC == nC)) then
  cC, cR = 1, (cR + 1); end; end; return self:setData(tM)
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

function metaMatrix:Ones(nR, nC) local tM = {}
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  for iR = 1, nR do tM[iR] = {}; for iC = 1, nC do tM[iR][iC] = 1
  end; end; return self:setData(tM)
end

function metaMatrix:getOnes(nR, nC)
  return self:getNew():Ones(nR, nC)
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

function metaMatrix:Add(oB)
  local oData = oB:getData()
  local mData = self:getData()
  local oR, oC = oB:getSize()
  local mR, mC = self:getSize()
  local extlb = metaMatrix.__extlb
  if(oR ~= mR) then
    return common.logStatus("matrix.Div: Row mismatch ["..oR.." x "..oC.."] + ["..mR.." x "..mC.."]",nil) end
  if(oC ~= mC) then
    return common.logStatus("matrix.Div: Col mismatch ["..oR.." x "..oC.."] + ["..mR.." x "..mC.."]",nil) end
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then
      mData[iR][iC]:Add(mData[iR][iC])
    else
      mData[iR][iC] = mData[iR][iC] + oData[iR][iC]
    end
  end end; return self
end

function metaMatrix:getAdd(oB)
  return self:getNew():Add(oB)
end

function metaMatrix:Sub(oB)
  local oData = oB:getData()
  local mData = self:getData()
  local oR, oC = oB:getSize()
  local mR, mC = self:getSize()
  local extlb = metaMatrix.__extlb
  if(oR ~= mR) then
    return common.logStatus("matrix.Sub: Row mismatch ["..oR.." x "..oC.."] - ["..mR.." x "..mC.."]",nil) end
  if(oC ~= mC) then
    return common.logStatus("matrix.Sub: Col mismatch ["..oR.." x "..oC.."] - ["..mR.." x "..mC.."]",nil) end
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then
      mData[iR][iC]:Sub(mData[iR][iC])
    else
      mData[iR][iC] = mData[iR][iC] - oData[iR][iC]
    end
  end end; return self
end

function metaMatrix:getSub(oB)
  return self:getNew():Sub(oB)
end

function metaMatrix:Exp()
  local mData = self:getData()
  local mR, mC = self:getSize()
  local extlb = metaMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then
      mData[iR][iC]:Exp()
    else
      mData[iR][iC] = math.exp(mData[iR][iC])
    end
  end end; return self
end

function metaMatrix:getExp()
  return self:getNew():Exp()
end

function metaMatrix:Log()
  local mData = self:getData()
  local mR, mC = self:getSize()
  local extlb = metaMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then mData[iR][iC]:Log()
    else mData[iR][iC] = math.log(mData[iR][iC]) end
  end end; return self
end

function metaMatrix:getLog()
  return self:getNew():Log()
end

function metaMatrix:Mul(oR, oI)
  if(matrix.isValid(oR)) then
    local rA, cA = self:getSize()
    local rB, cB = oR:getSize(); if(cA ~= rB) then
      return common.logStatus("matrix.Mul: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
    local tA, tB, tM = self:getData(), oR:getData(), {}
    for i = 1, rA do if(not tM[i]) then tM[i] = {} end
      for j = 1, cB do local nV = 0
        for k = 1, rB do nV = nV + tA[i][k] * tB[k][j] end
        tM[i][j] = nV
      end
    end; return self:setData(tM)
  else local tA, nR, nC = self:getData(), self:getSize()
    local extlb, nN = metaMatrix.__extlb
    if(extlb) then nN = extlb.complexNew(oR, oI)
    else nN = (tonumber(oR) or 0)  end
    for iR = 1, nR do for iC = 1, nC do
      if(extlb) then tA[iR][iC]:Mul(nN)
      else tA[iR][iC] = tA[iR][iC] * nN end
    end end; return self
  end
end

function metaMatrix:getMul(oR, oI)
  return self:getNew():Mul(oR, oI)
end

function metaMatrix:Trans()
  local tData, nR, nC = self:getData(), self:getSize()
  local nE = (nR > nC and nR or nC)
  for iC = 1, nE do for iR = 1, nE do if(iC < iR) then
    local vC = (tData[iC] and tData[iC][iR] or nil)
    local vR = (tData[iR] and tData[iR][iC] or nil)
    if(not tData[iC]) then tData[iC] = {} end
    if(not tData[iR]) then tData[iR] = {} end
    tData[iC][iR], tData[iR][iC] = vR, vC
  end; end; end; while(not tData[nE][1]) do
    tData[nE] = nil; nE = nE - 1 end
  return self:setData(tData)
end

function metaMatrix:getTrans()
  return self:getNew():Trans()
end

function metaMatrix:Adj()
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return common.logStatus("matrix.Adj: Rectangle ["..nR.." x "..nC.."]",nil) end
  local tData, tM = self:getData(), {}
  for iR = 1, nR do for iC = 1, nC do
    if(not tM[iR]) then tM[iR] = {} end
    tM[iR][iC] = (-1)^(iR+iC)*self:getScratch(iR,iC):getDet()
  end end; return self:setData(tM)
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

function metaMatrix:Div(oR, oI)
  local rA, cA = self:getSize()
  local rB, cB = oR:getSize(); if(cA ~= rB) then
    return common.logStatus("matrix.Div: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
  if(matrix.isValid(oR)) then
    return self:Mul(oR:getInv())
  else local extlb = metaMatrix.__extlb
    if(extlb) then return self:Mul(complexNew(oR, oI):Rev())
    else return self:Mul(1/(tonumber(oR) or 0)) end
  end
end

function metaMatrix:getDiv(oR, oI)
  return self:getNew():Div(oR, oI)
end

metaMatrix.__call = function(oM, nR, nC, nS)
  local tData, nS = oM:getData(), tonumber(nS)
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  local tR = tData[nR]; if(not tR) then
    return common.logStatus("matrix.Call: Missing row ["..nR.." x "..nC.."]",nil) end
  local nV = tR[nC]; if(not nV) then
    return common.logStatus("matrix.Call: Missing col ["..nR.." x "..nC.."]",nil) end
  if(nS) then tR[nC] = nS end; return nV -- Return the indexed column. Null if not found
end

function metaMatrix:Upper()
  local tData = self:getData()
  local nR, nC = self:getSize(); local iC = 1
  for iR = 1, nR do local tRow = tData[iR] 
    for iK = (iR+1), nR do local oRow = tData[iK]
      if(oRow[iC] ~= 0 and iC <= nC) then
        local nK = (tRow[iC] / oRow[iC])
        for iN = iC, nC do oRow[iN] = (oRow[iN] * nK) - tRow[iN] end
      end
    end; iC = (iC + 1)
  end; return self
end

function metaMatrix:getUpper()
  return self:getNew():Upper()
end

function metaMatrix:Lower()
  local tData = self:getData()
  local nR, nC = self:getSize(); local iC = nC
  for iR = nR, 1, -1  do local tRow = tData[iR] 
    for iK = (iR-1), 1, -1 do local oRow = tData[iK]
      if(oRow[iC] ~= 0 and iC <= nC) then
        local nK = (tRow[iC] / oRow[iC])
        for iN = iC, nC do oRow[iN] = (oRow[iN] * nK) - tRow[iN] end
      end
    end; iC = (iC - 1)
  end; return self
end

function metaMatrix:getLower()
  return self:getNew():Lower()
end

function metaMatrix:Drop()
  local tData = self:getData()
  local iR, nR, nC = 1, self:getSize()
  while(tData[iR]) do local nS = 0
    for iC = 1, nC do
      nS = nS + math.abs(tData[iR][iC]) 
    end if(nS == 0) then table.remove(tData, iR)
      else iR = iR + 1 end
  end; return self:setData(tData)
end

function metaMatrix:getDrop()
  return self:getNew():Drop()
end

function metaMatrix:getRank()
  local oR = self:getNew():Upper():Drop():getSize()
  local tR = self:getNew():Trans():Upper():Drop():getSize()
  return math.max(oR, tR)
end

function metaMatrix:Solve(oB)
  local tData, nR, nC = self:getData(), self:getSize(); if(nR ~= nC) then
    return common.logStatus("matrix.Solve: Rectangle ["..nR.." x "..nC.."]", nil) end
  return self:Inv():Mul(oB)
end

function metaMatrix:getSolve(oB)
  return self:getNew():Solve(oB)
end

function metaMatrix:getTrace()
  local mR, mC = self:getSize()
  local nE = math.min(mR, mC)
  local mData = self:getData()
  local extlb, nT = metaMatrix.__extlb
  if(extlb) then nT = extlb.complexNew() else nT = 0 end
  for iE = 1, nE do
    if(extlb) then nT:Add(mData[iE][iE])
    else nT = nT + mData[iE][iE] end
  end; return nT
end

function metaMatrix:Pow(oR, oI)
  local extlb, nK = metaMatrix.__extlb
  if(extlb) then nK = extlb.complexNew(oR, oI)
  else nK = (tonumber(oR) or 0) end
  return self:Log():Mul(nK):Exp()
end

function metaMatrix:getPow(oR, oI)
  return self:getNew():Pow(oR, oI)
end

function metaMatrix:getEig()
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return common.logStatus("matrix.getEig: Rectangle ["..nR.." x "..nC.."]", nil) end
  return self:getNew(), self:getNew()
end

return matrix
