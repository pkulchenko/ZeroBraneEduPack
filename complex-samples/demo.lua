require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

io.stdout:setvbuf("no")

local W, H = 800, 400

open("Complex ballistics")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

local drwText = true

local V0 = cmp.New(200,200):Print("Initial velocity: ","\n")
local P  = cmp.Convert("0+j0"):Print("Position        : ","\n")
local G  = cmp.Convert({0,-9.8}):Print("Gravity         : ","\n")
local V  = cmp.Convert(V0):Print("Moment velocity : ","\n")
local minX, maxX, minY, maxY, traJ = 0, 0, 0, 0, {cmp.New(P)}

while(P:getImag() >= 0) do
  V:Add(G); P:Add(V)
  traJ[#traJ+1] = P:getNew()
  local xP, yP = P:getParts()
  if(xP >= maxX) then maxX = xP end
  if(yP >= maxY) then maxY = yP end
  if(xP <= minX) then minX = xP end
  if(yP <= minY) then minY = yP end
end

local clGrn = colr(col.getColorGreenRGB())
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local trAj  = crt.New("tracer","Trajectory"):setInterval(intX, intY)
local zEro  = intY:Convert(0):getValue()

line(0, zEro, W, zEro)

for ID = 1, #traJ do
  wait(0.05)
  local cPos = traJ[ID]
  local Re, Im = cPos:getParts()
  trAj:putValue(Re, Im):Draw(clGrn)
  if(drwText) then
    text(tostring(cPos),0,intX:Convert(Re):getValue(),intY:Convert(Im):getValue()) end
  updt()
end

wait()
