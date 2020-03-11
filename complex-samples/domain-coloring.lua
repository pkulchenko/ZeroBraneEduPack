local loadString = load

require("wx")
require("turtle")
local common  = require("common")
local complex = require("complex")
local chartmap = require("chartmap")
local colormap = require("colormap")

io.stdout:setvbuf("no")

local nFunc = 2

local tFunc = {
  {"(z^2 - 1)*(z - 2 - i)^2/(z^2 + 2 + 2*i)",4},
  {"(z^3 - 1)", 1.3},
  {"(1/(1+z))", 5},
  {"(1/(1+z^2))", 5},
  {"(1/(1-(z:getReal()+i*z:getImag())^2))", 5}
} 

-- Tinker stuff
local nAlp = 0.6
local dX, dY = 1,1
local  W,  H = 500, 500

-- Automatic stuff
local nRan = tFunc[nFunc][2]
local cI = complex.getNew(0, 1) -- 0+i
local cT = complex.getNew()
local intX = chartmap.New("interval","WinX", -nRan, nRan, 0, W)
local intY = chartmap.New("interval","WinY", -nRan, nRan, H, 0)
local scOpe = chartmap.New("scope"):setInterval(intX, intY):setSize():setBorder()
      scOpe:setColor():setDelta(dX, dY):Draw(true, true, true):setSizeVtx(0)

local fFoo, sErr = loadString("return function(z, i) return "..tFunc[nFunc][1].." end")
if(not fFoo) then print("Load("..tostring(fFoo).."): "..sErr); return end
bSuc , fFoo = pcall(fFoo)
if(not bSuc) then print("Make("..tostring(bSuc).."): "..fFoo); return end

open("Complex domain coloring")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

scOpe:Draw(false, false, false)

for j = 0, H do
  for i = 0, W do -- Convert coordinates to complex mapping
    cT:Set(intX:Convert(i, true):getValue(),
           intY:Convert(j, true):getValue())
    local r, g, b, f = colormap.getColorComplexDomain(fFoo, cT, nAlp)
    if(not f) then common.logStatus("Cannot plot incorrect patameters"); break end
    pncl(colr(r, g, b)); pixl(i, j)
  end; updt()
end

wait()
