local turtle  = require("turtle")
local complex = require("complex")
local common  = require("common")
local col     = require("colormap")
local crt     = require("chartmap")

local dX,dY = 1,1
local W , H = 600, 400
local minX, maxX = -4, 8
local minY, maxY = 0, 8
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clB = colr(col.getColorBlueRGB())
local clR = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local p1 = complex.getNew(-3,0) 
local p2 = complex.getNew(-2,5) 
local p3 = complex.getNew(7,0)
local p4 = complex.getNew(7,7)
local crSys = crt.New("coordsys"):setInterval(intX, intY):setBorder(minX, maxX, minY, maxY)
      crSys:setSize(W, H):setColor(clBlk, clGry):setDelta(dX, dY)

local tK = {"n","N","cnt","Cnt"}
local ik = 3 -- 1..#tK
-- These are all the same
-- local tS = complex.getBezierCurve(p1,p2,p3,p4)
-- local tS = complex.getBezierCurve(p1,p2,p3,p4,100)
local tS = complex.getBezierCurve({[tK[ik]]=100,p1,p2,p3,p4})

common.logStatus("The distance between every grey line on X is: "..tostring(dX))
common.logStatus("The distance between every grey line on Y is: "..tostring(dY))

if(tS) then
  local function drawComplexLine(S, E, Cl)
    local x1 = intX:Convert(S:getReal()):getValue()
    local y1 = intY:Convert(S:getImag()):getValue()
    local x2 = intX:Convert(E:getReal()):getValue()
    local y2 = intY:Convert(E:getImag()):getValue()
    pncl(Cl); line(x1, y1, x2, y2)
  end; complex.setAction("ab", drawComplexLine)

  open("Complex Bezier curve")
  size(W,H); zero(0, 0); updt(false) -- disable auto updates

  crSys:Draw(true, true, true)

  p1:Action("ab", p2, clB)
  p2:Action("ab", p3, clB)
  p3:Action("ab", p4, clB)

  for ID = 1, (#tS-1) do
    tS[ID][1]:Action("ab", tS[ID+1][1], clR)
    updt(); wait(0.02)
  end 

  wait()
else
  common.logStatus("Your curve parameter are invalid !")
end
