require("turtle")
local complex  = require("complex")
local chartmap = require("chartmap")
local colormap = require("colormap")

local W, H     = 400, 400

open("Complex ballistics")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end
     
io.stdout:setvbuf("no")

logStatus("\nMethods starting with upper letter meke internal changes and return /self/ .")
logStatus("\nMethods starting with lower return somethng and do not change internals .")

logStatus("\nCreating complex")
local a = complex.New(7,7):Print("1: ","\n")
complex.New(a):Print("2: ","\n")
a:getDup():Print("3: ","\n")

logStatus("\nConverting complex from somrthing else")
complex.Convert(a):Print("1: ","\n")
complex.Convert({["r"] = a:getReal(), ["i"]=a.getImag()}):Print("2: ","\n")
complex.Convert("7+j7"):Print("3: ","\n")
complex.Convert("7+7i"):Print("4: ","\n")

logStatus("\nConverting to string. Variety of outputs")
logStatus("1: "..tostring(a))
logStatus("2: "..a:getFormat())
logStatus("3: "..a:getFormat("table"))
logStatus("4: "..a:getFormat("table",1,"%f",1))
logStatus("5: "..a:getFormat("table",3,"%5.2f",4))
logStatus("3: "..a:getFormat("string"))
logStatus("4: "..a:getFormat("string",1))
logStatus("5: "..a:getFormat("string",1,false))
logStatus("6: "..a:getFormat("string",1,true))
logStatus("7: "..a:getFormat("string",2,true))
logStatus("8: "..a:getFormat("string",3,true))
logStatus("9: "..a:getFormat("string",4,true))

logStatus("\nConverting to polar coordinates and back")
local r, p = a:getPolar(); print("1: "..r.."e^"..p.."i")
complex.Euler(r, p):Print("2: ","\n")

