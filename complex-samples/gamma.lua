require("wx")
require("turtle")
local com = require("common")
local col = require("colormap")
local crt = require("chartmap")
local cmp = require("complex").extend()

local W,  H = 200, 200
local minX, maxX = -5, 2
local minY, maxY = -3, 3
local dX, dY, cT, nAlp = 1, 1, cmp.getNew(), 0.5
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)

local fFoo = function(c, i)
  return c:getGamma()
end

cmp.setIterations(20)

open("Complex gamma function")
size(W, H)
zero(0, 0)
updt(false) -- disable auto updates
com.setTic()

for j = 0, H do
  for i = 0, W do
    cT:Set(intX:Convert(i, true):getValue(),
           intY:Convert(j, true):getValue())
    local r, g, b, f = col.getColorComplexDomain(fFoo, cT, nAlp)
    pncl(colr(r, g, b)); pixl(i, j)
  end
  updt()
end

com.logStatus("Elapsed: "..com.getToc())

-- To prodice a PNG snapshot, uncomment the line below
-- save(com.stringGetChunkPath().."snapshot")

wait()
