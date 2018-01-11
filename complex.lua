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

  function self:Mul(R,I)
    local A, C, D = Re, exportComplex(R, I)
    Re = A*C - Im*D
    Im = A*D + Im*C; return self
  end

  function self:Div(R,I)
    local A, C, D = Re, exportComplex(R, I)
    local Z = (C*C + D*D)
    if(Z ~= 0) then Re, Im = ((A*C + Im*D) / Z), ((Im*C -  A*D) / Z) end; return self
  end

  function self:Mod(R,I)
    local A, C, D = Re, exportComplex(R, I); self:Div(C,D)
    local rei, ref = math.modf(Re)
    local imi, imf = math.modf(Im)
    self:Set(ref,imf)
    self:Mul(C,D); return self
  end

  function self:Pow(R,I)
    local C, D = exportComplex(R, I)
    local Ro = self:getNorm()
    local Th = self:getAngRad()
    local nR = (Ro ^ C) * math.exp(-D * Th)
    local nF =  C * Th  + D * math.log(Ro)
    Re = nR * math.cos(nF)
    Im = nR * math.sin(nF); return self
  end

  return self
end

function metaComplex:Floor()
  local Re, Im = self:getParts()
  Re, Im = math.floor(Re), math.floor(Im)
  return self:setReal(Re):setImag(Im)
end

function metaComplex:Ceil()
  local Re, Im = self:getParts()
  Re = math.ceil(Re); Im = math.ceil(Im);
  return self:setReal(Re):setImag(Im)
end

function metaComplex:NegRe() return self:setReal(-self:getReal()) end

function metaComplex:NegIm() return self:setImag(-self:getImag()) end

function metaComplex:Conj() return self:NegIm() end

function metaComplex:Neg() return self:NegRe():NegIm() end

function metaComplex:getNorm2()
  local Re, Im = self:getParts(); return(Re*Re + Im*Im) end

function metaComplex:getNorm() return math.sqrt(self:getNorm2()) end

function metaComplex:getAngRad()
  local Re, Im = self:getParts(); return math.atan2(Im, Re) end

function metaComplex:getAngDeg() return ((self:getAngRad() * 180) / math.pi) end

function metaComplex:getDup() return complex.New(self:getParts()) end

function metaComplex:getTable(kR, kI)
  local kR, kI = (kR or metaComplex.__kreal[1]), (kI or metaComplex.__kimag[1])
  local Re, Im = self:getParts(); return {[kR] = Re, [kI] = Im}
end

function metaComplex:getNeg()
  local Re, Im = self:getParts(); return complex.New(-Re,-Im) end

function metaComplex:getNegRe()
  local Re, Im = self:getParts(); return complex.New(-Re, Im) end

function metaComplex:getNegIm()
  local Re, Im = self:getParts(); return complex.New(Re,-Im) end

function metaComplex:getConj()
  local Re, Im = self:getParts(); return complex.New(Re,-Im) end

function metaComplex:getCeil()
  local Re, Im = self:getParts()
  return complex.New(math.ceil(Re),math.ceil(Im))
end

function metaComplex:getFloor()
  local Re, Im = self:getParts()
  return complex.New(math.floor(Re),math.floor(Im))
end

function metaComplex:Print(sS,sE)
  io.write(tostring(sS or "").."{"..tostring(self:getReal())..
    ","..tostring(self:getImag()).."}"..tostring(sE or "")); return self
end

function metaComplex:Round(nF)
  local Re, Im = self:getParts()
  return self:setReal(roundValue(Re, nF)):setImag(roundValue(Im, nF))
end

function metaComplex:getRound(nP)
  local Re, Im = self:getParts()
  return complex.New(Re,Im):Round(nP)
end

function metaComplex:getPolar()
  return self:getNorm(), self:getAngRad()
end

