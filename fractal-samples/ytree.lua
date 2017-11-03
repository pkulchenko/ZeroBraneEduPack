require("turtle")
local fractal = require("fractal")

local D, W, H = 8, 1000,1000
local oTree = fractal.New("ytree", D, colr(100, 50, 255))
if(oTree) then
  open("Binary tree branching")
  size(W,H)
  zero(0, 0)
  updt(true) -- disable auto updates
  oTree:Allocate(oTree) 
  oTree:Draw(oTree,W/2,0,W/4,H/4,wait,0.01)
end
