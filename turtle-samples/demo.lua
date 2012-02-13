local demos = [[
  star.lua
  text.lua
  tree45.lua
  tree60.lua
  flower.lua
  wheel.lua
  snowflake.lua
  shell.lua
  circle.lua
  spiral-two.lua
  squared-spiral.lua
  rainbow.lua
  circles.lua
  rays.lua
  tree30.lua
  bounce.lua
]]

require "turtle"
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
  dofile('turtle-samples/'..file)
  size(x,y)
end
