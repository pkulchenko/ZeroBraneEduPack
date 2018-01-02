require("turtle")
local drw = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

io.stdout:setvbuf("no")

local W, H = 600, 400

open("Complex ballistics")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

local V0 = cmp.New(100,100):Print("Initial velocity: ","\n")
local P  = cmp.Convert("0+j0"):Print("Position        : ","\n")
local G  = cmp.Convert({0,-9.8}):Print("Gravity         : ","\n")
local V  = cmp.Convert(V0):Print("Moment velocity : ","\n")
local maxX, maxY, traJ = 0, 0, {cmp.New(P)}

while(P:getImag() >= 0) do
  V:Add(G); P:Add(V)
  traJ[#traJ+1] = P:getDupe()
  if(P:getReal() >= maxX) then maxX = P:getReal() end
  if(P:getImag() >= maxY) then maxY = P:getImag() end
end

local clGrn = colr(col.getColorGreenRGB())
local intX  = drw.newInterval("WinX", 0, maxX, 0, W)
local intY  = drw.newInterval("WinY", -100, maxY, H, 0)
local trAj  = drw.newTracer("Trajectory"):setInterval(intX, intY)

line(0, intY:Convert(0):getValue(), W, intY:Convert(0):getValue())

for ID = 1, #traJ do
  wait(0.1)
  local cPos = traJ[ID]
  local Re, Im = cPos:getReal(), cPos:getImag()
  trAj:putValue(Re, Im):Draw(clGrn)
  text(tostring(cPos),0,intX:Convert(Re):getValue(),intY:Convert(Im):getValue())
  updt()
end

