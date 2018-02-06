require("turtle")
local complex   = require("complex")
local chartmap  = require("chartmap")
local colormap  = require("colormap")
local common    = require("common")
local logStatus = common.logStatus

io.stdout:setvbuf("no")

logStatus("\nMethods starting with upper letter make internal changes and return /self/ .")
logStatus("\nMethods starting with lower return somethng and do not change internals .")

logStatus("\nCreating complex")
local a = complex.getNew(7,7):Print("1: ","\n")
complex.getNew(a):Print("2: ","\n")
a:getNew():Print("3: ","\n")
a:getNew(complex.getNew(1,-1)):Print("3: ","\n")
a:getNew(-7,nil):Print("4: ","\n")
a:getNew(nil,-7):Print("5: ","\n")
a:getNew(-7,-7):Print("6: ","\n")

logStatus("\nConverting complex from somrthing else "..tostring(a))
logStatus("The type of the first argument is used to identify what is converted")
complex.convNew(a):Print("Complex 1 : ","\n")
complex.convNew({a:getReal(),a.getImag()}):Print("Table 1 : ","\n")
complex.convNew({["r"] = a:getReal(), ["i"]=a.getImag()}):Print("Table 2 : ","\n")
complex.convNew({["asd"] = a:getReal(), ["fgh"]=a.getImag()},"asd","fgh"):Print("Table 3 : ","\n")
complex.convNew("7+j7"):Print("Direct string 1 : ","\n")
complex.convNew("7+7i"):Print("Direct string 2 : ","\n")
complex.convNew("7+J7"):Print("Direct string 3 : ","\n")
complex.convNew("7+7J"):Print("Direct string 4 : ","\n")
complex.convNew("7,7"):Print("Basic string 1 :  ","\n")
complex.convNew("7&7","&"):Print("Basic string 2 :  ","\n")
complex.convNew("{7,7}"):Print("Basic string 3 :  ","\n")
complex.convNew("/7,7/"):Print("Basic string 4 :  ","\n")
complex.convNew("[7,7]"):Print("Basic string 5 :  ","\n")
complex.convNew("(7,7)"):Print("Basic string 6 :  ","\n")
complex.convNew("|7,7|"):Print("Basic string 7 :  ","\n")
complex.convNew("<7,7>"):Print("Basic string 8 :  ","\n")
complex.convNew("/{7,7}/"):Print("Basic string 9 :  ","\n")
complex.convNew(7,7):Print("Number 1  : ","\n")
complex.convNew(true, true):Print("Boolean 1 : ","\n")
complex.convNew(true, false):Print("Boolean 2 : ","\n")
complex.convNew(false, true):Print("Boolean 3 : ","\n")
complex.convNew(false, false):Print("Boolean 4 : ","\n")
complex.convNew(nil, nil):Print("Boolean 5 : ","\n")

logStatus("\nConverting to string. Variety of outputs "..tostring(a))
logStatus("Export n/a 1: "..tostring(a))
logStatus("Export n/s 2: "..a:getFormat())
logStatus("Export table 3: "..a:getFormat("table"))
logStatus("Export table 4: "..a:getFormat("table",1,"%f",1))
logStatus("Export table 5: "..a:getFormat("table",3,"%5.2f",4))
logStatus("Export table 6: "..a:getFormat("table",3,"%5.2f",4,"asd","fgh"))
logStatus("Export string 1: "..a:getFormat("string"))
logStatus("Export string 2: "..a:getFormat("string",1))
logStatus("Export string 3: "..a:getFormat("string",1,false))
logStatus("Export string 4: "..a:getFormat("string",1,true))
logStatus("Export string 5: "..a:getFormat("string",2,true))
logStatus("Export string 6: "..a:getFormat("string",3,true))
logStatus("Export string 7: "..a:getFormat("string",4,true))
logStatus("Export string 8: "..a:getFormat("string",4,true,"$"))

