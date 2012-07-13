require "turtle"

local x,y = size() -- get the current screen size
local maxc = 256
updt(false) -- disable auto updates
for row = -x/2, x/2 do
  for col = -y/2, y/2 do
    local res = (row^2 + col^2)
    local b, g, r = res / (maxc^2) % maxc, res / maxc % maxc, res % maxc
    pncl(colr(r, g, b)) -- set pen color
    pixl(row, col) -- draw a pixel using the current pen
  end
  updt()
end
wait()
