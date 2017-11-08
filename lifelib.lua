local lifelib   = {}

local pairs     = pairs
local tonumber  = tonumber
local tostring  = tostring
local type      = type
local io        = io
local metaShape = {}
local metaField = {}

--------------------------- ALIVE / DEAD / PATH -------------------------------

local Aliv = "O"
local Dead = "-"
local ShapePath = "game-of-life/shapes/"

local function logStatus(anyMsg, ...)
  io.write(tostring(anyMsg).."\n"); return ...
end

local function getSign(anyVal)
  local nVal = (tonumber(anyVal) or 0); return ((nVal > 0 and 1) or (nVal < 0 and -1) or 0)
end

local function getValuesSED(Val,Min,Max)
  local s = (Val > 0) and Min or Max
  local e = (Val > 0) and Max or Min
  local d = getSign(e - s)
  return s, e, d
end

local function arMalloc2D(w,h)
  local Arr = {}
  for y=1,h do
    Arr[y] = {}
    for x=1,w do
      Arr[y][x]=0
    end
  end
  return Arr
end

local function arRotateR(Arr,sX,sY)
  local Tmp = arMalloc2D(sY,sX)
  local ii, jj = 1, 1
  for j = 1, sX, 1 do
    for i = sY, 1, -1  do
      if(jj > sY) then
        ii = ii + 1
        jj = 1
      end
      Tmp[ii][jj] = Arr[i][j]
      Arr[i][j]   = nil
      jj = jj + 1
    end
  end
  for i = 1, sX do
    Arr[i] = {}
    for j = 1, sY  do
      Arr[i][j] = Tmp[i][j]
    end
  end
end

local function arRotateL(Arr,sX,sY)
  local Tmp = arMalloc2D(sY,sX)
  local ii, jj = 1, 1
  for j = sX, 1, -1 do
    for i = 1, sY, 1  do
      if(jj > sY) then
        ii = ii + 1
        jj = 1
      end
      Tmp[ii][jj] = Arr[i][j]
      Arr[i][j]   = nil
      jj = jj + 1
    end
  end
  for i = 1, sX do
    Arr[i] = {}
    for j = 1, sY  do
      Arr[i][j] = Tmp[i][j]
    end
  end
end

local function arShift2D(Arr,sX,sY,nX,nY)
  if( not( sX > 0 and sY > 0) ) then return end
  local x = math.floor(nX or 0)
  local y = math.floor(nY or 0)
  local Tmp = 0
  if(x ~= 0) then
    local sx,ex,dx = getValuesSED(x,sX,1)
    local M
    for i = 1,sY do
      for j = sx,ex,dx do
        M = j-x
        if(M >= 1 and M <= sX) then
          Arr[i][j] = Arr[i][M]
        else
          Arr[i][j] = 0
        end
      end
    end
  end
  if(y ~= 0) then local M
    local sy,ey,dy = getValuesSED(y,sY,1)
    for i = sy,ey,dy do
      for j = 1,sX do
        M = i-y
        if(M >= 1 and M <= sY) then
          Arr[i][j] = Arr[M][j]
        else
          Arr[i][j] = 0
        end
      end
    end
  end
end

local function arRoll2D(Arr,sX,sY,nX,nY)
  if( not( sX > 0 and sY > 0) ) then return end
  local x = math.floor(nX or 0)
  local y = math.floor(nY or 0)
  if(y ~= 0) then
    local MaxY = (y > 0) and sY or 1
    local MinY = (y > 0) and 1 or sY
    local siY  = getSign(y)
          y    = y * siY
    local arTmp = {}
    while(y > 0) do
      for i = 1,sX do
        arTmp[i] = Arr[MaxY][i]
      end
      arShift2D(Arr,sX,sY,0,siY)
      for i = 1,sX do
        Arr[MinY][i] = arTmp[i]
      end
      y = y - 1
    end
  end
  if(x ~= 0) then
    local MaxX = (x > 0) and sX or 1
    local MinX = (x > 0) and 1 or sX
    local siX  = getSign(x)
          x    = x * siX
    local arTmp = {}
    while(x > 0) do
      for i = 1,sY do
        arTmp[i] = Arr[i][MaxX]
      end
      arShift2D(Arr,sX,sY,siX)
      for i = 1,sY do
        Arr[i][MinX] = arTmp[i]
      end
      x = x - 1
    end
  end
