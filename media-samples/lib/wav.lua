local wav    = {}
local common = require("common")

local revArr = common.tableArrReverse -- Reverse the array in case of little endian

-- This converts internal strings from table of bytes
function byteSTR(tB, nB)
  local out = {}; for ID = 1, #tB do
    out[ID] = string.char(tB[ID]) end
  return table.concat(out)
end

-- This converts internal integers from table of bytes
function byteUINT(tB, nB)
  local out = 0
  for ID = 1, nB do out = out * 256
    out = out + tB[ID] end; return out
end

-- This holds header and format definition location
local dataTS = {
  {
    Name = "HEADER",
    {"sGroupID"    , 4, byteSTR , "char/4"},
    {"dwFileLength", 4, byteUINT, "uint"  },
    {"sRiffType"   , 4, byteSTR , "char/4"}
  },
  {
    Name = "FORMAT",
    {"sGroupID"        , 4, byteSTR , "char/4" },
    {"dwChunkSize"     , 4, byteUINT, "uint"   },
    {"wFormatTag"      , 2, byteUINT, "ushort" },
    {"wChannels"       , 2, byteUINT, "ushort" },
    {"dwSamplesPerSec" , 4, byteUINT, "uint"   },
    {"dwAvgBytesPerSec", 4, byteUINT, "uint"   }, -- sampleRate * blockAlign
    {"wBlockAlign"     , 2, byteUINT, "ushort" },
    {"dwBitsPerSample" , 4, byteUINT, "uint"   }
  },
  {
    Name = "DATA",
    {"sGroupID"    , 4, byteSTR , "char/4"},
    {"dwChunkSize" , 4, byteUINT, "uint"  }
  }
}

local function applyEndian(tB, sT, bB)
  if(bB) then -- Little endian / big endian ( def: little when true )
    if(sT == "uint" or sT == "ushort") then 
      revArr(tB)
    end 
  end
end

function wav.read(sN)
  local sNam = tostring(sN)
  local W = io.open(sNam, "rb")
  if(not W) then return common.logStatus("wav.read: No file <"..sNam..">") end
  local wData = {}
  for I = 1, #dataTS do
    local tdtPar = dataTS[I]
    wData[tdtPar.Name] = {}
    local curChunk = wData[tdtPar.Name]
    for J = 1, #tdtPar do local par = tdtPar[J]
      curChunk[par[1]] = {}
      local arrN = par[2]
      local arrChunk = curChunk[par[1]]
      for K = 1, arrN do arrChunk[K] = W:read(1):byte() end
      applyEndian(arrChunk, par[4], true)
      if(par[3]) then curChunk[par[1]] = par[3](arrChunk, arrN) end
    end
  end; local gID
  gID = wData["HEADER"]["sGroupID"]
  if(gID ~= "RIFF") then return common.logStatus("wav.read: Header mismatch <"..gID..">") end
  gID = wData["HEADER"]["sRiffType"]
  if(gID ~= "WAVE") then return common.logStatus("wav.read: Header not wave <"..gID..">") end
  gID = wData["FORMAT"]["sGroupID"]
  if(gID ~= "fmt ") then return common.logStatus("wav.read: Format invalid <"..gID..">") end
  gID = wData["DATA"]["sGroupID"]
  if(gID ~= "data") then return common.logStatus("wav.read: Data invalid <"..gID..">") end
  
  local smpData = {}
  local smpByte = (wData["FORMAT"]["dwBitsPerSample"] / 8)
  local totCnan = wData["FORMAT"]["wChannels"]
  local curChan, isEOF = 1, false
  while(not isEOF) do
    if(curChan > totCnan) then curChan = 1 end
    if(not smpData[curChan]) then smpData[curChan] = {__top = 1} end
    local arrChan = smpData[curChan]
          arrChan[arrChan.__top] = {}
    local smpTop = arrChan[arrChan.__top] 
    for K = 1, smpByte do
      local smp = W:read(1)
      if(not smp) then
        common.logStatus("wav.read: Reached EOF for channel <"..curChan.."> sample <"..arrChan.__top..">")
        isEOF = true; arrChan[arrChan.__top] = nil; break
      end
      smpTop[K] = smp:byte()
    end
    if(not isEOF) then
      if(smpByte == 2) then -- Two bytes per sample
        applyEndian(smpTop, "uint", true)
        arrChan[arrChan.__top] = (byteUINT(smpTop, smpByte) - 32768) / 32768
      end
      arrChan.__top = arrChan.__top + 1
      curChan = curChan + 1
    end
  end
  
  wData["FORMAT"]["fDuration"] = smpData[1].__top / wData["FORMAT"]["dwSamplesPerSec"]
  wData["FORMAT"]["fBlockAlign"] = totCnan * smpByte
  wData["FORMAT"]["fBitRate"] = smpData[1].__top * totCnan * wData["FORMAT"]["dwBitsPerSample"]
  wData["FORMAT"]["fBitRate"] = wData["FORMAT"]["fBitRate"] / (wData["FORMAT"]["fDuration"])
    
  W:close()
  return wData, smpData
end

return wav
