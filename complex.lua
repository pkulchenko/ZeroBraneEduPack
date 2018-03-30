-- Copyright (C) 2017-2018 Deyan Dobromirov
-- A complex functionalities library

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
local logStatus    = common.logStatus
local logString    = common.logString
local getSign      = common.getSign
local getSignNon   = common.getSignNon
local roundValue   = common.getRound
local getClamp     = common.getClamp
local getValueKeys = common.getValueKeys
local isString     = common.isString
local isNumber     = common.isNumber
local isTable      = common.isTable
local isNil        = common.isNil
local getPick      = common.getPick

if not debug.getinfo(3) then
  print("This is a module to load with `local complex = require('complex')`.")
  os.exit(1)
end

metaComplex.__type  = "complex.complex"
metaComplex.__index = metaComplex

metaData.__valre = 0
metaData.__valre = 0
metaData.__cactf = {}
metaData.__valns = "X"
metaData.__margn = 1e-10
metaData.__curve = 100
metaData.__kurve = {"n","N","cnt","Cnt"}
metaData.__getpi = math.pi
metaData.__bords = {"{([<|/","})]>|/"}
metaData.__ssyms = {"i", "I", "j", "J"}
metaData.__radeg = (180 / metaData.__getpi)
metaData.__kreal = {1,"Real","real","Re","re","R","r","X","x"}
metaData.__kimag = {2,"Imag","imag","Im","im","I","i","Y","y"}

function complex.isValid(cNum)
  return (getmetatable(cNum) == metaComplex)
end

function complex.setMargin(nM)
  metaData.__margn = math.abs((tonumber(nM) or 0))
end

function complex.getMargin()
  return metaData.__margn
end

function complex.getUnpack(R, I, E)
  if(complex.isValid(R)) then local nR, nI = R:getParts() return nR, nI, I end
  return (tonumber(R) or metaData.__valre), (tonumber(I) or metaData.__valre), E
end

function complex.getNew(nRe, nIm)
  self = {}; setmetatable(self, metaComplex)
  local Re = tonumber(nRe) or metaData.__valre
  local Im = tonumber(nIm) or metaData.__valre

  if(complex.isValid(nRe)) then Re, Im = nRe:getReal(), nRe:getImag() end

  function self:setReal(R)  Re = (tonumber(R) or metaData.__valre); return self end
  function self:setImag(I)  Im = (tonumber(I) or metaData.__valre); return self end
  function self:getReal()   return Re end
  function self:getImag()   return Im end
  function self:getParts()  return Re, Im end

  function self:Set(R, I)
    local R, I = complex.getUnpack(R, I)
    Re, Im = R, I; return self
  end

  function self:Add(R, I)
    local R, I = complex.getUnpack(R, I)
    Re, Im = (Re + R), (Im + I); return self
  end

  function self:Sub(R, I)
    local R, I = complex.getUnpack(R, I)
    Re, Im = (Re - R), (Im - I); return self
  end

  function self:Rsz(vN)
    local nN = tonumber(vN)
    if(nN) then Re, Im = (Re * nN), (Im * nN) end; return self
  end

  function self:Mul(R, I, E)
    local A, B = self:getParts()
    local C, D, U = complex.getUnpack(R, I, E)
    if(U) then Re, Im = (A*C), (B*D) else
      Re, Im = (A*C - B*D), (A*D + B*C)
    end; return self
  end

  function self:Mid(R, I)
    local A, B = self:getParts()
    local C, D = complex.getUnpack(R, I)
    Re = ((A + C) / 2)
    Im = ((B + D) / 2); return self
  end

  function self:Div(R, I, E)
    local A, B = self:getParts()
    local C, D, U = complex.getUnpack(R, I, E)
    if(U) then Re, Im = (A/C), (B/D) else
      local Z = (C*C + D*D)
      Re = ((A*C + B*D) / Z)
      Im = ((B*C - A*D) / Z)
    end; return self
  end

  function self:Mod(R, I)
    local A, B = self:getParts()
    local C, D = complex.getUnpack(R, I); self:Div(C,D)
    local rei, ref = math.modf(Re)
    local imi, imf = math.modf(Im)
    self:Set(ref,imf)
    self:Mul(C,D); return self
  end

  function self:Rev()
    local N = self:getNorm2()
    local R, I = self:getParts()
    Re, Im = (R/N), (-I/N); return self
  end

  function self:Pow(R, I, E)
    local A, B = self:getParts()
    local C, D, U = complex.getUnpack(R, I, E)
    if(U) then Re, Im = (A^C), (B^D) else
      local N, G = self:getNorm2(), self:getAngRad()
      local eK = N^(C/2) * math.exp(-D*G)
      local eC = (C*G + 0.5*D*math.log(N))
      Re = eK * math.cos(eC)
      Im = eK * math.sin(eC)
    end; return self
  end

  return self
