require("turtle")
local complex  = require("complex")
local chartmap = require("chartmap")
local colormap = require("colormap")

io.stdout:setvbuf("no")

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end
     
logStatus("\nMethods starting with upper letter make internal changes and return /self/ .")
logStatus("\nMethods starting with lower return somethng and do not change internals .")

logStatus("\nCreating complex")
local a = complex.New(7,7):Print("1: ","\n")
complex.New(a):Print("2: ","\n")
a:getDup():Print("3: ","\n")

logStatus("\nConverting complex from somrthing else "..tostring(a))
complex.Convert(a):Print("1: ","\n")
complex.Convert({["r"] = a:getReal(), ["i"]=a.getImag()}):Print("2: ","\n")
complex.Convert("7+j7"):Print("3: ","\n")
complex.Convert("7+7i"):Print("4: ","\n")

logStatus("\nConverting to string. Variety of outputs "..tostring(a))
logStatus("Export 1: "..tostring(a))
logStatus("Export 2: "..a:getFormat())
logStatus("Export 3: "..a:getFormat("table"))
logStatus("Export 4: "..a:getFormat("table",1,"%f",1))
logStatus("Export 5: "..a:getFormat("table",3,"%5.2f",4))
logStatus("Export 3: "..a:getFormat("string"))
logStatus("Export 4: "..a:getFormat("string",1))
logStatus("Export 5: "..a:getFormat("string",1,false))
logStatus("Export 6: "..a:getFormat("string",1,true))
logStatus("Export 7: "..a:getFormat("string",2,true))
logStatus("Export 8: "..a:getFormat("string",3,true))
logStatus("Export 9: "..a:getFormat("string",4,true))

logStatus("\nConverting to polar coordinates and back "..tostring(a))
local r, p = a:getPolar(); print("1: "..r.."e^"..p.."i")
complex.Euler(r, p):Print("2: ","\n")

logStatus("\nClass methods "..tostring(a))
local t = complex.New(a)

logStatus("\nAddition "..tostring(a))
logStatus("Add 1: "..(a+1))
logStatus("Add 2: "..(a+2):Round(0.01))
logStatus("Add 3: "..t:Add(2):Round(0.01)); t:Set(a)
t:Add(.7,.7):Round(0.01):Print("Add 4: "," >> a+(0.7+0.7i) \n"); t:Set(a)
t:Add(a/10):Round(0.01):Print("Add 5: "," >> a+(0.7+0.7i) \n"); t:Set(a)

logStatus("\nSubstract "..tostring(a))
logStatus("Sub 1: "..(a-1))
logStatus("Sub 2: "..(a-2):Round(0.01))
logStatus("Sub 3: "..t:Sub(2):Round(0.01)); t:Set(a)
t:Sub(.7,.7):Round(0.01):Print("Add 4: "," >> a-(0.7+0.7i) \n"); t:Set(a)
t:Sub(a/10):Round(0.01):Print("Add 5: "," >> a-(0.7+0.7i) \n"); t:Set(a)

logStatus("\nMultiplication "..tostring(a))
logStatus("Mul 1: "..(a*1))
logStatus("Mul 2: "..(a*2):Round(0.01))
logStatus("Mul 3: "..t:Mul(2):Round(0.01)); t:Set(a)
t:Mul(.7,.7):Round(0.01):Print("Mul 4: "," >> a*(0.7+0.7i) \n"); t:Set(a)
t:Mul(a/10):Round(0.01):Print("Mul 5: "," >> a*(0.7+0.7i) \n"); t:Set(a)

logStatus("\nDivision "..tostring(a))
logStatus("Div 1: "..(a/1))
logStatus("Div 2: "..(a/2):Round(0.01))
logStatus("Div 3: "..t:Div(2):Round(0.01)); t:Set(a)
t:Div(.7,.7):Round(0.0001):Print("Div 4: "," >> a/(0.7+0.7i) \n"); t:Set(a)
t:Div(a/10):Round(0.0001):Print("Div 5: "," >> a/(0.7+0.7i) \n"); t:Set(a)

logStatus("\nPower "..tostring(a))
logStatus("Pow 1: "..(a^1))
logStatus("Pow 2: "..(a^2):Round(0.01))
logStatus("Pow 3: "..t:Pow(2):Round(0.01)); t:Set(a)
t:Pow(.7,.7):Round(0.0001):Print("Pow 4: "," >> a^(0.7+0.7i) \n"); t:Set(a) -- {-1.5828,2.3963}
t:Pow(a/10):Round(0.0001):Print("Pow 5: "," >> a^(0.7+0.7i) \n"); t:Set(a)  -- {-1.5828,2.3963}

logStatus("\nFlooring "..tostring(a))
local f = (complex.New(a) + complex.Convert("0.5+0.5i")); t:Set(f)
t:Floor():Print("Floor 1: "," >> floor(f)     << "..f.."\n"); t:Set(f)
t:getFloor():Print("Floor 2: "," >> new floor(f) << "..f.."\n"); t:Set(f)

