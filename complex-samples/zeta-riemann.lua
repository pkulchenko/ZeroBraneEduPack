require("wx")
require("turtle")
local com = require("common")
local col = require("colormap")
local crt = require("chartmap")
local cmp = require("complex").extend()

local W,  H = 200, 200
local greyLevel  = 200
local gnDrwStep = 0.002
local minX, maxX = -10, 10
local minY, maxY = -20, 20
local dX, dY, cT, nAlp = 1, 1, cmp.getNew(), 0.6
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(col.getColorPadRGB(greyLevel))
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local scOpe = crt.New("scope"):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setInterval(intX, intY):setDelta(dX, dY):setSizeVtx(0)
      
local fFoo = function(c, i)
  return c:getZetaRiemann()
end

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

-- scOpe:Draw(true, true, true); updt()

com.logStatus("Elapsed: "..com.getToc())

-- To prodice a PNG snapshot, uncomment the line below
-- save(com.stringGetChunkPath().."snapshot")

wait()
