-- The location of the ZeroBraneStudio executable `zbstudio`

local metaDirectories =
{
  iBase = 0,  -- The ID of the current IDE installation
  tBase = {}, -- Contains the ZBS install directories on different machines
  tPath = {}, -- Contains different sub-paths included relative to the install path
  sInam = "[/\\:*?<>|]+", -- Illegal characters for a file name
  sNmOS = tostring(jit.os):lower(),
  sArch = tostring(jit.arch):lower(),
  tSupr = {name = "SUPOUT", ["windows"] = " >nul 2>nul" , ["linux"] = " &> /dev/null"},
  tCdir = {name = "CHNDIR", ["windows"] = "cd "         , ["linux"] = "cd "          },
  tMdir = {name = "NEWDIR", ["windows"] = "mkdir "      , ["linux"] = "mkdir "       },
  tEdir = {name = "ERSDIR", ["windows"] = "rmdir /S /Q ", ["linux"] = "rm -rf "      },
  tNdir = {name = "RENDIR", ["windows"] = "ren "        , ["linux"] = "ren "         },
  tErec = {name = "ERSREC", ["windows"] = "del -f "     , ["linux"] = "rm -f "       },
  tRrec = {name = "RENREC", ["windows"] = "ren "        , ["linux"] = "ren "         }
}

local directories = {}

--------------- HELPER FUNCTIONS ---------------

function directories.getNorm(sD)
  local sS = tostring(sD or ""):gsub("\\","/"):gsub("/+","/")
  return ((sS:sub(-1,-1) == "/") and sS:sub(1,-2) or sS)
end

