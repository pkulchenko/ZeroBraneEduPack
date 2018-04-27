-- Copyright (C) 2017 Deyan Dobromirov
-- A common functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local signals = require('signals')`.")
  os.exit(1)
end

local tonumber    = tonumber
local tostring    = tostring
local type        = type
local math        = math
local bit         = bit
local signals     = {}
local metaSignals = {}
local common      = require("common")
local complex     = require("complex")
local revArr      = common.tableArrReverse
local byteSTR     = common.bytesGetString
local byteUINT    = common.bytesGetNumber
local byteMirr    = common.binaryMirror
local isNil       = common.isNil

-- This holds header and format definition location
metaSignals["WAVE_HEADER"] = {
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
    {"dwBitsPerSample" , 2, byteUINT, "uint"   }
  },
  {
    Name = "DATA",
    {"sGroupID"    , 4, byteSTR , "char/4"},
    {"dwChunkSize" , 4, byteUINT, "uint"  }
  }
}
metaSignals["REALNUM_UNIT"] = complex.getNew(1, 0)
metaSignals["IMAGINE_UNIT"] = complex.getNew(0, 1)
metaSignals["COMPLEX_VEXP"] = complex.getNew(math.exp(1))
metaSignals["WIN_FLATTOP"]  = {0.21557895, 0.41663158, 0.277263158, 0.083578947, 0.006947368}
metaSignals["WIN_NUTTALL"]  = {0.36358190, 0.48917750, 0.136599500, 0.010641100}
metaSignals["WIN_BLKHARR"]  = {0.35875000, 0.48829000, 0.141280000, 0.011680000}
metaSignals["DFT_PHASEFCT"] = {__top = 0}

-- Read an audio WAVE file giving the path /sN/
function signals.readWave(sN)
  local sNam = tostring(sN)
  local W = io.open(sNam, "rb")
  if(not W) then return common.logStatus("signals.readWave: No file <"..sNam..">") end
  local wData, hWave = {}, metaSignals["WAVE_HEADER"]
  for I = 1, #hWave do local tdtPar = hWave[I]
    wData[tdtPar.Name] = {}
    local curChunk = wData[tdtPar.Name]
    for J = 1, #tdtPar do local par = tdtPar[J]
      local nam, arr, foo, typ = par[1], par[2], par[3], par[4]
      curChunk[nam] = {}; local arrChunk = curChunk[nam]
      for K = 1, arr do arrChunk[K] = W:read(1):byte() end
      if(typ == "uint" or typ == "ushort") then  revArr(arrChunk) end
      if(foo) then curChunk[nam] = foo(arrChunk, arr) end
    end
  end; local gID
  gID = wData["HEADER"]["sGroupID"]
  if(gID ~= "RIFF") then return common.logStatus("signals.readWave: Header mismatch <"..gID..">") end
  gID = wData["HEADER"]["sRiffType"]
  if(gID ~= "WAVE") then return common.logStatus("signals.readWave: Header not wave <"..gID..">") end
  gID = wData["FORMAT"]["sGroupID"]
  if(gID ~= "fmt ") then return common.logStatus("signals.readWave: Format invalid <"..gID..">") end
  gID = wData["DATA"]["sGroupID"]
  if(gID ~= "data") then return common.logStatus("signals.readWave: Data invalid <"..gID..">") end

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
        common.logStatus("signals.readWave: Reached EOF for channel <"..curChan.."> sample <"..arrChan.__top..">")
        isEOF = true; arrChan[arrChan.__top] = nil; break
      end
      smpTop[K] = smp:byte()
    end
    if(not isEOF) then
      if(smpByte == 1) then
        arrChan[arrChan.__top] = (byteUINT(smpTop) - 128) / 128
      elseif(smpByte == 2) then -- Two bytes per sample
        arrChan[arrChan.__top] = (byteUINT(smpTop) - 32760) / 32760
      end
      if(curChan == 1) then smpAll  = smpAll  - 1 end
      arrChan.__top = arrChan.__top + 1
      curChan = curChan + 1
    else
      common.logStatus("signals.readWave: Reached EOF before chunk size <"..smpAll..">")
      smpAll = -1
    end
  end; W:close()
  return wData, smpData
end

-- Extend the signal by making a copy
function signals.getExtendBaseTwo(tS)
  local nL, tO = #tS, {}; if(common.binaryIsPower(nL)) then
    common.tableArrTransfer(tO, tS); return tO end
  local nT = common.binaryNextBaseTwo(nL)
  for iD = 1, nT do local vS = tS[iD]
    if(vS) then tO[iD] = vS else tO[iD] = 0 end end; return tO
end

-- Extend the signal without making a copy
function signals.setExtendBaseTwo(tS) local nL = #tS
  if(common.binaryIsPower(nL)) then return tS end
  local nS, nE = (nL+1), common.binaryNextBaseTwo(nL)
  for iD = nS, nE do tS[iD] = 0 end; return tS
end

-- Blackman window of length N
function signals.winBlackman(nN)
  local nK = (2 * math.pi / (nN-1))
  local tW, nN = {}, (nN-1)
  for iD = 1, (nN+1) do local nP = nK*(iD-1)
    tW[iD] = 0.42 - 0.5*math.cos(nP) + 0.08*math.cos(2*nP)
  end; return tW
end

-- Hamming window of length N
function signals.winHamming(nN)
  local tW, nN = {}, (nN-1)
  local nK = (2 * math.pi / nN)
  for iD = 1, (nN+1) do
    tW[iD] = 0.54 - 0.46 * math.cos(nK * (iD - 1))
  end; return tW
end

-- Gauss window of length N
function signals.winGauss(nN, vA)
  local nA = common.getPick(vA, vA, 2.5)
  local tW, nN = {}, (nN - 1)
  local N2, nK = (nN / 2), (2*nA / (nN-1))
  for iD = 1, (nN+1) do
    local pN = nK*(iD - N2 - 1)
    tW[iD] = math.exp(-0.5 * pN^2)
  end; return tW
end

-- Barthann window of length N
function signals.winBarthann(nN)
  local tW, nN = {}, (nN-1)
  for iD = 1, (nN+1) do
    local pN = (((iD-1) / nN) - 0.5)
    tW[iD] = 0.62 - 0.48*math.abs(pN) + 0.38*math.cos(2*math.pi*pN)
  end; return tW
end

-- Barthann window of length N
function signals.winHann(nN)
  local tW, nN = {}, (nN - 1)
  local nK = (2 * math.pi / nN)
  for iD = 1, (nN+1) do
    local pN = (((iD-1) / nN) - 0.5)
    tW[iD] = 0.5*(1-math.cos(nK*(iD-1)))
  end; return tW
end

-- Flattop window of length N
function signals.winFlattop(nN,...)
  local tP, tA = {...}, metaSignals["WIN_FLATTOP"]
  for iD = 1, 5 do local vP = tP[iD]
    tP[iD] = common.getPick(vP, vP, tA[iD]) end
  local nN, tW = (nN - 1), {}
  local nK = ((2 * math.pi) / nN)
  for iD = 1, (nN+1) do local nM, nS = tP[1], 1
    for iK = 2, 5 do nS = -nS
      nM = nM + nS * tP[iK] * math.cos(nK * (iK-1) * (iD-1))
    end; tW[iD] = nM
  end; return tW
end

-- Triangle window of length N
function signals.winTriangle(nN)
  local tW, nK, nS, nE = {}, 2/(nN-1), 1, nN
  tW[nS], tW[nE] = 0, 0
  nS, nE = (nS + 1), (nE - 1)
  while(nS <= nE) do
    tW[nS] = tW[nS-1] + nK
    tW[nE] = tW[nE+1] + nK
    nS, nE = (nS + 1), (nE - 1)
  end; return tW
end

-- Nuttall window of length N
function signals.winNuttall(nN,...)
  local tP, tA = {...}, metaSignals["WIN_NUTTALL"]
  for iD = 1, 4 do local vP = tP[iD]
    tP[iD] = common.getPick(vP, vP, tA[iD]) end
  local nN, tW = (nN - 1), {}
  local nK = ((2 * math.pi) / nN)
  for iD = 1, (nN+1) do
    local nM, nS = tP[1], 1
    for iK = 2, 4 do nS = -nS
      nM = nM + nS * tP[iK] * math.cos(nK * (iK-1) * (iD-1))
    end; tW[iD] = nM
  end; return tW
end

-- Blackman-Harris window of length N
function signals.winBlackHarris(nN,...)
  local tP, tA = {...}, metaSignals["WIN_BLKHARR"]
  for iD = 1, 4 do local vP = tP[iD]
    tP[iD] = common.getPick(vP, vP, tA[iD]) end
  local nN, tW = (nN - 1), {}
  local nK = ((2 * math.pi) / nN)
  for iD = 1, (nN+1) do
    local nM, nS = tP[1], 1
    for iK = 2, 4 do nS = -nS
      nM = nM + nS * tP[iK] * math.cos(nK * (iK-1) * (iD-1))
    end; tW[iD] = nM
  end; return tW
end

-- Exponential/Poisson window of length N
function signals.winPoisson(nN, nD)
  local nD, tW = (nD or 8.69), {}
  local nT, nN = (2*nD)/(8.69*nN), (nN-1)
  local N2 = (nN/2); for iD = 1, (nN+1) do
    tW[iD] = math.exp(-nT*math.abs((iD-1)-N2))
  end; return tW
end

-- Calculates the DFT phase factor single time
function signals.getPhaseFactorDFT(nK, nN)
  if(nK == 0) then
    return metaSignals["REALNUM_UNIT"]:getNew() end
  local cE = metaSignals["COMPLEX_VEXP"]
  local cI = metaSignals["IMAGINE_UNIT"]
  local cK = cI:getNew(-2 * math.pi * nK, 0)
  return cE:getPow(cK:Mul(cI):Div(2^nN, 0))
end

-- Removes the DFT phase factor for realtime
function signals.remPhaseFactorDFT(bG)
  local tW = metaSignals["DFT_PHASEFCT"]
  for iK, vV in pairs(tW) do tW[iK] = nil end
  tW.__top = 0; if(bG) then
    collectgarbage() end; return tW
end

-- Caches the DFT phase factor for realtime
function signals.setPhaseFactorDFT(nN)
  local tW = signals.remPhaseFactorDFT()
  local gW = signals.getPhaseFactorDFT
  local nR = common.binaryNeededBits(nN-1)
  for iD = 1, (nN/2) do tW[iD] = gW(iD-1, nR) end
  tW.__top = #tW; return tW
end

-- Converts from phase number and butterfly count to index
local function convIndexDFT(iP, iA, N2)
  local nT = (2^(iP - 1))
  local nI = ((iA / nT) * N2)
  return (math.floor(nI % N2) + 1)
end

function signals.getForwardDFT(tS)
  local cZ = complex.getNew()
  local aW = metaSignals["DFT_PHASEFCT"]
  local tF = signals.getExtendBaseTwo(tS)
  local nN, iM, tA, bW = #tF, 1, {}, (aW.__top > 0)
  local tW = common.getPick(bW, aW, {})
  for iD = 1, nN do tF[iD] = cZ:getNew(tF[iD]) end
  local nR, N2 = common.binaryNeededBits(nN-1), (nN / 2)
  for iD = 1, nN do tA[iD] = cZ:getNew()
    local mID = (common.binaryMirror(iD-1, nR) + 1)
    tA[iD]:Set(tF[mID]); if(not bW and iD <= N2) then
      tW[iD] = signals.getPhaseFactorDFT(iD-1, nR) end
  end; local cT = cZ:getNew()
  for iP = 1, nR do -- Generation of tF in phase iP
    for iK = 1, nN do -- Write down the cached phase factor
      cT:Set(tW[convIndexDFT(iP, bit.band(iK-1, iM-1), N2)])
      if(bit.band(iM, iK-1) ~= 0) then local iL = iK - iM
        tF[iK]:Set(tA[iL]):Sub(cT:Mul(tA[iK]))
      else local iL = iK + iM
        tF[iK]:Set(tA[iK]):Add(cT:Mul(tA[iL]))
      end -- One butterfly is completed
    end; for iD = 1, nN do tA[iD]:Set(tF[iD]) end
    iM = bit.lshift(iM, 1)
  end; return tA
end

return signals
