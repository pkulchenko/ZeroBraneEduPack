-- Copyright (C) 2017 Deyan Dobromirov
-- Implements matrix manipulations

if not debug.getinfo(3) then
  print("This is a module to load with `local matrix = require('matrix')`.")
  os.exit(1)
end

local common         = require("common")
local tostring       = tostring
local tonumber       = tonumber
local matrix         = {}
local metaMatrix     = {}
local dataMatrix     = {}
local isTable        = common.isTable
local isString       = common.isString
local isNumber       = common.isNumber
local logStatus      = common.logStatus
local convSignString = common.convSignString
metaMatrix.__type    = "matrix.matrix"
metaMatrix.__index   = metaMatrix
dataMatrix.__symch   = "x"

function matrix.extend()
  dataMatrix.__extlb = require("extensions").matrix; return matrix
end

function matrix.isValid(oM)
  return (getmetatable(oM) == metaMatrix)
end

function matrix.getType(oM)
  if(not oM) then return metaMatrix.__type end
  local tM = getmetatable(oM)
  return ((tM and tM.__type) and tostring(tM.__type) or type(oM))
end

function matrix.extValue(nV)
  
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
  local extlb = dataMatrix.__extlb
  function self:getData() return mtData end
  function self:cpyData() return common.copyItem(mtData) end
  function self:getSize() return mnR, mnC end
  function self:setData(oM)
    if(matrix.isValid(oM)) then mtData = oM:cpyData()
    elseif(oM) then mtData = common.copyItem(oM)
    else --[[ Reinitialize mtData ]] end
    mnR, mnC = #mtData, #mtData[1]
    for iR = 1, mnR do for iC = 1, mnC do
      if(extlb) then mtData[iR][iC] = extlb.complexNew(mtData[iR][iC])
      else mtData[iR][iC] = (tonumber(mtData[iR][iC]) or 0) end
    end; end; return self
  end; return self:setData(tM)
end

function metaMatrix:isSymbolic()
  return isString(self:getData()[1][1])
end

function metaMatrix:isSquare()
  local nR, nC = self:getSize(); return (nR == nC)
end

function metaMatrix:isUnit()
  return true
end

function metaMatrix:Apply(fC, ...)
  local tData, nR, nC = self:getData(), self:getSize()
  for iR = 1, nR do for iC = 1, nC do
    local bS, nC = pcall(fC, tData, iR, iC, ...)
    if(not bS) then return logStatus("matrix.Apply: Failed: "..nC, nil) end
    if(not isNumber(nC)) then return logStatus("matrix.Apply: NaN: "..tostring(nC), nil) end
    tData[iR][iC] = nC
  end; end; return self
end

function metaMatrix:getApply(fC, ...)
  return self:getNew():Apply(fC, ...)
end

function metaMatrix:Print(nS, sM)
  local sM = (sM and " "..tostring(sM) or "")
  local tData, nR, nC = self:getData(), self:getSize()
  logStatus("Matrix ["..nR.." x "..nC.."]"..sM)
  local nS = common.getClamp(tonumber(nS) or 0,0)
  for iR = 1, nR do local sL = ""
    for iC = 1, nC do
      sL = sL..", "..common.stringPadL(tostring(tData[iR][iC]), nS)
    end; logStatus("[ "..sL:sub(2,-1).." ]")
  end; return self
end

function metaMatrix:getNew(tM)
  return (tM and matrix.getNew(tM) or matrix.getNew(self:getData()))
end

function metaMatrix:Neg()
  local tData, nR, nC = self:getData(), self:getSize()
  local extlb = dataMatrix.__extlb
  for iR = 1, nR do for iC = 1, nC do
    if(extlb) then tData[iR][iC]:Neg()
    else tData[iR][iC] = -tData[iR][iC] end
  end; end; return self
end

function metaMatrix:getNeg()
  return self:getNew():Neg()
end

--[[
  Modify the internal elements of the matrix to be used in symbolic mode
  Uses the flag /bS/ to toggle on/off the symbolic mode
]]
function metaMatrix:setSym(bS)
  local tData, nR, nC = self:getData(), self:getSize()
  local extlb = dataMatrix.__extlb
  for iR = 1, nR do for iC = 1, nC do
    if(bS) then
      if(extlb) then tData[iR][iC] = tostring(tData[iR][iC])
      else tData[iR][iC] = convSignString(tonumber(tData[iR][iC]) or 0) end     
    else -- When toggled convert back to a number
      if(extlb) then tData[iR][iC] = extlb.complexConvNew(tData[iR][iC])
      else tData[iR][iC] = (tonumber(tData[iR][iC]) or 0) end      
    end
  end; end; return self
