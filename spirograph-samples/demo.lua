local demos = [[
  astroid.lua   
  bud.lua       
  cardioid.lua  
  donut.lua     
  double.lua    
  flower.lua    
  peanut.lua    
  resolution.lua
  rose.lua      
  spiral.lua    
  sunflower.lua 
  triangle.lua  
]]

require "spirograph"
local x,y = size()
local waitorg = wait
wait(1)
for file in demos:gmatch("([%w%p]+)") do
  wait = function(seconds)
    if seconds then return waitorg(seconds) end
    local x, y = size()
    posn(-x/2+10, -y/2+10)
    hide() -- hide the turtles (if any are shown)
    text("Done with '"..file.."'; pause for 2s...")
    updt() -- refresh the screen
    waitorg(2)
  end
  dofile('spirograph-samples/'..file)
  size(x,y)
end
