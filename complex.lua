local type         = type
local math         = math
local pcall        = pcall
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local complex       = {}
local metaComplex   = {}

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

metaComplex.__type  = "Complex"
metaComplex.__index = metaComplex
metaComplex.__bords = {"{([<|/","})]>|/"}
metaComplex.__valre = 0
metaComplex.__valim = 0
metaComplex.__valns = "X"
metaComplex.__ssyms = {"i", "I", "j", "J"}
metaComplex.__kreal = {1,"Real","real","Re","re","R","r","X","x"}
metaComplex.__kimag = {2,"Imag","imag","Im","im","I","i","Y","y"}

local function signValue(anyVal)
  local nVal = (tonumber(anyVal) or 0)
  return ((nVal > 0 and 1) or (nVal < 0 and -1) or 0)
end

local function roundValue(nE, nF)
  local e = (tonumber(nE) or 0)
  local f = signValue(e) * (tonumber(nF) or 0)
  if(f == 0) then return f end
  local q, d = math.modf(e/f)
  return (f * (q + (d > 0.5 and 1 or 0)))
end

local function clampValue(nA, nS, nE)
  local a = (tonumber(nA) or 0)
  local s, e = (tonumber(nS) or 0), (tonumber(nE) or 0)
  if(a < s) then return s end
  if(a > e) then return e end; return a
end

local function exportComplex(R, I)
  if(not I and getmetatable(R) == metaComplex) then return R:getParts() end
  return (tonumber(R) or metaComplex.__valre), (tonumber(I) or metaComplex.__valim)
end

local function selectKeyValue(tTab, tKeys, aKey)
  if(aKey) then return tTab[aKey] end
  local out; for ID = 1, #tKeys do
    local key = tKeys[ID]; out = (tTab[key] or out)
    if(out) then return out end
  end; return nil
end

function complex.IsValid(cNum)
  return (getmetatable(cNum) == metaComplex)
end

function complex.New(nRe,nIm)
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

  function self:Rsz(vNum)
    local nNum = tonumber(vNum)
    if(nNum) then Re, Im = (Re * nNum), (Im * nNum) end; return self
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

function metaComplex:getAbs(R, I)
  return complex.New(self):Abs(R, I)
end

function metaComplex:getDot(cV)
  local sR, sI = self:getParts()
  local vR, vI = cV:getParts()
  return (sR*vR + sI*vI)
end

function metaComplex:getAngVec(cV)
  return (self:getAngRad() - cV:getAngRad())
end

function metaComplex:getMid(R, I)
  return complex.New(self):Mid(R, I)
end

function metaComplex:getDist2(R, I)
  local C, D = self:getParts()
  local R, I = exportComplex(R, I)
  return ((R - C)^2 + (I - D)^2)
end

function metaComplex:getDist(R, I)
  return math.sqrt(self:getDist2(R, I))
end

function metaComplex:getDet(R, I)
  local C, D = self:getParts()
  local R, I = exportComplex(R, I)
  return (C*I - D*R)
end

function metaComplex:getSet(R, I)
  return complex.New(self):Set(R, I)
end

function metaComplex:getAdd(R, I)
  return complex.New(self):Add(R, I)
end

function metaComplex:getSub(R, I)
  return complex.New(self):Sub(R, I)
end

function metaComplex:getRsz(R, I)
  return complex.New(self):Rsz(R, I)
end

function metaComplex:getMul(R, I)
  return complex.New(self):Mul(R, I)
end

function metaComplex:getDiv(R, I)
  return complex.New(self):Div(R, I)
end

function metaComplex:getMod(R, I)
  return complex.New(self):Mod(R, I)
end

function metaComplex:getRev(R, I)
  return complex.New(self):Rev(R, I)
end

function metaComplex:getPow(R, I)
  return complex.New(self):Pow(R, I)
end

function metaComplex:Sin()
  local R, I = self:getParts()
  local rE = math.sin(R)*math.cosh(I)
  local iM = math.cos(R)*math.sinh(I)
  return self:setReal(rE):setImag(iM)
end

function metaComplex:getSin()
  return complex.New(self):Sin()
end

function metaComplex:Cos()
  local R, I = self:getParts()
  local rE =  math.cos(R)*math.cosh(I)
  local iM = -math.sin(R)*math.sinh(I)
  return self:setReal(rE):setImag(iM)
end

function metaComplex:getCos()
  return complex.New(self):Cos()
end

function metaComplex:Tang()
  return self:Set(self:getSin():Div(self:getCos()))
end

function metaComplex:getTang()
  return complex.New(self):Tang()
end

function metaComplex:Cotg()
  return self:Set(self:getCos():Div(self:getSin()))
end

function metaComplex:getCotg()
  return complex.New(self):Cotg()
end

function metaComplex:SinH()
  local E = math.exp(1)^self
  return self:Set(E):Sub(E:Rev()):Rsz(0.5)
