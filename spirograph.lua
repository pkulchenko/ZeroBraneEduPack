--
-- Copyright (C) 2012 Paul Kulchenko
-- Epicycloid (spirograph) calculation
-- The algorithm is based on http://www.math.psu.edu/dlittle/java/parametricequations/spirograph/SpiroGraph1.0/index.html
--

require "turtle"

local function gcd(x, y) return x % y == 0 and y or gcd(y, x % y) end

function spiro(R, r, p, n, w)
  local xp, yp
  local revs = r / gcd(R, r)
  n = n or 360 -- default resolution
  for count = 0, n * revs do
    local theta = (count == n * revs) and 0 or (2 * math.pi * count / n)
    local phi = theta * (1 + R / math.abs(r))
    local x = (R + r) * math.cos(theta) + p * math.cos(phi)
    local y = (R + r) * math.sin(theta) + p * math.sin(phi)
    if xp and yp then line(xp, yp, x, y) end
    xp,yp = x,y
    if w then wait(w) end
  end
end