end

--[[
  Modify destination row id /iD/, with the source /iS/.
  Uses the coefficient nK to scale the linear system
  to adjust the destination row by id based on the source
]]
function metaMatrix:Modify(iD, iS, nK)
  local tData, nR, nC = self:getData(), self:getSize()
  if(not iS) then return logStatus("matrix.Modify: Source missing",nil) end
  if(not iD) then return logStatus("matrix.Modify: Destination missing",nil) end
  if(not nK) then return logStatus("matrix.Modify: Modifyer missing",nil) end
  local tS = tData[iS]; if(not iS) then
    return logStatus("matrix.Modify: Source invalid",nil) end
  local tD = tData[iD]; if(not tD) then
    return logStatus("matrix.Modify: Destination invalid",nil) end
  for iC = 1, nC do tD[iC] = tD[iC] + nK * tS[iC] end; return self
end

function metaMatrix:getModify(iD, iS, nK)
  return self:getNew():Modify(iD, iS, nK)
end

--[[
 * Scratches the matrix by row /nR/ and colum /nC/
 * and converts matrix to sub-matrix
]]
function metaMatrix:Minor(nR,nC)
  local tData = self:getData()
  local tM, cR, cC, eR, eC = {}, 1, 1, self:getSize()
  for iR = 1, eR do for iC = 1, eC do
    if(not (iR == nR or iC == nC)) then
      if(not tM[cR]) then tM[cR] = {} end
      tM[cR][cC] = tData[iR][iC]; cC = (cC + 1)
  end end; if(not (iR == nR or iC == nC)) then
  cC, cR = 1, (cR + 1); end; end; return self:setData(tM)
end

function metaMatrix:getMinor(nR,nC)
  return self:getNew():Minor(nR,nC)
end

function metaMatrix:getCofactor(nR,nC)
  return (-1)^(nR+nC)*(self:getMinor(nR,nC):getDet())
end

--[[
 * Calcolates matrix determinant by expanding on the row /vR/
]]
function metaMatrix:getDet(vR)
  local nR, nC, bS = self:getSize(); if(nR ~= nC) then
    return logStatus("matrix.getDet: Rectangle ["..nR.." x "..nC.."]", 0) end
  local tData = self:getData(); bS = isString(tData[1][1])
  if(not isTable(tData)) then return tData end
  if(nR == 1 and nC == 1) then return tData[1][1] end
  if(nR == 2 and nC == 2) then local R1, R2 = tData[1], tData[2]
    return ((R1[1]*R2[2]) - (R2[1]*R1[2])) end
  local vR = common.getClamp(tonumber(vR) or 1, 1)
  local tR, iR, nD = tData[vR], 1, 0
  for iC = 1, nC do nD = nD + tR[iC]*self:getCofactor(vR,iC) end; return nD
end

--[[
  Builds the haracteristic polinomial for matrix roots
]]
function metaMatrix:getPolynomial()
  local symch, oM = dataMatrix.__symch, self:getNew()
  return oM:setItemsSym(true):Apply(function(tData,iR,iC,sS) local vV = tData[iR][iC]
    return (iC==iR and "("..vV.."-"..sS..")" or "("..vV..")") end, symch):getDet()
end

function metaMatrix:Rand(nR, nC, nL, nU, vC) local tM = {}
  local nR = common.getClamp(tonumber(nR) or 1 ,1)
  local nC = common.getClamp(tonumber(nC) or nR,1)
  for iR = 1, nR do tM[iR] = {}; for iC = 1, nC do
    if(extlb) then tM[iR][iC] = extlb.complexGetRandom(nL, nU, vC)
    else tM[iR][iC] = common.randomGetNumber(nL, nU, vC) end
  end; end; return self:setData(tM)
end

function metaMatrix:getRand(nR, nC, nL, nU, vC)
  return self:getNew():Rand(nR, nC, nL, nU, vC)
end

function metaMatrix:Fill(nR, nC, vV, bM)
  local tM, vR, vC = {}
  local extlb tData = dataMatrix.__extlb
  if(nR or nC) then
   vR = common.getClamp(tonumber(nR) or 1 ,1)
   vC = common.getClamp(tonumber(nC) or nR,1)
  else tData, vR, vC = self:getData(), self:getSize() end
  for iR = 1, vR do if(not tData) then tM[iR] = {} end
    for iC = 1, vC do if((bM and iR==iC) or not bM) then
      if(extlb) then
        if(tData) then tData[iR][iC]:Set(vV)
        else tM[iR][iC] = extlb.complexNew():Set(vV) end
      else 
        if(tData) then tData[iR][iC] = vV
        else tM[iR][iC] = vV end
      end
    end; end
  end; return (tData and self:setData() or self:setData(tM))
