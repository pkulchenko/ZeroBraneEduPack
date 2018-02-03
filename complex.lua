local common       = require("common")
local type         = type
local math         = math
local pcall        = pcall
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local complex      = {}
local metaComplex  = {}
local logStatus    = common.logStatus
local getSign      = common.getSign
local getSignNon   = common.getSignNon
local roundValue   = common.getRound
local getClamp     = common.getClamp
local getValueKeys = common.getValueKeys

metaComplex.__type  = "Complex"
metaComplex.__margn = 1e-10
metaComplex.__index = metaComplex
metaComplex.__bords = {"{([<|/","})]>|/"}
metaComplex.__valre = 0
metaComplex.__valim = 0
metaComplex.__valns = "X"
metaComplex.__ssyms = {"i", "I", "j", "J"}
metaComplex.__kreal = {1,"Real","real","Re","re","R","r","X","x"}
metaComplex.__kimag = {2,"Imag","imag","Im","im","I","i","Y","y"}
metaComplex.__getpi = math.pi
metaComplex.__radeg = (180 / metaComplex.__getpi)
metaComplex.__cactf = {}

local function exportComplex(R, I)
  if(not I and getmetatable(R) == metaComplex) then return R:getParts() end
  return (tonumber(R) or metaComplex.__valre), (tonumber(I) or metaComplex.__valim)
end

function complex.isValid(cNum)
  return (getmetatable(cNum) == metaComplex)
end

function complex.setMargin(nM)
  metaComplex.__margn = math.abs((tonumber(nM) or 0))
end

function complex.getMargin()
  return metaComplex.__margn
end

function complex.getNew(nRe, nIm)
  self = {}; setmetatable(self,metaComplex)
  local Re = tonumber(nRe) or metaComplex.__valre
  local Im = tonumber(nIm) or metaComplex.__valim

  if(getmetatable(nRe) == metaComplex) then
    Re, Im = nRe:getReal(), nRe:getImag() end

  function self:setReal(R)  Re = (tonumber(R) or metaComplex.__valre); return self end
  function self:setImag(I)  Im = (tonumber(I) or metaComplex.__valim); return self end
  function self:getReal()   return Re end
  function self:getImag()   return Im end
  function self:getParts()  return Re, Im end

  function self:Set(R,I)
    local R, I = exportComplex(R, I)
    Re, Im = R, I; return self
  end

  function self:Add(R,I)
    local R, I = exportComplex(R, I)
    Re, Im = (Re + R), (Im + I); return self
  end

  function self:Sub(R,I)
    local R, I = exportComplex(R, I)
    Re, Im = (Re - R), (Im - I); return self
  end

  function self:Rsz(vN)
    local nN = tonumber(vN)
    if(nN) then Re, Im = (Re * nN), (Im * nN) end; return self
  end

  function self:Abs(R, I)
    Re = (R and math.abs(Re) or Re)
    Im = (I and math.abs(Im) or Im); return self
  end

  function self:Mul(R,I)
    local A, B = self:getParts()
    local C, D = exportComplex(R, I)
    Re = (A*C - B*D)
    Im = (A*D + B*C); return self
  end

  function self:Mid(R,I)
    local A, B = self:getParts()
    local C, D = exportComplex(R, I)
    Re = ((A + C) / 2)
    Im = ((B + D) / 2); return self
  end

  function self:Div(R,I)
    local A, B = self:getParts()
    local C, D = exportComplex(R, I)
    local Z = (C*C + D*D)
    Re = ((A*C + B*D) / Z)
    Im = ((B*C - A*D) / Z)
    return self
  end

  function self:Mod(R,I)
    local A, B = self:getParts()
    local C, D = exportComplex(R, I); self:Div(C,D)
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

  function self:Pow(R,I)
    local A, B = self:getParts()
    local C, D = exportComplex(R, I)
    local N, G = self:getNorm2(), self:getAngRad()
    local eK = N^(C/2) * math.exp(-D*G)
    local eC = (C*G + 0.5*D*math.log(N))
    Re = eK * math.cos(eC)
    Im = eK * math.sin(eC); return self
  end

  return self
