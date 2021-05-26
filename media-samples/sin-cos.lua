require("turtle")
local cmp = require("complex")
local col = require("colormap")
local crt = require("chartmap")
local sig = require("signals")

local scrShot
local xySize = 3
local dX, dY = 1,1
local greyLevel  = 200
local  W,  H = 1800, 800
local minX, maxX = -110, 110
local minY, maxY = -50, 50
local clBlu = colr(col.getColorBlueRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clOrg = colr(col.getColorOrangeRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clGrn = colr(col.getColorGreenRGB())
local clMgn = colr(col.getColorMagenRGB())
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local scOpe = crt.New("scope"):setInterval(intX, intY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setBorder():setDelta(dX, dY)
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

local function getTable()
  return {
    oS = cmp.getNew(),
    oE = cmp.getNew(),
    oT = cmp.getNew(),
    bD = false,
    tR = crt.New("tracer","Wave"):setInterval(intX,intY):Cache(450):setSizeVtx(1)
  }
end

local w1, d1 = sig.New("wiper",25, 0.02,  0, 0.1):setOrg(-60, 25), getTable()
local w2, d2 = sig.New("wiper",25, 0.02, 90, 0.1):setOrg(-60,-25), getTable()

local function updtShot(w, d)
  local vTip = w:Update():getTip()
  d.oS:Set(d.oE); d.oE:Set(vTip)
  if(not d.bD) then d.bD = true else
    d.oE:Action("ab", d.oS, clMgn)
    scrShot = snap()
  end
end

local function drawWiper(w, d, c)
  local vTip = w:Update():getTip()
  d.oT:Set(vTip):ProjectRay(oDwn, vDwn)
  w:Draw("ab", clRed)
  d.tR:Move(2):Write(0, d.oT:getImag()):Draw(c)
  d.oT:Action("xy", clBlu)
  d.oT:Action("ab", vTip, clBlu)
  d.oE:Action("xy", clBlu)
end

if(w1 and w2) then
  open("FFT vector wiper graphing")
  size(W, H); zero(0, 0)

  updt(false) -- disable auto updates
  local cS, cE = cmp.getNew(), cmp.getNew()  
  scOpe:Draw(true, true, true)
  scOpe:setColorOrg(clBlk)
  scOpe:setColorDir(clBlk)
  cS:Set(minX,  25); cE:Set(maxX,  25)
  scOpe:drawComplexLine(cS, cE)
  cS:Set(minX, -25); cE:Set(maxX, -25)
  scOpe:drawComplexLine(cS, cE)

  scOpe:drawComplexText(cS:Set(minX+10,  25), "SIN(X)", 0)
  scOpe:drawComplexText(cS:Set(minX+10, -25), "COS(X)", 0)
  updt()
  
  scrShot = snap() -- store snapshot

  while(true) do
    undo(scrShot)
    updtShot(w1, d1)
    updtShot(w2, d2)
    drawWiper(w1, d1, clOrg)
    drawWiper(w2, d2, clGrn)
    updt(); wait(0.001)
  end
  
  wait()
else
  print("Remove the comment in front of FFT wiper generator")
end

