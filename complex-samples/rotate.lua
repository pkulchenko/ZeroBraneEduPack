require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

io.stdout:setvbuf("no")

local W ,  H = 800, 800
local dX, dY =  1 , 1
local gAlp   = 200
open("Complex rotation")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

local intX = crt.New("interval","WinX", -50, 50, 0, W)
local intY = crt.New("interval","WinY", -50, 50, H, 0)

local bxl, bxh = intX:getBorderIn()
local byl, byh = intY:getBorderIn()
local aAng, dA, nRad = 0, 15, 30
local C = cmp.New(nRad, 0)
local D = C:getNew()

-- Allocate colors
local clGrn = colr(col.getColorGreenRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(col.getColorPadRGB(gAlp))
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

cmp.Draw("ang", drawComplex)

drawCoordinateSystem(W, H, dX, dY, bxh, byh)

while(aAng < 360) do
  C:getRotRad(cmp.ToRadian(aAng)):Draw("ang",aAng,true)
  D:Set(C):RotRad(cmp.ToRadian(aAng)):Draw("ang",aAng)
  D:Set(C):setAngRad(cmp.ToRadian(aAng)):Draw("ang",aAng)
  C:getRotDeg(aAng):Draw("ang",aAng)
  D:Set(C):RotDeg(aAng):Draw("ang",aAng)
  D:Set(C):setAngDeg(aAng):Draw("ang",aAng)
  aAng = aAng + dA
  updt(); wait(0.1)
end

wait();
