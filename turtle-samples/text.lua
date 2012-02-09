require "turtle"

local shot = snap() -- store snapshot
for angle = 0, 720, 6 do
  undo(shot) -- restore saved snapshot to clear screen
  text("some text", -angle)
  text("some text", angle)
  wait(0.01)
end

wait()