function metaComplex:getRoots(nNum)
  local N = tonumber(nNum)
  if(N) then
    local N, tRt  = math.floor(N), {}
    local Pw, As  = (1 / N), ((2*math.pi) / N)
    local Rd, CRe = self:getNorm()   ^ Pw
    local Th, CIm = self:getAngRad() * Pw
    for k = 1, N do
      CRe = Rd * math.cos(Th)
      CIm = Rd * math.sin(Th)
      tRt[k] = complex.New(CRe,CIm)
      Th = Th + As
    end; return tRt
  end; return nil
end

function metaComplex:getFormat(...)
  local tArg = {...}
  local sMod = tostring(tArg[1] or "")
  if(sMod == "table") then
    local sN, Re, Im = tostring(tArg[3] or "%f"), self:getParts()
    local iS = math.floor((metaComplex.__bords[1]..metaComplex.__bords[2]):len()/2)
          iB = clampValue(tonumber(tArg[4] or 1), 1, iS)
    local eS = math.floor((#metaComplex.__kreal + #metaComplex.__kimag)/2)
          iD = clampValue((tonumber(tArg[2]) or 1), 1, eS)
    local sF = metaComplex.__bords[1]:sub(iB,iB)
    local sB = metaComplex.__bords[2]:sub(iB,iB)
    local kR = metaComplex.__kreal[iD]
    local kI = metaComplex.__kimag[iD]
    if(not (kR and kI)) then return tostring(self) end
    local qR = (getmetatable("R") == getmetatable(kR))
    local qI = (getmetatable("I") == getmetatable(kI))
          kR = qR and ("\""..kR.."\"") or kR
          kI = qI and ("\""..kI.."\"") or kI
    return (sF.."["..kR.."]="..sN:format(Re)..
               ",["..kI.."]="..sN:format(Im)..sB)
  elseif(sMod == "string") then
    local Re, Im = self:getParts()
    local mI, bS = (signValue(Im) * Im), tArg[3]
    local iD, eS = (tonumber(tArg[2]) or 1), #metaComplex.__ssyms
          iD = (iD > eS) and eS or iD
    local kI = metaComplex.__ssyms[iD]
    local sI = ((signValue(Im) < 0) and "-" or "+")
    if(bS) then return (Re..sI..kI..mI)
    else return (Re..sI..mI..kI) end
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
  if(getmetatable(cNum) == metaComplex) then
    return complex.New(-cNum:getReal(),-cNum:getImag())
  end
end

metaComplex.__add = function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Add(C2)
  return O
end

metaComplex.__sub = function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Sub(C2)
  return O
end

metaComplex.__mul = function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Mul(C2)
  return O
end

metaComplex.__div = function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Div(C2)
  return O
end

metaComplex.__mod =  function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Mod(C2)
  return O
end

metaComplex.__concat = function(A,B)
  return tostring(A)..tostring(B)
end

metaComplex.__pow =  function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Pow(C2)
  return O
end

metaComplex.__eq =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getReal(), C1:getImag()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getReal(), C2:getImag()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 == R2 and I1 == I2) then return true end
  return false
end

metaComplex.__le =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getReal(), C1:getImag()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getReal(), C2:getImag()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 <= R2 and I1 <= I2) then return true end
  return false
end

metaComplex.__lt =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then R1, I1 = C1:getReal(), C1:getImag()
  else R1, I1 = (tonumber(C1) or metaComplex.__valre), metaComplex.__valim end
  if(getmetatable(C2) == metaComplex) then R2, I2 = C2:getReal(), C2:getImag()
  else R2, I2 = (tonumber(C2) or metaComplex.__valre), metaComplex.__valim end
  if(R1 < R2 and I1 < I2) then return true end
  return false
end

