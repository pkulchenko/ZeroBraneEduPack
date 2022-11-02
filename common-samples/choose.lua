local common  = require("common")

local n, c, e = 1000, 0, ""
local s, f = os.clock(), 8
local ta, tb, tt = 0, 0, 0
for i = 0, n do
  e = "A"
  tt = os.clock()
  local a = common.getBinomChooseNK(n, i)
  ta = ta + (os.clock() - tt)
  tt = os.clock()
  local b = common.getBinomChooseRC(n, i)
  tb = tb + (os.clock() - tt)
  if(a == b) then
    e = "A"
  else
    local sa = tostring(a)
    local sb = tostring(b)
    if(sa == sb) then
      e = "B"
    else
      if(sa:find("+", 1, true) and
         sb:find("+", 1, true) and
         sa:sub(1, f) == sb:sub(1, f)
      ) then
        e = "C"
      else
        e = "X"
        c = c + 1
      end
    end
  end
  if(e == "X") then
    print(e, n, i, a, b)
  end
end

common.logStatus("Average A: "..(ta / n))
common.logStatus("Average B: "..(tb / n))
common.logStatus("Success  : "..(((n - c) / n) * 100).."%")
common.logStatus("Total    : "..(os.clock() - s))
