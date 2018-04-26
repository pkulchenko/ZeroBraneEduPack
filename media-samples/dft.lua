require("turtle")
local common   = require("common")
local complex  = require("complex")
local chartmap = require("chartmap")
local signals  = require("signals")
local colormap = require("colormap")

local ws = 200               -- Signal frequency
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

local scOpe = chartmap.New("scope"):setInterval(intX, intY)
      scOpe:setUpdate():setColor():setDelta(et / 10, 0.1)

local tim = os.clock()
local dft = signals.getForwardDFT(s); tim = ((os.clock()-tim) * 1000)

open("Discrete Fourier Transform (DFT) graph (red) and sampled signal (blue)")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

scOpe:Draw(true, false, true)
scOpe:drawGraph(s, t)

local xft, mft, tft, aft = {}, 0, 0, #dft
for i = 1, aft/2 do
  local nrm = dft[i]:getNorm()
  if(nrm > mft) then
    mft, tft = nrm, i
  end
end

for i = 1, aft do
  local nrm = dft[i]:getNorm()
  xft[i] = (nrm / mft) * 2 - 1
end
local dhz = (fs/(#xft-1))

intX:setBorderIn(1, #dft)
scOpe:setInterval(intX, intY):setUpdate()
scOpe:setColorDir(colr(colormap.getColorRedRGB())):drawGraph(xft); updt()

common.logStatus("DFT scale uses "..dhz.." Hz per division. Main frequency is at "..(tft-1)*dhz.. " of "..ws)
common.logStatus("DFT was calculated for "..tim.." milliseconds")

wait()