end

function metaComplex:Act(aK,...)
  if(not aK) then return self end
  local fDr = metaComplex.__cactf[aK]
  if(not fDr) then return self end
  return pcall(fDr,self,...)
end

function metaComplex:getNew(nR, nI)
  local N = complex.getNew(self); if(nR or nI) then
    local R, I = exportComplex(nR, nI); N:Set(R, I)
  end; return N
end

function metaComplex:Unit()
  return self:Rsz(1/self:getNorm())
end

function metaComplex:getUnit()
  return self:getNew():Unit()
end

function metaComplex:getAbs(R, I)
  return self:getNew():Abs(R, I)
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
  local R, I = exportComplex(R, I)
  return ((C - R)^2 + (D - I)^2)
end

function metaComplex:getDist(R, I)
  return math.sqrt(self:getDist2(R, I))
end

function metaComplex:getDet(R, I)
  local C, D = self:getParts()
  local R, I = exportComplex(R, I)
  return (C*I - D*R)
end

function metaComplex:getCross(R, I)
  return self:getDet(R, I)
end

function metaComplex:Right()
  local R, I = self:getParts()
  return self:setReal(I):setImag(-R)
end

function metaComplex:getRight()
  return self:getNew():Right()
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

function metaComplex:getMul(R, I)
  return self:getNew():Mul(R, I)
end

function metaComplex:getDiv(R, I)
  return self:getNew():Div(R, I)
end

function metaComplex:getMod(R, I)
  return self:getNew():Mod(R, I)
end

function metaComplex:getRev(R, I)
  return self:getNew():Rev(R, I)
end

function metaComplex:getPow(R, I)
  return self:getNew():Pow(R, I)
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

function metaComplex:Floor()
  local R, I = self:getParts()
        R, I = math.floor(R), math.floor(I)
  return self:setReal(R):setImag(I)
end

function metaComplex:getFloor()
  return self:getNew():Floor()
end

function metaComplex:Ceil()
  local R, I = self:getParts()
        R, I = math.ceil(R), math.ceil(I)
  return self:setReal(R):setImag(I)
end

function metaComplex:getCeil()
  return self:getNew():Ceil()
end

function metaComplex:NegRe() return self:setReal(-self:getReal()) end
function metaComplex:NegIm() return self:setImag(-self:getImag()) end
function metaComplex:Conj() return self:NegIm() end
function metaComplex:Neg() return self:NegRe():NegIm() end

function metaComplex:getNorm2()
  local R, I = self:getParts(); return(R*R + I*I) end

function metaComplex:getNorm() return math.sqrt(self:getNorm2()) end

function metaComplex:getAngRad()
  local R, I = self:getParts(); return math.atan2(I, R) end

function metaComplex:getTable(kR, kI)
  local kR, kI = (kR or metaComplex.__kreal[1]), (kI or metaComplex.__kimag[1])
  local R , I  = self:getParts(); return {[kR] = R, [kI] = I}
end

function metaComplex:getNeg  () return self:getNew():Neg() end
function metaComplex:getNegRe() return self:getNew():NegRe() end
function metaComplex:getNegIm() return self:getNew():NegIm() end
function metaComplex:getConj () return self:getNegIm() end

function metaComplex:Print(sS,sE)
  io.write(tostring(sS or "").."{"..tostring(self:getReal())..
    ","..tostring(self:getImag()).."}"..tostring(sE or "")); return self
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

function metaComplex:Project(cS, cE)
  local x1, y1 = cS:getParts()
  local x2, y2 = cE:getParts()
  local x3, y3 = self:getParts()
  local dx, dy = (x2-x1), (y2-y1)
  local ks = (dy*(x3-x1)-dx*(y3-y1)) / cS:getDist2(cE)
  return self:setReal(x3-ks*dy):setImag(y3+ks*dx)
end

function metaComplex:getProject(cS, cE)
  return self:getNew():Project(cS, cE)
end

function metaComplex:getLay(cS, cE)
  return cS:getSub(self):getCross(cE:getSub(self))
end

