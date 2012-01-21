-- Copyright (C) 2011-2012 Paul Kulchenko
-- A turtle graphics library

require("wx")

local frame = wx.wxFrame(
  wx.NULL, -- no parent for toplevel windows
  wx.wxID_ANY, -- don't need a wxWindow ID
  "Turtle Graph Window",
  wx.wxDefaultPosition,
  wx.wxSize(450, 450),
  wx.wxDEFAULT_FRAME_STYLE + wx.wxSTAY_ON_TOP 
  - wx.wxRESIZE_BORDER - wx.wxMAXIMIZE_BOX)

frame:Connect(wx.wxEVT_CLOSE_WINDOW, function() os.exit() end)
frame:Show(true)

local bitmap
local mdc = wx.wxMemoryDC()

local function reset ()
  local size = frame:GetClientSize()
  local w,h = size:GetWidth(),size:GetHeight()
  bitmap = wx.wxBitmap(w,h)

  mdc:SetDeviceOrigin(w/2, h/2)
  mdc:SelectObject(bitmap)
  mdc:Clear()
  mdc:SetPen(wx.wxBLACK_PEN)
  mdc:SetFont(wx.wxSWISS_FONT) -- thin TrueType font
  mdc:SelectObject(wx.wxNullBitmap)
end

reset()

local pendn = wx.wxBLACK_PEN
local penup = wx.wxTRANSPARENT_PEN
local angle = 0
local x, y = 0, 0
local sounds = {}
local bitmaps = {}
local key
local click = {}

-- paint event handler for the frame that's called by wxEVT_PAINT
function OnPaint(event)
  -- must always create a wxPaintDC in a wxEVT_PAINT handler
  local dc = wx.wxPaintDC(frame)
  dc:DrawBitmap(bitmap, 0, 0, true)
  dc:delete() -- ALWAYS delete() any wxDCs created when done
end

local exit = true
-- connect the paint event handler function with the paint event
frame:Connect(wx.wxEVT_PAINT, OnPaint)
frame:Connect(wx.wxEVT_ERASE_BACKGROUND, function () end) -- do nothing

frame:Connect(wx.wxEVT_KEY_DOWN, function (event) key = event:GetKeyCode() end)
frame:Connect(wx.wxEVT_LEFT_DCLICK, function (event) click['l2'] = event:GetLogicalPosition(mdc) end)
frame:Connect(wx.wxEVT_RIGHT_DCLICK, function (event) click['r2'] = event:GetLogicalPosition(mdc) end)
frame:Connect(wx.wxEVT_LEFT_UP, function (event) click['lu'] = event:GetLogicalPosition(mdc) end)
frame:Connect(wx.wxEVT_RIGHT_UP, function (event) click['ru'] = event:GetLogicalPosition(mdc) end)
frame:Connect(wx.wxEVT_LEFT_DOWN, function (event) click['ld'] = event:GetLogicalPosition(mdc) end)
frame:Connect(wx.wxEVT_RIGHT_DOWN, function (event) click['rd'] = event:GetLogicalPosition(mdc) end)

frame:Connect(wx.wxEVT_IDLE, 
  function () if exit then wx.wxGetApp():ExitMainLoop() end end)

local autoUpdate = true
local function updt (update)
  local curr = autoUpdate
  if update ~= nil then autoUpdate = update end

  frame:Refresh()
  frame:Update()
  wx.wxGetApp():MainLoop()

  return curr
end

local function move (dist) 
  if not dist then return end

  mdc:SelectObject(bitmap)

  local dx = math.floor(dist * math.cos(angle * math.pi/180)+0.5)
  local dy = math.floor(dist * math.sin(angle * math.pi/180)+0.5)
  mdc:DrawLine(x, y, x+dx, y+dy)
  x, y = x+dx, y+dy

  mdc:SelectObject(wx.wxNullBitmap)
  if autoUpdate then updt() end
end

local function fill (color, dx, dy)
  if not color then return end

  mdc:SelectObject(bitmap)

  mdc:SetBrush(wx.wxBrush(color, wx.wxSOLID))
  mdc:FloodFill(x+(dx or 0), y+(dy or 0), pendn:GetColour(), wx.wxFLOOD_BORDER)
  mdc:SetBrush(wx.wxNullBrush) -- release the brush

  mdc:SelectObject(wx.wxNullBitmap)
  if autoUpdate then updt() end
end

