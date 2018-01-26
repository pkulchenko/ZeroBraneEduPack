require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

io.stdout:setvbuf("no")

local W, H = 800, 800

open("Complex rotation")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

local intX = crt.New("interval","WinX", -50, 50, 0, W)
local intY = crt.New("interval","WinY", -50, 50, H, 0)

local aAng, dA, nRad = 0, 15, 30
local C = cmp.New(nRad, 0)
local D = C:getNew()

-- Allocate colors
local clGrn = colr(col.getColorGreenRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local x0, y0 = intX:Convert(0):getValue(), intY:Convert(0):getValue()

-- Draw the coordinate system
line(0, y0, W, y0); line(x0, 0, x0, H)

local function drawComplex(C,A,T)
  local r = C:getRound(0.1)
  local x = intX:Convert(r:getReal()):getValue()
  local y = intY:Convert(r:getImag()):getValue()
  pncl(clGrn); line(x0, y0, x, y)
  pncl(clRed); rect(x-2,y-2,5,5)
  if(T) then pncl(clBlk); text(A.." > "..tostring(r),r:getAngDeg(),x,y) end
end

while(aAng < 360) do
  drawComplex(C:getRotRad(cmp.ToRadian(aAng)),aAng,true)
  drawComplex(D:Set(C):RotRad(cmp.ToRadian(aAng)),aAng)
  drawComplex(D:Set(C):setAngRad(cmp.ToRadian(aAng)),aAng)
  drawComplex(C:getRotDeg(aAng),aAng)
  drawComplex(D:Set(C):RotDeg(aAng),aAng)
  drawComplex(D:Set(C):setAngDeg(aAng),aAng)
  aAng = aAng + dA
  updt(); wait(0.1)
end

wait();
