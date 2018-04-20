local wav    = {}
local common = require("common")

local revArr   = common.tableArrReverse -- Reverse the array in case of little endian
local byteSTR  = common.bytesGetString
local byteUINT = common.bytesGetNumber
local byteMirr = common.binaryMirror

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
    if(sT == "uint" or sT == "ushort") then  revArr(tB) end 
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
  local smpAll  = wData["DATA"]["dwChunkSize"] / (smpByte * wData["FORMAT"]["wChannels"])
  local totCnan = wData["FORMAT"]["wChannels"]
  local curChan, isEOF = 1, false
  
  wData["FORMAT"]["fDuration"] = smpAll / wData["FORMAT"]["dwSamplesPerSec"]
  wData["FORMAT"]["fBitRate"]  = smpAll * totCnan * wData["FORMAT"]["dwBitsPerSample"]
  wData["FORMAT"]["fBitRate"]  = wData["FORMAT"]["fBitRate"] / wData["FORMAT"]["fDuration"]
  wData["FORMAT"]["fDataFill"] = 100 * (wData["DATA"]["dwChunkSize"] / wData["HEADER"]["dwFileLength"])
  wData["DATA"]["dwSamplesPerChan"] = smpAll
  
  while(not isEOF and smpAll > 0) do
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
      if(smpByte == 1) then
        arrChan[arrChan.__top] = (byteUINT(smpTop, smpByte) - 128) / 128
      elseif(smpByte == 2) then -- Two bytes per sample
        arrChan[arrChan.__top] = (byteUINT(smpTop, smpByte) - 32768) / 32768
      end
      if(curChan == 1) then smpAll  = smpAll  - 1 end
      arrChan.__top = arrChan.__top + 1
      curChan = curChan + 1
    else
      common.logStatus("wav.read: Reached EOF before chunk size <"..smpAll..">")
      smpAll = -1
    end
  end; W:close()
  return wData, smpData
end

return wav
