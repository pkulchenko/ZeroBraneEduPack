require("turtle")

-- For more shapes please refer to: http://www.conwaylife.com/patterns/all.zip

local life = require("lifelib")

io.stdout:setvbuf("no")

function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

local function TurtleDraw(F,Arg)
  local sx = 0
  local sy = 18
  local fx = F:getW()
  local fy = F:getH()
  local dx = (Arg[1]-sx)/fx
  local dy = (Arg[2]-sy)/fy
  local x,y = 0,0
  local i = 1
  local Arr = F:getArray()
  wipe()
  text("Generation: "..(F:getGenerations() or "N/A").." {"..tostring(Arg[3])..
        ","..tostring(Arg[4]).."} > "..tostring(Arg[5]),0,0,0)
  while(Arr[i]) do
    local v = Arr[i]
    local j = 1
          x = 0
    while(v[j]) do
      if(v[j] == 1) then
        rect(x+sx,y+sy,dx,dy,0)
      end
      x = x + dx
      j = j + 1
    end
    y = y + dy
    i = i + 1
  end
end

local Arg = {500, 220,0,0}

local F = life.makeField(80,50)
      F:regDraw("turtle",TurtleDraw)

open("Game Of Life")
size(Arg[1],Arg[2])
updt(false)
zero(0, 0)

life.charAliv("o"); life.charDead("b")
life.shapesPath("conwaylife-samples/shapes")

local gg1 = life.makeShape("gosperglidergun","file","rle")
local gg2 = life.makeShape("gosperglidergun","file","rle")

if(gg1 and gg2) then
  -- Used for mouse clicks and keys
  Arg[3] = 10
  Arg[4] = 57
  Arg[5] = ""

  gg1:rotR():mirrorXY(true,true)
  gg2:rotR():mirrorXY(false,true)
  F:setShape(gg1,1,1):setShape(gg2,50,1)
  
  F:drwLife("turtle",Arg)

  while true do
    Arg[5] = char()
    F:drwLife("turtle",Arg):evoNext()
    updt()
  end
  
end