end

local function arMirror2D(Arr,sX,sY,fX,fY)
  local Tmp, s
  if(fY) then
    Tmp, s = 0, 1
    local e = sY
    while(s < e) do
      for k = 1,sX do
        Tmp = Arr[s][k]
        Arr[s][k] = Arr[e][k]
        Arr[e][k] = Tmp
      end
      s, e = (s + 1), (e - 1)
    end
  end
  if(fX) then
    Tmp, s = 0, 1
    local e = sX
    while(s < e) do
      for k = 1,sY do
        Tmp = Arr[k][s]
        Arr[k][s] = Arr[k][e]
        Arr[k][e] = Tmp
      end
      s, e = (s + 1), (e - 1)
    end
  end
end

local function strExplode(sStr,sDel)
  local List, Ch, Idx, ID, dL = {""}, "", 1, 1, (sDel:len()-1)
  while(Ch) do
    Ch = sStr:sub(Idx,Idx+dL)
    if    (Ch ==  "" ) then return List
    elseif(Ch == sDel) then ID = ID + 1; List[ID], Idx = "", (Idx + dL)
    else List[ID] = List[ID]..Ch:sub(1,1) end; Idx = Idx + 1
  end; return List
end

local function strImplode(tList,sDel)
  local ID, Str = 1, ""
  local Del = tostring(sDel or "")
  while(tList and tList[ID]) do
    Str = Str..tList[ID]; ID = ID + 1
    if(tList[ID] and sDel ~= "") then Str = Str..Del end
  end; return Str
end

local function stringTrim(sStr, sWhat)
  local sWhat = (sWhat or "%s")
  return sStr:match("^"..sWhat.."*(.-)"..sWhat.."*$") or sStr
end

lifelib.charAliv = function (sA)
  if(not sA) then return Aliv end
  local sA = tostring(sA):sub(1,1)
  if(sA ~= "" and sA ~= Dead) then Aliv = sA; return true end
  return false
end

lifelib.charDead = function(sD)
  if(not sD) then return Dead end
  local sD = tostring(sD):sub(1,1)
  if(sD ~= "" and sD ~= Aliv) then Dead = sD; return true end
  return false
end

lifelib.shapesPath = function(sData)
  if(not sData) then return ShapePath end
  local Typ = type(sData)
  if(Typ == "string" and sData ~= "") then
    ShapePath = stringTrim(sData:gsub("\\","/"),"/")
    return logStatus("Shapes location: "..ShapePath,true)
  end; return false
end

--------------------------- RULES -------------------------------

lifelib.getDefaultRule = function() -- Conway
  return { Name = "B3/S23", Data = { B = {3}, S = {2,3} } }
end

