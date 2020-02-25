require("turtle")
local crt = require("chartmap")
local col = require("colormap")
local com = require("common")

local  W,  H = 1200, 400
local dX, dY = 4, 0.12
local greyLevel  = 200
local minX, maxX = -180, 180
local minY, maxY = -1.2, 1.2
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clBlu = colr(col.getColorBlueRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGrn = colr(col.getColorGreenRGB())
local clYel = colr(col.getColorYellowRGB())
local clCya = colr(col.getColorCyanRGB())
local clMag = colr(col.getColorMagenRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clMgn = colr(col.getColorMagenRGB())
local scOpe = crt.New("scope"):setInterval(intX, intY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setBorder():setDelta(dX, dY)
local tF, gnD2R   = {}, (math.pi / 180)

local getAngNorm = com.getAngNorm

local function getSign(nN)
  return (((nN > 0) and 1) or ((nN < 0) and -1) or 0)
end

local function getRampNorm(nP)
  local nN = getAngNorm(nP)
  local nA, nM = -getAngNorm(nN + 180), math.abs(nN)  
  return (((nM > 90) and nA or nN) / 90)
end

local tT, tR, tO = {0, 45,90,135,180,-180,-135,-90,-45,-0}, {}, {}

tF[1] = {function(R, H)
  local nN = getAngNorm(R - H)  
  return ((math.abs(nN) == 180) and 0 or getSign(nN))
end, clBlu}

tF[2] = {function(R, H)
  return math.sin(gnD2R * getAngNorm(R - H))
end, clRed}

tF[3] = {function(R, H)
  return getRampNorm(R - H)
end, clGrn}

tF[4] = {function(R, H)
  local nP = getAngNorm(R - H)
  local nN = getRampNorm(R - H + 90)
  return getSign(nP) * math.sqrt(1 - nN^2)
end, clCya}

tF[5] = {function(R, H)
  local nP = getRampNorm(R - H)
  return (getSign(nP) * math.abs(nP)^0.5)
end, clMag}

tF[6] = {function(R, H)
  local nM = 10 -- Change this to control exp slope
  local nR = getRampNorm(R - H)
  local nA = nM * math.abs(nR)
  local nV = 1 - math.exp(-nA)
  local nK = 1 - math.exp(-nM)
  return nV * getSign(nR) / nK
end, clYel}

for r = -180, 180 do table.insert(tR, r) end

open("Piston internal signals. Sign (BLUE), sine-wave (RED), tiangular (GREEN), circle (CYAN), root (MAGEN) and exp (YELLOW)")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

for i = 1, #tT do local h = tT[i]; wipe()
  com.tableClear(tO); scOpe:Draw(true, true, true)
  for k = 1, #tF do
    for j = 1, #tR do tO[j] = tF[k][1](tR[j], tT[i]) end
    scOpe:setColorDir(tF[k][2]):drawGraph(tO, tR)
  end
  text("Testing header ID "..("%3d"):format(i).." origin at "..("%3d"):format(h),0,0,0)
  updt(); wait(0.2)
end

wait()