end

function metaComplex:getSinH()
  return complex.New(self):SinH()
end

function metaComplex:CosH()
  local E = math.exp(1)^self
  return self:Set(E):Add(E:Rev()):Rsz(0.5)
end

function metaComplex:getCosH()
  return complex.New(self):CosH()
end

function metaComplex:TangH()
  return self:Set(self:getSinH():Div(self:getCosH()))
end

function metaComplex:getTangH()
  return complex.New(self):TangH()
end

function metaComplex:CotgH()
  return self:Set(self:getCosH():Div(self:getSinH()))
end

function metaComplex:getCotgH()
  return complex.New(self):CotgH()
end

function metaComplex:Log()
  local R, T = self:getPolar()
  return self:setReal(math.log(R)):setImag(T)
end

function metaComplex:getLog()
  return complex.New(self):Log()
end

function metaComplex:Floor()
  local R, I = self:getParts()
        R, I = math.floor(R), math.floor(I)
  return self:setReal(R):setImag(I)
end

function metaComplex:getFloor()
  return complex.New(self):Floor()
end

function metaComplex:Ceil()
  local R, I = self:getParts()
        R, I = math.ceil(R), math.ceil(I)
  return self:setReal(R):setImag(I)
end

function metaComplex:getCeil()
  return complex.New(self):Ceil()
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

function metaComplex:getAngDeg() return ((self:getAngRad() * 180) / math.pi) end

function metaComplex:getNew(nR, nI)
  local N = complex.New(self:getParts())
  local R, I = tonumber(nR), tonumber(nI)
  if(R) then N:setReal(R) end
  if(I) then N:setImag(I) end; return N
end

function metaComplex:getTable(kR, kI)
  local kR, kI = (kR or metaComplex.__kreal[1]), (kI or metaComplex.__kimag[1])
  local R , I  = self:getParts(); return {[kR] = R, [kI] = I}
end

function metaComplex:getNeg()
  local R, I = self:getParts(); return complex.New(-R,-I) end

function metaComplex:getNegRe()
  local R, I = self:getParts(); return complex.New(-R, I) end

function metaComplex:getNegIm()
  local R, I = self:getParts(); return complex.New(R,-I) end

function metaComplex:getConj()
  local R, I = self:getParts(); return complex.New(R,-I) end

function metaComplex:Print(sS,sE)
  io.write(tostring(sS or "").."{"..tostring(self:getReal())..
    ","..tostring(self:getImag()).."}"..tostring(sE or "")); return self
end

function metaComplex:Round(nF)
  local R, I = self:getParts()
  return self:setReal(roundValue(R, nF)):setImag(roundValue(I, nF))
end

function metaComplex:getRound(nP)
  local R, I = self:getParts()
  return complex.New(R,I):Round(nP)
end

function metaComplex:getPolar()
  return self:getNorm(), self:getAngRad()
end

function metaComplex:getRoots(nNum)
  local N = math.floor(tonumber(nNum) or 0)
  if(N > 0) then local tRt = {}
    local Pw, As  = (1 / N), ((2*math.pi) / N)
    local Rd, CRe = self:getNorm()   ^ Pw
    local Th, CIm = self:getAngRad() * Pw
    for k = 1, N do
      CRe = Rd * math.cos(Th)
      CIm = Rd * math.sin(Th)
      tRt[k] = complex.New(CRe,CIm)
      Th = Th + As
    end; return tRt
  end; return logStatus("getRoots: Invalid <"..N..">")
end

