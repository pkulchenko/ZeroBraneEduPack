require("wx")
require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

io.stdout:setvbuf("no")

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

local  W,  H = 400, 400
local dX, dY = 1,1
local xySize = 3
local greyLevel  = 200
local minX, maxX = -20, 20
local minY, maxY = -20, 20
local intX  = crt.newInterval("WinX", minX, maxX, 0, W)
local intY  = crt.newInterval("WinY", minY, maxY, H, 0)
local clOrg = colr(col.getColorBlueRGB())
local clRel = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clMgn = colr(col.getColorMagenRGB())

local function drawCoordinateSystem(w, h, ix, iy, dx, dy, mx, my, cc, cu)
  local xe, ye = 0, 0
  for x = 0, mx, dx do
    local xp = intX:Convert( x):getValue()
    local xm = intX:Convert(-x):getValue()
    if(x == 0) then xe = xp
    else  pncl(cu); line(xp, 0, xp, h); line(xm, 0, xm, h) end
  end
  for y = 0, my, dx do
    local yp = intY:Convert( y):getValue()
    local ym = intY:Convert(-y):getValue()
    if(y == 0) then ye = yp
    else  pncl(cu); line(0, yp, w, yp); line(0, ym, w, ym) end
  end; pncl(cc)
  line(xe, 0, xe, h); line(0, ye, w, ye)
end

local function drawComplex(C, Ix, Iy, Cl)
  local x = Ix:Convert(C:getReal()):getValue()
  local y = Iy:Convert(C:getImag()):getValue()
  pncl(Cl); rect(x-xySize,y-xySize,2*xySize+1,2*xySize+1)
end

local function drawComplexLine(S, E, Ix, Iy, Cl)
  local x1 = Ix:Convert(S:getReal()):getValue()
  local y1 = Iy:Convert(S:getImag()):getValue()
  local x2 = Ix:Convert(E:getReal()):getValue()
  local y2 = Iy:Convert(E:getImag()):getValue()
  pncl(Cl); line(x1, y1, x2, y2)
end

logStatus("Create a primary ray to intersect using the left mouse button (BLUE)")
logStatus("Create a secondary ray to intersect using the right mouse button (RED)")
logStatus("By clicking on the chart the point selected will be drawn")
logStatus("On the coordinate system the OX and OY axises are drawn in black")
logStatus("The distance between every grey line on X is: "..tostring(dX))
logStatus("The distance between every grey line on Y is: "..tostring(dY))
logStatus("Press escape to clear all rays and refresh the coordinate system")

open("Complex rays intersection demo")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

drawCoordinateSystem(W, H, intX, intY, dX, dY, maxX, maxY, clBlk, clGry)

cRay1, cRay2, drw = {}, {}, true

while true do
  wait(0.2)
  local key = char()
  local lx, ly = clck('ld')
  local rx, ry = clck('rd')
  if(lx and ly and #cRay1 < 2) then
    lx = intX:Convert(lx,true):getValue()
    ly = intY:Convert(ly,true):getValue()
    local C = cmp.New(lx, ly)
    cRay1[#cRay1+1] = C
    drawComplex(C, intX, intY, clOrg)
    if(#cRay1 == 2) then drawComplexLine(cRay1[1], cRay1[2], intX, intY, clOrg) end
  elseif(rx and ry and #cRay2 < 2) then
    rx = intX:Convert(rx,true):getValue()
    ry = intY:Convert(ry,true):getValue()
    local C = cmp.New(rx, ry)
    drawComplex(C, intX, intY, clRel); cRay2[#cRay2+1] = C
    if(#cRay2 == 2) then drawComplexLine(cRay2[1], cRay2[2], intX, intY, clRel) end
  end
  if(drw and #cRay1 == 2 and #cRay2 == 2) then
    local int, nT, nU, cR, cS, XX = cmp.Intersect(cRay1[1], cRay1[2], cRay2[1], cRay2[2])
    if(int) then
      drawComplex(XX, intX, intY, clMgn)
      logStatus("The complex intersection is "..tostring(XX))
    end; drw = false
  end
  if(key == 27) then -- The user hits esc
    wipe(); drw = true
    cRay1[1], cRay1[2] = nil, nil
    cRay2[1], cRay2[2] = nil, nil
    drawCoordinateSystem(W, H, intX, intY, dX, dY, maxX, maxY, clBlk, clGry)
  end
  updt()
end

wait();