end

function metaMatrix:getFill(nR, nC, vV, bM)
  return self:getNew():Fill(nR, nC, vV, bM)
end

function metaMatrix:Zero(nR, nC)
  local extlb tData = dataMatrix.__extlb
  local nZ = (extlb and complexNew(0,0) or 0)
  return self:Fill(nR, nC, nZ)
end

function metaMatrix:getZero(nR, nC)
  return self:getNew():Zero(nR, nC)
end

function metaMatrix:Ones(nR, nC)
  local extlb tData = dataMatrix.__extlb
  local nZ = (extlb and complexNew(1,0) or 1)
  return self:Fill(nR, nC, nZ)
end

function metaMatrix:getOnes(nR, nC)
  return self:getNew():Ones(nR, nC)
end

function metaMatrix:Unit(nR, nC)
  return self:Fill(nR, nC, 1, true)
end

function metaMatrix:getUnit(nR, nC)
  return self:getNew():Unit(nR, nC)
end

function metaMatrix:Add(oM)
  local oR, oC = oM:getSize()
  local mR, mC = self:getSize()
  local mData, oData = self:getData(), oM:getData()
  if(oR ~= mR) then
    return logStatus("matrix.Div: Row mismatch ["..oR.." x "..oC.."] + ["..mR.." x "..mC.."]",nil) end
  if(oC ~= mC) then
    return logStatus("matrix.Div: Col mismatch ["..oR.." x "..oC.."] + ["..mR.." x "..mC.."]",nil) end
  local extlb = dataMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then mData[iR][iC]:Add(oData[iR][iC])
    else mData[iR][iC] = mData[iR][iC] + oData[iR][iC] end
  end end; return self
end

function metaMatrix:getAdd(oM)
  return self:getNew():Add(oM)
end

function metaMatrix:Sub(oM)
  local oR, oC = oM:getSize()
  local mR, mC = self:getSize()
  local mData, oData = self:getData(), oM:getData()
  if(oR ~= mR) then
    return logStatus("matrix.Sub: Row mismatch ["..oR.." x "..oC.."] - ["..mR.." x "..mC.."]",nil) end
  if(oC ~= mC) then
    return logStatus("matrix.Sub: Col mismatch ["..oR.." x "..oC.."] - ["..mR.." x "..mC.."]",nil) end
  local extlb = dataMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then mData[iR][iC]:Sub(oData[iR][iC])
    else mData[iR][iC] = mData[iR][iC] - oData[iR][iC] end
  end end; return self
end

function metaMatrix:getSub(oM)
  return self:getNew():Sub(oM)
end

function metaMatrix:Exp()
  local mData = self:getData()
  local mR, mC = self:getSize()
  local extlb = dataMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then mData[iR][iC]:Exp()
    else mData[iR][iC] = math.exp(mData[iR][iC]) end
  end end; return self
end

function metaMatrix:getExp()
  return self:getNew():Exp()
end

function metaMatrix:Log()
  local mData = self:getData()
  local mR, mC = self:getSize()
  local extlb = dataMatrix.__extlb
  for iR = 1, mR do for iC = 1, mC do
    if(extlb) then mData[iR][iC]:Log()
    else mData[iR][iC] = math.log(mData[iR][iC]) end
  end end; return self
end

function metaMatrix:getLog()
  return self:getNew():Log()
end

