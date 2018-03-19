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

local drgCoef = 2
local nMarg   = 30
local drwText = true
local V0 = cmp.getNew(200,200):Print("Initial velocity : ","\n")
local P  = cmp.convNew("0+j0"):Print("Position         : ","\n")
local G  = cmp.convNew({0,-9.8}):Print("Gravity          : ","\n")
local V  = cmp.convNew(V0):Print("Moment velocity  : ","\n")
local Wv = cmp.convNew(-4,2):Print("Wind velocity    : ","\n")
local minX, maxX, minY, maxY, traJ = 0, 0, 0, 0, {cmp.getNew(P)}

while(P:getImag() >= 0) do
  V:Add(G)                         -- Apply gravity
  V:Add(V:getUnit():Mul(-drgCoef)) -- Calculate drag
  V:Add(Wv)                        -- Add wind velocity
  P:Add(V)                         -- Calcilate position
  traJ[#traJ+1] = P:getNew()
  local xP, yP = P:getParts()
  if(xP >= maxX) then maxX = xP end
  if(yP >= maxY) then maxY = yP end
  if(xP <= minX) then minX = xP end
  if(yP <= minY) then minY = yP end
end

local oX,aN = cmp.getNew(1), 0
local clGrn = colr(col.getColorGreenRGB())
local intX  = crt.New("interval","WinX", minX, maxX,   nMarg, W-nMarg)
local intY  = crt.New("interval","WinY", minY, maxY, H-2*nMarg,   0)
local trAj  = crt.New("tracer","Trajectory"):setInterval(intX, intY)
local zEro  = intY:Convert(0):getValue()

line(0, zEro, W, zEro)

for ID = 1, #traJ do wait(0.05)
  local cPos = traJ[ID]
  if(traJ[ID+1]) then
    aN = (traJ[ID+1] - traJ[ID]):getAngDegVec(oX)-90 end
  local Re, Im = cPos:Round(0.001):getParts()
  trAj:putValue(Re, Im):Draw(clGrn)
  if(drwText) then intX:Convert(Re); intY:Convert(Im)
    text(tostring(cPos),aN,intX:getValue(),intY:getValue()) end
  updt()
end

wait()