function metaComplex:getFormat(...)
  local tArg = {...}
  local sMod = tostring(tArg[1] or "")
  if(sMod == "table") then
    local sN, R, I = tostring(tArg[3] or "%f"), self:getParts()
    local iS = math.floor((metaComplex.__bords[1]..metaComplex.__bords[2]):len()/2)
          iB = clampValue(tonumber(tArg[4] or 1), 1, iS)
    local eS = math.floor((#metaComplex.__kreal + #metaComplex.__kimag)/2)
          iD = clampValue((tonumber(tArg[2]) or 1), 1, eS)
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
    local mI, bS = (signValue(I) * I), tArg[3]
    local iD, eS = (tonumber(tArg[2]) or 1), #metaComplex.__ssyms
          iD = (iD > eS) and eS or iD
    local kI = tostring(tArg[4] or metaComplex.__ssyms[iD])
    local sI = ((signValue(I) < 0) and "-" or "+")
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
  return complex.New(cNum):Neg()
end

metaComplex.__add = function(C1,C2)
  return complex.New(C1):Add(C2)
end

metaComplex.__sub = function(C1,C2)
  return complex.New(C1):Sub(C2)
end

metaComplex.__mul = function(C1,C2)
  return complex.New(C1):Mul(C2)
end

metaComplex.__div = function(C1,C2)
  return complex.New(C1):Div(C2)
end

metaComplex.__mod =  function(C1,C2)
  return complex.New(C1):Mod(C2)
end

metaComplex.__pow =  function(C1,C2)
  return complex.New(C1):Pow(C2)
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

function complex.Project(cP, cS, cE)
  local x1, y1 = cS:getParts()
  local x2, y2 = cE:getParts()
  local x3, y3 = cP:getParts()
  local dx, dy = (x2-x1), (y2-y1)
  local ks = (dy*(x3-x1)-dx*(y3-y1)) / cS:getDist2(cE)
  return complex.New(x3-ks*dy, y3+ks*dx)
end

function complex.Intersect(cO1, cD1, cO2, cD2)
  local dD = cD1:getDet(cD2); if(dD == 0) then
    return false end; local dO = complex.New(cO2):Sub(cO1)
  local nT, nU = (dO:getDet(cD2) / dD), (dO:getDet(cD1) / dD)
  return true, nT, nU, dO:Set(cO1):Add(cD1:getRsz(nT))
end

function complex.Euler(vRm, vPh)
  local nRm, nPh = (tonumber(vRm) or 0), (tonumber(vPh) or 0)
  return complex.New(math.cos(nPh),math.sin(nPh)):Rsz(nRm)
end

function complex.ToDegree(nRad)
  if(math.deg) then return math.deg(nRad) end
  return ((tonumber(nRad) or 0) * 180) / math.pi
end

function complex.ToRadian(nDeg)
  if(math.rad) then return math.rad(nDeg) end
  return ((tonumber(nDeg) or 0) * math.pi) / 180
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
    elseif(not (FS and FE)) then break end;
  end; return Str, S, E
end

local function stringToComplex(sStr, nS, nE, sDel)
  local Del = tostring(sDel or ","):sub(1,1)
  local S, E, D = nS, nE, sStr:find(Del)
  if((not D) or (D < S) or (D > E)) then
    return complex.New(tonumber(sStr:sub(S,E)) or metaComplex.__valre, metaComplex.__valim) end
  return complex.New(tonumber(sStr:sub(S,D-1)) or metaComplex.__valre,
                     tonumber(sStr:sub(D+1,E)) or metaComplex.__valim)
end

local function stringToComplexI(sStr, nS, nE, nI)
  if(nI == 0) then
    return logStatus("stringToComplexI: Complex not in plain format [a+ib] or [a+bi]",nil) end
  local M = nI - 1 -- There will be no delimiter symbols here
  local C = sStr:sub(M,M)
  if(nI == nE) then  -- (-0.7-2.9i) Skip symbols until +/- is reached
    while(C ~= "+" and C ~= "-" and M > 0) do
      M = M - 1; C = sStr:sub(M,M) end;
    return complex.New(tonumber(sStr:sub(nS,M-1)) or metaComplex.__valre,
                       tonumber(sStr:sub(M,nE-1)) or metaComplex.__valim)
  else -- (-0.7-i2.9)
    return complex.New(tonumber(sStr:sub(nS,M-1))     or metaComplex.__valre,
                       tonumber(C..sStr:sub(nI+1,nE)) or metaComplex.__valim)
  end
end

local function tableToComplex(tTab, kRe, kIm)
  if(not tTab) then return nil end
  local R = selectKeyValue(tTab, metaComplex.__kreal, kRe)
  local I = selectKeyValue(tTab, metaComplex.__kimag, kIm)
  if(R or I) then
    return complex.New(tonumber(R) or metaComplex.__valre,
                       tonumber(I) or metaComplex.__valim) end
  return logStatus("tableToComplex: Table format not supported", complex.New())
end

function complex.Convert(vIn, ...)
  if(getmetatable(vIn) == metaComplex) then return complex.New(vIn) end
  local tIn, tArg = type(vIn), {...}
  if(tIn =="boolean") then
    return complex.New(vIn and 1 or 0,tArg[1] and 1 or 0)
  elseif(tIn ==  "table") then return tableToComplex(vIn, tArg[1], tArg[2])
  elseif(tIn == "number") then return complex.New(vIn,tArg[1])
  elseif(tIn ==    "nil") then return complex.New(0,0)
  elseif(tIn == "string") then
    local Str, S, E = stringValidComplex(vIn:gsub("*",""))
    if(not (Str and S and E)) then
      return logStatus("complex.Convert: Failed to validate <"..tostring(vIn)..">",nil) end
    Str = Str:sub(S ,E); E = E-S+1; S = 1; local Sim, I = metaComplex.__ssyms
    for ID = 1, #Sim do local val = Sim[ID]
      I = Str:find(val,S) or I; if(I) then break end end
    if(I and (I > 0)) then return stringToComplexI(Str, S, E, I)
    else return stringToComplex(Str, S, E, tArg[1]) end
  end
  return logStatus("complex.Convert: Type <"..tIn.."> not supported",nil)
end

return complex
