require("turtle")

local common   = require("common")
local colormap = require("colormap")
local chartmap = require("chartmap")

common.logStatus("Number PI     : "..tostring(common.getCall("pi", 100)))
common.logStatus("Exponent base : "..tostring(common.getCall("exp", 100)))
common.logStatus("Golden ratio  : "..tostring(common.getCall("phi", 100)))
common.logStatus("Something     : "..tostring(common.getCall("lol", 100)))

function approxPHI(itr, top)
  if(top == itr) then return 1 end
  return (1 + (1 / approxPHI(itr+1, top)))
end

function outRet(itr)
  return approxPHI(0, itr)
end

common.setCall("Custom user functional",approxPHI, outRet)

common.logStatus("Custom estimator example: "..common.getCall("Custom user functional", 100))


local logStatus = common.logStatus
local  W,  H = 800, 400
local minX, maxX = 0, 25
local minY, maxY = 0, 2.5
local intX  = chartmap.New("interval","WinX", minX, maxX, 0, W)
local intY  = chartmap.New("interval","WinY", minY, maxY, H, 0)
local trEst = chartmap.New("tracer","Est"):setInterval(intX, intY)
local scEst = math.floor(intY:Convert(outRet(maxX)):getValue())
local clBlu = colr(colormap.getColorBlueRGB())
local clRed = colr(colormap.getColorRedRGB())

open("Functional extimator")
size(W,H); zero(0, 0); updt(false) -- disable auto updates

pncl(clBlu); line(0, scEst, W, scEst)

for I = minX, maxX do
  trEst:putValue(I, common.getCall("Custom user functional", I)):Draw(clRed)
  local xc, yc = trEst:getChart()
  local xv, yv = trEst:getValue()
  local ang = ((I==0) and 0 or 90)
  local adjx = ((I==0) and -2 or 7)
  local adjy = ((I==0) and 0 or 7)
  text(("%10.9f"):format(yv),ang,xc-adjx, yc-adjy)
  
  updt()
end

wait()
