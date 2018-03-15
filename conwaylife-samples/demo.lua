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
        ","..tostring(tArg[4]).."} ("..tostring(tArg[6])..") > "..tostring(tArg[5]),0,0,0)
  while(Arr[i]) do
    local v, j, x = Arr[i], 1, 0
    while(v[j]) do
      if(v[j] == 1) then rect(x+sx,y+sy,dx,dy,0) end
      x, j = (x + dx), (j + 1)
    end
    y, i = (y + dy), (i + 1)
  end
end

local W, H, ID = 1000, 500, 1

local tParam = {
  -- Init via structure
  -- Init va string
  {Sta = "ob", Arg = {    
      "24bo11b$22bobo11b$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o14b$2o8bo3bob2o4bobo11b$10bo5bo7bo11b$11bo3bo20b$12b2o!",
      "string","rle", }},
  -- Init via file
  {Sta = "O.", Arg = {"gosperglidergun","file","cells" }},
  {Sta = "ob", Arg = {"gosperglidergun","file","rle"   }},
  {Sta = "*.", Arg = {"gosperglidergun","file","lif105"}},
  {Sta = "*.", Arg = {"gosperglidergun","file","lif106"}}
}

-- Create a field where shapes must be stamped inside.
-- Register a graphic interpretator of the data inside
local F = life.newField(200, 120)

if(F) then F:regDraw("turtle",turtleDraw)
  -- Set our relative shapes location definitions
  life.shapesPath("conwaylife-samples/shapes")

  -- Set the alive and dead character for decoding the file
  life.charAliv(tParam[ID].Sta:sub(1,1))
  life.charDead(tParam[ID].Sta:sub(2,2))

  -- Create a stamp using the desired shape
  local S = life.newStamp(unpack(tParam[ID].Arg))

  if(S) then
    -- Open ourselves a lovely window
    open("Game Of Life"); size(W, H)
    updt(false); zero(0, 0)
    
    --[[
     * You can use the shape object to make a stamp
     * of a certain shape over the field. In ths case
     * I am inserting a glider gum in various
     * orientations and locations, so I can make two stamps
     * over the filed "F" using the gun current stamp. 
    ]]
    F:setShape(S:rotR():mirrorXY(true,false),1,1)
    F:setShape(S:mirrorXY(true,false),190,1)
    
    -- Draw the field using the graphic interpretator function
    F:drwLife("turtle", W, H, key1, key2, str)

    while true do
      local key = char()
      local lx, ly = clck('ld')
      if(key == 315) then nTime = common.getClamp(nTime + 0.01, 0, 0.5) end
      if(key == 317) then nTime = common.getClamp(nTime - 0.01, 0, 0.5) end
      if(key == 32) then
        S:Reset(); F:Reset()
        F:setShape(S:rotR():mirrorXY(true,false),1,1)
        F:setShape(S:mirrorXY(true,false),190,1)
      end
      F:drwLife("turtle", W, H, lx, ly, key, nTime):evoNext()
      updt(); if(nTime and nTime > 0) then wait(nTime) end
    end
  else
    common.logStatus("Shape stamp is invalid or missing !")
  end
else
  common.logStatus("Field is invalid or missing !")
end
