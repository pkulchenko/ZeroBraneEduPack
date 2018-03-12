require("turtle")

-- For more shapes please refer to: http://www.conwaylife.com/patterns/all.zip

local life   = require("lifelib")
local common = require("common")
local nTime  = 0.03
io.stdout:setvbuf("no")

local function turtleDraw(F,...)
  local sx, sy, x, y, i = 0, 18, 0, 0, 1
  local fx, fy = F:getW(), F:getH()
  local Arr, tArg = F:getArray(), {...}
  local dx, dy = (tArg[1]-sx)/fx, (tArg[2]-sy)/fy
  wipe(); text("Generation: "..(F:getGenerations() or "N/A").." {"..tostring(tArg[3])..
        ","..tostring(tArg[4]).."} > "..tostring(tArg[5]),0,0,0)
  while(Arr[i]) do
    local v, j, x = Arr[i], 1, 0
    while(v[j]) do
      if(v[j] == 1) then rect(x+sx,y+sy,dx,dy,0) end
      x, j = (x + dx), (j + 1)
    end
    y, i = (y + dy), (i + 1)
  end
end

local W, H = 1000, 500

-- Create a field where shapes must be stamped inside.
-- Register a graphic interpretator of the data inside
local F = life.newField(150, 85):regDraw("turtle",turtleDraw)

if(F) then
  -- Set our relative shapes location definitions
  life.shapesPath("conwaylife-samples/shapes")

  -- Set the alive and dead character for decoding the file
  life.charAliv("o"); life.charDead("b")

  -- Create a stamp using the desired shape
  local S = life.newStamp("gosperglidergun","file","rle")

  if(S) then
    -- Open ourselves a lovely window
    open("Game Of Life"); size(W, H)
    updt(false); zero(0, 0)
    
    -- Used for mouse clicks and keys
    local key1, key2, str = 10, 57, ""
    --[[
     * You can use the shape object to make a stamp
     * of a certain shape over the field. In ths case
     * I am inserting a glider gum in various
     * orientations and locations, so I can make two stamps
     * over the filed "F" using the gun current stamp. 
    ]]
    F:setShape(S:rotR():mirrorXY(true,false),1,1)
    F:setShape(S:mirrorXY(true,false),130,1)
    
    -- Draw the field using the graphic interpretator function
    F:drwLife("turtle", W, H, key1, key2, str)

    while true do str = char()
      F:drwLife("turtle", W, H, key1, key2, str):evoNext()
      updt(); if(nTime and nTime > 0) then wait(nTime) end
    end
  else
    common.logStatus("Shape stamp is invalid or missing !")
  end
else
  common.logStatus("Field is invalid or missing !")
end
