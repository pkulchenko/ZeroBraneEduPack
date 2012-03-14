require "turtle"

local distance, angle, step = 140, 15, 15

updt(false) -- disable auto updates
for i = 1, 600 do
  rant(i) -- add a random turtle
  posn(rand(2)*distance-distance/2, rand(2)*distance-distance/2)
end

pick() -- pick all turtles
for i = 1, 2000 do
  turn(rand(angle))
  move(rand(step))
  updt()
end
wait()