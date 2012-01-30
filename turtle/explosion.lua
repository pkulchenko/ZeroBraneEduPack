require "turtle"

local shot = snap() -- store snapshot
posn(-40, 0)
text("Click left mouse button...")
while true do
  local x,y = clck('ld') -- check for left button pressed down
  if x and y then
    play("c:/windows/media/ding")
    posn(x-64,y-64) -- move turtle to the left to make the explosion centered
    for i=1,17 do
      undo(shot)
      local file = "turtle/explosion/explosion1-" .. i
      load(file, 128, 128)
      wait(0.02)
    end
  end
  updt() -- update is needed here to avoid "busy" loop
end
