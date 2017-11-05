local type         = type
local math         = math
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
metaComplex.__bords = {"/|<({[","/|>)}]"}

metaComplex.__tostring = function(Comp)
  local R = tostring(Comp:getReal())
  local I = tostring(Comp:getImag())
  if(R and I) then return "{"..R..","..I.."}" end
  return "{X,X}"
end

metaComplex.__unm = function(Comp)
  if(getmetatable(Comp) == metaComplex) then
    return Complex(-Comp:getReal(),-Comp:getImag())
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
  if(getmetatable(A) == metaComplex) then
    return "{"..A:getReal()..", "..A:getImag().."}"..tostring(B)
  elseif(getmetatable(B) == metaComplex) then
    return tostring(A).."{"..B:getReal()..", "..B:getImag().."}"
  end; return "N/A"
end

metaComplex.__pow =  function(C1,C2)
  local O = complex.New()
  O:Set(C1); O:Pow(C2)
  return O
end

metaComplex.__eq =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then
    R1, I1 = C1:getReal(), C1:getImag()
  else
    R1, I1 = (tonumber(C1) or 0), 0
  end
  if(getmetatable(C2) == metaComplex) then
    R2, I2 = C2:getReal(), C2:getImag()
  else
    R2, I2 = (tonumber(C2) or 0), 0
  end
  if(R1 == R2 and I1 == I2) then return true end
  return false
end

metaComplex.__le =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then
    R1, I1 = C1:getReal(), C1:getImag()
  else
    R1, I1 = (tonumber(C1) or 0), 0
  end
  if(getmetatable(C2) == metaComplex) then
    R2, I2 = C2:getReal(), C2:getImag()
  else
    R2, I2 = (tonumber(C2) or 0), 0
  end
  if(R1 <= R2 and I1 <= I2) then return true end
  return false
end

metaComplex.__lt =  function(C1,C2)
  local R1, R2, I1, I2 = 0, 0, 0, 0
  if(getmetatable(C1) == metaComplex) then
    R1, I1 = C1:getReal(), C1:getImag()
  else
    R1, I1 = (tonumber(C1) or 0), 0
  end
  if(getmetatable(C2) == metaComplex) then
    R2, I2 = C2:getReal(), C2:getImag()
  else
    R2, I2 = (tonumber(C2) or 0), 0
  end
  if(R1 < R2 and I1 < I2) then return true end
  return false
end

local function asrComplex(R,I)
  if(not I) then
    if(getmetatable(R) == metaComplex) then
      return R:getReal(), R:getImag()
    else return (tonumber(R) or 0), (tonumber(I) or 0) end
  else return (tonumber(R) or 0), (tonumber(I) or 0) end
end

function complex.New(nRe,nIm)
  self = {}
  local Re = tonumber(nRe) or 0
  local Im = tonumber(nIm) or 0

  setmetatable(self,metaComplex)

  function self:NegRe()     Re = -Re; return self end
  function self:NegIm()     Im = -Im; return self end
  function self:Conj()      Im = -Im; return self end
  function self:setReal(R)  Re = (tonumber(R) or 0); return self end
  function self:setImag(I)  Im = (tonumber(I) or 0); return self end
  function self:Floor()     Re = math.floor(Re); Im = math.floor(Im); return self end
  function self:Ceil()      Re = math.ceil(Re); Im = math.ceil(Im); return self end
  function self:Print(sS,sE)  io.write(tostring(sS or "").."{"..tostring(Re)..","..tostring(Im).."}"..tostring(sE or "")); return self end
  function self:getReal()   return Re end
  function self:getImag()   return Im end
  function self:getDupe()   return Complex(Re,Im) end
  function self:getFloor()  return Complex(math.floor(Re),math.floor(Im)) end
  function self:getCeil()   return Complex(math.ceil(Re),math.ceil(Im)) end
  function self:toPointXY() return {x = Re, y = Im} end
  function self:getNeg()    return Complex(-Re,-Im) end
  function self:getNegRe()  return Complex(-Re, Im) end
  function self:getNegIm()  return Complex( Re,-Im) end
  function self:getConj()   return Complex( Re,-Im) end
  function self:getNorm2()  return (Re*Re + Im*Im) end
  function self:getNorm()   return math.sqrt(Re*Re + Im*Im) end
  function self:getAngRad() return math.atan2(Im,Re) end
  function self:getAngDeg() return (math.atan2(Im,Re) * 180) / math.pi end

  function self:Round(nP)
    local nP = (tonumber(nP) or 0)
    if(nP < 0) then
      return logStatus("complex.Round: Negative count skip", self) end
    Re = tonumber(string.format("%."..nP.."f", Re))
    Im = tonumber(string.format("%."..nP.."f", Im)); return self
  end

  function self:getRound(nP) return complex.New(Re,IM):Round(nP) end

  function self:Set(R,I)
    local R,I = asrComplex(R,I)
    Re, Im = R, I; return self
  end

  function self:Add(R,I)
    local R,I = asrComplex(R,I)
    Re, Im = (Re + R), (Im + I); return self
  end

  function self:Sub(R,I)
    local R,I = asrComplex(R,I)
    Re, Im = (Re - R), (Im - I); return self
  end

  function self:Scale(nNum)
    local N = tonumber(nNum)
    if(N) then Re, Im = (Re * N), (Im * N) end; return self
  end

  function self:Mul(R,I)
    local A, C, D = Re, asrComplex(R,I)
    Re = A*C - Im*D
    Im = A*D + Im*C; return self
  end

  function self:Div(R,I)
    local A, C, D = Re, asrComplex(R,I)
    local Z = (C*C + D*D)
    if(Z ~= 0) then Re, Im = ((A *C + Im*D) / Z), ((Im*C -  A*D) / Z) end; return self
  end

  function self:Mod(R,I)
    local A, C, D = Re, asrComplex(R,I); self:Div(C,D)
    local rei, ref = math.modf(Re)
    local imi, imf = math.modf(Im)
    self:Set(ref,imf)
    self:Mul(C,D); return self
  end

  function self:Pow(R,I)
    local C, D = asrComplex(R,I)
    local Ro = self:getNorm()
    local Th = self:getAngRad()
    local nR = (Ro ^ C) * math.exp(-D * Th)
    local nF =  C * Th  + D * math.log(Ro)
    Re = nR * math.cos(nF)
    Im = nR * math.sin(nF); return self
  end

  function self:getRoots(nNum)
    local N = tonumber(nNum)
    if(N) then
      local N = math.floor(N)
      local tRoots = {}
      local Pi = math.pi
      local R  = self:getNorm()   ^ (1 / N)
      local Th = self:getAngRad() * (1 / N)
      local CRe, CIm
      local AngStep = (2*Pi) / N
      for k = 1, N do
        CRe = R * math.cos(Th)
        CIm = R * math.sin(Th)
        tRoots[k] = complex.New(CRe,CIm)
        Th = Th + AngStep
      end; return tRoots
    end; return nil
  end; return nil
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
    return complex.New(tonumber(sStr:sub(S,E)) or 0, 0) end
  return complex.New(tonumber(sStr:sub(S,D-1)) or 0, tonumber(sStr:sub(D+1,E)) or 0)