lifelib.getRuleBS = function(sStr)
  local BS = {Name = tostring(sStr or "")}
  if(BS.Name == "") then 
    return logStatus("getRuleBS: Empty rule") end
  local expBS = strExplode(BS.Name,"/")
  if(not (expBS[1] and expBS[2])) then 
    return logStatus("getRuleBS: Rule invalid <"..BS.Name..">") end
  local kB, kS = expBS[1]:sub(1,1)  , expBS[2]:sub(1,1)
  if(kB ~= "B") then return logStatus("getRuleBS: Born invalid <"..BS.Name..">") end
  if(kS ~= "S") then return logStatus("getRuleBS: Surv invalid <"..BS.Name..">") end
  local bI, sI = 2, 2; BS[kB], BS[kS] = {}, {}
  local cB, cS = expBS[1]:sub(bI,bI), expBS[2]:sub(sI,sI)
  while(cB ~= "" or cS ~= "") do
    local nB, nS = tonumber(cB), tonumber(cS)
    if(nB) then BS[kB][#BS.B + 1] = nB end
    if(nS) then BS[kS][#BS.S + 1] = nS end
    bI, sI = (bI + 1), (sI + 1)
    cB, cS = expBS[1]:sub(bI,bI), expBS[2]:sub(sI,sI)
  end; if(BS[kB][1] and BS[kS][1]) then return BS end
  return logStatus("getRuleBS: Population fail <"..BS.Name..">")
end

lifelib.getRleSettings = function(sStr)
  local Cpy = sStr..","
  local Len, Key = Cpy:len(), nil
  local Che, Exp, S, E = "", {}, 1, 1
  while(E <= Len) do
    Che = Cpy:sub(E,E)
    if(Che == "=") then
      Key = stringTrim(Cpy:sub(S,E-1))
      S = E + 1; E = E + 1
    elseif(Che == ",") then
      Exp[Key] = stringTrim(Cpy:sub(S,E-1))
      S = E + 1; E = E + 1
    end
    E = E + 1
  end
  return Exp
end

------------------- SHAPE INIT --------------------

local function copyShape(argShape,w,h)
  if(not argShape) then return false end
  if(not (w and h)) then return false end
  if(not (w > 0 and h > 0)) then return false end
  Rez = arMalloc2D(w,h)
  for i = 0,h-1 do for j = 0,w-1 do
      Rez[i+1][j+1] = tonumber(argShape[i*w+j+1]) or 0
  end end; return Rez
end

local function initStruct(sName)
  local Shapes = {
  ["heart"]       = { 1,0,1,
                      1,0,1,
                      1,1,1;
                      w = 3, h = 3 },
  ["glider"]      = { 0,0,1,
                      1,0,1,
                      0,1,1;
                      w = 3, h = 3 },
  ["explode"]     = { 0,1,0,
                      1,1,1,
                      1,0,1,
                      0,1,0;
                      w = 3, h = 4 },
  ["fish"]        = { 0,1,1,1,1,
                      1,0,0,0,1,
                      0,0,0,0,1,
                      1,0,0,1,0;
                      w = 5, h = 4 },
  ["butterfly"]   = { 1,0,0,0,1,
                      0,1,1,1,0,
                      1,0,0,0,1,
                      1,0,1,0,1,
                      1,0,0,0,1;
                      w = 5, h = 5 },
  ["glidergun"]   = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,
                     0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,
                     1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     1,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                     w = 36,h = 9},
  ["block"]       = {1,1,1,1;
                     w = 2, h = 2},
  ["blinker"]     = {1,1,1;
                     w = 3, h = 1},
  ["r_pentomino"] = {0,1,1,
                     1,1,0,
                     0,1,0;
                     w = 3, h = 3},
  ["pulsar"]      ={0,0,1,1,1,0,0,0,1,1,1,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    0,0,1,1,1,0,0,0,1,1,1,0,0,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,1,1,1,0,0,0,1,1,1,0,0,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    1,0,0,0,0,1,0,1,0,0,0,0,1,
                    0,0,0,0,0,0,0,0,0,0,0,0,0,
                    0,0,1,1,1,0,0,0,1,1,1,0,0;
                    w = 13, h = 13}
  }
  return Shapes[sName:lower()]
end

local function initStringText(sStr,sDel)
  local sStr = tostring(sStr or "")
  local sDel = tostring(sDel or "\n"):sub(1,1)
  local Rows = strExplode(sStr,sDel)
  local Rall = StrImplode(Rows)
  local Shape = {w = Rows[1]:len(), h = #Rows}
  for k = 1,(Shape.w * Shape.h) do
    Shape[k] = (Rall:sub(k,k) == Aliv) and 1 or 0
  end; return Shape
end

local function initStringRle(sStr, sDel, sEnd)
  local nS, nE, Ch
  local Cnt, Ind, Lin = 1, 1, true
  local Len = sStr:len()
  local Num, toNum, isNum = 0, 0, false
  local Shape = {w = 0, h = 0}
  local sDel = tostring(sDel or "$"):sub(1,1)
  local sEnd = tostring(sEnd or "!"):sub(1,1)
  while(Cnt <= Len) do
    Ch = sStr:sub(Cnt,Cnt)
    if(Ch == sEnd) then Shape.h = Shape.h + 1; break end
    toNum = tonumber(Ch)
    if(not isNum and toNum) then
      -- Start of a number
      isNum = true; nS = Cnt
    elseif(not toNum and isNum) then
      -- End of a number
      isNum = false; nE = Cnt - 1
      Num   = tonumber(sStr:sub(nS,nE)) or 0
    end
    if(Num > 0) then
      if(Lin) then Shape.w = Shape.w + Num end
      while(Num > 0) do
        Shape[Ind] = (((Ch == Aliv) and 1) or 0)
        Ind = Ind + 1
        Num = Num - 1
      end;
    elseif(Ch ~= sDel and Ch ~= sEnd and not isNum) then
      if(Lin) then Shape.w = Shape.w + 1 end
      Shape[Ind] = (((Ch == Aliv) and 1) or 0)
      Ind = Ind + 1
    elseif(Ch == sDel) then Shape.h = Shape.h + 1; Lin = false end
    Cnt = Cnt + 1
  end; return Shape
end

local function initFileLif105(sName)
  local N = ShapePath.."/lif/"..sName:lower().."_105.lif"; F = io.open(N,"rb")
  if(not F) then return logStatus("initFileLif105: Invalid file: <"..N..">",nil) end
  local Line, ID, CH, Data = "", 1, 1, {}
  local Shape = {w = 0, h = 0, Header = {}, Offset = {Cent = {}}}
  while(Line) do
    Line = F:read()
    if(not Line) then break end
    Line = stringTrim(Line)
    cFirst = Line:sub(1,1)
    leLine = Line:len()
    if(cFirst == "#") then
      local lnData  = stringTrim(Line:sub(2,-1))
      local cSecond = lnData:sub(1,1)
      if(cSecond == "P") then
        local sCoord = stringTrim(lnData:sub(2,leLine))
        local Center = sCoord:find(" ")
        Shape.Offset.Cent[1] = -tonumber(sCoord:sub(1,Center-1))
        Shape.Offset.Cent[2] = -tonumber(sCoord:sub(Center+1,sCoord:len()))
      else Shape.Header[ID] = Line:sub(2,leLine); ID = ID + 1 end
    else
      Shape.h = Shape.h + 1; Data[Shape.h] = {}
      if(leLine >= Shape.w) then Shape.w = leLine end
      for CH = 1, leLine do
        Data[Shape.h][CH] = ((Line:sub(CH,CH) == Aliv) and 1 or 0) end
    end
  end; F:close()
  for ID = 1, Shape.h do
    for CH = 1, Shape.w do
      Shape[(ID-1)*Shape.w+CH] = (Data[ID][CH] or 0)
    end
  end; return Shape
end

local function initFileLif106(sName)
  local N = ShapePath.."/lif/"..sName:lower().."_106.lif"; F = io.open(N,"rb")
  if(not F) then return logStatus("initFileLif106: Invalid file: <"..N..">",nil) end
  local Line, ID, CH, Data, Offset = "", 1, 1, {}, {}
  local MinX, MaxX, MinY, MaxY, x, y
  local Shape = {w = 0, h = 0, Header = {}}
  while(Line) do
    Line = F:read()
    if(not Line) then break end
    Line = stringTrim(Line)
    cFirst, leLine = Line:sub(1,1), Line:len()
    if(not (tonumber(cFirst) or cFirst == "+" or cFirst == "-" )) then
      Shape.Header[ID] = Line:sub(2,leLine) or ""; ID = ID + 1
    else
      ID = Line:find("%s")
      if(MinX and MaxX and MinY and MaxY and x and y) then
        x = tonumber(Line:sub(1,ID-1))
        y = tonumber(Line:sub(ID+1,leLine))
        if(x and y) then
          if(x > MaxX) then MaxX = x end
          if(x < MinX) then MinX = x end
          if(y > MaxY) then MaxY = y end
          if(y < MinY) then MinY = y end
        else return logStatus("Coordinates conversion failed !", nil) end
      else
        x = tonumber(Line:sub(1,ID-1)) or 0
        y = tonumber(Line:sub(ID+1,leLine)) or 0
        MaxX, MinX = x, x
        MaxY, MinY = y, y
      end
      Data[CH] = {x=x,y=y}; CH = CH + 1
    end
  end
  Shape.w = MaxX - MinX + 1
  Shape.h = MaxY - MinY + 1
  Offset.TopL = { MinX, MinY }
  Offset.TopR = { MaxX, MinY }
  Offset.BotL = { MinX, MaxY }
  Offset.BotR = { MaxX, MaxY }
  Offset.Cent = {x=math.floor(Shape.w/2), y=math.floor(Shape.h/2)}
  for ID = 1, Shape.w*Shape.h do Shape[ID] = 0 end
  CH = 1; while(Data[CH]) do
    local xyAlv = Data[CH]
    local xAlv  = Offset.Cent.x + Data[CH].x
    local yAlv  = Offset.Cent.y + Data[CH].y
    Shape[yAlv*Shape.w+xAlv+1], CH = 1, (CH + 1)
  end; F:close(); return Shape
end

local function initFileRle(sName)
  local N = ShapePath.."/rle/"..sName:lower()..".rle"; F = io.open(N,"rb")
  if(not F) then
    return logStatus("initFileRle: Invalid file: <"..N..">",nil) end
  local FilePos, ChCnt, leLine
  local Line, cFirst =  "",  ""
  local nS, nE, Ind, Cel = 1, 1, 1, 1
  local Num, isNum, toNum = 0, false, nil
  local Shape = {w = 0, h = 0, Rule = { Name = "", Data = {}}, Header = {}}
  while(Line) do
    Line = F:read()
    if(not Line) then break end
    Line = stringTrim(Line)
    cFirst = Line:sub(1,1)
    leLine = Line:len()
    if(cFirst == "#") then
      Shape.Header[Ind] = Line:sub(2,leLine)
      Ind = Ind + 1
    elseif(cFirst == "x") then
      local Settings = lifelib.getRleSettings(Line)
      Shape.w = tonumber(Settings["x"])
      Shape.h = tonumber(Settings["y"])
      Shape.Rule.Name = Settings["rule"]
      Shape.Rule.Data = lifelib.getRuleBS(Shape.Rule.Name)
    else
      nS, nE, ChCnt, leLine = 1, 1, 1, Line:len()
      while(ChCnt <= leLine) do
        cFirst = Line:sub(ChCnt,ChCnt)
        if(cFirst == "!") then break end
        toNum = tonumber(cFirst)
        if    (not isNum and toNum) then isNum = true ; nS = ChCnt -- Start of a number
        elseif(not toNum and isNum) then isNum = false; nE = ChCnt - 1 -- End of a number
          Num = tonumber(Line:sub(nS,nE)) or 0 end
        if(Num > 0) then
          while(Num > 0) do
            Shape[Cel] = (((cFirst == Aliv) and 1) or 0)
            Cel = Cel + 1; Num = Num - 1
          end
        elseif(cFirst ~= "$" and cFirst ~= "!" and not isNum ) then
          Shape[Cel] = (((cFirst == Aliv) and 1) or 0); Cel = Cel + 1
        end; ChCnt = ChCnt + 1
      end
    end
  end; F:close(); return Shape
end

local function initFileCells(sName)
  local N = ShapePath.."/cells/"..sName:lower()..".cells"; F = io.open(N,"rb")
  if(not F) then
    return logStatus("initFileCells: Invalid file: <"..N..">",nil) end
  local x, y, Lenw = 0, 0, 0, 1
  local Line, ID, CH, Data = "", 1, 1, {}
  local Shape = {w = 0, h = 0, Header = {}}
  while(Line) do
    Line = F:read()
    if(not Line) then break end
    Line = stringTrim(Line)
    Firs = Line:sub(1,1)
    Lenw = Line:len()
    if(Firs ~= "!") then
      Shape.h = Shape.h + 1; Data[Shape.h] = {}
      if(Lenw >= Shape.w) then Shape.w = Lenw end
      for CH = 1, Lenw do
        Data[Shape.h][CH] = ((Line:sub(CH,CH) == Aliv) and 1 or 0) end
    else
      Shape.Header[ID] = Line:sub(2,Lenw)
      ID = ID + 1
    end
  end; F:close()
  for ID = 1, Shape.h do
    for CH = 1, Shape.w do
      Shape[(ID-1)*Shape.w+CH] = (Data[ID][CH] or 0)
    end
  end; return Shape
end

local function drawConsole(F)
  local tArr = F:getArray()
  local fx   = F:getW()
  local fy   = F:getH()
  logStatus("Generation: "..(F:getGenerations() or "N/A"))
  local Line=""
  for y = 1, fy do for x = 1, fx do
      Line = Line..(((tArr[y][x]~=0) and Aliv) or Dead)
  end; logStatus(Line); Line = "" end
end

local function getSumStatus(nStatus,nSum,tRule)
  if(nStatus == 1) then -- Check survive
    for _, v in ipairs(tRule.Data["S"]) do
      if(v == nSum) then return 1 end
    end; return 0
  elseif(nStatus == 0) then -- Check born
    for _, v in ipairs(tRule.Data["B"]) do
      if(v == nSum) then return 1 end
    end; return 0
  end
end

--[[
 * Creates a field object used for living environment for the shapes ( organisms )
]]--
lifelib.makeField = function(w,h,sRule)
  local self  = {}
  local w = tonumber(w) or 0
        w = (w >= 1) and w or 1
  local h = tonumber(h) or 0
        h = (h >= 1) and h or 1
  local Gen, Rule = 0
  local Old = arMalloc2D(w,h)
  local New = arMalloc2D(w,h)
  local Draw = {["text"] = drawConsole}
  if(type(sRule) ~= "string") then
    Rule = lifelib.getDefaultRule()
  else
    Rule = {}
    Rule.Name = sRule
    Rule.Data = getRuleBS(sRule)
    if(Rule.Data == nil) then
      return logStatus("Field creator: Please redefine your life rule !",nil) end
  end
  --[[
   * Internal data primitives
  ]]--
  function self:getW() return w end
  function self:getH() return h end
  function self:getSellCount() return (w * h) end
  function self:getRuleName() return Rule.Name end
  function self:getRuleData() return Rule.Data end
  function self:shiftXY (nX,nY) arShift2D (Old,w,h,(tonumber(nX) or 0),(tonumber(nY) or 0)); return self end
  function self:rollXY  (nX,nY) arRoll2D  (Old,w,h,(tonumber(nX) or 0),(tonumber(nY) or 0)); return self end
  function self:mirrorXY(bX,bY) arMirror2D(Old,w,h,bX,bY); return self end
  function self:getArray()       return Old end
  function self:getGenerations() return Gen end
  function self:rotR() arRotateR(Old,w,h); h,w = w,h; return self end
  function self:rotL() arRotateL(Old,w,h); h,w = w,h; return self end
  --[[
   * Give birth to a shape inside the field array
  ]]--
  function self:setShape(Shape,Px,Py)
    local Px = (Px or 1) % w
    local Py = (Py or 1) % h
    if(Shape == nil) then
      return logStatus("Field.setShape(Shape,PosX,PosY): Shape: Not present !",nil) end
    if(getmetatable(Shape) ~= metaShape) then
      return logStatus("Field.setShape(Shape,PosX,PosY): Shape: SHAPE obj invalid !",nil) end
    if(Rule.Name ~= Shape:getRuleName()) then
      return logStatus("Field.setShape(Shape,PosX,PosY): Shape: Different kind of life !",nil) end
    local sw = Shape:getW()
    local sh = Shape:getH()
    local ar = Shape:getArray()
    for i = 1,sh do for j = 1,sw do
      local x, y = Px+j-1, Py+i-1
      if(x > w) then x = x-w end
      if(x < 1) then x = x+w end
      if(y > h) then y = y-h end
      if(y < 1) then y = y+h end
      Old[y][x] = ar[i][j]
    end end; return self
  end
  --[[
   * Calcolates the next generation
  ]]--
  function self:evoNext()
    local ym1, y, yp1, yi = (h - 1), h, 1, h
    while yi > 0 do
      local xm1, x, xp1, xi = (w - 1), w, 1, w
      while xi > 0 do
        local sum = Old[ym1][xm1] + Old[ym1][x] + Old[ym1][xp1] +
                    Old[ y ][xm1]               + Old[ y ][xp1] +
                    Old[yp1][xm1] + Old[yp1][x] + Old[yp1][xp1]
        New[y][x] = getSumStatus(Old[y][x],sum,Rule)
        xm1, x, xp1, xi = x, xp1, (xp1 + 1), (xi - 1)
      end; ym1, y, yp1, yi = y, yp1, (yp1 + 1), (yi - 1)
    end; Old, New, Gen = New, Old, (Gen + 1); return self
  end
  
  --[[
   * Registers a draw method under a particular key
  ]]--
  function self:regDraw(sKey,fFoo)
    if(type(sKey) == "string" and type(fFoo) == "function") then Draw[sKey] = fFoo
    else logStatus("Field.drwLife(sMode,tArgs): Drawing method @"..tostring(sKey).." registration skipped !")
    end; return self
  end
  
  --[[
   * Visualizates the field on the screen using the draw method given
  ]]--
  function self:drwLife(sMode,tArgs)
    local Mode = tostring(sMode or "text")
    local Args = tArgs or {}
    if(Draw[Mode]) then Draw[Mode](self,Args)
    else logStatus("Field.drwLife(sMode,tArgs): Drawing mode <"..Mode.."> not found !")
    end; return self
  end
  
  --[[
   * Converts the field to a number, beware they are big
  ]]--
  function self:toNumber()
    local Pow, Num, Flg = 0, 0, 0
    for i = h,1,-1 do for j = w,1,-1 do
      Flg = (Old[i][j] ~= 0) and 1 or 0
      Num = Num + Flg * 2 ^ Pow; Pow  = Pow + 1
    end end; return Num
  end

  --[[
   * Exports a field to a non-delimited string format
  ]]--
  function self:toString()
    local Line = ""
    for i = 1,h do for j = 1,w do
        Line = Line .. tostring((Old[i][j] ~= 0) and Aliv or Dead)
    end end; return Line
  end

  setmetatable(self, metaField); return self
end

--[[
 * Crates a shape ( life form ) object
]]--
lifelib.makeShape = function(sName, sSrc, sExt, tArg)
  local sName = tostring(sName or "")
  local sSrc  = tostring(sSrc  or "")
  local sExt  = tostring(sExt  or "")
  local tArg  = tArg or {}
  local isEmpty, iCnt, tInit = true, 1, nil
  if(sSrc == "file") then
    if    (sExt == "rle"   ) then tInit = initFileRle(sName)
    elseif(sExt == "cells" ) then tInit = initFileCells(sName)
    elseif(sExt == "lif105") then tInit = initFileLif105(sName)
    elseif(sExt == "lif106") then tInit = initFileLif106(sName)
    else return logStatus("makeShape(sName, sSrc, sExt, tArg): Extension <"..sExt.."> not supported on the source <"..sSrc.."> for <"..sName..">",nil) end
  elseif(sSrc == "string") then
    if    (sExt == "rle" ) then tInit = initStringRle(sName,tArg[1],tArg[2])
    elseif(sExt == "txt" ) then tInit = initStringText(sName,tArg[1])
    else return logStatus("makeShape(sName, sSrc, sExt, tArg): Extension <"..sExt.."> not supported on the source <"..sSrc.."> for <"..sName">",nil) end
  elseif(sSrc == "strict") then tInit = initStruct(sName)
  else return logStatus("makeShape(sName, sSrc, sExt, tArg): Source <"..sSrc.."> not suported for <"..sName..">",nil) end

  if(not tInit) then
    return logStatus("makeShape(sName, sSrc, sExt, tArg): No initialization table",nil) end
  if(not (tInit.w and tInit.h)) then
    return logStatus("makeShape(sName, sSrc, sExt, tArg): Initialization table bad dimensions\n",nil) end
  if(not (tInit.w > 0 and tInit.h > 0)) then
    return logStatus("makeShape(sName, sSrc, sExt, tArg): Check Shape unit structure !\n",nil) end

  while(tInit[iCnt]) do
    if(tInit[iCnt] == 1) then isEmpty = false end; iCnt = iCnt + 1 end
  if(isEmpty) then
    return logStatus("makeShape(sName, sSrc, sExt, tArg): Shape <"..sName.."> empty for <"..sExt.."> <"..sSrc..">",nil) end
  local self = {}
        self.Init = tInit
  local w    = tInit.w
  local h    = tInit.h
  local Data = copyShape(tInit,w,h)
  local Draw = { ["text"] = drawConsole }
  local Rule = ""
  if(type(sRule) == "string") then
    local Data = getRuleBS(sRule)
    if(Data ~= nil) then Rule = sRule
    else return logStatus("makeShape(sName, sSrc, sExt, tArg): Check creator's Rule !",nil) end
  elseif(type(tInit.Rule) == "table") then
    if(type(tInit.Rule.Name) == "string") then
      local Data = lifelib.getRuleBS(Rule)
      if(Data ~= nil) then Rule = tInit.Rule.Name
      else Rule = lifelib.getDefaultRule().Name end
    else return logStatus("makeShape(sName, sSrc, sExt, tArg): Check init Rule !",nil) end
  else Rule = lifelib.getDefaultRule().Name end
  --[[
   * Internal data primitives
  ]]--
  function self:getW() return w end
  function self:getH() return h end
  function self:rotR() arRotateR(Data,w,h); h,w = w,h; return self end
  function self:rotL() arRotateL(Data,w,h); h,w = w,h; return self end
  function self:getArray() return Data end
  function self:getRuleName() return Rule end
  function self:getCellCount() return (w * h) end
  function self:getGenerations() return nil end
  function self:mirrorXY(bX,bY) arMirror2D(Data,w,h,bX,bY); return self end
  function self:rollXY(nX,nY) arRoll2D(Data,w,h,tonumber(nX) or 0,tonumber(nY) or 0); return self end
  --[[
   * Registers a draw method under a particular key
  ]]--
  function self:regDraw(sKey,fFoo)
    if(type(sKey) == "string" and type(fFoo) == "function") then Draw[sKey] = fFoo
    else logStatus("Drawing method {"..tostring(sKey)..","..tostring(fFoo).."} registration skipped !") end
  end
  --[[
   * Visualizates the shape on the screen using the draw method given
  ]]--
  function self:drwLife(sMode,tArgs)
    local Mode = sMode or "text"
    local Args = tArgs or {}
    if(Draw[Mode]) then Draw[Mode](self, Args)
    else logStatus("Shape.drwLife(sMode,tArgs): Drawing mode not found !\n") end
  end
  --[[
   * Converts the shape to a number, beware they are big
  ]]--
  function self:toNumber()
    local Pow, Num = 0, 0
    for i = h,1,-1 do for j = w,1,-1 do
      Flg = (Data[i][j] ~= 0) and 1 or 0
      Num = Num + Flg * 2 ^ Pow; Pow = Pow + 1
    end end; return Num
  end
  --[[
   * Exports the shape in non-delimited string format
  ]]--
  function self:toString()
    local Line = ""
    for i = 1,h do for j = 1,w do
        Line = Line .. tostring((Data[i][j] ~= 0) and Aliv or Dead)
    end end; return Line
  end
  --[[
   * Exports the shape in RLE format
  ]]--
  function self:toStringRle(sD, sE)
    local BaseCh, CurCh, Line, Cnt  = "", "", "", 0
    local sD, sE = tostring(sD):sub(1,1), tostring(sE):sub(1,1)
    for i = 1,h do
      BaseCh = tostring(((Data[i][1] ~= 0) and Aliv) or Dead); Cnt = 0
      for j = 1,w do
        CurCh = tostring(((Data[i][j] ~= 0) and Aliv) or Dead)
        if(CurCh == BaseCh) then Cnt = Cnt + 1
        else
          if(Cnt > 1) then Line  = Line..Cnt..BaseCh
          else Line  = Line..BaseCh end
          BaseCh, Cnt = CurCh, 1
        end
      end
      if(Cnt > 1) then Line  = Line..Cnt..BaseCh
      else Line  = Line .. BaseCh end
      if(i ~= h) then Line = Line..sD end
    end; return Line..sE
  end
  --[[
   * Exports the shape in text format
   * sDel the delemiter for the lines
   * bAll Draw the shape to the end of the line
  ]]--
  function self:toStringText(sDel,bTrim)
    if(sDel == Aliv) then
      return logStatus("Shape.toStringText(sMode,tArgs) Delimiter <"..sDel.."> matches alive","") end
    if(sDel == Dead) then
      return logStatus("Shape.toStringText(sMode,tArgs) Delimiter <"..sDel.."> matches dead","")  end
    local Line, Len = ""
    for i = 1,h do Len = w
      if(bTrim) then while(Data[i][Len] == 0) do Len = Len - 1 end end
      for j = 1,Len do
        Line = Line..tostring(((Data[i][j] ~= 0) and Aliv) or Dead)
      end; Line = Line..sDel
    end; return Line
  end
  setmetatable(self, metaShape); return self
end

return lifelib
