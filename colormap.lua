local math      = math
local colormap  = {}
local clMapping = {}
local clClamp   = {0, 255}
local clHash    = {
  R = {1, "r", "R", "red"  , "Red"  , "RED"  },
  G = {2, "g", "G", "green", "Green", "GREEN"},
  B = {3, "b", "B", "blue" , "Blue" , "BLUE" }
}

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

local function selectKeyValue(tTab, tKeys, aKey)
  if(aKey) then return tTab[aKey] end
  local out; for ID = 1, #tKeys do
    local key = tKeys[ID]; out = (tTab[key] or out)
    if(out) then return out end
  end; return nil
end

--[[ https://en.wikipedia.org/wiki/HSL_and_HSV ]]
local function projectColorHC(h,c)
  local hp = h / 60
  local x  = c * (1 - math.abs((hp % 2) - 1))
  if(hp >= 0 and hp < 1) then return c, x , 0 end
  if(hp >= 1 and hp < 2) then return x, c , 0 end
  if(hp >= 2 and hp < 3) then return 0, c , x end
  if(hp >= 3 and hp < 4) then return 0, x , c end
  if(hp >= 4 and hp < 5) then return x, 0 , c end
  if(hp >= 5 and hp < 6) then return c, 0 , x end
  return 0, 0, 0
end

function colormap.getColorBlackRGB () return 0  ,  0,  0 end
function colormap.getColorRedRGB   () return 255,  0,  0 end
function colormap.getColorGreenRGB () return 0  ,255,  0 end
function colormap.getColorBlueRGB  () return 0  ,  0,255 end
function colormap.getColorYellowRGB() return 255,255,  0 end
function colormap.getColorCyanRGB  () return 0  ,255,255 end
function colormap.getColorMagenRGB () return 255,  0,255 end
function colormap.getColorWhiteRGB () return 255,255,255 end

function colormap.getColorRotateLeft(r, g, b) return g, b, r end
function colormap.getColorRotateRigh(r, g, b) return b, r, g end

local function roundValue(nE, nF)
  local nE = tonumber(nE); if(not nE) then
    return logStatus("colormap.roundValue: NAN {"..type(nE).."}<"..tostring(nE)..">") end
  local nF = (tonumber(nF) or 0); if(nF == 0) then
    return logStatus("colormap.roundValue: Fraction must be <> 0") end
  local q, f = math.modf(nE/nF)
  return nF * (q + (f > 0.5 and 1 or 0))
end

-- H [0,360], S [0,1], V [0,1]
function colormap.getColorHSV(h,s,v)
  local c = v * s
  local m = v - c
  local r, g, b = projectColorHC(h,c)
  return roundValue(clClamp[2] * (r + m),1),
         roundValue(clClamp[2] * (g + m),1),
         roundValue(clClamp[2] * (b + m),1)
end

-- H [0,360], S [0,1], L [0,1]
function colormap.getColorHSL(h,s,l)
  local c = (1 - math.abs(2*l - 1)) * s
  local m = l - 0.5*c
  local r, g, b = projectColorHC(h,c)
  return roundValue(clClamp[2] * (r + m),1),
         roundValue(clClamp[2] * (g + m),1),
         roundValue(clClamp[2] * (b + m),1)
end

-- H [0,360], C [0,1], L [0,1]
function colormap.getColorHCL(h,c,l)
  local r, g, b = projectColorHC(h,c)
  local m = l - (0.30*r + 0.59*g + 0.11*b)
  return roundValue(clClamp[2] * (r + m),1),
         roundValue(clClamp[2] * (g + m),1),
         roundValue(clClamp[2] * (b + m),1)
end

function colormap.getClamp(vN)
  local nN = tonumber(vN); if(not nN) then
    return logStatus("colormap.getClamp: NAN {"..type(nN).."}<"..tostring(nN)..">") end
  if(nN <= clClamp[1]) then return clClamp[1] end
  if(nN >= clClamp[2]) then return clClamp[2] end; return math.floor(nN)
end

function colormap.printColorMap(sKey, ...)
  if(type(sKey) == "number") then
    local tArg = {...}; local r, g, b = sKey, tArg[1], tArg[2]
    return logStatus("colormap.printColorMap: {"..tostring(r)..","..tostring(g)..","..tostring(b).."}")
  end; local sKey = tostring(sKey)
  local tRgb = clMapping[sKey]; if(not tRgb) then
    return logStatus("colormap.printColorMap: No mapping for <"..sKey..">") end
  local tyRgb = type(tRgb); if(tyRgb ~= "table") then
    return logStatus("colormap.printColorMap: Internal structure is ["..tyRgb.."]<"..tostring(tRgb)..">") end
  local nRgb, pRef = #tRgb, "colormap.printColorMap["..sKey.."] "
  local fRgb = "%"..tostring(nRgb):len().."d"
  for ID = 1, nRgb do local tRow = tRgb[ID]
    local tyRow = type(tRow); if(tyRow == "table") then
      logStatus(pRef..fRgb:format(ID)..": {"..table.concat(tRow, ",").."}")
    else logStatus(pRef..fRgb:format(ID)..": ["..tyRow.."]<"..tostring(tRow)..">") end
  end
end

function colormap.setColorMap(sKey,tTable,bReplace)
  local tyTable = type(tTable); if(tyTable ~= "table") then
    return logStatus("colormap.getColorMap: Missing table argument",nil) end
  local sKey = tostring(sKey)
  local tRgb = clMapping[sKey]; if(tRgb and not bReplace) then
    return logStatus("colormap.getColorMap: Exists mapping for <"..sKey..">",nil) end
  clMapping[sKey] = tTable; if(not tTable.Size) then tTable.Size = #tTable end
  return clMapping[sKey]
end

function colormap.getColorMap(sKey,iNdex)
  local iNdex = (tonumber(iNdex) or 0); if(iNdex <= 0) then
    return logStatus("colormap.getColorMap: Missing index #"..tostring(iNdex), colormap.getColorBlackRGB()) end
  local sKey, tCl = tostring(sKey)
  local tRgb = clMapping[sKey]; if(not tRgb) then
    return logStatus("colormap.getColorMap: Missing mapping for <"..sKey..">", colormap.getColorBlackRGB()) end
  local cID = (iNdex % tRgb.Size + 1); tCl = tRgb[cID]
  if(not tCl) then tCl = tRgb.Miss end
  if(not tCl) then return colormap.getColorBlackRGB() end
  return colormap.getClamp(tCl[1]), colormap.getClamp(tCl[2]), colormap.getClamp(tCl[3])
end

--[[
  Colormap for fiery-red-yellow
  https://a4.pbase.com/o6/09/60809/1/79579853.u4uTlB2w.Elephantvalleyhistogramcolors.JPG
]]--
function colormap.getColorRegion(iDepth, maxDepth, iRegions)
  local sKey, iDepth = "getColorRegion", (tonumber(iDepth) or 0); if(iDepth <= 0) then
    logStatus("colormap.getColorRegion: Missing Region depth #"..iDepth,colormap.getColorBlackRGB()) end
  local maxDepth = (tonumber(maxDepth) or 0); if(maxDepth <= 0) then
    logStatus("colormap.getColorRegion: Missing Region max depth #"..maxDepth,colormap.getColorBlackRGB()) end
  local iRegions = (tonumber(iRegions) or 0); if(iRegions <= 0) then
    logStatus("colormap.getColorRegion: Missing Regions count #"..iRegions,colormap.getColorBlackRGB()) end
  if (iDepth == maxDepth) then return colormap.getColorBlackRGB() end
  -- Cache the damn thing as it is too heavy
  if(not clMapping[sKey]) then clMapping[sKey] = {} end
  if(not clMapping[sKey][iRegions]) then clMapping[sKey][iRegions] = {} end
  local arRegions = clMapping[sKey][iRegions][maxDepth]
  if(not clMapping[sKey][iRegions][maxDepth]) then
    clMapping[sKey][iRegions][maxDepth] = {{brd = (maxDepth / iRegions), foo = function(iTer) return iTer * 2, 0, 0 end}}
    arRegions = clMapping[sKey][iRegions][maxDepth]
    local oneThird = math.ceil(0.33 * iRegions)
    for regid = 2,iRegions do
      arRegions[regid] = {}
      arRegions[regid].brd = arRegions[regid - 1].brd + arRegions[1].brd
      if(regid <= oneThird and regid > 1) then
        arRegions[regid].foo = function(iTer)
          return colormap.getClamp((((iTer - arRegions[regid-1].brd) * arRegions[oneThird-regid+1].brd)
                 * arRegions[2].brd) + arRegions[2].brd), 0, 0
        end
      else
        arRegions[regid].foo = function(iTer)
          return clClamp[2], colormap.getClamp((((iTer - arRegions[regid-1].brd) * arRegions[1].brd)
                 / arRegions[regid-2].brd) + arRegions[regid-3].brd), clClamp[1]
        end
      end
    end
  end
  local lowBorder = 1
  for regid = 1, iRegions do
    local uppBorder = arRegions[regid].brd
    if(iDepth >= lowBorder and iDepth < uppBorder) then return arRegions[regid].foo(iDepth) end
    lowBorder = arRegions[regid].brd
  end
end

function stringExplode(sStr,sDel)
  local aLst, Ch, Idx, ID, dL = {""}, "", 1, 1, (sDel:len()-1)
  while(Ch) do
    Ch = sStr:sub(Idx,Idx+dL)
    if    (Ch ==  "" ) then return aLst
    elseif(Ch == sDel) then ID = ID + 1; aLst[ID], Idx = "", (Idx + dL)
    else aLst[ID] = aLst[ID]..Ch:sub(1,1) end; Idx = Idx + 1
  end; return aLst
end

local function tableToColorRGB(tTab, kR, kG, kB)
  if(not tTab) then return nil end
  local cR = colormap.getClamp(tonumber(selectKeyValue(tTab, clHash.R, kR)) or clClamp[1])
  local cG = colormap.getClamp(tonumber(selectKeyValue(tTab, clHash.G, kG)) or clClamp[1])
  local cB = colormap.getClamp(tonumber(selectKeyValue(tTab, clHash.B, kB)) or clClamp[1])
  return cR, cG, cB
end

function colormap.Convert(aIn, ...)
  local tArg, tyIn, cR, cG, cB = {...}, type(aIn)
  if(tyIn == "boolean") then
    cR = (aIn     and clClamp[2] or clClamp[1])
    cG = (tArg[1] and clClamp[2] or clClamp[1])
    cB = (tArg[2] and clClamp[2] or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "string") then
    local sDe = (tArg[1] and tostring(tArg[1]) or ",")
    local tCol = stringExplode(aIn,sDe)
    cR = colormap.getClamp(tonumber(tCol[1]) or clClamp[1])
    cG = colormap.getClamp(tonumber(tCol[2]) or clClamp[1])
    cB = colormap.getClamp(tonumber(tCol[3]) or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "number") then
    cR = colormap.getClamp(tonumber(aIn    ) or clClamp[1])
    cG = colormap.getClamp(tonumber(tArg[1]) or clClamp[1])
    cB = colormap.getClamp(tonumber(tArg[2]) or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "table") then return tableToColorRGB(aIn, tArg[1], tArg[2], tArg[3]) end
  return logStatus("colormap.Convert: Type <"..tyIn.."> not supported",nil)
end

return colormap
