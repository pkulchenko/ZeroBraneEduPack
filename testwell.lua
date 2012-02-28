--
-- Copyright (C) 2012 Paul Kulchenko
-- A simple testing library
-- Based on lua-TestMore : <http://fperrad.github.com/lua-TestMore/>
-- Copyright (c) 2009-2011 Francois Perrad
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--

local pairs = pairs
local tostring = tostring
local type = type
local _G = _G

_ENV = nil

-----------------------------------------------------------

local tb = {
  curr_test = 0,
  good_test = 0,
  skip_test = 0,
}

function tb:print(...)
  print(...)
end

function tb:note(...)
  self:print(...)
end

function tb:diag(...)
  local arg = {...}
  for k, v in pairs(arg) do
    arg[k] = tostring(v)
  end
  local msg = table.concat(arg)
  msg = msg:gsub("\n", "\n# ")
  msg = msg:gsub("\n# \n", "\n#\n")
  msg = msg:gsub("\n# $", '')
  self:print("# " .. msg)
end

function tb:ok(test, name, more)
  self.curr_test = self.curr_test + 1
  self.good_test = self.good_test + (test and 1 or 0)
  self.skip_test = self.skip_test + (test == nil and 1 or 0)
  name = tostring(name or '')
  local out = ''
  if not test then
    out = "not "
  end
  out = out .. "ok " .. self.curr_test
  if name ~= '' then
    out = out .. " - " .. name
  end
  self:print(out)
  if test == false then
    self:diag("    Failed test " .. (name and ("'" .. name .. "'") or ''))
    if debug then
      local info = debug.getinfo(3)
      local file = info.short_src
      local line = info.currentline
      self:diag("    in " .. file .. " at line " .. line .. ".")
    end
    self:diag(more)
  end
end

function tb:done_testing()
  return self.curr_test, self.good_test, self.skip_test
end

-----------------------------------------------------------

local m = {}

function m.ok(test, name)
  tb:ok(test, name)
end

function m.is(got, expected, name)
  local pass = got == expected
  if got == nil then pass = nil end
  tb:ok(pass, name, not pass and 
      "         got: " .. tostring(got) ..
    "\n    expected: " .. tostring(expected))
end

function m.isnt(got, expected, name)
  local pass = got ~= expected
  if got == nil then pass = nil end
  tb:ok(pass, name, not pass and
      "         got: " .. tostring(got) ..
    "\n    expected: anything else")
end

function m.like(got, pattern, name)
  if type(pattern) ~= 'string' then
    return tb:ok(false, name, "pattern isn't a string : " .. tostring(pattern))
  end

  local pass = tostring(got):match(pattern)
  if got == nil then pass = nil end
  tb:ok(pass, name, not pass and 
      "                  '" .. tostring(got) .. "'" ..
    "\n    doesn't match '" .. pattern .. "'")
end

function m.unlike(got, pattern, name)
  if type(pattern) ~= 'string' then
    return tb:ok(false, name, "pattern isn't a string : " .. tostring(pattern))
  end

  local pass = not tostring(got):match(pattern)
  if got == nil then pass = nil end
  tb:ok(pass, name, not pass and 
      "                  '" .. tostring(got) .. "'" ..
    "\n          matches '" .. pattern .. "'")
end

local cmp = {
    ['<']  = function (a, b) return a <  b end,
    ['<='] = function (a, b) return a <= b end,
    ['>']  = function (a, b) return a >  b end,
    ['>='] = function (a, b) return a >= b end,
    ['=='] = function (a, b) return a == b end,
    ['~='] = function (a, b) return a ~= b end,
}

function m.cmp_ok(this, op, that, name)
  local f = cmp[op]
  if not f then
    return tb:ok(false, name, "unknown operator : " .. tostring(op))
  end

  local pass = f(this, that)
  if this == nil then pass = nil end
  tb:ok(pass, name, not pass and 
      "    " .. tostring(this) ..
    "\n        " .. op ..
    "\n    " .. tostring(that))
end

function m.type_ok(val, t, name)
  if type(t) ~= 'string' then
    return tb:ok(false, name, "type isn't a string : " .. tostring(t))
  end

  if type(val) == t then
    tb:ok(true, name)
  else
    tb:ok(false, name,
      "    " .. tostring(val) .. " isn't a '" .. t .."', it's a '" .. type(val) .. "'")
  end
end

function m.diag(...)
  tb:diag(...)
end

function m.report()
  local total, good, skipped = tb:done_testing()
  local failed = total - good - skipped
  local sum = ("(%d/%d/%d)."):format(good, skipped, total)
  local num, msg = 0, ""
  if good > 0 then
    num, msg = good, msg .. "passed " .. good
  end
  if failed > 0 then
    num, msg = failed, msg .. (#msg > 0 and (skipped > 0 and ", " or " and ") or "")
      .. "failed " .. failed
  end
  if skipped > 0 then 
    num, msg = skipped, msg .. (#msg > 0 and ((good > 0 and failed > 0 and ',' or '') .." and ") or "")
      .. "skipped " .. skipped
  end
  msg = ("Looks like you %s test%s of %d %s"):format(msg, (num > 1 and 's' or ''), total, sum)
  if skipped == total then msg = "Looks like you skipped all tests " .. sum end
  if good == total then msg = "All tests passed " .. sum end
  tb:note(("1..%d # %s"):format(total, msg))
end

for k, v in pairs(m) do  -- injection
  _G[k] = v
end

return m
