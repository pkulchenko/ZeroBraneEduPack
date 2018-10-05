-- Copyright (C) 2017 Deyan Dobromirov
-- A complex functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local complex = require('complex')`.")
  os.exit(1)
end

local common       = require("common")
local type         = type
local math         = math
local pcall        = pcall
local tonumber     = tonumber
local tostring     = tostring
local getmetatable = getmetatable
local setmetatable = setmetatable
local complex      = {}
local metaComplex  = {}
local metaData     = {}
local isNil           = common.isNil
local getPick         = common.getPick
local getSign         = common.getSign
local getRound        = common.getRound
local getClamp        = common.getClamp
local isString        = common.isString
local isType          = common.isType
local isNumber        = common.isNumber
local logStatus       = common.logStatus
local logString       = common.logString
local getSignNon      = common.getSignNon
local getValueKeys    = common.getValueKeys
local randomGetNumber = common.randomGetNumber

metaComplex.__type  = "complex.complex"
metaComplex.__index = metaComplex

metaData.__valre = 0
metaData.__valim = 0
metaData.__cactf = {}
metaData.__valns = "X"
metaData.__margn = 1e-10
metaData.__curve = 100
metaData.__getpi = math.pi
metaData.__bords = {"{([<|/","})]>|/"}
metaData.__ssyms = {"i", "I", "j", "J", "k", "K"}
metaData.__radeg = (180 / metaData.__getpi)
metaData.__kreal = {1,"Real","real","Re","re","R","r","X","x"}
metaData.__kimag = {2,"Imag","imag","Im","im","I","i","Y","y"}

function complex.isValid(cNum)
  return (getmetatable(cNum) == metaComplex)
end

function complex.getType(cNum)
  if(not cNum) then return metaComplex.__type end
  local tM = getmetatable(cNum)
  return ((tM and tM.__type) and tostring(tM.__type) or type(cNum))
end

function complex.setMargin(nM)
  metaData.__margn = math.abs(tonumber(nM) or 0)
end

function complex.getMargin()
  return metaData.__margn
end

local function getUnpackStack(R, I, E)
  if(complex.isValid(R)) then local nR, nI = R:getParts() return nR, nI, I end
  return (tonumber(R) or metaData.__valre), (tonumber(I) or metaData.__valim), E
end

function complex.getNew(nRe, nIm)
  self = {}; setmetatable(self, metaComplex)
  local Re = tonumber(nRe) or metaData.__valre
  local Im = tonumber(nIm) or metaData.__valim

  if(complex.isValid(nRe)) then Re, Im = nRe:getParts() end

  function self:setReal(R)  Re = (tonumber(R) or metaData.__valre); return self end
  function self:setImag(I)  Im = (tonumber(I) or metaData.__valim); return self end
  function self:getReal()   return Re end
  function self:getImag()   return Im end
  function self:getParts()  return Re, Im end

  function self:Set(R, I)
    local R, I = getUnpackStack(R, I)
    Re, Im = R, I; return self
  end

  function self:Add(R, I)
    local R, I = getUnpackStack(R, I)
    Re, Im = (Re + R), (Im + I); return self
  end

  function self:Sub(R, I)
    local R, I = getUnpackStack(R, I)
    Re, Im = (Re - R), (Im - I); return self
  end

  function self:Rsz(vN) local nN = tonumber(vN)
    if(nN) then Re, Im = (Re * nN), (Im * nN) end; return self
  end

  function self:Mul(R, I, E)
    local C, D, U = getUnpackStack(R, I, E)
    if(U) then Re, Im = (Re*C), (Im*D) else
      Re, Im = (Re*C - Im*D), (Re*D + Im*C)
    end; return self
  end

  function self:Mid(R, I)
    local C, D = getUnpackStack(R, I)
    Re, Im = ((Re + C) / 2), ((Im + D) / 2); return self
  end

  function self:Div(R, I, E)
    local C, D, U = getUnpackStack(R, I, E)
    if(U) then Re, Im = (Re/C), (Im/D) else local Z = (C*C + D*D)
      Re, Im = ((Re*C + Im*D) / Z), ((Im*C - Re*D) / Z)
    end; return self
  end

  function self:Mod(R, I)
    local C, D = getUnpackStack(R, I); self:Div(C,D)
    local rei, ref = math.modf(Re)
    local imi, imf = math.modf(Im)
    return self:Set(ref,imf):Mul(C,D)
  end

  function self:Rev()
    local N = self:getNorm2()
    Re, Im = (Re/N), (-Im/N); return self
  end

  function self:Pow(R, I, E)
    local C, D, U = getUnpackStack(R, I, E)
    if(U) then Re, Im = (Re^C), (Im^D) else
      local N, G = self:getNorm2(), self:getAngRad()
      local eK = N^(C/2) * math.exp(-D*G)
      local eC = (C*G + 0.5*D*math.log(N))
      Re, Im = (eK * math.cos(eC)), (eK * math.sin(eC))
    end; return self
  end

  return self
end

function metaComplex:Action(aK,...)
  if(not aK) then return false, self end
  local fDr = metaData.__cactf[aK]
  if(not fDr) then return false, self end
  return pcall(fDr,self,...)
end

function metaComplex:getNew(nR, nI)
  local N = complex.getNew(self); if(nR or nI) then
    local R, I = getUnpackStack(nR, nI); N:Set(R, I)
  end; return N
end

function metaComplex:Random(nL, nU, vC)
  local R = randomGetNumber(nL, nU, vC)
  local I = randomGetNumber(nL, nU, vC)
  return self:setReal(R):setImag(I)
end

function metaComplex:getRandom(nL, nU, vC)
  return self:getNew():Random(nL, nU, vC)
end

function metaComplex:Apply(fF, bR, bI)
  local R, I = self:getParts()
  local br, sR, vR = getPick(isNil(bR), true, bR)
  local bi, sI, vI = getPick(isNil(bI), true, bI)
  if(br) then sR, vR = pcall(fF, R); if(not sR) then
    return logStatus("complex.Apply(R): Failed: "..vR, self) end end
  if(bi) then sI, vI = pcall(fF, I); if(not sI) then
    return logStatus("complex.Apply(I): Failed: "..vI, self) end end
  R, I = ((br) and vR or R), ((bi) and vI or I)
  return self:setReal(R):setImag(I)
end

function metaComplex:getType () return metaComplex.__type end
function metaComplex:NegRe   () return self:setReal(-self:getReal()) end
function metaComplex:NegIm   () return self:setImag(-self:getImag()) end
function metaComplex:Conj    () return self:NegIm() end
function metaComplex:Neg     () return self:NegRe():NegIm() end
function metaComplex:getNeg  () return self:getNew():Neg() end
function metaComplex:getNegRe() return self:getNew():NegRe() end
function metaComplex:getNegIm() return self:getNew():NegIm() end
function metaComplex:getConj () return self:getNegIm() end

function metaComplex:getNorm2()
  local R, I = self:getParts(); return (R*R + I*I) end

function metaComplex:getNorm() return math.sqrt(self:getNorm2()) end

function metaComplex:setNorm(nN)
  return self:Rsz((tonumber(nN) or 0) / self:getNorm())
end

function metaComplex:Unit()
  return self:Rsz(1/self:getNorm())
end

function metaComplex:getUnit()
  return self:getNew():Unit()
end

function metaComplex:getDot(cV)
  local sR, sI = self:getParts()
  local vR, vI = cV:getParts()
  return (sR*vR + sI*vI)
end

function metaComplex:getAngRadVec(cV)
  return (cV:getAngRad() - self:getAngRad())
end

function metaComplex:getMid(R, I)
  return self:getNew():Mid(R, I)
end

function metaComplex:Mean(tV)
  local sT = type(tV); if(not isType(sT, 5)) then
    return logStatus("complex.Mean: Mismatch "..sT, self) end
  local nE = #tV; if(nE <= 1) then return self end
  self:Set(tV[1]); for iD = 2, nE do self:Add(tV[iD]) end
  self:Rsz(1/nE) return self
end

function metaComplex:getMean(tV)
  return self:getNew():Mean(tV)
end

function metaComplex:getDist2(R, I)
  local C, D = self:getParts()
  local R, I = getUnpackStack(R, I)
  return ((C - R)^2 + (D - I)^2)
end

function metaComplex:getDist(R, I)
  return math.sqrt(self:getDist2(R, I))
end

function metaComplex:getCross(R, I)
  local C, D = self:getParts()
  local R, I = getUnpackStack(R, I)
  return (C*I - D*R)
end

function metaComplex:Sign(bE, bC, bN)
  if(bE) then return self:Apply(getSign) end
  if(bC) then local R, I = self:getParts()
    return ((R ~= 0) and getSign(R) or getSign(I)) end
  if(bN) then return self:Apply(getSignNon) end
  return self:Unit()
end

function metaComplex:getSign(bE, bC, bN)
  return self:getNew():Sign(bE, bC, bN)
end

function metaComplex:Swap()
  local R, I = self:getParts()
  return self:setReal(I):setImag(R)
end

function metaComplex:getSwap()
  return self:getNew():Swap()
end

function metaComplex:Right()
  return self:Swap():NegIm()
end

function metaComplex:getRight()
  return self:getNew():Right()
end

function metaComplex:Left()
  return self:Swap():NegRe()
end

function metaComplex:getLeft()
  return self:getNew():Left()
end

function metaComplex:getSet(R, I)
  return self:getNew():Set(R, I)
end

function metaComplex:getAdd(R, I)
  return self:getNew():Add(R, I)
end

function metaComplex:getSub(R, I)
  return self:getNew():Sub(R, I)
end

function metaComplex:getRsz(R, I)
  return self:getNew():Rsz(R, I)
end

function metaComplex:getMul(R, I, E)
  return self:getNew():Mul(R, I, E)
end

function metaComplex:getDiv(R, I, E)
  return self:getNew():Div(R, I, E)
end

function metaComplex:getMod(R, I)
  return self:getNew():Mod(R, I)
end

function metaComplex:getRev(R, I)
  return self:getNew():Rev(R, I)
end

function metaComplex:getPow(R, I, E)
  return self:getNew():Pow(R, I, E)
end

function metaComplex:Exp(cP)
  local E = self:getNew(math.exp(1))
  return self:Set(E:Pow(cP or self))
end

function metaComplex:getExp(cP)
  return self:getNew():Exp(cP)
end

function metaComplex:AddPythagor(R, I)
  local cP = self:getNew(R, I)
  return self:Pow(2):Add(cP:Pow(2)):Pow(0.5)
end

function metaComplex:getAddPythagor(cP)
  return self:getNew():AddPythagor(cP)
end

function metaComplex:Margin(nE)
  local nR, nI = self:getParts()
  local nM = (tonumber(nE) or metaData.__margn)
  if(math.abs(nR) < nM) then nR = 0 end
  if(math.abs(nI) < nM) then nI = 0 end
  return self:Set(nR, nI)
end

function metaComplex:getMargin(nE)
  return self:getNew():Margin(nE)
end

function metaComplex:Bisect(cD)
  return self:RotRad(self:getAngRadVec(cD) / 2)
end

function metaComplex:getBisect(cD)
  return self:getNew():Bisect(cD)
end

function metaComplex:Sin()
  local R, I = self:getParts()
  local rE = math.sin(R)*math.cosh(I)
  local iM = math.cos(R)*math.sinh(I)
  return self:setReal(rE):setImag(iM)
end

function metaComplex:getSin()
  return self:getNew():Sin()
end

function metaComplex:ArcSin()
  local Z = self:getNew():Pow(2):Neg():Add(1):Pow(0.5)
  return self:Mul(0, 1):Add(Z):Log():Mul(0, -1)
end

function metaComplex:getArcSin()
  return self:getNew():ArcSin()
end

function metaComplex:Cos()
  local R, I = self:getParts()
  local rE =  math.cos(R)*math.cosh(I)
  local iM = -math.sin(R)*math.sinh(I)
  return self:setReal(rE):setImag(iM)
end

function metaComplex:getCos()
  return self:getNew():Cos()
end

function metaComplex:ArcCos()
  local Z = self:getNew():Pow(2):Neg():Add(1):Pow(0.5)
  return self:Add(Z:Mul(0, 1)):Log():Mul(0, -1)
end

function metaComplex:getArcCos()
  return self:getNew():ArcCos()
end

function metaComplex:Tang()
  return self:Set(self:getSin():Div(self:getCos()))
end

function metaComplex:getTang()
  return self:getNew():Tang()
end

function metaComplex:ArcTang()
  local D = self:getAdd(0, 1)
  local N = self:getNeg():Add(0, 1)
  return self:Set(N:Div(D):Log():Mul(0, -0.5))
end

function metaComplex:getArcTang()
  return self:getNew():ArcTang()
end

function metaComplex:Cotg()
  return self:Tang():Rev()
end

function metaComplex:getCotg()
  return self:getNew():Cotg()
end

function metaComplex:ArcCotg()
  return self:Rev():ArcTang()
end

function metaComplex:getArcCotg()
  return self:getNew():ArcCotg()
end

function metaComplex:SinH()
  local E = self:getExp()
  return self:Set(E):Sub(E:Rev()):Rsz(0.5)
end

function metaComplex:getSinH()
  return self:getNew():SinH()
end

function metaComplex:ArcSinH()
  local Z = self:getNew():Pow(2):Add(1):Pow(0.5)
  return self:Add(Z):Log()
end

function metaComplex:getArcSinH()
  return self:getNew():ArcSinH()
end

function metaComplex:CosH()
  local E = self:getExp()
  return self:Set(E):Add(E:Rev()):Rsz(0.5)
end

function metaComplex:getCosH()
  return self:getNew():CosH()
end

function metaComplex:ArcCosH()
  local P = self:getNew():Add(1):Pow(0.5)
  local N = self:getNew():Sub(1):Pow(0.5)
  return self:Add(P:Mul(N)):Log()
end

function metaComplex:getArcCosH()
  return self:getNew():ArcCosH()
end

function metaComplex:TangH()
  return self:Set(self:getSinH():Div(self:getCosH()))
end

function metaComplex:getTangH()
  return self:getNew():TangH()
end

function metaComplex:ArcTangH()
  local P = self:getNew():Add(1):Log()
  local N = self:getNew():Neg():Add(1):Log()
  return self:Set(P:Sub(N)):Mul(0.5)
end

function metaComplex:getArcTangH()
  return self:getNew():ArcTangH()
end

function metaComplex:CotgH()
  return self:Set(self:getCosH():Div(self:getSinH()))
end

function metaComplex:getCotgH()
  return self:getNew():CotgH()
end

function metaComplex:ArcCotgH()
  local P = self:getNew():Rev():Add(1):Log()
  local N = self:getNew():Rev():Neg():Add(1):Log()
  return self:Set(P:Sub(N)):Mul(0.5)
end

function metaComplex:getArcCotgH()
  return self:getNew():ArcCotgH()
end

function metaComplex:Log(nK)
  local P, R, T = metaData.__getpi, self:getPolar()
  return self:setReal(math.log(R)):setImag(T+2*(tonumber(nK) or 0)*P)
end

function metaComplex:getLog(nK)
  return self:getNew():Log(nK)
end

function metaComplex:getApply(fF, bR, bI)
  return self:getNew():Apply(fF, bR, bI)
end

function metaComplex:Abs(bR, bI)
  return self:Apply(math.abs, bR, bI)
end

function metaComplex:getAbs(bR, bI)
  return self:getNew():Abs(bR, bI)
end

function metaComplex:Floor(bR, bI)
  return self:Apply(math.floor, bR, bI)
end

function metaComplex:getFloor(bR, bI)
  return self:getNew():Floor(bR, bI)
end

function metaComplex:Ceil(bR, bI)
  return self:Apply(math.ceil, bR, bI)
end

function metaComplex:getCeil(bR, bI)
  return self:getNew():Ceil(bR, bI)
end

function metaComplex:getAngRad()
  local R, I = self:getParts(); return math.atan2(I, R) end

function metaComplex:getTable(kR, kI)
  local kR, kI = (kR or metaData.__kreal[1]), (kI or metaData.__kimag[1])
  local R , I  = self:getParts(); return {[kR] = R, [kI] = I}
end

function metaComplex:Print(sS,sE)
  return logString(tostring(sS or "")..tostring(self)..tostring(sE or ""), self)
end

function metaComplex:Round(nF)
  local R, I = self:getParts()
  return self:setReal(getRound(R, nF)):setImag(getRound(I, nF))
end

function metaComplex:getRound(nP)
  return self:getNew():Round(nP)
end

function metaComplex:getPolar()
  return self:getNorm(), self:getAngRad()
end

function metaComplex:setAngRad(nA)
  local nR, nP = self:getNorm(), (tonumber(nA) or 0)
  return self:setReal(math.cos(nP)):setImag(math.sin(nP)):Rsz(nR)
end

function metaComplex:RotRad(nA)
  return self:setAngRad(self:getAngRad() + (tonumber(nA) or 0))
end

function metaComplex:getRotRad(nA)
  return self:getNew():RotRad(nA)
end

function metaComplex:setPolarRad(nN, nA)
  return self:Set((tonumber(nN) or 0), 0):setAngRad(nA)
end

function metaComplex:ProjectRay(cO, cD)
  local cV = self:getNew():Sub(cO)
  local nK = cV:getCross(cD) / cD:getNorm2()
  return self:Add(cD:getMul(nK, -nK, true):Swap())
end

function metaComplex:getProjectRay(cO, cD)
  return self:getNew():ProjectRay(cO, cD)
end

function metaComplex:ProjectLine(cS, cE)
  return self:ProjectRay(cS, cE:getSub(cS))
end

function metaComplex:getProjectLine(cS, cE)
  return self:getNew():ProjectLine(cS, cE)
end

function metaComplex:ProjectCircle(cC, nR)
  return self:Sub(cC):Unit():Mul(nR):Add(cC)
end

function metaComplex:getProjectCircle(cC, nR)
  return self:getNew():ProjectCircle(cC, nR)
end

function metaComplex:getLayRay(cO, cD)
  return self:getSub(cO):getCross(cD)
end

function metaComplex:getLayLine(cS, cE)
  return cS:getSub(self):getCross(cE:getSub(self))
end

function metaComplex:MirrorRay(cO, cD)
  local cP = self:getNew():ProjectRay(cO, cD)
  return self:Add(cP:Sub(self):Rsz(2))
end

function metaComplex:getMirrorRay(cO, cD)
  return self:getNew():MirrorRay(cO, cD)
end

function metaComplex:MirrorLine(cS, cE)
  return self:MirrorRay(cS, cE:getSub(cS))
end

function metaComplex:getMirrorLine(cS, cE)
  return self:getNew():MirrorLine(cS, cE)
end

function metaComplex:getAreaParallelogram(cE)
  return math.abs(self:getCross(cE))
end

function metaComplex:getAreaTriangle(cE)
  return math.abs(self:getCross(cE) / 2)
end

function complex.getAreaShoelace(...)
  local tV, nP, nN = {...}, 0, 0
  if(isType(type(tV[1]), 5)) then tV = tV[1] end
  local nE = #tV; tV[nE+1] = tV[1]
  for ID = 1, nE do
    local cB, cN = tV[ID], tV[ID+1]
    nP = nP + (cB:getReal()*cN:getImag())
    nN = nN + (cB:getImag()*cN:getReal())
  end; return math.abs(0.5 * (nP - nN))
end

function complex.getAreaHeron(...)
  local tV = {...}; if(isType(type(tV[1]), 5)) then tV = tV[1] end
  local nV = #tV; if(nV < 3) then local sV = tostring(nV or "")
    return logStatus("complex.getAreaHeron: Vertexes lacking <"..sV..">", 0) end
  if(nV > 3) then local sV = tostring(nV or "")
    logStatus("complex.getAreaHeron: Vertexes extra <"..sV..">") end
  local nA = tV[1]:getSub(tV[2]):getNorm2()
  local nB = tV[2]:getSub(tV[3]):getNorm2()
  local nC = tV[3]:getSub(tV[1]):getNorm2()
  local nD = (4 * (nA*nB + nA*nC + nB*nC))
  local nE = ((nA + nB + nC)^2)
  return math.abs(0.25 * math.sqrt(nD - nE))
end

function metaComplex:isAmongLine(cS, cE, bF)
  local nM = metaData.__margn
  if(math.abs(self:getLayLine(cS, cE)) < nM) then
    local dV = cE:getSub(cS)
    local dS = self:getSub(cS):getDot(dV)
    local dE = self:getSub(cE):getDot(dV)
    if(not bF and dS * dE > 0) then return false end
    return true
  end; return false
end

function metaComplex:isZeroReal()
  return (math.abs(self:getReal()) < metaData.__margn)
end

function metaComplex:isZeroImag()
  return (math.abs(self:getImag()) < metaData.__margn)
end

function metaComplex:isZero(bR, bI)
  local bR = getPick(isNil(bR), true, bR)
  local bI = getPick(isNil(bI), true, bI)
  local zR, zI = self:isZeroReal(), self:isZeroImag()
  if(bR and bI) then return (zR and zI) end
  if(bR) then return zR end; if(bI) then return zI end
  return logStatus("complex.isZero: Not applicable", nil)
end

function metaComplex:isInfReal(bR)
  local mH, nR = math.huge, self:getReal()
  if(bR) then return (nR == -mH) end
  return (nR == mH)
end

function metaComplex:isInfImag(bI)
  local mH, nI = math.huge, self:getImag()
  if(bI) then return (nI == -mH) end
  return (nI == mH)
end

function metaComplex:isInf(bR, bI)
  return (self:isInfReal(bR) and self:isInfImag(bI))
end

function metaComplex:Inf(bR, bI)
  local nH, sR, sI = math.huge, self:getParts()
  local nR = getPick(isNil(bR), sR, getPick(bR, -nH, nH))
  local nI = getPick(isNil(bI), sI, getPick(bI, -nH, nH))
  return self:setReal(nR):setImag(nI)
end

function metaComplex:getInf(bR, bI)
  return self:getNew():Inf(bR, bI)
end

function metaComplex:isNanReal()
  local nR = self:getReal(); return (nR ~= nR)
end

function metaComplex:isNanImag()
  local nI = self:getImag(); return (nI ~= nI)
end

function metaComplex:isNan()
  return (self:isNanReal() and self:isNanImag())
end

function metaComplex:Nan(bR, bI)
  local nN, sR, sI = (0/0), self:getParts()
  local nR = getPick(isNil(bR), sR, getPick(bR, nN, sR))
  local nI = getPick(isNil(bI), sI, getPick(bI, nN, sI))
  return self:setReal(nR):setImag(nI)
end

function metaComplex:getNan(bR, bI)
  return self:getNew():Nan(bR, bI)
end

function metaComplex:isAmongRay(cO, cD, bF)
  local nM = metaData.__margn
  if(math.abs(self:getLayRay(cO, cD)) < nM) then
    local dO = self:getSub(cO):getDot(cD)
    local dE = cO:getAdd(cD):Sub(self):Neg():getDot(cD)
    if(dO < 0 and dE < 0) then return false end
    if(not bF and dO > 0 and dE > 0) then return false end
    return true
  end; return false
end

function metaComplex:isOrthogonal(vC)
  return (math.abs(self:getDot(vC)) < metaData.__margn)
end

function metaComplex:isCollinear(vC)
  return (math.abs(self:getCross(vC)) < metaData.__margn)
end

function metaComplex:isInCircle(cO, vR)
  local nM = metaData.__margn
  local nR = getClamp(tonumber(vR) or 0, 0)
  local nN = self:getSub(cO):getNorm()
  return (nN <= (nR+nM))
end

function metaComplex:isAmongCircle(cO, vR)
  local nM = metaData.__margn
  local nN = self:getSub(cO):getNorm()
  local nR = getClamp(tonumber(vR) or 0, 0)
  return ((nN <= (nR+nM)) and (nN >= (nR-nM)))
end

function metaComplex:getRoots(nNm)
  local nN = math.floor(tonumber(nNm) or 0)
  if(nN > 0) then local tRt = {}
    local nPw, nA  = (1 / nN), ((2*metaData.__getpi) / nN)
    local nRa = self:getNorm()   ^ nPw
    local nAn = self:getAngRad() * nPw
    for k = 1, nN do
      local cRe, cIm = (nRa * math.cos(nAn)), (nRa * math.sin(nAn))
      tRt[k], nAn = self:getNew(cRe,cIm), (nAn + nA)
    end; return tRt
  end; return logStatus("complex.getRoots: Invalid <"..nN..">")
end

function metaComplex:getFormat(...)
  local tArg = {...}
  local sMod = tostring(tArg[1] or ""):lower()
  if(isType(sMod, 5)) then
    local tvB = metaData.__bords
    local tkR, tkI = metaData.__kreal, metaData.__kimag
    local sN, R, I = tostring(tArg[3] or "%f"), self:getParts()
    local iS = math.floor((tvB[1]..tvB[2]):len()/2)
          iB = getClamp(tonumber(tArg[4] or 1), 1, iS)
    local eS = math.floor((#tkR + #tkI)/2)
          iD = getClamp((tonumber(tArg[2]) or 1), 1, eS)
    local sF, sB = tvB[1]:sub(iB,iB), tvB[2]:sub(iB,iB)
    local kR, kI = (tArg[5] or tkR[iD]), (tArg[6] or tkI[iD])
    if(not (kR and kI)) then return tostring(self) end
    local qR, qI = isString(kR), isString(kI)
          kR = qR and ("\""..kR.."\"") or tostring(kR)
          kI = qI and ("\""..kI.."\"") or tostring(kI)
    return (sF.."["..kR.."]="..sN:format(R)..
               ",["..kI.."]="..sN:format(I)..sB)
  elseif(isType(sMod, 3)) then
    local S, R, I = metaData.__ssyms, self:getParts()
    local mI, bS = (getSign(I) * I), tArg[3]
    local iD = getClamp(tonumber(tArg[2]) or 1, 1, #S)
    local kI = tostring(tArg[4] or S[iD])
    local sI = ((getSign(I) < 0) and "-" or "+")
    if(bS) then return (R..sI..kI..mI)
    else return (R..sI..mI..kI) end
  end; return tostring(self)
end

metaComplex.__len = function(cNum) return cNum:getNorm() end

metaComplex.__call = function(cNum, sMth, ...)
  return pcall(cNum[tostring(sMth)], cNum, ...)
end

metaComplex.__tostring = function(cNum)
  local R = tostring(cNum:getReal() or metaData.__valns)
  local I = tostring(cNum:getImag() or metaData.__valns)
  return "{"..R..","..I.."}"
end

metaComplex.__unm = function(cNum)
  return complex.getNew(cNum):Neg()
end

metaComplex.__add = function(C1,C2)
  return complex.getNew(C1):Add(C2)
end

metaComplex.__sub = function(C1,C2)
  return complex.getNew(C1):Sub(C2)
end

metaComplex.__mul = function(C1,C2)
  return complex.getNew(C1):Mul(C2)
end

metaComplex.__div = function(C1,C2)
  return complex.getNew(C1):Div(C2)
end

metaComplex.__mod =  function(C1,C2)
  return complex.getNew(C1):Mod(C2)
end

metaComplex.__pow =  function(C1,C2)
  return complex.getNew(C1):Pow(C2)
end

metaComplex.__concat = function(A,B)
  return tostring(A)..tostring(B)
end

metaComplex.__eq =  function(C1,C2)
  local R1, I1 = getUnpackStack(C1)
  local R2, I2 = getUnpackStack(C2)
  if(R1 == R2 and I1 == I2) then return true end
  return false
end

metaComplex.__le =  function(C1,C2)
  local R1, I1 = getUnpackStack(C1)
  local R2, I2 = getUnpackStack(C2)
  if(I1 == 0 and I2 == 0) then return (R1 <= R2) end
  if(R1 <= R2 and I1 <= I2) then return true end
  return false
end

metaComplex.__lt =  function(C1,C2)
  local R1, I1 = getUnpackStack(C1)
  local R2, I2 = getUnpackStack(C2)
  if(I1 == 0 and I2 == 0) then return (R1 < R2) end
  if(R1 < R2 and I1 < I2) then return true end
  return false
end

function complex.getIntersectRayRay(cO1, cD1, cO2, cD2)
  local dD = cD1:getCross(cD2); if(dD == 0) then
    return logStatus("complex.getIntersectRayRay: Rays parallel", nil) end
  local dO = cO2:getNew():Sub(cO1)
  local nT, nU = (dO:getCross(cD2) / dD), (dO:getCross(cD1) / dD)
  return dO:Set(cO1):Add(cD1:getRsz(nT)), nT, nU
end

function complex.getIntersectRayLine(cO, cD, cS, cE)
  return complex.getIntersectRayRay(cO, cD, cS, cE:getSub(cS))
end

function complex.getIntersectRayCircle(cO, cD, cC, nR)
  local nA = cD:getNorm2(); if(nA <= metaData.__margn) then
    return logStatus("complex.getIntersectRayCircle: Norm less than margin", nil) end
  local cR = cO:getNew():Sub(cC)
  local nB, nC = 2 * cD:getDot(cR), (cR:getNorm2() - nR^2)
  local nD = (nB^2 - 4*nA*nC); if(nD < 0) then
    return logStatus("complex.getIntersectRayCircle: Imaginary roots", nil) end
  local dA = (1/(2*nA)); nD, nB = dA*math.sqrt(nD), -nB*dA
  local xM = cD:getNew():Mul(nB - nD):Add(cO)
  local xP = cD:getNew():Mul(nB + nD):Add(cO)
  if(cO:isInCircle(cC, nR)) then return xP, xM end
  return xM, xP -- Outside the circle
end

function complex.getIntersectCircleCircle(cO1, nR1, cO2, nR2)
  local cS, cA = cO2:getSub(cO1), cO2:getAdd(cO1)
  local nD, nRA, nRS = cS:getNorm2(), (nR1 + nR2), (nR1 - nR2); if(nRA^2 < nD) then
    return logStatus("complex.getIntersectCircleCircle: Intersection missing", nil) end
  local dR = (nRA^2 - nD) * (nD - nRS^2); if(dR < 0) then
    return logStatus("complex.getIntersectCircleCircle: Irrational area", nil) end
  local nK = 0.25 * math.sqrt(dR)
  local cV = cS:getSwap():Mul(2, -2, true):Rsz(nK / nD)
  local mR = (0.5 * (nR1^2 - nR2^2)) / nD
  local xB = cA:Rsz(0.5):Add(cS:Rsz(mR))
  return xB:getAdd(cV), xB:getSub(cV), xB
end

function complex.getReflectRayRay(cO1, cD1, cO2, cD2)
  local uD = cD1:getUnit() -- Get unit ray direction
  local cN = cO1:getProjectRay(cO2, cD2):Neg():Add(cO1):Unit()
  local cR = uD:Sub(cN:getNew():Mul(2 * uD:getDot(cN))):Unit()
  if(cR:getDot(cN) < 0) then -- Ray points away from the reflection wall
    return logStatus("complex.getReflectRayRay: Normal mismatch", nil, cN) end
  return cR, cN
end

function complex.getReflectRayLine(cO, cD, cS, cE)
  return complex.getReflectRayRay(cO, cD, cS, cE:getSub(cS))
end

function complex.getReflectRayCircle(cO, cD, cC, nR, xU)
  local xX = (xU and xU or complex.getIntersectRayCircle(cO, cD, cC, nR))
  if(not complex.isValid(xX)) then
    return logStatus("complex.getReflectRayCircle: Intersect mismatch", nil) end
  local cX = xX:getSub(cC):Right()
  local cR, cN = complex.getReflectRayRay(cO, cD, xX, cX)
  return cR, cN, cX:Set(xX)
end

function complex.getRefractRayAngle(vI, vO, bV)
  local nI, nO, nA = (tonumber(vI) or 0), (tonumber(vO) or 0)
  if(bV) then nA = (nI / nO) else nA = (nO / nI) end
  if(math.abs(nA) > 1) then nA = (1 / nA) end
  return math.asin(nA)
end

function complex.getRefractRayRay(cO1, cD1, cO2, cD2, vI, vO, bV)
  local nI, nO = (tonumber(vI) or 0), (tonumber(vO) or 0)
  local cN = cO1:getProjectRay(cO2, cD2):Neg():Add(cO1):Unit()
  local sI, sO, sB = cN:getCross(cD1:getUnit():Neg())
  if(bV) then sO, sB = ((sI * nO) / nI), (nI / nO)
  else sO, sB = ((sI * nI) / nO), (nO / nI) end; if(math.abs(sO) > 1) then
    return logStatus("complex.getRefractRayRay: Normal mismatch", nil, cN) end
  return cN:getNeg():RotRad(math.asin(sO)), cN
end

function complex.getRefractRayLine(cO, cD, cS, cE, nI, nO)
  return complex.getRefractRayRay(cO, cD, cS, cE:getSub(cS), nI, nO)
end

function complex.getRefractRayCircle(cO, cD, cC, nR, vI, vO, bV, xU)
  local xX = (xU and xU or complex.getIntersectRayCircle(cO, cD, cC, nR))
  if(not complex.isValid(xX)) then
    return logStatus("complex.getRefractRayCircle: Intersect mismatch", nil) end
  local cX = xX:getSub(cC):Right()
  local cR, cN = complex.getRefractRayRay(cO, cD, xX, cX, vI, vO, bV)
  return cR, cN, cX:Set(xX)
end

function complex.getEuler(vRm, vPh)
  local nRm, nPh = (tonumber(vRm) or 0), (tonumber(vPh) or 0)
  return self:getNew(math.cos(nPh),math.sin(nPh)):Rsz(nRm)
end

function complex.toDegree(nRad)
  if(math.deg) then return math.deg(nRad) end
  return (tonumber(nRad) or 0) * metaData.__radeg
end

function complex.toRadian(nDeg)
  if(math.rad) then return math.rad(nDeg) end
  return (tonumber(nDeg) or 0) / metaData.__radeg
end

function metaComplex:getAngDeg() return complex.toDegree(self:getAngRad()) end

function metaComplex:setAngDeg(nA)
  return self:setAngRad(complex.toRadian(tonumber(nA) or 0))
end

function metaComplex:RotDeg(nA)
  return self:RotRad(complex.toRadian(tonumber(nA) or 0))
end

function metaComplex:getRotDeg(nA)
  return self:getNew():RotDeg(nA)
end

function metaComplex:setPolarDeg(nN, nA)
  return self:Set((tonumber(nN) or 0), 0):setAngDeg(nA)
end

function metaComplex:getAngDegVec(cV)
  return complex.toDegree(self:getAngRadVec(cV))
end

function metaComplex:getMatrix()
  local R, I = self:getParts(); return {{R, -I}, {I, R}}
end

function complex.setAction(aK, fD)
  if(not aK) then return logStatus("complex.setAction: Miss-key", false) end
  if(isType(type(fD), 4)) then metaData.__cactf[aK] = fD; return true end
  return logStatus("complex.setAction: Non-function", false)
end

local function stringValidComplex(sStr)
  local Str = sStr:gsub("%s","") -- Remove hollows
  local S, E, B = 1, Str:len(), metaData.__bords
  while(S < E) do
    local CS, CE = Str:sub(S,S), Str:sub(E,E)
    local FS, FE = B[1]:find(CS,1,true), B[2]:find(CE,1,true)
    if((not FS) and FE) then
      return logStatus("stringValidComplex: Unbalanced end #"..CS..CE.."#",nil) end
    if((not FE) and FS) then
      return logStatus("stringValidComplex: Unbalanced beg #"..CS..CE.."#",nil) end
    if(FS and FE and FS > 0 and FE > 0) then
      if(FS == FE) then S = S + 1; E = E - 1
      else return logStatus("stringValidComplex: Bracket mismatch #"..CS..CE.."#",nil) end
    elseif(not (FS and FE)) then break end
  end; return Str, S, E
end

local function stringToComplex(sStr, nS, nE, sDel)
  local Del = tostring(sDel or ","):sub(1,1)
  local S, E, D = nS, nE, sStr:find(Del)
  if((not D) or (D < S) or (D > E)) then
    return complex.getNew(tonumber(sStr:sub(S,E)) or metaData.__valre, metaData.__valim) end
  return complex.getNew(tonumber(sStr:sub(S,D-1)) or metaData.__valre,
                        tonumber(sStr:sub(D+1,E)) or metaData.__valim)
end

local function stringToComplexI(sStr, nS, nE, nI)
  if(nI == 0) then
    return logStatus("stringToComplexI: Complex not in plain format [a+ib] or [a+bi]",nil) end
  local M = (nI - 1); local C = sStr:sub(M,M) -- There will be no delimiter symbols here
  if(nI == nE) then  -- (-0.7-2.9i) Skip symbols until +/- is reached
    while(C ~= "+" and C ~= "-" and M > 0) do M = M - 1; C = sStr:sub(M,M) end
    local vR, vI = sStr:sub(nS,M-1), sStr:sub(M,nE-1) -- Automatically change real part
              vI = (tonumber(vI) and vI or (vI.."1")) -- Process cases for (+i,-i,i)
    return complex.getNew(tonumber(vR) or metaData.__valre,
                          tonumber(vI) or metaData.__valim)
  else -- (-0.7-i2.9)
    local vR, vI = sStr:sub(nS,M-1), (C..sStr:sub(nI+1,nE))
    return complex.getNew(tonumber(vR) or metaData.__valre,
                          tonumber(vI) or metaData.__valim)
  end
end

local function tableToComplex(tTab, kRe, kIm)
  if(not tTab) then
    return logStatus("tableToComplex: Table missing", nil) end
  local R = getValueKeys(tTab, metaData.__kreal, kRe)
  local I = getValueKeys(tTab, metaData.__kimag, kIm)
  if(R or I) then
    return complex.getNew(tonumber(R) or metaData.__valre,
                          tonumber(I) or metaData.__valim) end
  return logStatus("tableToComplex: Table format not supported", complex.getNew())
end

function complex.getRandom(nL, nU, vC)
  local R = randomGetNumber(nL, nU, vC)
  local I = randomGetNumber(nL, nU, vC)
  return complex.getNew(R, I)
end

function complex.convNew(vIn, ...)
  if(complex.isValid(vIn)) then return vIn:getNew() end
  local tyIn, tArg = type(vIn), {...}
  if(isType(tyIn, 2)) then return complex.getNew(vIn and 1 or 0,tArg[1] and 1 or 0)
  elseif(isType(tyIn, 5)) then return tableToComplex(vIn, tArg[1], tArg[2])
  elseif(isType(tyIn, 1)) then return complex.getNew(vIn,tArg[1])
  elseif(isType(tyIn, 6)) then return complex.getNew(0,0)
  elseif(isType(tyIn, 4)) then local bS, vR, vI = pcall(vIn, ...)
    if(not bS) then return logStatus("complex.convNew: Function: "..vR,nil) end
    return complex.convNew(vR, vI) -- Translator function generating converter format
  elseif(isType(tyIn, 3)) then -- Remove brackets and leave the values
    local Str, S, E = stringValidComplex(vIn:gsub("*","")); if(not Str) then
      return logStatus("complex.convNew: Failed to validate <"..tostring(vIn)..">",nil) end
    Str = Str:sub(S, E); E = E-S+1; S = 1 -- Refresh string indexes
    local Sim, I = metaData.__ssyms    -- Prepare to find imaginary unit
    for ID = 1, #Sim do local val = Sim[ID]
      I = Str:find(val, S, true) or I; if(I) then break end end
    if(I and (I > 0)) then return stringToComplexI(Str, S, E, I)
    else return stringToComplex(Str, S, E, tArg[1]) end
  end
  return logStatus("complex.convNew: Type <"..tyIn.."> not supported",nil)
end

local function getUnpackSplit(...)
  local tA, tC, nC, iC = {...}, {}, 0, 1
  if(complex.isValid(tA[1])) then
    while(complex.isValid(tA[1])) do tC[iC] = tA[1]
      table.remove(tA, 1); iC = iC + 1
    end; nC = (iC-1)
  else
    if(isType(type(tA[1]), 5)) then
      tC = tA[1]; nC = #tA[1]; table.remove(tA, 1); end
  end; return tC, nC, unpack(tA)
end

local function getBezierCurveVertexRec(nS, tV)
  local tD, tP, nD = {}, {}, (#tV-1)
  for ID = 1, nD do tD[ID] = tV[ID+1]:getNew():Sub(tV[ID]) end
  for ID = 1, nD do tP[ID] = tV[ID]:getAdd(tD[ID]:getRsz(nS)) end
  if(nD > 1) then return getBezierCurveVertexRec(nS, tP) end
  return tP[1], tD[1]
end

function complex.getBezierCurve(...)
  local tV, nV, nT = getUnpackSplit(...)
  nT = math.floor(tonumber(nT) or metaData.__curve); if(nT < 2) then
    return logStatus(complex.getBezierCurve..": Curve samples not enough",nil) end
  if(not (tV[1] and tV[2])) then
    return logStatus("complex.getBezierCurve: Two vertexes are needed",nil) end
  if(not complex.isValid(tV[1])) then
    return logStatus("complex.getBezierCurve: First vertex invalid <"..type(tV[1])..">",nil) end
  if(not complex.isValid(tV[2])) then
    return logStatus("complex.getBezierCurve: Second vertex invalid <"..type(tV[2])..">",nil) end
  local ID, cT, dT, tS = 1, 0, (1/nT), {}
  tS[ID] = {tV[ID]:getNew(), tV[ID+1]:getSub(tV[ID]), 0}
  cT, ID = (cT + dT), (ID + 1); while(cT < 1) do
    local vP, vD = getBezierCurveVertexRec(cT, tV)
    tS[ID] = {vP, vD, cT}; cT, ID = (cT + dT), (ID + 1)
  end; tS[ID] = {tV[nV]:getNew(), tV[nV]:getSub(tV[nV-1]), 1}; return tS
end

local function catmullromTangent(nT, cS, cE, nA)
  return ((cE:getNew():Sub(cS):getNorm()^(tonumber(nA) or 0.5))+nT)
end

local function catmullromSegment(cP0, cP1, cP2, cP3, nN, nA)
  local nT0, tC = 0, {} -- Start point is always zero
  local nT1 = catmullromTangent(nT0, cP0, cP1, nA)
  local nT2 = catmullromTangent(nT1, cP1, cP2, nA)
  local nT3 = catmullromTangent(nT2, cP2, cP3, nA)
  local tTN = common.tableArrGetLinearSpace(nT1, nT2, nN)
  for iD = 1, #tTN do
    local tA1 = cP0:getNew():Mul((nT1-tTN[iD])/(nT1-nT0)):Add(cP1:getMul((tTN[iD]-nT0)/(nT1-nT0)))
    local tA2 = cP1:getNew():Mul((nT2-tTN[iD])/(nT2-nT1)):Add(cP2:getMul((tTN[iD]-nT1)/(nT2-nT1)))
    local tA3 = cP2:getNew():Mul((nT3-tTN[iD])/(nT3-nT2)):Add(cP3:getMul((tTN[iD]-nT2)/(nT3-nT2)))
    local tB1 = tA1:getNew():Mul((nT2-tTN[iD])/(nT2-nT0)):Add(tA2:getMul((tTN[iD]-nT0)/(nT2-nT0)))
    local tB2 = tA2:getNew():Mul((nT3-tTN[iD])/(nT3-nT1)):Add(tA3:getMul((tTN[iD]-nT1)/(nT3-nT1)))
       tC[iD] = tB1:Mul((nT2-tTN[iD])/(nT2-nT1)):Add(tB2:Mul((tTN[iD]-nT1)/(nT2-nT1)))
  end; return tC
end

function complex.getCatmullRomCurve(...)
  local tV, nV, nT, nA = getUnpackSplit(...)
  nT = math.floor(tonumber(nT) or metaData.__curve); if(nT < 2) then
    return logStatus("complex.getCatmullRomCurve: Curve samples not enough",nil) end
  if(not (tV[1] and tV[2])) then
    return logStatus("complex.getCatmullRomCurve: Two vertexes are needed",nil) end
  if(not complex.isValid(tV[1])) then
    return logStatus("complex.getCatmullRomCurve: First vertex invalid <"..type(tV[1])..">",nil) end
  if(not complex.isValid(tV[2])) then
    return logStatus("complex.getCatmullRomCurve: Second vertex invalid <"..type(tV[2])..">",nil) end
  local vM = metaData.__margn
  local cS, tC = tV[1]:getNew():Unit():Mul(vM):Add(tV[1]), {}
  local cE, iC = tV[nV]:getNew():Unit():Mul(vM):Add(tV[nV]), 1
  table.insert(tV, 1, cS); table.insert(tV, cE); nV = #tV;
  for iD = 1, (nV-3) do tC[iC] = tV[iD+1]:getNew(); iC = (iC + 1)
    local tS = catmullromSegment(tV[iD], tV[iD+1], tV[iD+2], tV[iD+3], nT, nA)
    for iK = 1, #tS do tC[iC] = tS[iK]; iC = (iC + 1) end
  end; tC[iC] = tV[nV-1]:getNew()
  table.remove(tV, 1); table.remove(tV); return tC
end

function complex.getRegularPolygon(cS, nN, nR, nI)
  local eN = (tonumber(nN) or 0); if(eN <= 0) then
    return logStatus("complex.getRegularPolygon: Vertexes #"..tostring(nN),nil) end
  local vD = cS:getNew(1, 0); if(nR) then vD:Set(nR, nI) end
  local tV, nD = {cS:getNew()}, ((2*metaData.__getpi) / eN)
  for iD = 2, eN do tV[iD] = tV[iD-1]:getAdd(vD); vD:RotRad(nD) end; return tV
end

function metaComplex:AltitudeCenter(...)
  local tO, tI, tV, nV = {}, {}, getUnpackSplit(...)
  for iD = 1, nV do local cP, cN = (tV[iD+1] or tV[1]), (tV[iD-1] or tV[nV])
    tO[iD] = tV[iD]:getProjectLine(cP, cN) end
  for iD = 1, nV do local nN = (tV[iD+1] and (iD+1) or 1)
    local dC, dN = tO[iD]:getSub(tV[iD]), tO[nN]:getSub(tV[nN])
    tI[iD] = complex.getIntersectRayRay(tV[iD], dC, tV[nN], dN) end
  return self:Mean(tI)
end

function metaComplex:getAltitudeCenter(...)
  return self:getNew():AltitudeCenter(...)
end

function metaComplex:MedianCenter(...)
  local tO, tI, tV, nV = {}, {}, getUnpackSplit(...)
  for iD = 1, nV do tO[iD] = (tV[iD+1] or tV[1]):getMid(tV[iD-1] or tV[nV]) end
  for iD = 1, nV do local nN = (tV[iD+1] and (iD+1) or 1)
    local dC, dN = tO[iD]:getSub(tV[iD]), tO[nN]:getSub(tV[nN])
    tI[iD] = complex.getIntersectRayRay(tV[iD], dC, tV[nN], dN) end
  return self:Mean(tI)
end

function metaComplex:getMedianCenter(...)
  return self:getNew():MedianCenter(...)
end

function metaComplex:InnerCircleCenter(...)
  local tO, tI, tV, nV = {}, {}, getUnpackSplit(...)
  local dC, dN = self:getNew(), self:getNew()
  for iD = 1, nV do
    dC:Set(tV[iD-1] or tV[nV]):Sub(tV[iD])
    dN:Set(tV[iD+1] or tV[ 1]):Sub(tV[iD])
    tO[iD] = dC:getBisect(dN)
  end
  for iD = 1, nV do local nN = (tV[iD+1] and (iD+1) or 1)
    tI[iD] = complex.getIntersectRayRay(tV[iD], tO[iD], tV[nN], tO[nN]) end
  return self:Mean(tI)
end

function metaComplex:getInnerCircleCenter(...)
  self:getNew():InnerCircleCenter(...)
end

function metaComplex:OuterCircleCenter(...)
  local tO, tI, tV, nV = {}, {}, getUnpackSplit(...)
  for iD = 1, nV do tO[iD] = tV[iD]:getMid(tV[iD+1] or tV[1]) end
  for iD = 1, nV do local nN = (tV[iD+1] and (iD+1) or 1)
    local dC, dN = tO[iD]:getSub(tV[iD]):Right(), tO[nN]:getSub(tV[nN]):Right()
    tI[iD] = complex.getIntersectRayRay(tO[iD], dC, tO[nN], dN)
  end; return self:Mean(tI)
end

function metaComplex:getOuterCircleCenter(...)
  return self:getNew():OuterCircleCenter(...)
end

function metaComplex:MidcircleCenter(...)
  return self -- TO DO
end

function metaComplex:getMidcircleCenter(...)
  return self:getNew():MidcircleCenter(...)
end

return complex
