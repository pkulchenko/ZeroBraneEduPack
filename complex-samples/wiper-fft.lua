require("turtle")
local cmp = require("complex")
local col = require("colormap")
local crt = require("chartmap")

local xySize = 3
local dX, dY = 1,1
local greyLevel  = 200
local  W,  H = 800, 800
local minX, maxX = -50, 50
local minY, maxY = -50, 50
local clBlu = colr(col.getColorBlueRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clMgn = colr(col.getColorMagenRGB())
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local scOpe = crt.New("scope"):setInterval(intX, intY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setBorder():setDelta(dX, dY)

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

local function makeWiper(nR, nP, nF)
  local mD = os.clock() -- Old time
  local mT = os.clock() -- New time
  local mP = (tonumber(nP) or 0)
  local mR = math.abs(tonumber(nR) or 0)
  local mF = math.abs(tonumber(nF) or 0)
  local mW = (2 * math.pi * mF)
  local mV = cmp.getNew():Euler(mR, cmp.toRad(mP))
  local mO = cmp.getNew()
  local mN -- Next wiper attached to the tip of the prevoious
  local self = {}
  function self:getOrigin()
    return (mO and mO:getNew() or nil)
  end
  function self:setOrigin(...)
    mO:Set(...); return self
  end
  function self:getVector()
    return mV:getNew()
  end
  function self:Update()
    mD, mT = mT, os.clock()
    mV:RotRad(mW * (mT - mD))
    if(mN) then
      mN:Update()
    end; return self
  end
  function self:Draw()
    local vT = mO:getAdd(mV)
    mO:Action("ab", vT, clRed);
    if(mN) then
      mN:setOrigin(vT)
      mN:Draw()
    end
    return self
  end
  function self:getVertex(wV)
    local nV = math.floor(tonumber(wV) or 0)
          nV = (nV > 0 and nV or 0)
    local wC, vT, ID = self, mO:getNew(), 1
    while(ID <= nV and wC) do
      vT:Add(wC:getVector())
      wC, ID = wC:getNext(), (ID + 1)
    end; return vT
  end
  function self:getTip()
    local wC, vT = self, mO:getNew()
    while(wC) do -- Iterate as a list of pointers
      vT:Add(wC:getVector())
      wC = wC:getNext()
    end; return vT
  end
  function self:setNext(...)
    mN = makeWiper(...); return self
  end
  function self:addNext(...)
    self:setNext(...); return mN
  end
  function self:cpyNext()
    local wR, wP = mV:getPolar()
    self:setNext(mR, mP, mF); return mN
  end
  function self:frqNext(wF)
    self:setNext(mR, mP, wF); return mN
  end
  function self:getNext()
    return mN
  end
  return self
end

local w = makeWiper(10, 0, 0.2)
      w:frqNext(0.4):frqNext(0.6):frqNext(0.8)

open("FFT vector wiper graphing")
size(W, H); zero(0, 0)

updt(false) -- disable auto updates
scOpe:Draw(true, true, true)
local scrShot = snap() -- store snapshot
local oS, oE, bD = cmp.getNew(), cmp.getNew(), false

while(true) do
  undo(scrShot); w:Update()
  oS:Set(oE); oE:Set(w:getTip())
  if(not bD) then bD = true else
    oE:Action("ab", oS, clMgn)
  end; scrShot = snap()
  oE:Action("xy", clBlu)
  w:Draw(); updt(); wait(0.001)
end

wait()