function metaComplex:isAmong(cS, cE)
  local nM = metaComplex.__margn
  if(math.abs(self:getLay(cS, cE)) < nM) then
    local dV = cE:getSub(cS)
    local dS = self:getSub(cS):getDot(dV)
    local dE = self:getSub(cE):getDot(dV)
    if(dS * dE > 0) then return false end; return true
  end; return false
end

function metaComplex:getRoots(nNm)
  local nN = math.floor(tonumber(nNm) or 0)
  if(nN > 0) then local tRt = {}
    local nPw, dA  = (1 / nN), ((2*metaComplex.__getpi) / nN)
    local nRa = self:getNorm()   ^ nPw
    local nAn = self:getAngRad() * nPw
    for k = 1, nN do
      local cRe, cIm = (nRa * math.cos(nAn)), (nRa * math.sin(nAn))
      tRt[k], nAn = self:getNew(cRe,cIm), (nAn + dA)
    end; return tRt
  end; return logStatus("getRoots: Invalid <"..nN..">")
end

function metaComplex:getFormat(...)
  local tArg = {...}
  local sMod = tostring(tArg[1] or "")
  if(sMod == "table") then
    local sN, R, I = tostring(tArg[3] or "%f"), self:getParts()
    local iS = math.floor((metaComplex.__bords[1]..metaComplex.__bords[2]):len()/2)
          iB = getClamp(tonumber(tArg[4] or 1), 1, iS)
    local eS = math.floor((#metaComplex.__kreal + #metaComplex.__kimag)/2)
          iD = getClamp((tonumber(tArg[2]) or 1), 1, eS)
    local sF = metaComplex.__bords[1]:sub(iB,iB)
    local sB = metaComplex.__bords[2]:sub(iB,iB)
    local kR = tostring(tArg[5] or metaComplex.__kreal[iD])
    local kI = tostring(tArg[6] or metaComplex.__kimag[iD])
    if(not (kR and kI)) then return tostring(self) end
    local qR = (getmetatable("R") == getmetatable(kR))
    local qI = (getmetatable("I") == getmetatable(kI))
          kR = qR and ("\""..kR.."\"") or kR
          kI = qI and ("\""..kI.."\"") or kI
    return (sF.."["..kR.."]="..sN:format(R)..
               ",["..kI.."]="..sN:format(I)..sB)
  elseif(sMod == "string") then
    local R, I = self:getParts()
    local mI, bS = (getSign(I) * I), tArg[3]
    local iD, eS = (tonumber(tArg[2]) or 1), #metaComplex.__ssyms
          iD = (iD > eS) and eS or iD
    local kI = tostring(tArg[4] or metaComplex.__ssyms[iD])
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
  local R = tostring(cNum:getReal() or metaComplex.__valns)
  local I = tostring(cNum:getImag() or metaComplex.__valns)
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
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getParts()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getParts()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 == R2 and I1 == I2) then return true end
  return false
end

metaComplex.__le =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getParts()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getParts()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 <= R2 and I1 <= I2) then return true end
  return false
end

metaComplex.__lt =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getParts()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getParts()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 < R2 and I1 < I2) then return true end
  return false
end

function complex.getIntersectRayRay(cO1, cD1, cO2, cD2)
  local dD = cD1:getDet(cD2); if(dD == 0) then
    return false end; local dO = cO2:getNew():Sub(cO1)
  local nT, nU = (dO:getDet(cD2) / dD), (dO:getDet(cD1) / dD)
  return true, nT, nU, dO:Set(cO1):Add(cD1:getRsz(nT))
end

function complex.getIntersectRayCircle(cO, cD, cC, nR)
  local nA = cD:getNorm2()
  if(nA <= metaComplex.__margn) then return false end
  local cR = cO:getNew():Sub(cC)
  local nB, nC = 2*cD:getDot(cR), (cR:getNorm2() - nR^2)
  local nD = nB^2-4*nA*nC
  if(nD < 0) then return false end
  local dA = (1/(2*nA))
  local nD = dA*math.sqrt(nD); nB = -nB*dA
  local pP = cD:getNew():Mul(nB + nD):Add(cO)
  local pM = cD:getNew():Mul(nB - nD):Add(cO)
  return true, pP, pM