logStatus("\nClass methods")
local t = complex.New(a)
--- Addition
logStatus("Add 1: "..(a+1))
logStatus("Add 2: "..(a+2):Round(0.01))
logStatus("Add 3: "..t:Add(2):Round(0.01)); t:Set(a)
t:Add(.7,.7):Round(0.01):Print("Add 4: "," >> a+(0.7+0.7i) \n"); t:Set(a)
t:Add(a/10):Round(0.01):Print("Add 5: "," >> a+(0.7+0.7i) \n"); t:Set(a)
--- Substract
logStatus("Sub 1: "..(a-1))
logStatus("Sub 2: "..(a-2):Round(0.01))
logStatus("Sub 3: "..t:Sub(2):Round(0.01)); t:Set(a)
t:Sub(.7,.7):Round(0.01):Print("Add 4: "," >> a-(0.7+0.7i) \n"); t:Set(a)
t:Sub(a/10):Round(0.01):Print("Add 5: "," >> a-(0.7+0.7i) \n"); t:Set(a)
--- Multy
logStatus("Mul 1: "..(a*1))
logStatus("Mul 2: "..(a*2):Round(0.01))
logStatus("Mul 3: "..t:Mul(2):Round(0.01)); t:Set(a)
t:Mul(.7,.7):Round(0.01):Print("Mul 4: "," >> a-(0.7+0.7i) \n"); t:Set(a)
t:Mul(a/10):Round(0.01):Print("Mul 5: "," >> a-(0.7+0.7i) \n"); t:Set(a)
--- Divide
logStatus("Div 1: "..(a/1))
logStatus("Div 2: "..(a/2):Round(0.01))
logStatus("Div 3: "..t:Div(2):Round(0.01)); t:Set(a)
t:Div(.7,.7):Round(0.01):Print("Div 4: "," >> a-(0.7+0.7i) \n"); t:Set(a)
t:Div(a/10):Round(0.01):Print("Div 5: "," >> a-(0.7+0.7i) \n"); t:Set(a)
--- Power
logStatus("Pow 1: "..(a^1))
logStatus("Pow 2: "..(a^2):Round(0.01))
logStatus("Pow 3: "..t:Pow(2):Round(0.01)); t:Set(a)
t:Pow(.7,.7):Round(0.01):Print("Pow 4: "," >> a^(0.7+0.7i) \n"); t:Set(a)
t:Pow(a/10):Round(0.01):Print("Pow 5: "," >> a^(0.7+0.7i) \n"); t:Set(a)
--- Flooring
local f = complex.New(a) + complex.Convert("0.5+0.5i"); t:Set(f)
t:Floor():Print("Floor 1: "," >> floor(f)     << "..f.."\n"); t:Set(f)
t:getFloor():Print("Floor 2: "," >> new floor(f) << "..f.."\n"); t:Set(f)
--- Ceiling
local c = complex.New(a) + complex.Convert("0.5+0.5i"); t:Set(c)
c:Ceil():Print("Floor 1: "," >> ceil(c)      << "..f.."\n"); t:Set(c)
c:getCeil():Print("Floor 2: "," >> new ceil(c)  << "..f.."\n"); t:Set(c)
--Negate
local n = complex.New(a)
complex.New(-n):Print("Neg 1: ","\n"); n:Set(a)
complex.New(n:Neg()):Print("Neg 2: ","\n"); n:Set(a)
complex.New(n:NegRe()):Print("Neg 3: ","\n"); n:Set(a)
complex.New(n:NegIm()):Print("Neg 4: ","\n"); n:Set(a)
complex.New(n:Conj()):Print("Neg 5: ","\n"); n:Set(a)
n:getNeg():Print("new Neg 1: ","\n"); n:Set(a)
n:getNegRe():Print("new Neg 2: ","\n"); n:Set(a)
n:getNegIm():Print("new Neg 3: ","\n"); n:Set(a)
n:getConj():Print("new Neg 4: ","\n"); n:Set(a)
--- Round
--- Positive away from zero
local ru = ( a:getDup() * 10 + complex.Convert(" 0.36+0.36j")):Print("Positive : ","\n")
local rd = (-a:getDup() * 10 + complex.Convert("-0.36-0.36j")):Print("Negative : ","\n")
ru:getDup():Round(0 or nil):Print("Zero     :","\n")
ru:getDup():Round(1):Print("Away positive integer   :","\n")
ru:getDup():Round(0.1):Print("Away positive float     :","\n")
ru:getDup():Round(-1):Print("Towards positive integer:","\n")
ru:getDup():Round(-0.1):Print("Towards positive float  :","\n")
rd:getDup():Round(1):Print("Away negative integer   :","\n")
rd:getDup():Round(0.1):Print("Away negative float     :","\n")
rd:getDup():Round(-1):Print("Towards negative integer:","\n")
rd:getDup():Round(-0.1):Print("Towards negative float  :","\n")

logStatus("Less            : "..tostring(complex.New(1,2) <  complex.New(2,3)))
logStatus("Less or equal   : "..tostring(complex.New(1,2) <= complex.New(2,3)))
logStatus("Geater          : "..tostring(complex.New(5,6) >  complex.New(2,3)))
logStatus("Greater or equal: "..tostring(complex.New(2,4) >= complex.New(2,3)))
logStatus("Equal           : "..tostring(complex.New(1,2) == complex.New(1,2)))

local b = 5 -- Roots base
local re, im = a:getParts()
local intX = chartmap.newInterval("WinX", -re/2, re/2, 0, W)
local intY = chartmap.newInterval("WinY", -im/2, im/2, H, 0)
local x0, y0 = intX:Convert(0):getValue(), intY:Convert(0):getValue()

line(0, y0, W, y0); line(x0, 0, x0, H)

local clGrn = colr(colormap.getColorGreenRGB())
local clRed = colr(colormap.getColorRedRGB())
local clBlk = colr(colormap.getColorBlackRGB())

local function drawComplex(C, x0, y0, Ix, Iy)
  local r = C:getRound(0.001)
  local x = Ix:Convert(r:getReal()):getValue()
  local y = Iy:Convert(r:getImag()):getValue()
  pncl(clGrn); line(x0, y0, x, y)
  pncl(clRed); rect(x-2,y-2,5,5)
  pncl(clBlk); text(tostring(r),r:getAngDeg()+90,x,y)
end

local r = a:getRoots(b)
if(r) then
  for id = 1, #r do
    logStatus(r[id].."^"..b.." = "..(r[id]^b))
    drawComplex(r[id], x0, y0, intX, intY)
  end
end

wait()
