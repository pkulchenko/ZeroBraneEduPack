require("turtle")

local pid = require("pidloop")
local col = require("colormap")

io.stdout:setvbuf("no")

local W, H  = 1200, 800

local minC, maxC = -150, 150
local To    = 0.001
local endTm = 0.1
local intX  = pid.newInterval("WinX",  0,endTm, 0, W)
local intY  = pid.newInterval("WinY",-10,150 , H, 0)
local APR   = pid.newUnit(To,{0.74,-0.114},{1.282,-0.98,0.258},"Hesitating plant"):Dump()
local PID   = pid.newControl(To,"Lin-QR"):Setup({0.825, 0.0036, 33.8, minC, maxC}):setStruct(true,false):Dump()

local trRef = pid.newTracer("Ref"):setInterval(intX, intY)
local trCon = pid.newTracer("Con"):setInterval(intX, intY)
local trPV  = pid.newTracer("PV" ):setInterval(intX, intY)

open("Trasition processes")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates
local curTm, yTx, dyTx = 0, 0, 15
local clRed = colr(col.getColorRedRGB())
local clGrn = colr(col.getColorGreenRGB())
local clBlu = colr(col.getColorBlueRGB())
local clBlk = colr(col.getColorBlackRGB())

text("( Blue ) System reference", 0, 0, yTx); yTx = yTx + dyTx
text("( Green ) Control signal", 0, 0, yTx); yTx = yTx + dyTx
text("( Black ) Plant uncontrolled step responce", 0, 0, yTx); yTx = yTx + dyTx
text("( Red ) Plant controlled step responce", 0, 0, yTx); yTx = yTx + dyTx

local pvv, con, ref = 0, 0, 100

curTm = 0
while(curTm <= endTm) do
  if(curTm > 0.1 * endTm) then con = 100 else con = 0 end
  wait(To)
  pvv = APR:Process(con):getOutput()
  trPV:putValue(curTm, pvv):Draw(clBlk)
  curTm = curTm + To; updt()
end; APR:Reset(); trPV:Reset(); wait(0.5)

-- wipe();

curTm, pvv = 0, 0
while(curTm <= endTm) do
  wait(To)
  if(curTm > 0.1 * endTm) then ref = 100 else ref = 0 end
  trRef:putValue(curTm, ref):Draw(clBlu)
  con = PID:Process(ref,pvv):getControl()
  trCon:putValue(curTm,con):Draw(clGrn)
  pvv = APR:Process(con):getOutput()
  trPV:putValue(curTm, pvv):Draw(clRed)
  print(ref.." > "..pvv.." > "..con)
  curTm = curTm + To; updt()
end