function metaMatrix:Mul(oM)
  local extlb = dataMatrix.__extlb
  if(matrix.isValid(oM)) then
    local rA, cA = self:getSize()
    local rB, cB = oM:getSize(); if(cA ~= rB) then
      return logStatus("matrix.Mul: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
    local tA, tB, tM = self:getData(), oM:getData(), {}
    for i = 1, rA do if(not tM[i]) then tM[i] = {} end
      for j = 1, cB do local nV
        if(extlb) then nV = extlb.complexNew() else nV = 0 end
        for k = 1, rB do
          if(extlb) then nV:Add(tA[i][k] * tB[k][j])
          else nV = nV + (tA[i][k] * tB[k][j]) end
        end; tM[i][j] = nV
      end
    end; return self:setData(tM)
  else
    local nR, nC = self:getSize()
    local tA, nN = self:getData()
    if(extlb) then nN = extlb.complexNew(oM)
    else nN = (tonumber(oM) or 0) end
    for iR = 1, nR do for iC = 1, nC do
      if(extlb) then tA[iR][iC]:Mul(nN)
      else tA[iR][iC] = tA[iR][iC] * nN end
    end end; return self
  end
end

function metaMatrix:getMul(oM)
  return self:getNew():Mul(oM)
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
  end; end; end;
  while(not tData[nE][1]) do tData[nE] = nil; nE = nE - 1 end
  return self:setData() -- Reinitialize data size
end

function metaMatrix:getTrans()
  return self:getNew():Trans()
end

function metaMatrix:Adj()
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return logStatus("matrix.Adj: Rectangle ["..nR.." x "..nC.."]",nil) end
  local tData, tM = self:getData(), {}
  for iR = 1, nR do for iC = 1, nC do
    if(not tM[iR]) then tM[iR] = {} end
    tM[iR][iC] = self:getCofactor(iR,iC)
  end end; return self:setData(tM)
end

function metaMatrix:getAdj()
  return self:getNew():Adj()
end

function metaMatrix:Inv()
  local nD = self:getDet(); if(nD ~= 0) then
    return self:Adj():Trans():Mul(1/nD)
  else return logStatus("matrix.Inv: Not inverted",self) end
end

function metaMatrix:getInv()
  return self:getNew():Inv()
end

function metaMatrix:Div(oR, oI)
  local rA, cA = self:getSize()
  local rB, cB = oR:getSize(); if(cA ~= rB) then
    return logStatus("matrix.Div: Dimension mismatch ["..rA.." x "..cA.."] * ["..rB.." x "..cB.."]",nil) end
  if(matrix.isValid(oR)) then
    return self:Mul(oR:getInv())
  else local extlb = dataMatrix.__extlb
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
    return logStatus("matrix.Call: Missing row ["..nR.." x "..nC.."]",nil) end
  local nV = tR[nC]; if(not nV) then
    return logStatus("matrix.Call: Missing col ["..nR.." x "..nC.."]",nil) end
  if(nS) then tR[nC] = nS end; return nV -- Return the indexed column. Null if not found
end

function metaMatrix:Upper(bS)
  local tData, nR, nC = self:getData(), self:getSize()
  local tS, iR, eR, dR, iC, dC = tData[1], 2, nR, 1
  if(bS) then iC, dC = nC, -1 else iC, dC = 1, 1 end
  while(iR <= eR) do local iD = iR
    while(iD <= eR) do local tD = tData[iD]
      local nK = (tD[iC] / tS[iC])
      self:Modify(iD, iR-dR, -nK); iD = (iD + dR)
    end; tS, iC, iR = tData[iR], (iC + dC), (iR + dR)
  end; return self
end

function metaMatrix:getUpper(bS)
  return self:getNew():Upper(bS)
end

function metaMatrix:Lower(bS)
  local tData, nR, nC = self:getData(), self:getSize()
  local tS, iR, eR, dR, iC, dC = tData[nR], (nR-1), 1, -1
  if(bS) then iC, dC = 1, 1 else iC, dC = nC, -1 end
  while(iR >= eR) do local iD = iR
    while(iD >= eR) do local tD = tData[iD]
      local nK = (tD[iC] / tS[iC])
      self:Modify(iD, iR-dR, -nK); iD = (iD + dR)
    end; tS, iC, iR = tData[iR], (iC + dC), (iR + dR)
  end; return self
end

function metaMatrix:getLower(bS)
  return self:getNew():Lower(bS)
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
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return logStatus("matrix.Solve: Rectangle ["..nR.." x "..nC.."]", nil) end
  return self:Inv():Mul(oB)
end

function metaMatrix:getSolve(oB)
  return self:getNew():Solve(oB)
end

function metaMatrix:getTrace()
  local mR, mC = self:getSize()
  local nE = math.min(mR, mC)
  local mData = self:getData()
  local extlb, nT = dataMatrix.__extlb
  if(extlb) then nT = extlb.complexNew() else nT = 0 end
  for iE = 1, nE do
    if(extlb) then nT:Add(mData[iE][iE])
    else nT = nT + mData[iE][iE] end
  end; return nT
end

function metaMatrix:PowExp(oR, oI)
  local extlb, nK = dataMatrix.__extlb
  if(extlb) then nK = extlb.complexNew(oR, oI)
  else nK = (tonumber(oR) or 0) end
  return self:Log():Mul(nK):Exp()
end

function metaMatrix:getPowExp(oR, oI)
  return self:getNew():PowExp(oR, oI)
end

-- det(tI - A) = 0
function metaMatrix:getRoots()
  
end

function metaMatrix:getEig()
  local nR, nC = self:getSize(); if(nR ~= nC) then
    return logStatus("matrix.getEig: Rectangle ["..nR.." x "..nC.."]", nil) end
  return self:getNew(), self:getNew()
end

return matrix
