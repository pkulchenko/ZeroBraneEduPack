require("wx")
require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")
local com = require("common")

io.stdout:setvbuf("no")

local logStatus = com.logStatus
local  W,  H = 400, 400
local dX, dY = 1,1
local xySize = 3
local greyLevel  = 200
local minX, maxX = -20, 20
local minY, maxY = -20, 20
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clOrg = colr(col.getColorBlueRGB())
local clRel = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clMgn = colr(col.getColorMagenRGB())

local function drawCoordinateSystem(w, h, dx, dy, mx, my)
  local xe, ye = 0, 0
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

local function drawComplex(C, Cl)
  local x = intX:Convert(C:getReal()):getValue()
  local y = intY:Convert(C:getImag()):getValue()
  pncl(Cl); rect(x-xySize,y-xySize,2*xySize+1,2*xySize+1)
end

local function drawComplexLine(S, E, Cl)
  local x1 = intX:Convert(S:getReal()):getValue()
  local y1 = intY:Convert(S:getImag()):getValue()
  local x2 = intX:Convert(E:getReal()):getValue()
  local y2 = intY:Convert(E:getImag()):getValue()
  pncl(Cl); line(x1, y1, x2, y2)
end

cmp.setAction("xy", drawComplex)
cmp.setAction("ab", drawComplexLine)

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

drawCoordinateSystem(W, H, dX, dY, maxX, maxY)

cRay1, cRay2, drw = {}, {}, true

while true do
  wait(0.2)
  local key = char()
  local lx, ly = clck('ld')
  local rx, ry = clck('rd')
  if(lx and ly and #cRay1 < 2) then -- Reverse the interval conversion polarity
    lx = intX:Convert(lx,true):getValue() -- It helps by converting x,y from positive integers to the interval above
    ly = intY:Convert(ly,true):getValue()
    local C = cmp.getNew(lx, ly)
    cRay1[#cRay1+1] = C; C:Act("xy", clOrg)
    if(#cRay1 == 2) then cRay1[1]:Act("ab", cRay1[2], clOrg) end
  elseif(rx and ry and #cRay2 < 2) then -- Reverse-convert x, y position to a complex number
    rx = intX:Convert(rx,true):getValue()
    ry = intY:Convert(ry,true):getValue()
    local C = cmp.getNew(rx, ry); C:Act("xy", clRel); cRay2[#cRay2+1] = C
    if(#cRay2 == 2) then cRay2[1]:Act("ab", cRay2[2], clRel) end
  end
  if(drw and #cRay1 == 2 and #cRay2 == 2) then
    local cD1, cD2 = (cRay1[2] - cRay1[1]), (cRay2[2] - cRay2[1])
    local suc, nT, nU, XX = cmp.getIntersectRayRay(cRay1[1], cD1, cRay2[1], cD2)
    if(suc) then XX:Act("xy", clMgn)
      local onOne = XX:isAmong(cRay1[1], cRay1[2])
      local onTwo = XX:isAmong(cRay2[1], cRay2[2])
      logStatus("The complex intersection is "..tostring(XX))
      logStatus("The point is "..(onOne and "ON" or "OFF").." the first line (BLUE)")
      logStatus("The point is "..(onTwo and "ON" or "OFF").." the second line (RED)")
    end; drw = false
  end
  if(key == 27) then -- The user hits esc
    wipe(); drw = true
    cRay1[1], cRay1[2] = nil, nil
    cRay2[1], cRay2[2] = nil, nil; collectgarbage()
    drawCoordinateSystem(W, H, dX, dY, maxX, maxY)
  end
  updt()
end

wait();
