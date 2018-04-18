require("turtle")
local common = require("common")
local wav = require("media-samples/lib/wav")
-- https://blogs.msdn.microsoft.com/dawate/2009/06/23/intro-to-audio-programming-part-2-demystifying-the-wav-format/

local wData, smpData = wav.read("media-samples/crickets.wav")

common.logTable(wData)