end

local function StrI2Complex(sStr, nS, nE, nI)
  if(nI == 0) then
    return logStatus("StrI2Complex: Complex not in plain format [a+ib] or [a+bi]",nil) end
  local M = nI - 1 -- There will be no delimiter symbols here
  local C = sStr:sub(M,M)
  if(nI == nE) then  -- (-0.7-2.9i) Skip symbols til +/- is reached
    while(C ~= "+" and C ~= "-") do
      M = M - 1; C = sStr:sub(M,M)
    end; return complex.New(tonumber(sStr:sub(nS,M-1)), tonumber(sStr:sub(M,nE-1)))
  else -- (-0.7-i2.9)
    return complex.New(tonumber(sStr:sub(nS,M-1)), tonumber(C..sStr:sub(nI+1,nE)))
  end
end

local function Tab2Complex(tTab)
  if(not tTab) then return nil end
  local V1 = tTab[1]
        V1 = tTab["Real"] or V1
        V1 = tTab["real"] or V1
        V1 = tTab["Re"]   or V1
        V1 = tTab["re"]   or V1
        V1 = tTab["R"]    or V1
        V1 = tTab["r"]    or V1
        V1 = tTab["X"]    or V1
        V1 = tTab["x"]    or V1
  local V2 = tTab[2]
        V2 = tTab["Imag"] or V2
        V2 = tTab["imag"] or V2
        V2 = tTab["Im"]   or V2
        V2 = tTab["im"]   or V2
        V2 = tTab["I"]    or V2
        V2 = tTab["i"]    or V2
        V2 = tTab["Y"]    or V2
        V2 = tTab["y"]    or V2
  if(V1 or V2) then
    V2 = tonumber(V2) or 0
    V1 = tonumber(V1) or 0
    return complex.New(V1,V2)
  end
  return logStatus("StrI2Complex: Table format not supported",nil)
end

function complex.Convert(In,Del)
  local tIn = type(In)
  if(tIn ==  "table") then return Tab2Complex(In) end
  if(tIn == "number") then return complex.New(In,0) end
  if(tIn ==    "nil") then return complex.New(0,0) end
  if(tIn == "string") then
    local Str, S, E = StrValidateComplex(In:gsub("*",""))
    if(not (Str and S and E)) then
      return logStatus("ToComplex: Failed to vlalidate <"..tostring(In)..">",nil) end
        Str = Str:sub(S ,E); E = E-S+1; S = 1
    local I = Str:find("i",S)
          I = Str:find("I",S) or I
          I = Str:find("j",S) or I
          I = Str:find("J",S) or I
    if(I and (I > 0)) then return StrI2Complex(Str, S, E, I)
    else return Str2Complex(Str, S, E, Del) end
  end
  return logStatus("ToComplex: Type <"..Tin.."> not supported",nil)
end

return complex