local function text (text, angle)
  if not text then return end

  mdc:SelectObject(bitmap)

  if angle then
    mdc:DrawRotatedText(text, x, y, angle)
  else
    mdc:DrawText(text, x, y)
  end

  mdc:SelectObject(wx.wxNullBitmap)
  if autoUpdate then updt() end
end

local function load (file)
  if not file then return end
  if not wx.wxFileName(file):FileExists() then file = file .. ".png" end

  if not bitmaps[file] then
    bitmaps[file] = wx.wxBitmap()
    bitmaps[file]:LoadFile(file, wx.wxBITMAP_TYPE_ANY)
  end

  -- if the size is the same, then load the entire bitmap
  if bitmap:GetWidth() == bitmaps[file]:GetWidth() and
     bitmap:GetHeight() == bitmaps[file]:GetHeight() then
    bitmap:LoadFile(file, wx.wxBITMAP_TYPE_ANY)
  else
    mdc:SelectObject(bitmap)
    mdc:DrawBitmap(bitmaps[file], x, y, true)
    mdc:SelectObject(wx.wxNullBitmap)
  end
  if autoUpdate then updt() end
end

local function wipe ()
  mdc:SelectObject(bitmap)
  mdc:Clear()
  mdc:SelectObject(wx.wxNullBitmap)
  if autoUpdate then updt() end
end

local function wait (seconds)
  if seconds then
    wx.wxMilliSleep(seconds*1000)
  else
    exit = false
    wx.wxGetApp():MainLoop()
  end
end

local function pndn () mdc:SetPen(pendn) end
local function pnup () mdc:SetPen(penup) end
local function rand (limit) return limit and (math.random(limit)-1) or (0) end

local drawing = {
  pndn = pndn,
  pnup = pnup,
  pnsz = function (size)
    local curr = pendn:GetWidth(size)
    if size then pendn:SetWidth(size) pndn() end
    return curr
  end,
  pncl = function (color)
    local curr = pendn:GetColour()
    if color then pendn:SetColour(color) pndn() end
    return curr
  end,
  colr = function (r, g, b)
    if not g or not b then return r end
    return wx.wxColour(r, g, b):GetAsString(wx.wxC2S_CSS_SYNTAX)
  end,
  dist = function () return math.sqrt(x*x + y*y) end,
  char = function (char)
    if char then return type(char) == 'string' and char:byte() or char end
    local curr = key
    key = nil
    return curr
  end,
  clck = function (type)
    if not click[type] then return end
    local curr = click[type]
    click[type] = nil
    return curr.x, curr.y
  end,
  goto = function (nx,ny)
    if not nx and not ny then return x, y end
    if nx then x = nx end
    if ny then y = ny end
  end,
  goby = function (nx,ny) if nx and ny then x, y = x+nx, y+ny end end,
  turn = function (turn)
    if not turn then return angle end
    angle = (angle + turn) % 360
  end,
  bank = function () end,
  ptch = function () end,
  fill = fill,
  move = move,
  wipe = wipe,
  wait = wait,
  updt = updt,
  auto = auto,
  jump = function (dist) pnup() move(dist) pndn() end,
  back = function (dist) move(-dist) end,
  rand = rand,
  ranc = function () return colr(rand(256),rand(256),rand(256)) end,
  load = load,
  save = function (file) bitmap:SaveFile(file .. '.png', wx.wxBITMAP_TYPE_PNG) end,
  snap = function () return bitmap:GetSubBitmap(
    wx.wxRect(0, 0, bitmap:GetWidth(), bitmap:GetHeight())) end,
  undo = function (snapshot) if snapshot then bitmap = wx.wxBitmap(snapshot) end end,
  size = function (x, y)
    local size = frame:GetClientSize()
    if not x and not y then return size:GetWidth(), size:GetHeight() end
    frame:SetClientSize(x or size:GetWidth(), y or size:GetHeight())
    reset()
  end,
  play = function (file) 
    if not wx.wxFileName(file):FileExists() then file = file .. ".wav" end
    if not sounds[file] then sounds[file] = wx.wxSound(file) end
    sounds[file]:Play()
  end,
  text = text,
  time = function () return os.clock() end,

  hide = function () end,
  show = function () end,
  init = function () end, -- initialize turtle and the field
  trtl = function (num) end, -- get a (current) turtle
  copy = function () end, -- copy a turtle
  pick = function () end, -- pick a turtle (or a group) to work with
}

for name, func in pairs(drawing) do
  _G[name] = func
end
