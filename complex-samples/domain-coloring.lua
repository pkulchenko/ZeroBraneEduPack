compileString = load

require("wx")
require("turtle")
local common  = require("common")
local complex = require("complex")
local chartmap = require("chartmap")
local colormap = require("colormap")

io.stdout:setvbuf("no")

local nFunc = 5

local tFunc = {
  {"(z^3 - 1)", 1.3},
  {"(z^4 - 1)", 1.3},
  {"(z^5 - 1)", 1.3},
  {"(z^6 - 1)", 1.3},
  {"(1/(1+z))", 5},
  {"(1/(1+z^2))", 5},
  {"(z^2 - 1)*(z - 2 - i)^2/(z^2 + 2 + 2*i)",4},
  {"(1/(1-(z:getReal()+i*z:getImag())^2))", 5}
} 

-- Tinker stuff
local nAlp = 0.5
local  W,  H = 500, 500

-- Automatic stuff
local dX, dY = 1 , 1
local nRan = tFunc[nFunc][2]
local cI = complex.getNew(0, 1) -- 0+i
local cT = complex.getNew()
local intX = chartmap.New("interval","WinX", -nRan, nRan, 0, W)
local intY = chartmap.New("interval","WinY", -nRan, nRan, H, 0)

local fF = common.getCompileString("return function(z, i) return "..tFunc[nFunc][1].." end")
if(not fF) then return end

open("Complex domain coloring")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

for j = 0, H do
  for i = 0, W do -- Convert coordinates to complex mapping
    cT:Set(intX:Convert(i, true):getValue(),
           intY:Convert(j, true):getValue())
    local r, g, b, f = colormap.getColorComplexDomain(fF, cT, nAlp)
    if(not f) then common.logStatus("Cannot plot incorrect patameters"); break end
    pncl(colr(r, g, b)); pixl(i, j)
  end; updt()
end

wait()
