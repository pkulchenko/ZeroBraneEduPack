--
-- Copyright (C) 2012 Paul Kulchenko
-- Epicycloid (spirograph) calculation
-- The algorithm is based on http://www.math.psu.edu/dlittle/java/parametricequations/spirograph/SpiroGraph1.0/index.html
--

require "turtle"

open("Spirograph Window")

local function gcd(x, y) return x % y == 0 and y or gcd(y, x % y) end

function spiro(R, r, p, n, w, show)
  local xp, yp
  local revs = r / gcd(R, r)
  local sign = r >= 0 and 1 or -1;
  local old = {}
  n = n or 360 -- default resolution
  updt(false)
  for count = 0, n * revs do
    local theta = (count == n * revs) and 0 or (2 * math.pi * count / n)
    local phi = theta * (1 + R / math.abs(r))
    local x = (R + r) * math.cos(theta) + p * math.cos(phi)
    local y = sign * (R + r) * math.sin(theta) + p * math.sin(phi)
    if xp and yp then
      if show and #old > 0 then circles(unpack(old)) end
      line(xp, yp, x, y)
      old = {x, y, R, r, p, theta, phi}
      if show then circles(unpack(old)) end
    end
    xp,yp = x,y
    updt()
    if w then wait(w) end
  end
  if show then circles(unpack(old)) end -- erase circles
  updt(true)
end

function circles(x, y, R, r, p, theta, phi)
  local func = logf(wx.wxXOR)
  local width = pnsz(2)
  local sign = r >= 0 and 1 or -1;
  local cx = (R + r) * math.cos(theta)
  local cy = sign * (R + r) * math.sin(theta)

  local color = pncl("#FF00FF")
  crcl(0, 0, R)
  pncl("#FFFF00")
  crcl(cx, cy, r)
  pncl("#00FFFF")
  crcl(x, y, 4)
  line(cx, cy, x, y)

  pncl(color)
  pnsz(width)
  logf(func)
end
