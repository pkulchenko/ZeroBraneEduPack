local turtle  = require("turtle")
local complex = require("complex")
local common  = require("common")
local col     = require("colormap")
local crt     = require("chartmap")

local dX,dY = 1,1
local W , H = 800, 600
local minX, maxX = -4, 8
local minY, maxY = -2, 8
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clB = colr(col.getColorBlueRGB())
local clR = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local p1 = complex.getNew(-3, 0) 
local p2 = complex.getNew(-2, 5) 
local p3 = complex.getNew( 7, 0)
local p4 = complex.getNew( 7, 7)
local scOpe = crt.New("scope"):setInterval(intX, intY):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setDelta(dX, dY)

-- These calls produce the same curve for interpolation length <n-samples>
-- The default curve interpolation sample count is 100
-- When you need the recursive version of the curve with De Casteljau's algorithm
-- local tS = complex.getBezierCurveCasteljau( p1, p2, ..., pn) < Uses the default interpolation count
-- local tS = complex.getBezierCurveCasteljau( p1, p2, ..., pn,n-samples)
-- local tS = complex.getBezierCurveCasteljau({p1, p2, ..., pn},n-samples)
-- If you need rational curve to apply weight to a control point you can use 
-- local tS = complex.getBezierCurveRational( p1, p2, ..., pn) < Uses the default interpolation count and ones as weights
-- local tS = complex.getBezierCurveRational( p1, p2, ..., pn,n-samples) < Uses ones as weights
-- local tS = complex.getBezierCurveRational({p1, p2, ..., pn},n-samples) < Uses ones as weights
-- local tS = complex.getBezierCurveRational({p1, p2, ..., pn},n-samples,c-weigths) < Uses ones as weights
-- To find the location among the curve for a given t [0..1] use
-- complex.getBezierCurvePointRational({p1, p2, ..., pn},n-samples,c-weigths)

local ns = 6 -- Amount of mid-samples to calculate the curve for
local mn = "Rational" -- The name of the algorithm being used
local nt = 0.35 -- Calculate one sample point for specific T [0..1]
local tw = {1,1,1,1} -- Control point weights for rational Bezier curves
local tp = {p1,p2,p3,p4} -- Curve control points array
local tS = complex["getBezierCurve"..mn](tp, ns, tw)
local cP = complex["getBezierCurvePoint"..mn](tp, nt)

if(tS) then
  common.logStatus("The distance between every grey line on X is: "..tostring(dX))
  common.logStatus("The distance between every grey line on Y is: "..tostring(dY))
  
  local function drawComplexLine(S, E, Cl)
    local x1 = intX:Convert(S:getReal()):getValue()
    local y1 = intY:Convert(S:getImag()):getValue()
    local x2 = intX:Convert(E:getReal()):getValue()
    local y2 = intY:Convert(E:getImag()):getValue()
    pncl(Cl); line(x1, y1, x2, y2)
  end; complex.setAction("ab", drawComplexLine)

  open("Complex Bezier curve")
  size(W,H); zero(0, 0); updt(false) -- disable auto updates

  scOpe:Draw(false, false, true, true)

  for iD = 1, (#tp - 1) do
    tp[iD]:Action("ab", tp[iD+1], clB)
    scOpe:drawComplexPoint(tp[iD], nil, true, 65)
  end; scOpe:drawComplexPoint(tp[#tp], nil, true, 65)

  for iD = 1, (#tS-1) do
    tS[iD]:Action("ab", tS[iD+1], clR)
    scOpe:drawComplexPoint(tS[iD])
    updt(); wait(0.02)
  end
  
  scOpe:drawComplexPoint(cP, colr(0,0,255), tostring(cP), -60);  updt()
  
  wait()
else
  common.logStatus("Your curve parameters are invalid !")
end