logStatus("\nCeiling")
local c = complex.New(a) + complex.Convert("0.5+0.5i"); t:Set(c)
c:Ceil():Print("Floor 1: "," >> ceil(c)      << "..f.."\n"); t:Set(c)
c:getCeil():Print("Floor 2: "," >> new ceil(c)  << "..f.."\n"); t:Set(c)

logStatus("\nNegate")
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

logStatus("\nRound")
logStatus("\nPositive away from zero")
local ru = ( a:getDup() * 10 + complex.Convert(" 0.36+0.36j")):Print("Positive : ","\n")
local rd = (-a:getDup() * 10 + complex.Convert("-0.36-0.36j")):Print("Negative : ","\n")
ru:getDup():Round(0 or nil):Print("Zero     :","\n")
ru:getDup():Round(1):Print("Round away positive integer   :","\n")
ru:getDup():Round(0.1):Print("Round away positive float     :","\n")
ru:getDup():Round(-1):Print("Round towards positive integer:","\n")
ru:getDup():Round(-0.1):Print("Round towards positive float  :","\n")
rd:getDup():Round(1):Print("Round away negative integer   :","\n")
rd:getDup():Round(0.1):Print("Round away negative float     :","\n")
rd:getDup():Round(-1):Print("Round towards negative integer:","\n")
rd:getDup():Round(-0.1):Print("Round towards negative float  :","\n")

logStatus("\nComparison operators")
logStatus("Compare less            : "..tostring(complex.New(1,2) <  complex.New(2,3)))
logStatus("Compare less or equal   : "..tostring(complex.New(1,2) <= complex.New(2,3)))
logStatus("Compare geater          : "..tostring(complex.New(5,6) >  complex.New(2,3)))
logStatus("Compare greater or equal: "..tostring(complex.New(2,4) >= complex.New(2,3)))
logStatus("Compare equal           : "..tostring(complex.New(1,2) == complex.New(1,2)))

logStatus("\nComplex number call using the \"__call\" method")
-- When calling the complex number as a function
-- the first argument is the method you want to call given as string,
-- the next are var-args, which are the parameters of the method.
-- The call will always return a status and varargs representing the result of the call.
-- For example let's set the complex number's real and imaginery parts via complex call.
local bSuccess, cNum = a:getDup()("Set",1,1)
if(bSuccess) then
  logStatus("The complex call was successful. The result is "..tostring(cNum).."\n")
else
  logStatus("The complex call was not successful.\n")
end

local tTrig = {
  {"Sine          : ","getSin  ","{1.0137832978161,0.885986829195}      "},
  {"Cosine        : ","getCos  ","{1.1633319692207,-0.7720914350223}    "},
  {"Tangent       : ","getTang ","{0.25407140331504,0.93021872707887}   "},
  {"Cotangent     : ","getCotg ","{0.27323643702064,-1.0003866917748}   "},
  {"Hyp sine      : ","getSinH ","{296.25646574921,461.392875559}       "},
  {"Hyp cosine    : ","getCosH ","{296.25695844114,461.39210823679}     "},
  {"Hyp tangent   : ","getTangH","{1.0000006920752,1.5122148957712e-006}"},
  {"Hyp cotangent : ","getCotgH","{0.999999307923,-1.5122128026371e-006}"},
  {"Logarithm     : ","getLog  ","{1.9560115027141,0.14189705460416}    "}
}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local b = complex.New(7,1)
for id = 1, #tTrig do
  local suc, rez = b(trim(tTrig[id][2]))
        rez = tostring(rez)
  local com = trim(tTrig[id][3])

  logStatus(tTrig[id][1]..((rez == com) and "OK" or "FAIL").." >> "..com)
end; logStatus("")

local W, H = 800, 800 -- window size

local R = 2 -- Roots base

open("Graphical complex roots for "..tostring(a))
size(W, H)
zero(0, 0)
updt(false) -- disable auto updates

-- Adjust the mapping intervals accrding to the number rooted
local re, im = a:getParts()
local intX = chartmap.newInterval("WinX", -re/2, re/2, 0, W)
local intY = chartmap.newInterval("WinY", -im/2, im/2, H, 0)
local x0, y0 = intX:Convert(0):getValue(), intY:Convert(0):getValue()

-- Draw the coordinate system
line(0, y0, W, y0); line(x0, 0, x0, H)

-- Allocate colors
local clGrn = colr(colormap.getColorGreenRGB())
local clRed = colr(colormap.getColorRedRGB())
local clBlk = colr(colormap.getColorBlackRGB())

-- Custom function for drawing a number on the complex plane
local function drawComplex(C, x0, y0, Ix, Iy)
  local r = C:getRound(0.001)
  local x = Ix:Convert(r:getReal()):getValue()
  local y = Iy:Convert(r:getImag()):getValue()
  pncl(clGrn); line(x0, y0, x, y)
  pncl(clRed); rect(x-2,y-2,5,5)
  pncl(clBlk); text(tostring(r),r:getAngDeg()+90,x,y)
end

logStatus("Complex roots returns a table of complex numbers being the roots of the base number "..tostring(a))
local r = a:getRoots(R)
if(r) then
  for id = 1, #r do
    logStatus(r[id].."^"..R.." = "..(r[id]^R))
    drawComplex(r[id], x0, y0, intX, intY)
  end
end

wait()
