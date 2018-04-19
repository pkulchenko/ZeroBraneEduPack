require("turtle")
local common = require("common")
local col = require("colormap")
local crt = require("chartmap")
local wav = require("media-samples/lib/wav")

-- https://blogs.msdn.microsoft.com/dawate/2009/06/23/intro-to-audio-programming-part-2-demystifying-the-wav-format/

local wData, smpData = wav.read("media-samples/crickets.wav")

common.logTable(wData)
common.logStatus("Array  samples: <"..(smpData[1].__top-1)..">")
common.logStatus("Record samples: <"..wData["DATA"]["dwSamplesPerChan"]..">")
local smpFrac = math.floor(wData["DATA"]["dwSamplesPerChan"]/100)
local tData, iTop = smpData[1], smpFrac
local dX,dY = smpFrac/10, 0.1
local W , H = 800, 500
local minX, maxX = 1, iTop
local minY, maxY = -1.2, 1.2
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local trWAV = crt.New("tracer","WAV"):setInterval(intX, intY)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clBlu = colr(col.getColorBlueRGB())
local clRed = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local crWAV = crt.New("coordsys"):setDelta(dX, dY):setBorder(minX, maxX, minY, maxY)
      crWAV:setSize(W, H):setColor(clBlk, clGry):setInterval(intX, intY)
 
open("Wave file plotter")
size(W,H); zero(0, 0); updt(false) -- disable auto updates

crWAV:Draw(true, true, true)

for i = 1, iTop do
  trWAV:putValue(i, tData[i]):Draw(clBlu); updt()
end

wait()


