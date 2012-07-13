require "turtle"

local x,y = size() -- get the current screen size
local maxc = 256
updt(false) -- disable auto updates
load('turtle-samples/zerobrane', -x/2, -y/2)
pnsz(3)
for row = -x/2, x/2, 3 do
  for col = -y/2, y/2, 3 do
    pnpx(row, col)
    line(row, col, row+rand(7), col-rand(7))
  end
  updt()
end
wait()
