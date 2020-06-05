-- The location of the ZeroBraneStudio executable `zbstudio`

local metaDirectories =
{
  iBase = 0,  -- The ID of the current IDE installation
  tBase = {}, -- Contains the ZBS install directories on different machines
  tPath = {}  -- Contains different sub-paths included relative to the install path
}

local directories = {}

--------------- HELPER FUNCTIONS ---------------

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

function directories.setBase(...)
  tableClear(directories.retBase())
  return directories.addBase(...)
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

function directories.setBase(vB)
  local iBase = math.floor(tonumber(vB) or 0)
  local tBase = metaDirectories.tBase
  if(not (tBase and next(tBase))) then
    error("Directory base list missing") end
  local iCount = 0 -- Stores the number of paths processed
  local tPath = metaDirectories.tPath
  metaDirectories.iCount = iCount
  metaDirectories.iBase  = iBase
  metaDirectories.sBase  = sBase
  local iS = (vB and iBase or 1)
  local iE = (vB and iBase or #tBase)
  for iK = iS, iE do
    local sBase = tostring(tBase[iK] or "")
    if(sBase:len() <= 0 and iK > 0) then errorOptions(tBase, iBase, "install") end
    for iD = 1, #tPath do
      local sP = tostring(tPath[iD] or "")
      if(sP:len() > 0) then
        local sD = (sBase.."/"..sP)
        local bS, sE, nE = os.execute("cd /d "..sD)
        if(bS and bS ~= nil and nE == 0) then
          iCount = iCount + 1
          metaDirectories[iCount] = sD
          package.path = package.path..";"..sD.."/?.lua"
          package.cpath = package.cpath..";"..sD.."/?.dll"
        else
          print("Provided directory has been skipped: ["..iD.."]["..sD.."]")
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

return directories
