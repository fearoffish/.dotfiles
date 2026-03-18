-- Hammerspoon Window Management
-- Hyper key (Cmd+Shift+Alt+Ctrl) + vim keys for window positioning

-- Config
local hyper = {"cmd", "alt", "shift", "ctrl"}
local frameTolerance = 2
local undoMaxHistory = 20
hs.window.animationDuration = 0.1

-- State
local cycleState = {}
local undoHistory = {}
local dualCycleIndex = 0
local dualCycleWindows = {}

-- Position definitions (unit rects: x, y, w, h)
local positions = {
  h = {
    {0, 0, 0.5, 1},       -- left half
    {0, 0, 1/3, 1},       -- left third
    {0, 0, 2/3, 1},       -- left two-thirds
  },
  l = {
    {0.5, 0, 0.5, 1},     -- right half
    {2/3, 0, 1/3, 1},     -- right third
    {1/3, 0, 2/3, 1},     -- right two-thirds
  },
  k = {
    {0, 0, 1, 0.5},       -- top half
    {0, 0, 1, 1/3},       -- top third
    {0, 0, 1, 2/3},       -- top two-thirds
  },
  j = {
    {0, 0.5, 1, 0.5},     -- bottom half
    {0, 2/3, 1, 1/3},     -- bottom third
    {0, 1/3, 1, 2/3},     -- bottom two-thirds
  },
  n = {
    {0, 0, 0.5, 0.5},     -- top-left quarter
    {0.5, 0, 0.5, 0.5},   -- top-right quarter
    {0.5, 0.5, 0.5, 0.5}, -- bottom-right quarter
    {0, 0.5, 0.5, 0.5},   -- bottom-left quarter
  },
}

-- Utility: compare two frames within tolerance
local function framesEqual(f1, f2)
  return math.abs(f1.x - f2.x) < frameTolerance
    and math.abs(f1.y - f2.y) < frameTolerance
    and math.abs(f1.w - f2.w) < frameTolerance
    and math.abs(f1.h - f2.h) < frameTolerance
end

-- Utility: push window state onto undo stack
local function undoPush(win)
  table.insert(undoHistory, {windowId = win:id(), frame = win:frame()})
  if #undoHistory > undoMaxHistory then
    table.remove(undoHistory, 1)
  end
end

-- Utility: pop most recent undo entry for a window
local function undoPop(win)
  local id = win:id()
  for i = #undoHistory, 1, -1 do
    if undoHistory[i].windowId == id then
      local entry = table.remove(undoHistory, i)
      return entry.frame
    end
  end
  return nil
end

-- Core: move window to a unit rect on its current screen
local function moveWindow(win, unitRect)
  undoPush(win)
  win:moveToUnit(unitRect)
end

