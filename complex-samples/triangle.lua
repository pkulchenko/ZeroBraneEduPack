local turtle  = require("turtle")
local complex = require("complex")
local common  = require("common")
local col     = require("colormap")
local crt     = require("chartmap")

local dX,dY = 1,1
local W , H = 600, 600
local minX, maxX = -10, 10
local minY, maxY = -10, 10
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clB = colr(col.getColorBlueRGB())
local clR = colr(col.getColorRedRGB())
local clM = colr(col.getColorMagenRGB())
local clC = colr(col.getColorCyanRGB())
local clY = colr(col.getColorYellowRGB())
local clBlk = colr(col.getColorBlackRGB())
local scOpe = crt.New("scope"):setInterval(intX, intY):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setDelta(dX, dY)
      
local cO = complex.getNew()
local tV = {cO:getNew(3,4), cO:getNew(-5,1), cO:getNew(3,-7)}
if(tV) then
  
  common.logStatus("The distance between every grey line on X is: "..tostring(dX))
  common.logStatus("The distance between every grey line on Y is: "..tostring(dY))

  open("Complex regular polygon")
  size(W,H); zero(0, 0); updt(false) -- disable auto updates

  local cM = cO:Mean(tV); for i = 1, #tV do tV[i]:Sub(cM) end
  scOpe:Draw(true, true, true):drawComplexPolygon(tV)
  scOpe:drawComplex(cO:AltitudeCenter(tV))
  scOpe:setColorPos(clB):drawComplex(cO:MedianCenter(tV))
  scOpe:setColorPos(clM):drawComplex(cO:InnerCircleCenter(tV))
  scOpe:setColorPos(clC):drawComplex(cO:OuterCircleCenter(tV))
  scOpe:setColorPos(clY):drawComplex(cO:MidcircleCenter(tV))
  wait()
else
  common.logStatus("Your poly parameters are invalid !")
end
