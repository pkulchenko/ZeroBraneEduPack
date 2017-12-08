require("turtle")

-- For more shapes please refer to: http://www.conwaylife.com/patterns/all.zip

local life = require("lifelib")

io.stdout:setvbuf("no")

function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

local function TurtleDraw(F,...)
  local sx, sy, x, y, i = 0, 18, 0, 0, 1
  local fx, fy = F:getW(), F:getH()
  local Arr, tArg = F:getArray(), {...}
  local dx, dy = (tArg[1]-sx)/fx, (tArg[2]-sy)/fy
  wipe(); text("Generation: "..(F:getGenerations() or "N/A").." {"..tostring(tArg[3])..
        ","..tostring(tArg[4]).."} > "..tostring(tArg[5]),0,0,0)
  while(Arr[i]) do
    local v, j, x = Arr[i], 1, 0
    while(v[j]) do
      if(v[j] == 1) then
        rect(x+sx,y+sy,dx,dy,0)
      end
      x, j = (x + dx), (j + 1)
    end
    y, i = (y + dy), (i + 1)
  end
end

local W, H = 500, 220

local F = life.makeField(80,50):regDraw("turtle",TurtleDraw)

open("Game Of Life"); size(W, H)
updt(false); zero(0, 0)

life.shapesPath("conwaylife-samples/shapes")

life.charAliv("o"); life.charDead("b")
local gg1 = life.makeShape("gosperglidergun","file","rle")
life.charAliv("O"); life.charDead(".")
local gg2 = life.makeShape("gosperglidergun","file","cells")

if(gg1 and gg2) then
  -- Used for mouse clicks and keys
  local key1, key2, str = 10, 57, ""
  gg1:rotR():mirrorXY(true,true)
  gg2:rotR():mirrorXY(false,true)
  F:setShape(gg1,1,1):setShape(gg2,50,1)

  F:drwLife("turtle", W, H, key1, key2, str)

  while true do str = char()
    F:drwLife("turtle", W, H, key1, key2, str):evoNext(); updt()
  end

end
