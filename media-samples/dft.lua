require("turtle")
local common   = require("common")
local complex  = require("complex")
local chartmap = require("chartmap")
local signals  = require("signals")
local colormap = require("colormap")

local ws = 50                -- Signal frequency
local fs = 2500              -- Sampling rate
local et = 1/10              -- End time (seconds)
local es = et * fs           -- Total samples
local pr = 1 / fs            -- Time per sample
local w = (2 * math.pi * ws) -- Signal angular frequency
local s, t, i = {}, {}, 1    -- Arry containing samples and time
for d = 0, et, pr do
  t[i] = d
  s[i] = math.sin(w * t[i])
  i = i + 1
end

local W, H = 1000, 600
local intX  = chartmap.New("interval","WinX", 0, et, 0, W)
local intY  = chartmap.New("interval","WinY", -1, 1, H, 0)

local crSys = chartmap.New("coordsys"):setInterval(intX, intY)
      crSys:setUpdate():setColor():setDelta(et / 10, 0.1)

open("Discrete Fourier Transform (DFT) graph (red) and sampled signal (blue)")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

crSys:Draw(true, false, true)
crSys:drawGraph(s, t)

local dft = signals.getDFT(s)
local xft, mft = {}, 0
for i = 1, #dft do
  if(mft < dft[i]:getNorm()) then mft = dft[i]:getNorm() end
end
for i = 1, #dft do
  xft[i] = (dft[i]:getNorm() / mft) * 2 - 1
end

intX:setBorderIn(1, #dft)
crSys:setInterval(intX, intY):setUpdate()
crSys:setColorDir(colr(colormap.getColorRedRGB())):drawGraph(xft); updt()

wait()