end

function metaComplex:Action(aK,...)
  if(not aK) then return self end
  local fDr = metaData.__cactf[aK]
  if(not fDr) then return self end
  return pcall(fDr,self,...)
end

function metaComplex:getNew(nR, nI)
  local N = complex.getNew(self); if(nR or nI) then
    local R, I = complex.getUnpack(nR, nI); N:Set(R, I)
  end; return N
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
  return (self:getAngRad() - cV:getAngRad())
end

function metaComplex:getMid(R, I)
  return self:getNew():Mid(R, I)
end

function metaComplex:getDist2(R, I)
  local C, D = self:getParts()
  local R, I = complex.getUnpack(R, I)
  return ((C - R)^2 + (D - I)^2)
end

function metaComplex:getDist(R, I)
  return math.sqrt(self:getDist2(R, I))
end

function metaComplex:getCross(R, I)
  local C, D = self:getParts()
  local R, I = complex.getUnpack(R, I)
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

function metaComplex:Sin()
  local R, I = self:getParts()
  local rE = math.sin(R)*math.cosh(I)
  local iM = math.cos(R)*math.sinh(I)
  return self:setReal(rE):setImag(iM)
end

function metaComplex:getSin()
  return self:getNew():Sin()
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

function metaComplex:Tang()
  return self:Set(self:getSin():Div(self:getCos()))
end

function metaComplex:getTang()
  return self:getNew():Tang()
end

function metaComplex:Cotg()
  return self:Set(self:getCos():Div(self:getSin()))
end

function metaComplex:getCotg()
  return self:getNew():Cotg()
end

function metaComplex:SinH()
  local E = math.exp(1)^self
  return self:Set(E):Sub(E:Rev()):Rsz(0.5)
end

function metaComplex:getSinH()
  return self:getNew():SinH()
end

function metaComplex:CosH()
  local E = math.exp(1)^self
  return self:Set(E):Add(E:Rev()):Rsz(0.5)
end

function metaComplex:getCosH()
  return self:getNew():CosH()
end

function metaComplex:TangH()
  return self:Set(self:getSinH():Div(self:getCosH()))
end

function metaComplex:getTangH()
  return self:getNew():TangH()
end

function metaComplex:CotgH()
  return self:Set(self:getCosH():Div(self:getSinH()))
end

function metaComplex:getCotgH()
  return self:getNew():CotgH()
end

function metaComplex:Log()
  local R, T = self:getPolar()
  return self:setReal(math.log(R)):setImag(T)
end

function metaComplex:getLog()
  return self:getNew():Log()
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

function metaComplex:getNorm2()
  local R, I = self:getParts(); return(R*R + I*I) end

function metaComplex:getNorm() return math.sqrt(self:getNorm2()) end

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
  return self:setReal(roundValue(R, nF)):setImag(roundValue(I, nF))
end

function metaComplex:getRound(nP)
  return self:getNew():Round(nP)
end

function metaComplex:getPolar()
  return self:getNorm(), self:getAngRad()
end

function metaComplex:RotRad(nA)
  local nR, nP = self:getPolar(); nP = (nP + (tonumber(nA) or 0))
  return self:setReal(math.cos(nP)):setImag(math.sin(nP)):Rsz(nR)
end

function metaComplex:getRotRad(nA)
  return self:getNew():RotRad(nA)
end

function metaComplex:setAngRad(nA)
  local nR, nP = self:getNorm(), (tonumber(nA) or 0)
  return self:setReal(math.cos(nP)):setImag(math.sin(nP)):Rsz(nR)
end

function metaComplex:ProjectRay(cO, cD)
  local cV = self:getNew():Sub(cO)
  local nK = cV:getCross(cD) / cD:getNorm2()
  return self:Add(cD:Mul(nK, -nK, true):Swap())
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

function metaComplex:getLayMargin(cS, cE)
  return cS:getSub(self):getCross(cE:getSub(self))
end

function metaComplex:isAmongLine(cS, cE, bF)
  local nM = metaData.__margn
  if(math.abs(self:getLayMargin(cS, cE)) < nM) then
    local dV = cE:getSub(cS)
    local dS = self:getSub(cS):getDot(dV)
    local dE = self:getSub(cE):getDot(dV)
    if(not bF and dS * dE > 0) then return false end
    return true
  end; return false