local function StrValidateComplex(sStr)
  local Str = sStr:gsub("%s","") -- Remove hollows
  local S, E = 1, Str:len()
  while(S < E) do
    local CS = Str:sub(S,S)
    local CE = Str:sub(E,E)
    local FS = metaComplex.__bords[1]:find(CS,1,true)
    local FE = metaComplex.__bords[2]:find(CE,1,true)
    if((not FS) and FE) then
      return logStatus("StrValidateComplex: Unbalanced end #"..CS..CE.."#",nil) end
    if((not FE) and FS) then
      return logStatus("StrValidateComplex: Unbalanced beg #"..CS..CE.."#",nil) end
    if(FS and FE and FS > 0 and FE > 0) then
      if(FS == FE) then S = S + 1; E = E - 1
      else return logStatus("StrValidateComplex: Bracket mismatch #"..CS..CE.."#",nil) end
    elseif(not (FS and FE)) then break end;
  end; return Str, S, E
end

local function Str2Complex(sStr, nS, nE, sDel)
  local Del = tostring(sDel or ","):sub(1,1)
  local S, E, D = nS, nE, sStr:find(Del)
  if((not D) or (D < S) or (D > E)) then
    return complex.New(tonumber(sStr:sub(S,E)) or metaComplex.__valre, metaComplex.__valim) end
  return complex.New(tonumber(sStr:sub(S,D-1)) or metaComplex.__valre,
                     tonumber(sStr:sub(D+1,E)) or metaComplex.__valim)
end

local function StrI2Complex(sStr, nS, nE, nI)
  if(nI == 0) then
    return logStatus("StrI2Complex: Complex not in plain format [a+ib] or [a+bi]",nil) end
  local M = nI - 1 -- There will be no delimiter symbols here
  local C = sStr:sub(M,M)
  if(nI == nE) then  -- (-0.7-2.9i) Skip symbols until +/- is reached
    while(C ~= "+" and C ~= "-") do
      M = M - 1; C = sStr:sub(M,M)
    end; return complex.New(tonumber(sStr:sub(nS,M-1)) or metaComplex.__valre,
                            tonumber(sStr:sub(M,nE-1)) or metaComplex.__valim)
  else -- (-0.7-i2.9)
    return complex.New(tonumber(sStr:sub(nS,M-1))     or metaComplex.__valre,
                       tonumber(C..sStr:sub(nI+1,nE)) or metaComplex.__valim)
  end
end

local function Tab2Complex(tTab)
  if(not tTab) then return nil end; local R, I
  for ID = 1, #metaComplex.__kreal do
    local val = metaComplex.__kreal[ID]
    R = tTab[val] or R; if(R) then break end
  end
  for ID = 1, #metaComplex.__kimag do
    local val = metaComplex.__kimag[ID]
    I = tTab[val] or I; if(I) then break end
  end
  if(R or I) then
    return complex.New(tonumber(R) or metaComplex.__valre,
                       tonumber(I) or metaComplex.__valim) end
  return logStatus("Tab2Complex: Table format not supported", complex.New())
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

function complex.Convert(vIn,Del)
  if(getmetatable(vIn) == metaComplex) then return vIn:getDup() end
  local tIn = type(vIn)
  if(tIn =="boolean") then return complex.New(vIn and 1 or 0,0) end
  if(tIn ==  "table") then return Tab2Complex(vIn) end
  if(tIn == "number") then return complex.New(vIn,0) end
  if(tIn ==    "nil") then return complex.New(0,0) end
  if(tIn == "string") then
    local Str, S, E = StrValidateComplex(vIn:gsub("*",""))
    if(not (Str and S and E)) then
      return logStatus("complex.Convert: Failed to validate <"..tostring(vIn)..">",nil) end
        Str = Str:sub(S ,E); E = E-S+1; S = 1; local I
    for ID = 1, #metaComplex.__ssyms do
      local val = metaComplex.__ssyms[ID]
      I = Str:find(val,S) or I; if(I) then break end
    end
    if(I and (I > 0)) then return StrI2Complex(Str, S, E, I)
    else return Str2Complex(Str, S, E, Del) end
  end
  return logStatus("complex.Convert: Type <"..tIn.."> not supported",nil)
end

return complex
