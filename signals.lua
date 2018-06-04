-- Copyright (C) 2017 Deyan Dobromirov
-- Signal processing functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local signals = require('signals')`.")
  os.exit(1)
end

local tonumber          = tonumber
local tostring          = tostring
local type              = type
local setmetatable      = setmetatable
local math              = math
local bit               = bit
local signals           = {}
local metaSignals       = {}
local common            = require("common")
local complex           = require("complex")
local revArr            = common.tableArrReverse
local byteSTR           = common.bytesGetString
local byteUINT          = common.bytesGetNumber
local byteMirr          = common.binaryMirror
local isNumber          = common.isNumber
local isNil             = common.isNil
local logStatus         = common.logStatus
local toBool            = common.toBool
local isTable           = common.isTable
local getSign           = common.getSign
local binaryIsPower     = common.binaryIsPower
local binaryNextBaseTwo = common.binaryNextBaseTwo
local tableArrTransfer  = common.tableArrTransfer
local randomSetSeed     = common.randomSetSeed
local randomGetNumber   = common.randomGetNumber
local getPick           = common.getPick
local binaryNeededBits  = common.binaryNeededBits
local binaryMirror      = common.binaryMirror
local isFunction        = common.isFunction
local logConcat         = common.logConcat
local logString         = common.logString
local stringPadL        = common.stringPadL

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
  if(not W) then return logStatus("signals.readWave: No file <"..sNam..">") end
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
  if(gID ~= "RIFF") then return logStatus("signals.readWave: Header mismatch <"..gID..">") end
  gID = wData["HEADER"]["sRiffType"]
  if(gID ~= "WAVE") then return logStatus("signals.readWave: Header not wave <"..gID..">") end
  gID = wData["FORMAT"]["sGroupID"]
  if(gID ~= "fmt ") then return logStatus("signals.readWave: Format invalid <"..gID..">") end
  gID = wData["DATA"]["sGroupID"]
  if(gID ~= "data") then return logStatus("signals.readWave: Data invalid <"..gID..">") end

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
        logStatus("signals.readWave: Reached EOF for channel <"..curChan.."> sample <"..arrChan.__top..">")
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
      logStatus("signals.readWave: Reached EOF before chunk size <"..smpAll..">")
      smpAll = -1
    end
  end; W:close()
  return wData, smpData
end

-- Generate ramp signal
function signals.getRamp(nS, nE, nD)
  local tS, iD = {}, 1; for dD = nS, nE, nD do
    tS[iD] = dD; iD = iD + 1 end; return tS
end

-- Generate periodical signal
function signals.setWave(tD, fW, nW, tT, nT, tS)
  local nT, iD = (tonumber(nT) or 0), 1; while(tT[iD]) do
    local vS = (tS and tS[iD]); vS = vS and tS[iD] or 0
    tD[iD] = vS + fW(nW * tT[iD] + nT); iD = (iD+1)
  end; return tD
end

-- Weights the signal trough the given window
function signals.setWeight(tD, tS, tW, tA, tB)
  local bW, bA, bB = isNumber(tW), isNumber(tA), isNumber(tB)
  local iD = 1; while(tS[iD]) do
    local mW = (bW and tW or (tW and tonumber(tW[iD]) or 1))
    local mA = (bA and tA or (tA and tonumber(tA[iD]) or 0))
    local mB = (bB and tB or (tB and tonumber(tB[iD]) or 1))
    tD[iD] = tS[iD] * mW + mA * mB; iD = (iD+1)
  end; return tD
end

function signals.convCircleToLineFrq(nW)
  return (nW / (2 * math.pi))
end

function signals.convLineToCircleFrq(nF)
  return (2 * math.pi * nF)
end

function signals.convPeriodToLineFrq(nT)
  return (1 / nT)
end

function signals.convLineFrqToPeriod(nF)
  return (1 / nF)
end

-- Extend the signal by making a copy
function signals.getExtendBaseTwo(tS)
  local nL, tO = #tS, {}; if(binaryIsPower(nL)) then
    tableArrTransfer(tO, tS); return tO end
  local nT = binaryNextBaseTwo(nL)
  for iD = 1, nT do local vS = tS[iD]
    if(vS) then tO[iD] = vS else tO[iD] = 0 end end; return tO
end

-- Extend the signal without making a copy
function signals.setExtendBaseTwo(tS) local nL = #tS
  if(binaryIsPower(nL)) then return tS end
  local nS, nE = (nL+1), binaryNextBaseTwo(nL)
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
  local nA = getPick(vA, vA, 2.5)
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

-- Sinewave window of length N
function signals.winSine(nN)
  local tW, nN = {}, (nN-1)
  local nK = math.pi/nN
  for iD = 1, (nN+1) do
    tW[iD] = math.sin(nK*(iD-1))
  end; return tW
end

-- Parabolic window of length N
function signals.winParabolic(nN)
  local tW, nN = {}, (nN-1)
  local nK = nN/2
  for iD = 1, (nN+1) do
    tW[iD] = 1-(((iD-1)-nK)/nK)^2
  end; return tW
end

-- Hanning window of length N
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
    tP[iD] = getPick(vP, vP, tA[iD]) end
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
    tP[iD] = getPick(vP, vP, tA[iD]) end
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
    tP[iD] = getPick(vP, vP, tA[iD]) end
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
  local nR = binaryNeededBits(nN-1)
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
  local tW = getPick(bW, aW, {})
  for iD = 1, nN do tF[iD] = cZ:getNew(tF[iD]) end
  local nR, N2 = binaryNeededBits(nN-1), (nN / 2)
  for iD = 1, nN do tA[iD] = cZ:getNew()
    local mID = (binaryMirror(iD-1, nR) + 1)
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

--[[
* newNeuralNet: Class neural network manager
]]
local metaNeuralNet = {}
      metaNeuralNet.__index = metaNeuralNet
      metaNeuralNet.__type  = "signals.neuralnet"
      metaNeuralNet.__metatable = metaNeuralNet.__type
      metaNeuralNet.__tostring = function(oNet) return oNet:getString() end
local function newNeuralNet(sName)
  local self, mtData, mID, mName = {}, {}, 1, tostring(sName or "NET")
  local mfAct, mfOut, mfDif; randomSetSeed()
  function self:addLayer(...)
    local tArg = {...}; nArg = #tArg;
    mtData[mID] = {}; mtData[mID].V = {}
    if(mID > 1) then mtData[mID].W = {} end
    for k = 1, #tArg do
      if(not isTable(tArg[k])) then
        return logStatus("newNeuralNet.addLayer: Weight #"..tostring(k).." not table", self) end
      mtData[mID].V[k] = 0
      if(mID > 1) then mtData[mID].W[k] = {}
        for i = 1, #(mtData[mID-1].V) do
        mtData[mID].W[k][i] = (tArg[k][i] or randomGetNumber()) end
      end
    end; mID = mID + 1; return self
  end
  function self:getString()
    return ("["..metaNeuralNet.__type.."]: "..mName)
  end
  function self:remLayer()
    mtData[mID] = nil; mID = (mID - 1); return self
  end
  function self:Process()
    for k = 2, (mID-1) do
      local tN = mtData[k].V
      local tP = mtData[k-1].V
      local tW = mtData[k].W
      for i = 1, #tN do tN[i] = 0 end 
      for i = 1, #tN do
        for j = 1, #tP do if(tW[i][j]) then
          tN[i] = tN[i] + tW[i][j] * tP[j] end
        end
        if(mfAct) then tN[i] = mfAct(tN[i]) end
      end; return self
    end
  end
  function self:getOut(bOv)
    if(mID < 2) then return {} end
    local tV, vO = mtData[mID-1].V
    if(bOv and mfOut) then vO = mfOut(tV)
    else vO = {}; for k = 1, #tV do table.insert(vO, tV[k]) end
    end; return vO
  end
  function self:setValue(...)
    local tArg, tVal = {...}, mtData[1].V; nArg = #tArg
    for k = 1, #tVal do tVal[k] = tonumber(tArg[k] or 0) end
    return self
  end
  function self:setActive(fA, fD, fO)
    if(isFunction(fA)) then mfAct = fA 
      local bS, aR = pcall(mfAct, 0)
      if(not bS) then mfAct = logStatus("newNeuralNet.setActive(dif): Fail "..tostring(aR), self) end
    else mfAct = logStatus("newNeuralNet.setActive(act): Skip", self) end
    if(isFunction(fD)) then mfDif = fD 
      local bS, aR = pcall(mfDif, 0)
      if(not bS) then mfDif = logStatus("newNeuralNet.setActive(dif): Fail "..tostring(aR), self) end
    else mfDif = logStatus("newNeuralNet.setActive(dif): Skip", self) end
    if(isFunction(fO)) then mfOut = fO
      local bS, aR = pcall(mfOut, 0)
      if(not bS) then mfOut = logStatus("newNeuralNet.setActive(out): Fail "..tostring(aR), self) end
    else mfOut = logStatus("newNeuralNet.setActive(out): Skip", self) end
    return self
  end
  function self:getWeightLayer(vLay)
    local tW, mW = {}, mtData[iLay].W
    for k = 1, #mW do tW[k] = {}
      signals.setWeight(tW[k], mW[k])
    end; return tW
  end
  function self:getValueLayer(vLay)
    local iLay = math.floor(tonumber(vLay) or 0)
    local mV = mtData[iLay]; if(isNil(mV)) then
      return logStatus("newNeuralNet.trainLayer: Missing layer #"..tostring(vLay), self) end
    local tV, mV = {}, mV.V; for k = 1, #mV do tV[k] = mV[k]; end; return tV
  end
  function self:trainLayer(iLay, tSet, iTr, bL, vK)
    if(not isFunction(mfDif)) then
      return logStatus("newNeuralNet.trainLayer: Derivative missing", self) end
    if(iLay < 2) then return self end
    local nK = (tonumber(vK) or 1); if(bL) then logString("\nTraining:") end
    local tOut, tErr, tAdj = {}, {}, {}
    for k = 1, iTr do if(bL and ((k % 10000) == 0)) then logString(".") end
      for i = 1, #tSet do
        tOut[i] = self:setValue(unpack(tSet[i][1])):Process()
        if(isNil(tOut[i])) then return logStatus("newNeuralNet.trainLayer: Process fail", self) end
        tOut[i] = tOut[i]:getOut(); tErr[i], tAdj[i] = {}, {}
        signals.setWeight(tErr[i],tSet[i][2],1,tOut[i],-1)
        for j = 1, #tOut[i] do tAdj[i][j] = {}
          signals.setWeight(tAdj[i][j],tSet[i][1],tErr[i][j] * mfDif(tOut[i][j]) * nK)
          signals.setWeight(mtData[iLay].W[j],mtData[iLay].W[j],1,tAdj[i][j])
        end
      end
    end; if(bL) then logString("done\n") end; return self
  end
  function self:getNeuronsCnt()
    local nC = 0; for k = 2, (mID-1) do
      nC = nC + #mtData[k].V
    end return nC
  end
  function self:getWeightsCnt()
    local nC = 0; for k = 2, (mID-1) do
      local mW = mtData[k].W
      nC = nC + #mW * #(mW[1])
    end return nC
  end
  function self:getType() return metaNeuralNet.__type end
  function self:Dump(vL)
    local sT = self:getType()
    local iL = math.floor(tonumber(vL) or sT:len())
    logStatus("["..self:getType().."] Properties:")
    logStatus("  Name    : "..mName)
    logStatus("  Layers  : "..(mID-1))
    logStatus("  Neurons : "..self:getNeuronsCnt())
    logStatus("  Weights : "..self:getWeightsCnt())
    logStatus("  Interanal weights and and values status:")
    logConcat(stringPadL("V[1]",iL," "),", ", unpack(mtData[1].V))
    for k = 2, (mID-1) do local mW = mtData[k].W; for i = 1, #mW do
      logConcat(stringPadL("W["..(k-1).."->"..k.."]["..i.."]",iL," "),", ", unpack(mtData[k].W[i])) end
    logConcat(stringPadL("V["..k.."]",iL," "),", ", unpack(mtData[k].V))
    end; return self
  end; return self
end

--[[
* newControl: Class state processing manager
* nTo   > Controller sampling time in seconds
* arPar > Parameter array {Kp, Ti, Td, satD, satU}
]]
local metaControl = {}
      metaControl.__index = metaControl
      metaControl.__type  = "signals.control"
      metaControl.__metatable = metaControl.__type
      metaControl.__tostring = function(oControl) return oControl:getString() end
local function newControl(nTo, sName)
  local mTo = (tonumber(nTo) or 0); if(mTo <= 0) then -- Sampling time [s]
    return logStatus(nil, "newControl: Sampling time <"..tostring(nTo).."> invalid") end
  local self  = {}                 -- Place to store the methods
  local mfAbs = math and math.abs  -- Function used for error absolute
  local mfSgn = getSign            -- Function used for error sign
  local mErrO, mErrN  = 0, 0       -- Error state values
  local mvCon, meInt  = 0, true    -- Control value and integral enabled
  local mvP, mvI, mvD = 0, 0, 0    -- Term values
  local mkP, mkI, mkD = 0, 0, 0    -- P, I and D term gains
  local mpP, mpI, mpD = 1, 1, 1    -- Raise the error to power of that much
  local mbCmb, mbInv, mSatD, mSatU = true, false -- Saturation limits and settings
  local mName, mType, mUser = (sName and tostring(sName) or "N/A"), "", {}

  setmetatable(self, metaControl)

  function self:getTerm(kV,eV,pV) return (kV*mfSgn(eV)*mfAbs(eV)^pV) end
  function self:Dump() return logStatus(self:getString(), self) end
  function self:getGains() return mkP, mkI, mkD end
  function self:getTerms() return mvP, mvI, mvD end
  function self:setEnIntegral(bEn) meInt = toBool(bEn); return self end
  function self:getEnIntegral() return meInt end
  function self:getError() return mErrO, mErrN end
  function self:getControl() return mvCon end
  function self:getUser() return mUser end
  function self:getType() return mType end
  function self:getPeriod() return mTo end
  function self:setPower(pP, pI, pD)
    mpP, mpI, mpD = (tonumber(pP) or 0), (tonumber(pI) or 0), (tonumber(pD) or 0); return self end
  function self:setClamp(sD, sU) mSatD, mSatU = (tonumber(sD) or 0), (tonumber(sU) or 0); return self end
  function self:setStruct(bCmb, bInv) mbCmb, mbInv = toBool(bCmb), toBool(bInv); return self end

  function self:Reset()
    mErrO, mErrN  = 0, 0
    mvP, mvI, mvD = 0, 0, 0
    mvCon, meInt  = 0, true
    return self
  end

  function self:Process(vRef,vOut)
    mErrO = mErrN -- Refresh error state sample
    mErrN = (mbInv and (vOut-vRef) or (vRef-vOut))
    if(mkP > 0) then -- P-Term
      mvP = self:getTerm(mkP, mErrN, mpP) end
    if((mkI > 0) and (mErrN ~= 0) and meInt) then -- I-Term
      mvI = self:getTerm(mkI, mErrN + mErrO, mpI) + mvI end
    if((mkD ~= 0) and (mErrN ~= mErrO)) then -- D-Term
      mvD = self:getTerm(mkD, mErrN - mErrO, mpD) end
    mvCon = mvP + mvI + mvD  -- Calculate the control signal
    if(mSatD and mSatU) then -- Apply anti-windup effect
      if    (mvCon < mSatD) then mvCon, meInt = mSatD, false
      elseif(mvCon > mSatU) then mvCon, meInt = mSatU, false
      else meInt = true end
    end; return self
  end

  function self:getString()
    local sInfo = (mType ~= "") and (mType.."-") or mType
          sInfo = "["..sInfo..metaControl.__type.."] Properties:\n"
          sInfo = sInfo.."  Name : "..mName.." ["..tostring(mTo).."]s\n"
          sInfo = sInfo.."  Param: {"..tostring(mUser[1])..", "..tostring(mUser[2])..", "
          sInfo = sInfo..tostring(mUser[3])..", "..tostring(mUser[4])..", "..tostring(mUser[5]).."}\n"
          sInfo = sInfo.."  Gains: {P="..tostring(mkP)..", I="..tostring(mkI)..", D="..tostring(mkD).."}\n"
          sInfo = sInfo.."  Power: {P="..tostring(mpP)..", I="..tostring(mpI)..", D="..tostring(mpD).."}\n"
          sInfo = sInfo.."  Limit: {D="..tostring(mSatD)..",U="..tostring(mSatU).."}\n"
          sInfo = sInfo.."  Error: {"..tostring(mErrO)..", "..tostring(mErrN).."}\n"
          sInfo = sInfo.."  Value: ["..tostring(mvCon).."] {P="..tostring(mvP)
          sInfo = sInfo..", I="..tostring(mvI)..", D="..tostring(mvD).."}\n"; return sInfo
  end

  function self:Setup(arParam)
    if(type(arParam) ~= "table") then
      return logStatus("newControl.Setup: Params table <"..type(arParam).."> invalid") end

    if(arParam[1] and (tonumber(arParam[1] or 0) > 0)) then
      mkP = (tonumber(arParam[1] or 0))
    else return logStatus("newControl.Setup: P-gain <"..tostring(arParam[1]).."> invalid") end

    if(arParam[2] and (tonumber(arParam[2] or 0) > 0)) then
      mkI = (mTo / (2 * (tonumber(arParam[2] or 0)))) -- Discrete integral approximation
      if(mbCmb) then mkI = mkI * mkP end
    else logStatus("newControl.Setup: I-gain <"..tostring(arParam[2]).."> skipped") end

    if(arParam[3] and (tonumber(arParam[3] or 0) ~= 0)) then
      mkD = (tonumber(arParam[3] or 0) * mTo)  -- Discrete derivative approximation
      if(mbCmb) then mkD = mkD * mkP end
    else logStatus("newControl.Setup: D-gain <"..tostring(arParam[3]).."> skipped") end

    if(arParam[4] and arParam[5] and ((tonumber(arParam[4]) or 0) < (tonumber(arParam[5]) or 0))) then
      mSatD, mSatU = (tonumber(arParam[4]) or 0), (tonumber(arParam[5]) or 0)
    else logStatus("newControl.Setup: Saturation skipped <"..tostring(arParam[4]).."<"..tostring(arParam[5]).."> skipped") end
    mType = ((mkP > 0) and "P" or "")..((mkI > 0) and "I" or "")..((mkD > 0) and "D" or "")
    for ID = 1, 5, 1 do mUser[ID] = arParam[ID] end; return self -- Init multiple states using the table
  end

  function self:Mul(nMul)
    local Mul = (tonumber(nMul) or 0)
    if(Mul <= 0) then return self end
    for ID = 1, 5, 1 do mUser[ID] = mUser[ID] * Mul end
    self:Setup(mUser); return self -- Init multiple states using the table
  end

  return self
end

-- https://www.mathworks.com/help/simulink/slref/discretefilter.html
local metaPlant = {}
      metaPlant.__index     = metaPlant
      metaPlant.__type      = "signals.plant"
      metaPlant.__metatable = metaPlant.__type
      metaPlant.__tostring  = function(oPlant) return oPlant:getString() end
local function newPlant(nTo, tNum, tDen, sName)
  local mOrd = #tDen; if(mOrd < #tNum) then
    return logStatus("Plant physically impossible") end
  if(tDen[1] == 0) then
    return logStatus("Plant denominator invalid") end
  local self, mTo  = {}, (tonumber(nTo) or 0)
  if(mTo <= 0) then return logStatus("Plant sampling time <"..tostring(nTo).."> invalid") end
  local mName, mOut = tostring(sName or "Plant plant"), nil
  local mSta, mDen, mNum = {}, {}, {}

  for ik = 1, mOrd, 1 do mSta[ik] = 0 end
  for iK = 1, mOrd, 1 do mDen[iK] = (tonumber(tDen[iK]) or 0) end
  for iK = 1, mOrd, 1 do mNum[iK] = (tonumber(tNum[iK]) or 0) end
  for iK = 1, (mOrd - #tNum), 1 do table.insert(mNum,1,0); mNum[#mNum] = nil end

  function self:Scale()
    local nK = mDen[1]
    for iK = 1, mOrd do
      mNum[iK] = (mNum[iK] / nK)
      mDen[iK] = (mDen[iK] / nK)
    end; return self
  end

  function self:getString()
    local sInfo = "["..metaPlant.__type.."] Properties:\n"
    sInfo = sInfo.."  Name       : "..mName.."^"..tostring(mOrd).." ["..tostring(mTo).."]s\n"
    sInfo = sInfo.."  Numenator  : {"..table.concat(mNum,", ").."}\n"
    sInfo = sInfo.."  Denumenator: {"..table.concat(mDen,", ").."}\n"
    sInfo = sInfo.."  States     : {"..table.concat(mSta,", ").."}\n"; return sInfo
  end
  function self:Dump() return logStatus(self:getString(), self)  end
  function self:getOutput() return mOut end

  function self:getBeta()
    local nOut, iK = 0, mOrd
    while(iK > 0) do
      nOut = nOut + (mNum[iK] or 0) * mSta[iK]
      iK = iK - 1 -- Get next state
    end; return nOut
  end

  function self:getAlpha()
    local nOut, iK = 0, mOrd
    while(iK > 1) do
      nOut = nOut - (mDen[iK] or 0) * mSta[iK]
      iK = iK - 1 -- Get next state
    end; return nOut
  end

  function self:putState(vX)
    local iK, nX = mOrd, (tonumber(vX) or 0)
    while(iK > 0 and mSta[iK]) do
      mSta[iK] = (mSta[iK-1] or 0); iK = iK - 1 -- Get next state
    end; mSta[1] = nX; return self
  end

  function self:Process(vU)
    local nU, nA = (tonumber(vU) or 0), self:getAlpha()
    self:putState((nU + nA) / mDen[1]); mOut = self:getBeta(); return self
  end

  function self:Reset()
    for iK = 1, #mSta, 1 do mSta[iK] = 0 end; mOut = 0; return self
  end

  return self
end

function signals.New(sType, ...)
  local sType = "signals."..tostring(sType or "")
  if(sType == metaControl.__type) then return newControl(...) end
  if(sType == metaPlant.__type) then return newPlant(...) end
  if(sType == metaNeuralNet.__type) then return newNeuralNet(...) end
end

return signals