logStatus("\nConverting to polar coordinates and back "..tostring(a))
local r, p = a:getPolar(); print("1: "..r.."e^"..p.."i")
complex.getEuler(r, p):Print("2: ","\n")

logStatus("\nAngle handling radian to degree and back "..tostring(a))
local r, d = a:getAngRad(), a:getAngDeg()
logStatus("1: Angle in radian "..r.." is "..complex.toDegree(r).." in degrees")
logStatus("2: Angle in degree "..d.." is "..complex.toRadian(d).." in radians")

logStatus("\nClass methods "..tostring(a))
local t = complex.getNew(a)

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
local f = (complex.getNew(a) + complex.convNew("0.5+0.5i")); t:Set(f)
t:Floor():Print("Floor 1: "," >> floor(f)     << "..f.."\n"); t:Set(f)
t:getFloor():Print("Floor 2: "," >> new floor(f) << "..f.."\n"); t:Set(f)

logStatus("\nCeiling "..tostring(a))
local c = complex.getNew(a) + complex.convNew("0.5+0.5i"); t:Set(c)
c:Ceil():Print("Floor 1: "," >> ceil(c)      << "..f.."\n"); t:Set(c)
c:getCeil():Print("Floor 2: "," >> new ceil(c)  << "..f.."\n"); t:Set(c)

logStatus("\nNegate "..tostring(a))
local n = complex.getNew(a)
complex.getNew(-n):Print("Neg 1: ","\n"); n:Set(a)
complex.getNew(n:Neg()):Print("Neg 2: ","\n"); n:Set(a)
complex.getNew(n:NegRe()):Print("Neg 3: ","\n"); n:Set(a)
complex.getNew(n:NegIm()):Print("Neg 4: ","\n"); n:Set(a)
complex.getNew(n:Conj()):Print("Neg 5: ","\n"); n:Set(a)
n:getNeg():Print("new Neg 1: ","\n"); n:Set(a)
n:getNegRe():Print("new Neg 2: ","\n"); n:Set(a)
n:getNegIm():Print("new Neg 3: ","\n"); n:Set(a)
n:getConj():Print("new Neg 4: ","\n"); n:Set(a)

logStatus("\nRound "..tostring(a))
logStatus("Positive away from zero "..tostring(a))
local ru = ( a:getNew() * 10 + complex.convNew(" 0.36+0.36j")):Print("Positive : ","\n")
local rd = (-a:getNew() * 10 + complex.convNew("-0.36-0.36j")):Print("Negative : ","\n")
ru:getNew():Round(0 or nil):Print("Zero     :","\n")
ru:getNew():Round(1):Print("Round away positive integer   :","\n")
ru:getNew():Round(0.1):Print("Round away positive float     :","\n")
ru:getNew():Round(-1):Print("Round towards positive integer:","\n")
ru:getNew():Round(-0.1):Print("Round towards positive float  :","\n")
rd:getNew():Round(1):Print("Round away negative integer   :","\n")
rd:getNew():Round(0.1):Print("Round away negative float     :","\n")
rd:getNew():Round(-1):Print("Round towards negative integer:","\n")
rd:getNew():Round(-0.1):Print("Round towards negative float  :","\n")

logStatus("\nComparison operators")
logStatus("Compare less            : "..tostring(complex.getNew(1,2) <  complex.getNew(2,3)))
logStatus("Compare less or equal   : "..tostring(complex.getNew(1,2) <= complex.getNew(2,3)))
logStatus("Compare geater          : "..tostring(complex.getNew(5,6) >  complex.getNew(2,3)))
logStatus("Compare greater or equal: "..tostring(complex.getNew(2,4) >= complex.getNew(2,3)))
logStatus("Compare equal           : "..tostring(complex.getNew(1,2) == complex.getNew(1,2)))

logStatus("\nComplex number call using the \"__call\" method "..tostring(a))
-- When calling the complex number as a function
-- the first argument is the method you want to call given as string,
-- the next are var-args, which are the parameters of the method.
-- The call will always return a status and varargs representing the result of the call.
-- For example let's set the complex number's real and imaginery parts via complex call.
local bSuccess, cNum = a:getNew()("Set",1,1)
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