-- Core: cycle window through positions for a given key
local function cycleWindow(key, positionList)
  local win = hs.window.focusedWindow()
  if not win then return end

  local winId = win:id()
  local screen = win:screen()
  local screenFrame = screen:frame()
  local currentFrame = win:frame()
  local nextIndex = 1

  -- Check stored cycle state
  local state = cycleState[key]
  if state and state.windowId == winId then
    nextIndex = (state.index % #positionList) + 1
  else
    -- Scan for matching position
    for i, pos in ipairs(positionList) do
      local target = hs.geometry.unitrect(pos[1], pos[2], pos[3], pos[4])
      local targetFrame = target:fromUnitRect(screenFrame)
      if framesEqual(currentFrame, targetFrame) then
        nextIndex = (i % #positionList) + 1
        break
      end
    end
  end

  cycleState[key] = {windowId = winId, index = nextIndex}
  local pos = positionList[nextIndex]
  moveWindow(win, pos)
end

-- Core: center window preserving current size
local function centerWindow()
  local win = hs.window.focusedWindow()
  if not win then return end

  undoPush(win)
  local screenFrame = win:screen():frame()
  local winFrame = win:frame()
  winFrame.x = screenFrame.x + (screenFrame.w - winFrame.w) / 2
  winFrame.y = screenFrame.y + (screenFrame.h - winFrame.h) / 2
  win:setFrame(winFrame)
end

-- Core: move window to next/previous screen
local function moveToScreen(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local screens = hs.screen.allScreens()
  if #screens < 2 then return end

  local currentScreen = win:screen()
  local currentIndex = nil
  for i, screen in ipairs(screens) do
    if screen == currentScreen then
      currentIndex = i
      break
    end
  end
  if not currentIndex then return end

  local nextIndex = ((currentIndex - 1 + direction) % #screens) + 1
  local nextScreen = screens[nextIndex]

  -- Get unit rect on current screen, apply to new screen
  local currentScreenFrame = currentScreen:frame()
  local winFrame = win:frame()
  local unitX = (winFrame.x - currentScreenFrame.x) / currentScreenFrame.w
  local unitY = (winFrame.y - currentScreenFrame.y) / currentScreenFrame.h
  local unitW = winFrame.w / currentScreenFrame.w
  local unitH = winFrame.h / currentScreenFrame.h

  undoPush(win)
  win:moveToScreen(nextScreen)
  win:moveToUnit({unitX, unitY, unitW, unitH})
end

-- Dual-window layout pairs: {front window, back window}
local dualLayouts = {
  -- Front window on left
  {{0, 0, 0.5, 1},   {0.5, 0, 0.5, 1}},   -- half / half
  {{0, 0, 2/3, 1},   {2/3, 0, 1/3, 1}},    -- 2/3 / 1/3
  {{0, 0, 1/3, 1},   {1/3, 0, 2/3, 1}},    -- 1/3 / 2/3
  -- Front window on right
  {{0.5, 0, 0.5, 1}, {0, 0, 0.5, 1}},      -- half / half
  {{2/3, 0, 1/3, 1}, {0, 0, 2/3, 1}},       -- 1/3 / 2/3
  {{1/3, 0, 2/3, 1}, {0, 0, 1/3, 1}},       -- 2/3 / 1/3
}

-- Core: cycle two frontmost windows through paired layouts
local function cycleDualLayout()
  local allWindows = hs.window.orderedWindows()
  if #allWindows < 2 then return end

  local frontWin = allWindows[1]
  local backWin = allWindows[2]

  -- If same pair as last time, advance; otherwise reset
  local sameWindows = #dualCycleWindows == 2
    and ((dualCycleWindows[1] == frontWin:id() and dualCycleWindows[2] == backWin:id())
      or (dualCycleWindows[1] == backWin:id() and dualCycleWindows[2] == frontWin:id()))

  if sameWindows then
    dualCycleIndex = (dualCycleIndex % #dualLayouts) + 1
  else
    dualCycleIndex = 1
    dualCycleWindows = {frontWin:id(), backWin:id()}
  end

  local layout = dualLayouts[dualCycleIndex]

  -- Move back window to front window's screen if needed
  local targetScreen = frontWin:screen()
  if backWin:screen() ~= targetScreen then
    backWin:moveToScreen(targetScreen)
  end

  undoPush(frontWin)
  undoPush(backWin)
  frontWin:moveToUnit(layout[1])
  backWin:moveToUnit(layout[2])
end

-- Core: undo last move
local function undoLast()
  local win = hs.window.focusedWindow()
  if not win then return end

  local frame = undoPop(win)
  if frame then
    win:setFrame(frame)
  end
end

-- Key bindings: directional cycles
for key, positionList in pairs(positions) do
  hs.hotkey.bind(hyper, key, function()
    cycleWindow(key, positionList)
  end)
end

-- Key bindings: maximize
hs.hotkey.bind(hyper, "return", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  moveWindow(win, {0, 0, 1, 1})
end)

-- Key bindings: center
hs.hotkey.bind(hyper, "c", function() centerWindow() end)

-- Key bindings: multi-monitor
hs.hotkey.bind(hyper, "]", function() moveToScreen(1) end)
hs.hotkey.bind(hyper, "[", function() moveToScreen(-1) end)

-- Key bindings: dual-window layout cycle
hs.hotkey.bind(hyper, "i", function() cycleDualLayout() end)

-- Key bindings: undo
hs.hotkey.bind(hyper, "z", function() undoLast() end)

-- Reload notification
hs.alert.show("Hammerspoon config loaded")
