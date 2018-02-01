local common = require("common")

for i = 1, 100 do
  --[[
    The random number/string generation seed creator has
    protected call can be invoked every second. That way
    it can take randomization to the maximum by reverting the
    number and using the the seconds for triggering the most significant bits
    The function randomGetNumber arguments:
      1) Print logs (optional)
  ]]
  common.randomSetSeed(true)
  --[[
    As you know according to lua random number generation manual,
    the first 2 or 3 numbers are not that "random" as requested.
    That's why we have to call the random generator some couple of
    times before returning the actual value
    The function randomGetNumber arguments:
      1) Dummy invoke times of "math.random" to generate the actual number (optional)
      2) Lower limit for the "math.random" function (optional)
      2) Upper limit for the "math.random" function (optional)
    The function "randomGetString" arguments:
      1) How long the generated string must be (optional) (0 for empty string)
      2) Controls the "randomGetNumber" first parameter when generating an index
  ]]
  local n = common.randomGetNumber(nil, 100)
  local s = common.randomGetString(80)
  common.logStatus(("ID: %4d <%s> #%d"):format(i, s, n))
  common.timeDelay(0.1)
end

common.timeDelay()