local b = complex.getNew(7,1)
for id = 1, #tTrig do
  local suc, rez = b(trim(tTrig[id][2]))
  if(suc) then rez = tostring(rez)
    local com = trim(tTrig[id][3])
    logStatus(tTrig[id][1]..((rez == com) and "OK" or "FAIL").." >> "..com)
  else
    logStatus("There was a problem executing method <"..tTrig[id][1].."> at index #"..id)
    logStatus("Error recieved: "..tostring(rez))
  end
end; logStatus("")

local W, H   = 800, 800 -- Window size
local dX, dY = 1, 1     -- Coordiante system step
local gAlp   = 200      -- Coordinate system grey alpha level
local R = 5             -- Roots base

open("Graphical complex roots for "..tostring(a))
size(W, H)
zero(0, 0)
updt(false) -- disable auto updates

-- Adjust the mapping intervals accrding to the number rooted
local re, im = a:getParts()
local intX = chartmap.New("interval","WinX", -re/2, re/2, 0, W)
local intY = chartmap.New("interval","WinY", -im/2, im/2, H, 0)
local _x0, _y0 = intX:Convert(0):getValue(), intY:Convert(0):getValue()

-- Allocate colors
local clGrn = colr(colormap.getColorGreenRGB())
local clRed = colr(colormap.getColorRedRGB())
local clBlk = colr(colormap.getColorBlackRGB())
local clGry = colr(colormap.getColorPadRGB(gAlp))

-- This is used to properly draw the coordiante system
local function drawCoordinateSystem(w, h, dx, dy, mx, my)
  local xe, ye = 0, 0, 200
  for x = 0, mx, dx do
    local xp = intX:Convert( x):getValue()
    local xm = intX:Convert(-x):getValue()
    if(x == 0) then xe = xp
    else  pncl(clGry); line(xp, 0, xp, h); line(xm, 0, xm, h) end
  end
  for y = 0, my, dx do
    local yp = intY:Convert( y):getValue()
    local ym = intY:Convert(-y):getValue()
    if(y == 0) then ye = yp
    else  pncl(clGry); line(0, yp, w, yp); line(0, ym, w, ym) end
  end; pncl(clBlk)
  line(xe, 0, xe, h); line(0, ye, w, ye)
end

--[[
  Custom function for drawing a number on the complex plane
  The the first argument must always be the complex mumber
  tat you are gonna draw a.k.a. SELF. The other parameters are
  VARARG, which means you can use a bunch of then in the stack
  In this example all athe arguments are local for this file
  so there is no point of extending the vararg on the stack
  Prototype: drawFunction(SELF, ...)
]]
local function drawComplexFunction(C)
  local r = C:getRound(0.001)
  local x = intX:Convert(r:getReal()):getValue()
  local y = intY:Convert(r:getImag()):getValue()
  pncl(clGrn); line(_x0, _y0, x, y)
  pncl(clRed); rect(x-2,y-2,5,5)
  pncl(clBlk); text(tostring(r),r:getAngDeg()+90,x,y)
end

--[[
  It is easy for the complex numbers to be drawn using a attached drawing method
  internally as every object keeps its local data and you can draw stuff using less arguments
  Prototype: complex.setAction(KEY, FUNCTION)
]]
complex.setAction("This your action key !" ,drawComplexFunction) -- This is how you register a drawing method

drawCoordinateSystem(W, H, dX, dY, re/2, im/2)

logStatus("Complex roots returns a table of complex numbers being the roots of the base number "..tostring(a))
local r = a:getRoots(R)
if(r) then
  for id = 1, #r do
    logStatus(r[id].."^"..R.." = "..(r[id]^R))
    r[id]:Action("This your action key !"); updt()
    wait(0.3)
  end
end

wait()