end

function complex.getReflectRayLine(cO, cD, cS, cE)
  local uD, uO = cD:getUnit(), cO:getNew():Sub(cD)
  local cN = uO:getProject(cS, cE):Neg():Add(uO):Unit()
  local cR = uD:getNew():Sub(cN:getNew():Mul(2 * uD:getDot(cN))):Unit()
  return cN, cR
end

function complex.getReflectRayCircle(cO, cD, cC, nR)
  local bS, pP, pM = complex.getIntersectRayCircle(cO, cD, cC, nR)
  if(not bS) then return false end
  pP:Set(pM):Sub(cC):Right():Add(pM)
  return true, complex.getReflectRayLine(cO, cD, pP, pM)
end

function complex.getEuler(vRm, vPh)
  local nRm, nPh = (tonumber(vRm) or 0), (tonumber(vPh) or 0)
  return self:getNew(math.cos(nPh),math.sin(nPh)):Rsz(nRm)
end

function complex.toDegree(nRad)
  if(math.deg) then return math.deg(nRad) end
  return (tonumber(nRad) or 0) * metaComplex.__radeg
end

function complex.toRadian(nDeg)
  if(math.rad) then return math.rad(nDeg) end
  return (tonumber(nDeg) or 0) / metaComplex.__radeg
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
    metaComplex.__cactf[aK] = fD; return true end
  return logStatus("complex.setAction: Non-function", false)
end

local function stringValidComplex(sStr)
  local Str = sStr:gsub("%s","") -- Remove hollows
  local S, E, B = 1, Str:len(), metaComplex.__bords
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
    return complex.getNew(tonumber(sStr:sub(S,E)) or metaComplex.__valre, metaComplex.__valim) end
  return complex.getNew(tonumber(sStr:sub(S,D-1)) or metaComplex.__valre,
                     tonumber(sStr:sub(D+1,E)) or metaComplex.__valim)
end

local function stringToComplexI(sStr, nS, nE, nI)
  if(nI == 0) then
    return logStatus("stringToComplexI: Complex not in plain format [a+ib] or [a+bi]",nil) end
  local M = (nI - 1); local C = sStr:sub(M,M) -- There will be no delimiter symbols here
  if(nI == nE) then  -- (-0.7-2.9i) Skip symbols until +/- is reached
    while(C ~= "+" and C ~= "-" and M > 0) do
      M = M - 1; C = sStr:sub(M,M) end
    return complex.getNew(tonumber(sStr:sub(nS,M-1)) or metaComplex.__valre,
                       tonumber(sStr:sub(M,nE-1)) or metaComplex.__valim)
  else -- (-0.7-i2.9)
    return complex.getNew(tonumber(sStr:sub(nS,M-1))     or metaComplex.__valre,
                       tonumber(C..sStr:sub(nI+1,nE)) or metaComplex.__valim)
  end
end

local function tableToComplex(tTab, kRe, kIm)
  if(not tTab) then return nil end
  local R = getValueKeys(tTab, metaComplex.__kreal, kRe)
  local I = getValueKeys(tTab, metaComplex.__kimag, kIm)
  if(R or I) then
    return complex.getNew(tonumber(R) or metaComplex.__valre,
                          tonumber(I) or metaComplex.__valim) end
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
  elseif(tyIn == "string") then
    local Str, S, E = stringValidComplex(vIn:gsub("*",""))
    if(not (Str and S and E)) then
      return logStatus("complex.convNew: Failed to validate <"..tostring(vIn)..">",nil) end
    Str = Str:sub(S ,E); E = E-S+1; S = 1; local Sim, I = metaComplex.__ssyms
    for ID = 1, #Sim do local val = Sim[ID]
      I = Str:find(val,S) or I; if(I) then break end end
    if(I and (I > 0)) then return stringToComplexI(Str, S, E, I)
    else return stringToComplex(Str, S, E, tArg[1]) end
  end
  return logStatus("complex.convNew: Type <"..tyIn.."> not supported",nil)
end

return complex
