require("wx")
require("turtle")
local cmp = require("complex")
local com = require("common")
local col = require("colormap")
local crt = require("chartmap")

-- 1 : Nearest neighbour ( ZoH )
-- 2 : Bilinear interpolation ( FoH )
-- 3 : Bicubic interpolation ( SoH )
local nOH = 1

local W,  H = 300, 300
local greyLevel  = 200
local gnAccuracy = 0.003
local minX, maxX = 0, 1
local minY, maxY = 0, 1
local dX, dY, xySize = 1, 1, 3
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(col.getColorPadRGB(greyLevel))
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local scOpe = crt.New("scope"):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setInterval(intX, intY):setDelta(dX, dY):setSizeVtx(0)

local tMap = {
  {0  ,  0,180},
  {0  ,255,255},
  {0  ,255,  0},
  {255,255,  0},
  {255,  0,  0},
  {180,  0,  0}
}

local tPal = col.getColorMapInterpolate(tMap, 15)
col.setColorMap("interp", tPal)
local nTot = (col.getColorMap("interp").Size - 1)

com.logStatus("https://en.wikipedia.org/wiki/Bilinear_interpolation")
com.logStatus("Interpolated pallete map size: "..nTot)

local cZ = cmp.getNew()
local tArea = {cZ:getNew(0,1),
               cZ:getNew(1,1),
               cZ:getNew(0,0),
               cZ:getNew(1,0), 1, 0.5, 0, 1, nOH, false}

open("Complex surface interpolation")
size(W, H)
zero(0, 0)
updt(false) -- disable auto updates
for j = 1, 0, -gnAccuracy do
  for i = 0, 1, gnAccuracy do  
    local nV = cZ:getNew(i,j):getInterpolateBilinear(unpack(tArea))
    local nI = com.getClamp(com.getRound(nV*nTot, 1), 1, nTot)
    local r, g, b = col.getColorMap("interp", nI)
    scOpe:drawPointXY(i, j, colr(r, g, b))
  end; updt()
end

-- To prodice a PNG snapshot, uncomment the line below
-- save(com.stringGetChunkPath().."snapshot")

wait()
