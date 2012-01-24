local demos = [[
  paint.lua
  text.lua
  tree45.lua
  tree60.lua
  flower.lua
  spiral.lua
  snowflake.lua
  rays.lua
  tree30.lua
  squared-spiral.lua
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
    text("Done with '"..file.."'; pause for 2s...")
    updt()
    waitorg(2)
  end
  dofile(file)
  size(x,y)
end
