require("wx")
require("turtle")
local com = require('common')

local nW, nH = 1200, 800

local tHan = {
  ID = {"A", "B", "C"},
  A = {},
  B = {},
  C = {},
  Set = {
    ["nDisk"] = 10, -- The amount of disks to get moved
    ["nWait"] = 0, -- The amout of time to wait before a move
    ["clBase"] = colr(139,69,19), -- Base pylon color
    ["clDisk"] = colr(0,255,0), -- Disks color
    ["dW"] = 10, -- The distance between all pylons and window edges X
    ["dH"] = 20, -- The distance between all pylons and window edges Y
    ["dP"] = 10, -- The width of one pylon stick or plate
    ["dT"] = 18, -- Pylon name text offset delta
    ["wT"] = 70, -- Fixed width of the first, top, smallest disk
    ["wB"] = 0,  -- Fixed width of the last, bottom, largest disk
    ["dD"] = 0,  -- The disk size width delta until the bottom disk is reached
    ["bW"] = 0,  -- Pylon base support width
    ["bH"] = 0,   -- Pylon hight
    ["tS"] = os.clock() -- Start time of the process
  }
}

local function drawState()
  local tSet = tHan.Set
  local dP = tSet["dP"]
  local clDisk = tSet["clDisk"]
  for iD = 1, #tHan.ID do
    local key = tHan.ID[iD]
    local val = tHan[key]
    for iK = 1, #val do local dsk = val[iK]
      local dX, dY = (val.C-dsk.W/2), (val.Y-iK*(dP+dsk.H))
      pncl(clDisk); rect(dX,dY,dsk.W,dsk.H)
    end
  end
end

local function drawBase()
  local dW = tHan.Set["dW"]
  local dH = tHan.Set["dH"]
  local dP = tHan.Set["dP"]
  local dT = tHan.Set["dT"]
  local bW = tHan.Set["bW"]
  local bH = tHan.Set["bH"]
  local tS = tHan.Set["tS"]
  local clBase = tHan.Set["clBase"]; wipe()
  for iD = 1, #tHan.ID do
    local key = tHan.ID[iD]
    local val = tHan[key]
    local xP = (val.X + (bW / 2)) - dP/2
    pncl(clBase); rect(xP,dH,dP,bH)
    text(tHan.ID[iD],0,xP,dH-dT)
    pncl(clBase); rect(val.X,val.Y,bW,dP)
    text("Time: "..tostring(os.clock()-tS))
  end
end

local function doMove(ID, tS, tD)
  local nWait = tHan.Set["nWait"]
  if(nWait and nWait > 0) then wait(nWait) end
  tD[#tD+1] = tS[#tS]; tS[#tS] = nil
  drawBase(); drawState(); updt()
end

local function doHanoj(ID, tS, tD, tT)
  if(ID == 1) then doMove(ID, tS, tD) else
    doHanoj(ID-1, tS, tT, tD)
    doMove(ID, tS, tD)
    doHanoj(ID-1, tT, tD, tS)
  end
end

local function goHanoj(tH)
  local tSet = tHan.Set
  local nD = tHan.Set["nDisk"]
  local A,B,C = tH[tH.ID[1]], tH[tH.ID[2]], tH[tH.ID[3]]
  tSet["bW"] = ((nW - 4*tSet["dW"]) / 3)
  tSet["bH"] = (nH - 2*tSet["dH"])
  tSet["wB"] = (tSet["bW"] - 2*tSet["dP"])
  tSet["dD"] = (tSet["wB"] - tSet["wT"])/(nD-1)
  A[1] = {ID=1,W=tSet["wT"],H=tSet["dP"]}
  for iD = 2, (nD-1) do
    A[iD] = {ID=iD,W=(A[iD-1].W+tSet["dD"]),H=tSet["dP"]}
  end
  A[nD] = {ID=nD,W=tSet["wB"],H=tSet["dP"]}
  com.tableArrReverse(A)
  local xB, yB = tSet["dW"], (nH - tSet["dH"] - tSet["dP"])
  for iD = 1, #tHan.ID do
    local key = tHan.ID[iD]
    local val = tHan[key]
    val.name  = key
    val.X = xB
    val.Y = yB
    val.C = (xB + tSet["bW"]/2)
    xB = xB + tSet["dW"] + tSet["bW"]
  end  
  drawBase(); drawState();  
  doHanoj(nD, A, C, B)
  drawBase(); drawState();
end

open("The towers of Hanoj")
size(nW, nH); zero(0, 0)
updt(false) -- disable auto updates
goHanoj(tHan)
wait()
