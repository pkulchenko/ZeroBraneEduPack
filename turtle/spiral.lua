require "turtle"

local step = 1
while dist() < 200 do
  move(step)
  turn(10)
  step = step + 0.05
end

wait()