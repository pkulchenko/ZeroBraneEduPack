-- The location of the ZeroBraneStudio executable `zbstudio`

local metaDirectories =
{
  iBase = 0,  -- The ID of the current IDE installation
  tBase = {}, -- Contains the ZBS install directories on different machines
  tPath = {}, -- Contains different sub-paths included relative to the install path
  bSupr = true, -- Global output supression for OS commants for terminal
  sInam = "[/\\:*?<>|]+", -- Illegal characters for a file name
  sNmOS = tostring(jit.os):lower(), -- Operating system we are running on
  sArch = tostring(jit.arch):lower(), -- CPU architecture we are running on
  tSupr = {name = "SUPOUT", ["windows"] = " >nul 2>nul"       , ["linux"] = " &> /dev/null"},
  tLdir = {name = "LISTDR", ["windows"] = "dir "              , ["linux"] = "ls -lt "      },
  tCdir = {name = "CHNDIR", ["windows"] = "cd "               , ["linux"] = "cd "          },
  tMdir = {name = "NEWDIR", ["windows"] = "mkdir "            , ["linux"] = "mkdir "       },
  tEdir = {name = "ERSDIR", ["windows"] = "rmdir /S /Q "      , ["linux"] = "rm -rf "      },
  tNdir = {name = "RENDIR", ["windows"] = "ren "              , ["linux"] = "mv "          },
  tDcpy = {name = "CPYDIR", ["windows"] = "xcopy /q /s /e /y ", ["linux"] = "cp -r "       },
  tErec = {name = "ERSREC", ["windows"] = "del -f "           , ["linux"] = "rm -f "       },
  tRrec = {name = "RENREC", ["windows"] = "ren "              , ["linux"] = "mv "          },
  tRcpy = {name = "CPYREC", ["windows"] = "xcopy /q /y "      , ["linux"] = "cp "          }
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

--------------- COMMAND LINE ---------------

local function getPrepareOS(tTY, sBS, sNS, sBD, sND, sPM)
  local sPF = metaDirectories.sInam -- File name check
  local bPM = metaDirectories.bSupr -- Supress messages
  local sNS = tostring(sNS or ""); if(sNS:find(sPF)) then
    error("Invalid source ["..sNS.."]: "..tTY.name) end
  local sND = tostring(sND or ""); if(sND:find(sPF)) then
    error("Invalid destin ["..sND.."]: "..tTY.name) end
  local sOS = metaDirectories.sNmOS
  local sMD = tTY[sOS]; if(not sMD) then
    error("Invalid request ["..sOS.."]: "..tTY.name) end
  local sSP = metaDirectories.tSupr[sOS]
        sSP = ((sSP and (bPM or bPM == nil)) and sSP or "")
  local sCD = metaDirectories.tCdir[sOS]
  local sBS = directories.getNorm(sBS)
  local sBD = tostring(sBD or ""); if(sBD ~= "") then
    sBD = directories.getNorm(sBD).."/" end; sND = sBD..sND
  if(sBS:find("%s+")) then sBS = "\""..sBS.."\"" end
  if(sNS:find("%s+")) then sNS = "\""..sNS.."\"" end
  if(sND:find("%s+")) then sND = "\""..sND.."\"" end
  if(sOS == "windows") then
    if(sND ~= "") then sND = " "..sND
      if    (tTY.name == "CPYDIR") then sND = (sND.."/")
      elseif(tTY.name == "CPYREC") then sND = (sND.."*") end
    end
    sBS = sBS:gsub("/","\\")
    sNS = sNS:gsub("/","\\")
    sND = sND:gsub("/","\\")
    if(sBS ~= "") then
      local bD = sBS:find(":", 1, true)
      if(sNS ~= "") then -- Return the terminal command
        return sCD..(bD and "/d " or "")..sBS..sSP.." && "..sMD..sNS..sND..(sPM or sSP)
      else -- File name is not provided. Change directory
        return sCD..(bD and "/d " or "")..sBS..sSP
      end -- Otherwise execute in current folder
    else return sMD..sNS..sND..sSP end
  elseif(sOS == "linux") then
    if(sBS ~= "") then
      if(sNS ~= "") then -- Return the terminal command
        return sCD..sBS..sSP.." && "..sMD..sNS..sND..(sPM or sSP)
      else -- File name is not provided. Change directory
        return sCD..sBS..sSP
      end -- Otherwise execute in current folder
    else return sMD..sNS..sND..sSP end
  else error("Unsupported OS: "..sOS) end
end

local function getExecuteOS(sC)
  local bS, sE, nE = os.execute(sC)
  return bS, sE, nE, sC
end

function directories.ripDir(sD) -- Split a fork
  local tR, sD = {}, tostring(sD or ""):gsub("\\","/")
  for w in sD:gmatch("([^/]+)") do
    table.insert(tR, w)
  end; return tR
end

function directories.supCMD(bP) -- Supress CMD messages globally
  metaDirectories.bSupr = ((bP or bP == nil) and true or false)
end

function directories.swcDir(sB) -- Use the current directory
  return getExecuteOS(getPrepareOS(metaDirectories.tCdir, sB, "", "", ""))
end

function directories.newDir(sN, sB)
  return getExecuteOS(getPrepareOS(metaDirectories.tMdir, sB, sN, "", ""))
end

function directories.ersDir(sN, sB)
  return getExecuteOS(getPrepareOS(metaDirectories.tEdir, sB, sN, "", ""))
end

function directories.renDir(sO, sN, sB) -- Name will always contain space
  return getExecuteOS(getPrepareOS(metaDirectories.tNdir, sB, sO, "", sN))
end

function directories.cpyDir(sO, sN, sB, sD) -- Name will always contain space
  return getExecuteOS(getPrepareOS(metaDirectories.tDcpy, sB, sO, sD, sN))
end

function directories.ersRec(sN, sB)
  return getExecuteOS(getPrepareOS(metaDirectories.tErec, sB, sN, "", ""))
end

function directories.renRec(sO, sN, sB) -- Name will always contain space
  return getExecuteOS(getPrepareOS(metaDirectories.tRrec, sB, sO.."\" \""..sN, "", ""))
end

function directories.cpyRec(sO, sN, sB, sD) -- Name will always contain space
  return getExecuteOS(getPrepareOS(metaDirectories.tRcpy, sB, sO, sD, sN))
end

function directories.conDir(sN, sB, bR, sT) -- Read direcory contents
  local sT = tostring(sT or "")
  if(sT:len() == 0) then
    sT = tostring(debug.getinfo(2).source or "")
    sT = sT:gsub("\\","/"):sub(2,-1):match(".+/")
  end
  local nam = os.tmpname():gsub("%W+","_")..".txt"
  local dir = getPrepareOS(metaDirectories.tLdir, sB, sN, nil, nil, ">>"..sT..nam)
  local rem = getPrepareOS(metaDirectories.tErec, sT, nam, "", "")
  local bS = getExecuteOS(dir); if(not bS) then error("Read: "..dir) end
  local fD = io.open(sT..nam, "rb"); if(not fD) then
    error("Unable to open file: "..sT..nam) end
  local sD, tD, sOS = fD:read("*line"), {}, metaDirectories.sNmOS  
  while(sD) do sD = sD:match("^%s*(.-)%s*$")
    if(sD:len() > 0) then
      if(sOS == "windows") then
        if(sD:find("File%(s%)")) then
          -- Do nothing. Do not register item
        elseif(sD:find("Dir%(s%)")) then
          -- Do nothing. Do not register item
        elseif(sD:find("Volume in drive")) then
          local rR = sD:match("drive.*$"):gsub("drive%s", "")
                rR = rR:gsub("is", "/"):gsub("%s", "")
          local tL = directories.ripDir(rR)
                tD.Drive, tD.Tag = tL[1], tL[2]
        elseif(sD:find("Volume Serial Number is")) then
          tD.SN = sD:match("is.*$"):gsub("is%s", "")
        elseif(sD:find("Directory of")) then
          tD.Root = sD:match("of.*$"):gsub("of%s", ""):gsub("\\","/")
        elseif(sD:find("<DIR>")) then
          if(not tD.Tree) then tD.Tree = {} end
          local rR = sD:gsub("%s*<DIR>%s*", "/")
          local tL = directories.ripDir(rR)
          local tF = {Time = tL[1], Name = tL[2]}
          if(bR and tF.Name ~= "." and tF.Name ~= "..") then
            tF.Fork = directories.conDir(tF.Name, tD.Root, bR, sT)
          end; table.insert(tD.Tree, tF)
        elseif(sD:find((" "):rep(5))) then
          if(not tD.File) then tD.File = {} end
          local rR = sD:gsub("(%s%s)%s+", "/")
          local tL = directories.ripDir(rR)
          local tF = {Time = tL[1], Name = tL[2], Size = ""}
          for n in tF.Name:gmatch("[0-9]+%s") do
            tF.Size = tF.Size..n
            tF.Name = tF.Name:gsub(n, "")
          end; tF.Size = tF.Size:sub(1,-2)
          table.insert(tD.File, tF)
        else
          error("Unmached line: "..sD)
        end
      elseif(sOS == "linux") then
      else error("Unmached OS: "..sOS) end
    end
    sD = fD:read("*line")
  end; fD:close()
  local bS = getExecuteOS(rem); if(not bS) then
    error("Unable to remove temp file: "..rem) end
  return tD
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

local function setBaseID(iBase)
  local tBase = directories.retBase()
  if(not (tBase and next(tBase))) then
    error("Base table missing") end
  local sBase = tBase[iBase]
  if(not (type(sBase) == "string" and sBase:len() > 0)) then
    error("Base path missing ["..tostring(sBase).."]") end
  local bS, sE, nE = directories.swcDir(sBase, true)
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
        local bS, sE, nE = directories.swcDir(sD, true)
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

function directories.getBase(vB)
  if(vB) then
    local iB = tonumber(vB)
    if(iB) then
      local iB = math.floor(iB)
      local tB = directories.retBase()
      local sB = tB[iB]
      if(sB) then return sB, iB end
    else
      local iB = tostring(vB or "")
      local tB = directories.retBase()
      for iK = 1, #tB do local sB = tB[iK]
        if(tostring(sB):find(iB)) then
          return sB, iK
        end
      end
    end
  else
    return metaDirectories.sBase,
           metaDirectories.iBase
  end
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
      if(iD > 0) then setBaseID(iD) else
        errorOptions(directories.retBase(), iD, "base")
      end
    else
      tableClear(directories.retBase()); directories.addBase(vD)
      setBaseID(1)
    end
  else
    local iN = #directories.retBase()
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

return directories