local function errorOptions(tT, iT, sS, nT)
  local iT = tostring(iT or "N/A")
  local sS, nT = tostring(sS or "N/A"), (nT or #tT)
  io.write(("Available %s is:\n"):format(sS))
  for iK = 1, nT do local vK = tostring(tT[iK])
    io.write("  ["..iK.."]["..vK.."]\n")
  end; error(("Invalid %s ID ["..iT.."]"):format(sS))
end

local function tableClear(tT)
  if(not tT) then error("Table missing") end
  local sT = type(tT); if(sT ~= "table") then
    error("Type mismatch ["..sT.."]") end
  if(not next(tT)) then return tT end
  for k, v in pairs(tT) do tT[k] = nil end
  return directories
end

local function tableRemove(tT, iD, sS)
  local sS = tostring(sS or ""); sS = ((sS == "") and "N/A" or sS)
  local iV, nT = math.floor(tonumber(iD) or 0), #tT
  if((iV <= 0) or (iV > nT)) then errorOptions(tT, iV, sS, nT) end
  table.remove(tT, iV); return directories
end

local function tableInsert(tT, iT, ...)
  local tA, iK = {...}, 1
  local iT = (tonumber(iT) or 0)
  while(tA[iK]) do
    local sV = tostring(tA[iK] or "")
    if(iT > 0) then
      table.insert(tT, iT, sV)
    elseif(iT < 0) then
      table.insert(tT, #tT - iT + 1, sV)
    else
      table.insert(tT, sV)
    end
    iK = iK + 1
  end; return directories
end

--------------- LIBRARY METHODS ---------------

function directories.getCount()
  return metaDirectories.iCount
end

--------------- PATH ---------------

function directories.retPath()
  return metaDirectories.tPath
end

function directories.remPathID(vP)
  return tableRemove(directories.retPath(), vP, "path")
end

function directories.addPath(...)
  return tableInsert(directories.retPath(), 0, ...)
end

function directories.addPathID(iD, ...)
  return tableInsert(directories.retPath(), iD, ...)
end

function directories.setPath(...)
  tableClear(directories.retPath())
  return directories.addPath(...)
end

--------------- BASE ---------------

function directories.osChange(sBase)
  local sOS = metaDirectories.sNmOS
  local sSP = (metaDirectories.tSupr[sOS] or "")
  if(sOS == "windows") then -- Windows
    return os.execute("cd /d "..sBase..sSP)
  elseif(sOS == "linux") then -- Linux
    return os.execute("cd "..sBase..sSP)
  else -- Not supported OS
    error("Invalid["..sOS.."]: "..sBase)
  end
end

local function setBaseID(iBase)
  local tBase = directories.retBase()
  if(not (tBase and next(tBase))) then
    error("Base table missing") end
  local sBase = tBase[iBase]
  if(not (type(sBase) == "string" and sBase:len() > 0)) then
    error("Base path missing ["..tostring(sBase).."]") end
  local bS, sE, nE = directories.osChange(sBase)
  if(not (bS and bS ~= nil and nE == 0)) then
    error("Base path invalid ["..sBase.."]") end
  local iCount = 0 -- Stores the number of paths processed
  local tPath = metaDirectories.tPath
  metaDirectories.iCount = iCount
  metaDirectories.iBase  = iBase
  metaDirectories.sBase  = sBase
  local iS = (iBase or 1)
  local iE = (iBase or #tBase)
  for iK = iS, iE do
    local sBase = tostring(tBase[iK] or "")
    if(sBase:len() <= 0 and iK > 0) then errorOptions(tBase, iBase, "install") end
    for iD = 1, #tPath do
      local sP = tostring(tPath[iD] or "")
      if(sP:len() > 0) then
        local sD = (sBase.."/"..sP)
        local bS, sE, nE = directories.osChange(sD)
        if(bS and bS ~= nil and nE == 0) then
          iCount = iCount + 1
          metaDirectories[iCount] = sD
          package.path = package.path..";"..sD.."/?.lua"
          package.cpath = package.cpath..";"..sD.."/?.dll"
          print("[V]["..iD.."]["..sD.."]")
        else
          print("[X]["..iD.."]["..sD.."]")
        end
      end
    end
  end
  metaDirectories.iCount = iCount
  return directories
end

function directories.getBase()
  return metaDirectories.sBase, metaDirectories.iBase
end

function directories.retBase()
  return metaDirectories.tBase
end

function directories.remBaseID(vB)
  return tableRemove(directories.retBase(), vB, "base")
end

function directories.addBase(...)
  return tableInsert(directories.retBase(), 0, ...)
end

function directories.addBaseID(iD, ...)
  return tableInsert(directories.retBase(), iD, ...)
end

function directories.setBase(vD)
  if(vD) then
    local iD = tonumber(vD)
    if(iD) then
      print("directories.setBase: Process ["..iD.."]")
      if(iD > 0) then setBaseID(iD) else
        errorOptions(directories.retBase(), iD, "base")
      end
    else
      tableClear(directories.retBase()); directories.addBase(vD)
      print("directories.setBase: Replace ["..tostring(vD).."]")
      setBaseID(1)
    end
  else
    local iN = #directories.retBase()
    print("directories.setBase: Using ["..iN.."]")
    setBaseID(iN)
  end
end

--------------- INITIALIATION ---------------

function directories.getLast()
  return metaDirectories[metaDirectories.Count]
end

function directories.getFirst()
  return metaDirectories[1]
end

function directories.getList()
  local tO, iO = {}, 1
  while(metaDirectories[iO]) do
    tO[iO] = metaDirectories[iO]
    iO = iO + 1
  end; return tO
end

function directories.getByID(vD)
  local iD = (tonumber(vD) or 0); if(iD < 1) then
    error("Identifier mismatch ["..iD.."]") end
  local sP = metaDirectories[iD]; if(not sP) then
    error("Missing path under ID ["..iD.."]") end
  return sP
end

--------------- COMMAND LINE ---------------

local function getExecuteOS(tTY, sBS, sNA, bP, bR)
  local sP = metaDirectories.sInam
  local sN = tostring(sNA or ""); if(sN:find(sP)) then
    error("Invalid name ["..sN.."]: "..tTY.name) end
  local sB = directories.getNorm(sBS)
  local sOS = metaDirectories.sNmOS
  local sSP = metaDirectories.tSupr[sOS]
  local sCD = metaDirectories.tCdir[sOS]
  local sMD = tTY[sOS]; if(not sMD) then
    error("Invalid request ["..sOS.."]: "..tTY.name) end
  if(sN:find("%s+")) then sN = "\""..sN.."\"" end
  if(sB:find("%s+")) then sB = "\""..sB.."\"" end
  local sC  = sMD..sN..((bP or bP == nil) and sSP or "")
  if(metaDirectories.sNmOS == "windows") then
    if(sB ~= "") then
      local bD = sB:find(":", 1, true)
      sC = sCD..(bD and "/d " or "")..sB.." && "..sC
    end
  elseif(metaDirectories.sNmOS == "linux") then
    if(sB ~= "") then sC = sCD..sB.." && "..sC end
  else error("Unsupported OS: "..sOS) end
  return sC -- Return the terminal command
end

function directories.newDir(sN, sB, bP, bR)
  return os.execute(getExecuteOS(metaDirectories.tMdir, sB, sN, bP, bR))
end

function directories.ersDir(sN, sB, bP, bR)
  return os.execute(getExecuteOS(metaDirectories.tEdir, sB, sN, bP, bR))
end

function directories.renDir(sO, sN, sB, bP, bR) -- Name will always contain space
  return os.execute(getExecuteOS(metaDirectories.tNdir, sB, sO.."\" \""..sN, bP, bR))
end

function directories.ersRec(sN, sB, bP, bR)
  return os.execute(getExecuteOS(metaDirectories.tErec, sB, sN, bP, bR))
end

function directories.renRec(sO, sN, sB, bP, bR) -- Name will always contain space
  return os.execute(getExecuteOS(metaDirectories.tRrec, sB, sO.."\" \""..sN, bP, bR))
end

return directories
