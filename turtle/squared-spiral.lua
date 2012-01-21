require "turtle"

size(700, 700)
pncl(colr(127,127,127))

local step = 1
for i=1,215 do
  move(step)
  turn(89.58)
  step = step + 3
end

save("squared-spiral")

wait()