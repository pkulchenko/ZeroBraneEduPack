local cmn = require("common")

local fNam = "common-samples/data.txt"

local f = io.open(fNam, "wb")
local m = "*line"

if(f) then local I
  
  local tD = {
    "    aaaaaaaaaaa    ",
    "bbbbbbbbbbb    ",
    "    ccccccccccc",
    "ddddddddddd",
  }
  
  I = 1; while(tD[I]) do
    f:write(tD[I].."\n"); I = I + 1
  end; f:flush(); f:close()
  
  f = io.open(fNam, "rb")
  
  if(f) then
    local l, e = cmn.fileRead(f, m)

    while(not e) do
      cmn.logStatus("Result: "..cmn.stringPadL("<"..l..">", 22).." : "..tostring(e))
      l, e = cmn.fileRead(f, m)
    end
  end
  
  f:close()
end