end

function metaComplex:isAmongRay(cO, cD, bF)
  local nM = metaData.__margn
  local cE = cO:getNew():Add(cD)
  if(math.abs(self:getLayMargin(cO, cE)) < nM) then
    local dO = self:getSub(cO):getDot(cD)
    local dE = self:getSub(cE):getDot(cD)
    if(dO < 0 and dE < 0) then return false end
    if(not bF and dO > 0 and dE > 0) then return false end
    return true
  end; return false
end

function metaComplex:getRoots(nNm)
  local nN = math.floor(tonumber(nNm) or 0)
  if(nN > 0) then local tRt = {}
    local nPw, dA  = (1 / nN), ((2*metaData.__getpi) / nN)
    local nRa = self:getNorm()   ^ nPw
    local nAn = self:getAngRad() * nPw
    for k = 1, nN do
      local cRe, cIm = (nRa * math.cos(nAn)), (nRa * math.sin(nAn))
      tRt[k], nAn = self:getNew(cRe,cIm), (nAn + dA)
    end; return tRt
  end; return logStatus("complex.getRoots: Invalid <"..nN..">")
end

function metaComplex:getFormat(...)
  local tArg = {...}
  local sMod = tostring(tArg[1] or "")
  if(sMod == "table") then
    local tvB = metaData.__bords
    local tkR, tkI = metaData.__kreal, metaData.__kimag
    local sN, R, I = tostring(tArg[3] or "%f"), self:getParts()
    local iS = math.floor((tvB[1]..tvB[2]):len()/2)
          iB = getClamp(tonumber(tArg[4] or 1), 1, iS)
    local eS = math.floor((#tkR + #tkI)/2)
          iD = getClamp((tonumber(tArg[2]) or 1), 1, eS)
    local sF, sB = tvB[1]:sub(iB,iB), tvB[2]:sub(iB,iB)
    local kR = tostring(tArg[5] or tkR[iD])
    local kI = tostring(tArg[6] or tkI[iD])
    if(not (kR and kI)) then return tostring(self) end
    local qR, qI = isString(kR), isString(kI)
          kR = qR and ("\""..kR.."\"") or kR
          kI = qI and ("\""..kI.."\"") or kI
    return (sF.."["..kR.."]="..sN:format(R)..
               ",["..kI.."]="..sN:format(I)..sB)
  elseif(sMod == "string") then
    local R, I = self:getParts()
    local mI, bS = (getSign(I) * I), tArg[3]
    local iD, eS = (tonumber(tArg[2]) or 1), #metaData.__ssyms
          iD = (iD > eS) and eS or iD
    local kI = tostring(tArg[4] or metaData.__ssyms[iD])
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
  local R1, I1 = complex.getUnpack(C1)
  local R2, I2 = complex.getUnpack(C2)
  if(R1 == R2 and I1 == I2) then return true end
  return false
end

metaComplex.__le =  function(C1,C2)
  local R1, I1 = complex.getUnpack(C1)
  local R2, I2 = complex.getUnpack(C2)
  if(I1 == 0 and I2 == 0) then return (R1 <= R2) end
  if(R1 <= R2 and I1 <= I2) then return true end
  return false
end

metaComplex.__lt =  function(C1,C2)
  local R1, I1 = complex.getUnpack(C1)
  local R2, I2 = complex.getUnpack(C2)
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

function complex.getIntersectRayCircle(cO, cD, cC, nR)
  local nA = cD:getNorm2(); if(nA <= metaData.__margn) then
    return logStatus("complex.getIntersectRayCircle: Norm less than margin", nil) end
  local cR = cO:getNew():Sub(cC)
  local nB, nC = 2*cD:getDot(cR), (cR:getNorm2() - nR^2)
  local nD = nB^2-4*nA*nC; if(nD < 0) then
    return logStatus("complex.getIntersectRayCircle: Irrational roots", nil) end
  local dA = (1/(2*nA)); nD, nB = dA*math.sqrt(nD), -nB*dA
  local xF = cD:getNew():Mul(nB + nD):Add(cO)
  local xN = cD:getNew():Mul(nB - nD):Add(cO)
  return xN, xF
end

function complex.getReflectRayLine(cO, cD, cS, cE)
  local uD, uO = cD:getUnit(), cO:getNew():Sub(cD)
  local cN = uO:getProjectLine(cS, cE):Neg():Add(uO):Unit()
  local cR = uD:getNew():Sub(cN:getNew():Mul(2 * uD:getDot(cN))):Unit()
  return cR, cN
end

function complex.getReflectRayCircle(cO, cD, cC, nR, xF)
  local xN = (xF and xF or complex.getIntersectRayCircle(cO, cD, cC, nR))
  if(not complex.isValid(xN)) then return logStatus("complex.getReflectRayCircle: "..
    "Intersection invalid {"..type(xN).."}["..tostring(xN).."]", nil) end
  local cE = xN:getNew():Sub(cC):Right():Add(xN)
  return complex.getReflectRayLine(cO, cD, xN, cE)
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
  local xB = cA:getRsz(0.5):Add(cS:getRsz(mR))
  return xB:getAdd(cV), xB:getSub(cV), xB
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

function metaComplex:RotDeg(nA)
  return self:RotRad(complex.toRadian(tonumber(nA) or 0))
end

function metaComplex:getRotDeg(nA)
  return self:getNew():RotDeg(nA)
end

function metaComplex:setAngDeg(nA)
  return self:setAngRad(complex.toRadian(tonumber(nA) or 0))
end

function metaComplex:getAngDegVec(cV)
  return complex.toDegree(self:getAngRadVec(cV))
end

function complex.setAction(aK, fD)
  if(not aK) then return logStatus("complex.setAction: Miss-key", false) end
  if(type(fD) == "function") then
    metaData.__cactf[aK] = fD; return true end
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
    return complex.getNew(tonumber(sStr:sub(S,E)) or metaData.__valre, metaData.__valre) end
  return complex.getNew(tonumber(sStr:sub(S,D-1)) or metaData.__valre,
                     tonumber(sStr:sub(D+1,E)) or metaData.__valre)
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
                          tonumber(vI) or metaData.__valre)
  else -- (-0.7-i2.9)
    local vR, vI = sStr:sub(nS,M-1), (C..sStr:sub(nI+1,nE))
    return complex.getNew(tonumber(vR) or metaData.__valre,
                          tonumber(vI) or metaData.__valre)
  end
end

local function tableToComplex(tTab, kRe, kIm)
  if(not tTab) then
    return logStatus("tableToComplex: Table missing", nil) end
  local R = getValueKeys(tTab, metaData.__kreal, kRe)
  local I = getValueKeys(tTab, metaData.__kimag, kIm)
  if(R or I) then
    return complex.getNew(tonumber(R) or metaData.__valre,
                          tonumber(I) or metaData.__valre) end
  return logStatus("tableToComplex: Table format not supported", complex.getNew())
end

function complex.convNew(vIn, ...)
  if(getmetatable(vIn) == metaComplex) then return vIn:getNew() end
  local tyIn, tArg = type(vIn), {...}
  if(tyIn =="boolean") then
    return complex.getNew(vIn and 1 or 0,tArg[1] and 1 or 0)
  elseif(tyIn ==  "table") then return tableToComplex(vIn, tArg[1], tArg[2])
  elseif(tyIn == "number") then return complex.getNew(vIn,tArg[1])
  elseif(tyIn ==    "nil") then return complex.getNew(0,0)
  elseif(tyIn == "string") then -- Remove brackets and leave the values
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

local function getBezierCurveVertexRec(nS, tV)
  local tD, tP, nD = {}, {}, (#tV-1)
  for ID = 1, nD do tD[ID] = tV[ID+1]:getNew():Sub(tV[ID]) end
  for ID = 1, nD do tP[ID] = tV[ID]:getAdd(tD[ID]:getRsz(nS)) end
  if(nD > 1) then return getBezierCurveVertexRec(nS, tP) end
  return tP[1], tD[1]
end

function complex.getBezierCurve(...)
  local tV = {...}; local nV, nT = #tV, 0
  local tK, nC = metaData.__kurve, metaData.__curve
  if(complex.isValid(tV[1])) then local nN = tonumber(tV[nV])
    nT = getPick(nN, nN, nC); if(nN) then tV[nV] = nil end; nV = #tV
  else local kN = getValueKeys(tV[1], tK)
    nT = getPick(tonumber(kN), tonumber(kN), nC)
    if(tonumber(tV[2])) then nT = tonumber(tV[2]) end; tV = tV[1]; nV = #tV
  end; nT = math.floor(nT); if(nT < 2) then
    return logStatus("complex.getBezierCurve: Curve samples not enough ",nil) end
  if(not (tV[1] and tV[2])) then
    return logStatus("complex.getBezierCurve: Two vertexes are needed ",nil) end
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

return complex
