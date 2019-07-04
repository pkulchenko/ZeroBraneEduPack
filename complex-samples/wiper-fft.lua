require("turtle")
local cmp = require("complex")
local col = require("colormap")
local crt = require("chartmap")
local sig = require("signals")

local xySize = 3
local dX, dY = 1,1
local greyLevel  = 200
local  W,  H = 1800, 800
local minX, maxX = -110, 110
local minY, maxY = -50, 50
local clBlu = colr(col.getColorBlueRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clGrn = colr(col.getColorGreenRGB())
local clMgn = colr(col.getColorMagenRGB())
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local scOpe = crt.New("scope"):setInterval(intX, intY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setBorder():setDelta(dX, dY)
local trWav = crt.New("tracer","Wave"):setInterval(intX,intY):setCache(500, true)
local vRgh = cmp.getNew(1,0)
local vDwn = cmp.getNew(0,(minY-maxY))
local oDwn = cmp.getNew(0,maxY)

local function drawComplexLine(S, E, Cl)
  local x1 = intX:Convert(S:getReal()):getValue()
  local y1 = intY:Convert(S:getImag()):getValue()
  local x2 = intX:Convert(E:getReal()):getValue()
  local y2 = intY:Convert(E:getImag()):getValue()
  pncl(Cl); line(x1, y1, x2, y2)
end

local function drawComplex(C, Cl)
  local x = intX:Convert(C:getReal()):getValue()
  local y = intY:Convert(C:getImag()):getValue()
  pncl(Cl); rect(x-xySize,y-xySize,2*xySize+1,2*xySize+1)
end

cmp.setAction("xy", drawComplex)
cmp.setAction("ab", drawComplexLine)

local w = sig.New("wiper",20, 0, 0.1):setOrigin(-60,0)
local n, c, d, f = 15, w:getFreq(), w:getFreq(), w
for i = 1, n do
  local k = (2 * i + 1)
  f = f:addNext(w:getAbs()*(1/k), w:getPhase(), w:getFreq()*k)
end

open("FFT vector wiper graphing")
size(W, H); zero(0, 0)

updt(false) -- disable auto updates
scOpe:Draw(true, true, true)
local scrShot = snap() -- store snapshot
local oS, oE, bD = cmp.getNew(), cmp.getNew(), false

while(true) do
  undo(scrShot); w:Update()
  local vTip = w:getTip()
  oS:Set(oE); oE:Set(vTip)
  if(not bD) then bD = true else
    oE:Action("ab", oS, clMgn)
  end;
  scrShot = snap() -- Below that point items are deleted from the frame
  local xX = cmp.getIntersectRayRay(vTip, vRgh, oDwn, vDwn)
  if(xX) then
    xX:Action("xy", clBlu)
    xX:Action("ab", vTip, clBlu)
    oE:Action("xy", clBlu)
    w:Draw(clRed)
    trWav:movCache(2):putValue(0, xX:getImag()):Draw(clBlu)
  end
  updt(); wait(0.001)
end

wait()
