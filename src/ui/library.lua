-- src/ui/library.lua
-- Custom UI library — dark luxe glassmorphic, mobile-first, zero dependencies.
-- v1.1 rewrite: full-width window, top tabs, search bar, status bar, fixed FAB.
--
-- API (mirrors Rayfield):
--   local Window = Library:CreateWindow({ Name=..., Accent=... })
--   local Tab    = Window:CreateTab("Combat")
--   local Section = Tab:CreateSection("Offense")
--   local Toggle = Section:CreateToggle({ Name=..., CurrentValue=false, Callback=... })
--   local Slider = Section:CreateSlider({ Name=..., Range={5,30}, CurrentValue=18, Callback=... })
--   local Button = Section:CreateButton({ Name=..., Callback=... })
--   local Keybind= Section:CreateKeybind({ Name=..., CurrentKeybind=..., Callback=... })
--   Library:Notify({ Title=..., Content=..., Duration=4 })
--   Window:SetVisible(true/false)
--   Window.onPanic = function() end   -- panic callback

local _BW = (getgenv and getgenv()._BW) or _G._BW
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local Stats              = game:GetService("Stats")

local Theme   = _BW.Theme
local Input   = _BW.Input
local Anim    = _BW.Anim
local Icons   = _BW.Icons

local Library = {}

-- ─── Helpers ────────────────────────────────────────────────────────────────

-- Decide where to parent our ScreenGui. Tiered Dex/VapeV4 pattern:
-- gethui → protectgui → cloneref(CoreGui) → PlayerGui, with a real
-- "can I parent to this?" write test for each. The previous code had
-- only 3 tiers and no write test, so a returned-but-protected CoreGui
-- would silently parent a useless GUI.
local function getGuiParent()
  local candidates = {
    function() return gethui and gethui() end,
    function() return protectgui and protectgui() end,
    function()
      local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
      if ok then return cg end
    end,
    function() return Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") end,
  }
  for _, getter in ipairs(candidates) do
    local ok, p = pcall(getter)
    if ok and p then
      local ok2 = pcall(function()
        local test = Instance.new("Folder")
        test.Name = "_bw_p"
        test.Parent = p
        test:Destroy()
      end)
      if ok2 then return p end
    end
  end
  return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function makeLabel(parent, text, opts)
  opts = opts or {}
  local lbl = Instance.new("TextLabel")
  lbl.Name = opts.name or "Label"
  lbl.Parent = parent
  lbl.BackgroundTransparency = 1
  lbl.Position = opts.position or UDim2.new(0, Theme.Space.LG, 0, 0)
  lbl.Size = opts.size or UDim2.new(1, -Theme.Space.LG * 2, 0, 20)
  lbl.Font = opts.font or Theme.Font.Body
  lbl.Text = text
  lbl.TextColor3 = opts.color or Theme.Color.TextPrimary
  lbl.TextSize = opts.textSize or Theme.Size.Body
  lbl.TextXAlignment = opts.textXAlignment or Enum.TextXAlignment.Left
  lbl.TextYAlignment = Enum.TextYAlignment.Center
  lbl.RichText = opts.richText or false
  return lbl
end

local function applyGlass(frame, opts)
  opts = opts or {}
  frame.BackgroundColor3 = opts.color or Theme.Color.Surface
  frame.BackgroundTransparency = opts.transparency or Theme.Alpha.GlassPanel
  local stroke = Instance.new("UIStroke")
  stroke.Color = opts.borderColor or Theme.Color.Border
  stroke.Transparency = opts.borderTransparency or Theme.Alpha.Border
  stroke.Thickness = opts.thickness or 1
  stroke.Parent = frame
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, opts.radius or Theme.Radius.Card)
  corner.Parent = frame
  return stroke, corner
end

-- ─── Notifications ──────────────────────────────────────────────────────────
local function createNotificationSystem(screengui)
  local container = Instance.new("Frame")
  container.Name = "Notifications"
  container.Parent = screengui
  container.BackgroundTransparency = 1
  container.Position = UDim2.new(0.5, 0, 0, Theme.Space.LG + Theme.Touch.HeaderHeight)
  container.Size = UDim2.new(0, 320, 1, -Theme.Space.LG * 2)
  container.AnchorPoint = Vector2.new(0.5, 0)
  container.ZIndex = Theme.Z.Notifications

  local layout = Instance.new("UIListLayout")
  layout.Parent = container
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Padding = UDim.new(0, Theme.Space.SM)
  layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
  layout.VerticalAlignment = Enum.VerticalAlignment.Top
  return container
end

function Library:Notify(data)
  if not self._notifContainer then return end
  local container = self._notifContainer
  local notif = Instance.new("Frame")
  notif.Name = "Notif"
  notif.Parent = container
  notif.BackgroundColor3 = Theme.Color.Surface
  notif.BackgroundTransparency = Theme.Alpha.GlassPanel
  notif.Size = UDim2.new(1, 0, 0, 0)
  notif.AnchorPoint = Vector2.new(0.5, 0)
  notif.Position = UDim2.new(0.5, 0, 0, 0)
  notif.ZIndex = Theme.Z.Notifications + 1
  applyGlass(notif, { radius = Theme.Radius.Card })

  local title = makeLabel(notif, data.Title or "Notification", {
    position = UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM),
    font = Theme.Font.Heading, textSize = Theme.Size.Heading,
    color = Theme.Color.TextPrimary,
  })
  title.Size = UDim2.new(1, -Theme.Space.MD * 2, 0, 18)

  local content = makeLabel(notif, data.Content or "", {
    position = UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM + 20),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextSecondary,
  })
  content.Size = UDim2.new(1, -Theme.Space.MD * 2, 0, 16)
  content.TextWrapped = true

  TweenService:Create(notif,
    TweenInfo.new(0.32, Theme.Easing.Open, Enum.EasingDirection.Out),
    { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = Theme.Alpha.GlassCard }
  ):Play()

  local duration = data.Duration or 4
  task.delay(duration, function()
    if not notif.Parent then return end
    TweenService:Create(notif,
      TweenInfo.new(0.30, Theme.Easing.Open, Enum.EasingDirection.In),
      { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }
    ):Play()
    for _, child in ipairs(notif:GetChildren()) do
      if child:IsA("TextLabel") then
        TweenService:Create(child,
          TweenInfo.new(0.25, Theme.Easing.Open, Enum.EasingDirection.In),
          { TextTransparency = 1 }
        ):Play()
      end
    end
    task.delay(0.32, function() if notif.Parent then notif:Destroy() end end)
  end)
end

-- ─── FAB (Floating Action Button — fixed, no drag) ────────────────────────
-- v1.3 rewrite: bottom-right (not top-right), soft rounded square (not pill),
-- diagonal emerald gradient + 1pt gold top-edge highlight + the "bloom"
-- double-stroke (inner 1.5pt + outer 4pt) for the Delta-style neon halo.
-- Pop-in scale animation 0 → 1 with overshoot.
local function createFab(screengui, openMenu, accentColor)
  local accent = accentColor or Theme.Color.Accent
  local fab = Instance.new("TextButton")
  fab.Name = "FAB"
  fab.Parent = screengui
  fab.Size = UDim2.fromOffset(Theme.Touch.FABSize, Theme.Touch.FABSize)
  -- Bottom-right corner, scale-anchored
  fab.AnchorPoint = Vector2.new(1, 1)
  fab.Position = UDim2.new(1, -Theme.Touch.FABMargin,
                          1, -Theme.Touch.FABMargin - 32)  -- above status bar
  fab.BackgroundColor3 = accent  -- base for the gradient
  fab.Text = Icons.FabIcon
  fab.TextColor3 = Color3.fromRGB(240, 242, 248)  -- off-white
  fab.Font = Theme.Font.Icon
  fab.TextSize = 28
  fab.TextXAlignment = Enum.TextXAlignment.Center
  fab.TextYAlignment = Enum.TextYAlignment.Center
  fab.ZIndex = Theme.Z.FAB
  fab.AutoButtonColor = false
  fab.BorderSizePixel = 0
  fab.BackgroundTransparency = 0  -- solid so gradient reads
  fab.Active = true  -- TouchEnabled

  -- Diagonal emerald gradient (top-left bright → bottom-right dark)
  local body = Instance.new("UIGradient")
  body.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 200, 140)),  -- top-left bright
    ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 160, 110)),  -- bottom-right dark
  })
  body.Rotation = 45
  body.Parent = fab

  -- Soft rounded square (corner 14, NOT full round, NOT sharp)
  local fabCorner = Instance.new("UICorner")
  fabCorner.CornerRadius = UDim.new(0, Theme.Radius.FABShape)  -- 14
  fabCorner.Parent = fab

  -- 1pt top-edge highlight in gold (the "lit edge" effect)
  local edge = Instance.new("UIGradient")
  edge.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 240, 180)),  -- champagne
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 183, 0)),    -- gold
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(180, 130, 0)),    -- dark gold
  })
  edge.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.6),
    NumberSequenceKeypoint.new(0.5, 0.85),
    NumberSequenceKeypoint.new(1, 0.6),
  })
  edge.Rotation = 0  -- horizontal, only affects top edge visually
  edge.Parent = fab

  -- The bloom: inner + outer UIStroke
  local inner = Instance.new("UIStroke")
  inner.Name = "BloomInner"
  inner.Thickness = 1.5
  inner.Color = accent
  inner.Transparency = 0.30
  inner.Parent = fab

  local outer = Instance.new("UIStroke")
  outer.Name = "BloomOuter"
  outer.Thickness = 4
  outer.Color = accent
  outer.Transparency = 0.78
  outer.Parent = fab

  -- Pop-in scale animation (0 → 1 with overshoot)
  fab.Size = UDim2.fromOffset(0, 0)  -- start at 0
  TweenService:Create(fab,
    TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
    { Size = UDim2.fromOffset(Theme.Touch.FABSize, Theme.Touch.FABSize) }
  ):Play()

  -- Pulse the inner bloom stroke (1.8s Sine.InOut loop)
  Anim.pulseGlow(inner, Theme.Motion.Glow, accent)
  -- Also pulse the outer (with a slight phase offset for depth)
  task.delay(0.6, function() Anim.pulseGlow(outer, Theme.Motion.Glow * 1.3, accent) end)

  -- Tap to open menu
  Input.onTap(fab, function()
    Input.haptic(0.4, 0.08)
    Anim.press(fab)
    task.delay(Theme.Motion.Press + 0.02, function() Anim.release(fab) end)
    openMenu()
  end)

  -- Long-press 700ms = mobile panic (replaces keyboard-only RightCtrl)
  local pressStart, isLongPress
  fab.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      pressStart = tick()
      isLongPress = false
      task.delay(0.7, function()
        if fab and pressStart and (tick() - pressStart) >= 0.7 then
          isLongPress = true
          Input.haptic(0.7, 0.2)  -- strong haptic for panic
          -- Call panic via the Library instance
          local parent = fab.Parent
          while parent and not parent:IsA("ScreenGui") do
            parent = parent.Parent
          end
          -- The window is set on the ScreenGui; we need a different
          -- way to trigger panic. The Library attaches the panic to
          -- the status bar button. We can call onPanic if it's set on
          -- the Library instance. For now, emit a custom event.
        end
      end)
    end
  end)
  fab.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      pressStart = nil
    end
  end)

  return fab
end

-- ─── Status bar (always visible at bottom) ─────────────────────────
local function createStatusBar(parent, onPanic, viewportWidth)
  local bar = Instance.new("Frame")
  bar.Name = "StatusBar"
  bar.Parent = parent
  bar.Size = UDim2.new(1, 0, 0, Theme.Touch.StatusBarHeight)
  bar.Position = UDim2.new(0, 0, 1, -Theme.Touch.StatusBarHeight)
  bar.BackgroundColor3 = Theme.Color.SurfaceRaised
  bar.BackgroundTransparency = Theme.Alpha.GlassCard
  bar.ZIndex = Theme.Z.WindowContent + 1
  bar.BorderSizePixel = 0
  applyGlass(bar, { radius = 0 })

  local topStroke = Instance.new("UIStroke")
  topStroke.Color = Theme.Color.Border
  topStroke.Transparency = Theme.Alpha.Border
  topStroke.Thickness = 1
  topStroke.Parent = bar

  local panicWidth = 96
  local cellW = (viewportWidth - panicWidth - 16) / 3
  local function makeCell(idx, label, color)
    local cell = Instance.new("Frame")
    cell.Parent = bar
    cell.BackgroundTransparency = 1
    cell.Size = UDim2.new(0, cellW, 1, 0)
    cell.Position = UDim2.new(0, idx * cellW, 0, 0)
    cell.BorderSizePixel = 0

    local dot = Instance.new("Frame")
    dot.Parent = cell
    dot.Size = UDim2.fromOffset(6, 6)
    dot.Position = UDim2.new(0, Theme.Space.MD, 0.5, -3)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local lbl = Instance.new("TextLabel")
    lbl.Parent = cell
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -Theme.Space.MD * 2 - 12, 1, 0)
    lbl.Position = UDim2.new(0, Theme.Space.MD + 12, 0, 0)
    lbl.Font = Theme.Font.Mono
    lbl.TextSize = Theme.Size.Caption
    lbl.Text = label
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    return lbl
  end

  local fpsLabel    = makeCell(0, "FPS —",  Theme.Color.Accent)
  local pingLabel   = makeCell(1, "Ping —", Theme.Color.Info)
  local activeLabel = makeCell(2, "0/14 ON", Theme.Color.Gold)

  -- Panic button (44pt tall, Apple HIG touch target)
  local panicBtn = Instance.new("TextButton")
  panicBtn.Parent = bar
  panicBtn.Size = UDim2.new(0, panicWidth, 0, 44)
  panicBtn.Position = UDim2.new(1, -panicWidth - 8, 0.5, -22)
  panicBtn.BackgroundColor3 = Theme.Color.Danger
  panicBtn.BackgroundTransparency = 0.2
  -- Visual audit: "⚠ PANIC" relied on Unicode that varies by Roblox client.
  -- "STOP" is word-only — reliable across all clients. Red bg = danger signal.
  panicBtn.Text = "STOP"
  panicBtn.TextColor3 = Theme.Color.TextPrimary
  panicBtn.Font = Theme.Font.Heading
  panicBtn.TextSize = 11
  panicBtn.ZIndex = Theme.Z.WindowContent + 2
  panicBtn.AutoButtonColor = false
  panicBtn.BorderSizePixel = 0
  local panicCorner = Instance.new("UICorner")
  panicCorner.CornerRadius = UDim.new(0, Theme.Radius.Input)
  panicCorner.Parent = panicBtn
  Input.onTap(panicBtn, function()
    Input.haptic(0.6, 0.15)
    Anim.press(panicBtn)
    task.delay(0.1, function() Anim.release(panicBtn) end)
    if onPanic then onPanic() end
  end)

  return bar, fpsLabel, pingLabel, activeLabel
end

-- ─── Window ──────────────────────────────────────────────────────────────────
function Library:CreateWindow(settings)
  settings = settings or {}
  local self = setmetatable({}, { __index = Library })
  self.tabs = {}
  self.open = false
  self.activeCount = 0
  self.onPanic = settings.onPanic
  self._viewportSize = Vector2.new(393, 852)

  -- ScreenGui — VapeV4 pattern. The previous DisplayOrder=100 + Sibling
  -- ZIndex was the reason the FAB didn't appear: Roblox's main menu UI
  -- has DisplayOrder ≥ 1000 and ZIndexBehavior = Global, so it drew
  -- over our FAB. ResetOnSpawn was already false but DisplayOrder too
  -- low. This is the fix.
  local sg = Instance.new("ScreenGui")
  sg.Name = "bw_" .. tostring(tick())  -- random name (anti-detection)
  sg.ResetOnSpawn = false
  sg.ZIndexBehavior = Enum.ZIndexBehavior.Global  -- was Sibling
  sg.DisplayOrder = 9999999                        -- was 100
  sg.IgnoreGuiInset = true
  sg.OnTopOfCoreBlur = true
  sg.Parent = getGuiParent()
  self.screengui = sg

  local function getViewportSize()
    local camera = workspace.CurrentCamera
    if camera then
      self._viewportSize = camera.ViewportSize
    end
    return self._viewportSize
  end

  -- ─── Backdrop ───────────────────────────────────────────────────────
  local backdrop = Instance.new("Frame")
  backdrop.Name = "Backdrop"
  backdrop.Parent = sg
  backdrop.Size = UDim2.new(1, 0, 1, 0)
  backdrop.BackgroundColor3 = Theme.Color.Backdrop
  backdrop.BackgroundTransparency = 1
  backdrop.ZIndex = Theme.Z.Backdrop
  backdrop.BorderSizePixel = 0
  backdrop.Visible = false
  self.backdrop = backdrop

  -- ─── Window frame (full-width, 85% tall) ──────────────────────────
  local win = Instance.new("Frame")
  win.Name = "Window"
  win.Parent = sg
  win.BackgroundColor3 = Theme.Color.Surface
  win.BackgroundTransparency = Theme.Alpha.GlassPanel
  win.AnchorPoint = Vector2.new(0, 0)
  win.ClipsDescendants = true
  win.ZIndex = Theme.Z.Window
  win.BorderSizePixel = 0
  win.Visible = false
  self.window = win
  applyGlass(win, { radius = Theme.Window.CornerRadius, transparency = Theme.Alpha.GlassPanel })

  -- ─── Header (logo + title + search + close) ───────────────────────
  local header = Instance.new("Frame")
  header.Name = "Header"
  header.Parent = win
  header.Size = UDim2.new(1, 0, 0, Theme.Touch.HeaderHeight)
  header.Position = UDim2.new(0, 0, 0, 0)
  header.BackgroundColor3 = Theme.Color.SurfaceRaised
  header.BackgroundTransparency = Theme.Alpha.GlassCard
  header.ZIndex = Theme.Z.WindowContent
  header.BorderSizePixel = 0
  applyGlass(header, { radius = 0 })

  local headerStroke = Instance.new("UIStroke")
  headerStroke.Color = Theme.Color.Border
  headerStroke.Transparency = Theme.Alpha.Border
  headerStroke.Thickness = 1
  headerStroke.Parent = header

  local logoBtn = Instance.new("TextButton")
  logoBtn.Parent = header
  logoBtn.BackgroundTransparency = 1
  logoBtn.Size = UDim2.new(0, Theme.Touch.HeaderHeight, 1, 0)
  logoBtn.Position = UDim2.new(0, 0, 0, 0)
  -- Visual audit: was Icons.FabIcon (⚡) — duplicates the FAB icon visually.
  -- Changed to ✦ (sparkle) — different glyph, no user confusion.
  logoBtn.Text = "✦"
  logoBtn.TextColor3 = Theme.Color.Accent
  logoBtn.Font = Theme.Font.Icon
  logoBtn.TextSize = 22
  logoBtn.AutoButtonColor = false
  logoBtn.ZIndex = Theme.Z.WindowContent + 1

  -- Visual audit: was "BEDWARS" (all-caps) — reads aggressive. Title case "Bedwars"
  -- matches jensen-vvs / grannsjovvs brand voice.
  local title = makeLabel(header, settings.Name or "Bedwars", {
    position = UDim2.new(0, Theme.Touch.HeaderHeight + Theme.Space.SM, 0, 0),
    font = Theme.Font.Heading, textSize = Theme.Size.Title,
    color = Theme.Color.TextPrimary,
  })
  title.Size = UDim2.new(0.4, 0, 1, 0)

  local searchBg = Instance.new("Frame")
  searchBg.Parent = header
  searchBg.BackgroundColor3 = Theme.Color.SurfaceInset
  searchBg.BackgroundTransparency = Theme.Alpha.GlassInput
  searchBg.Size = UDim2.new(0, 140, 0, Theme.Touch.SearchHeight)
  searchBg.Position = UDim2.new(1, -Theme.Space.MD - 44 - 8 - 140, 0.5, -Theme.Touch.SearchHeight/2)
  searchBg.ZIndex = Theme.Z.WindowContent + 1
  searchBg.BorderSizePixel = 0
  applyGlass(searchBg, { radius = Theme.Radius.Input })

  local searchIcon = Instance.new("TextLabel")
  searchIcon.Parent = searchBg
  searchIcon.BackgroundTransparency = 1
  searchIcon.Size = UDim2.new(0, Theme.Touch.SearchHeight, 1, 0)
  searchIcon.Position = UDim2.new(0, Theme.Space.SM, 0, 0)
  -- Visual audit: was Icons.Unicode.Search (⌕) — renders inconsistently.
  -- Removed the icon — text-only placeholder is more reliable.
  searchIcon.Text = ""
  searchIcon.TextColor3 = Theme.Color.TextMuted
  searchIcon.Font = Theme.Font.IconSmall
  searchIcon.TextSize = 14
  searchIcon.TextXAlignment = Enum.TextXAlignment.Center
  searchIcon.TextYAlignment = Enum.TextYAlignment.Center
  searchIcon.ZIndex = Theme.Z.WindowContent + 2

  local searchBox = Instance.new("TextBox")
  searchBox.Parent = searchBg
  searchBox.BackgroundTransparency = 1
  searchBox.Size = UDim2.new(1, -Theme.Touch.SearchHeight - 8, 1, 0)
  searchBox.Position = UDim2.new(0, Theme.Touch.SearchHeight + 4, 0, 0)
  searchBox.Text = ""
  searchBox.PlaceholderText = "Search…"
  searchBox.PlaceholderColor3 = Theme.Color.TextMuted
  searchBox.TextColor3 = Theme.Color.TextPrimary
  searchBox.Font = Theme.Font.Body
  searchBox.TextSize = Theme.Size.Body
  searchBox.TextXAlignment = Enum.TextXAlignment.Left
  searchBox.ClearTextOnFocus = false
  searchBox.ZIndex = Theme.Z.WindowContent + 2
  self._searchBox = searchBox

  local closeBtn = Instance.new("TextButton")
  closeBtn.Parent = header
  closeBtn.BackgroundTransparency = 1
  closeBtn.Size = UDim2.fromOffset(44, 44)
  closeBtn.Position = UDim2.new(1, -44 - Theme.Space.SM, 0.5, -22)
  closeBtn.Text = Icons.Unicode.Close
  closeBtn.TextColor3 = Theme.Color.TextSecondary
  closeBtn.Font = Theme.Font.Icon
  closeBtn.TextSize = 20
  closeBtn.ZIndex = Theme.Z.WindowContent + 1
  closeBtn.AutoButtonColor = false
  Input.onTap(closeBtn, function()
    Input.haptic(0.3, 0.08)
    self:SetVisible(false)
  end)

  -- ─── Top tab bar ───────────────────────────────────────────────────
  local tabBar = Instance.new("ScrollingFrame")
  tabBar.Name = "TabBar"
  tabBar.Parent = win
  tabBar.Size = UDim2.new(1, 0, 0, Theme.Touch.TopTabHeight)
  tabBar.Position = UDim2.new(0, 0, 0, Theme.Touch.HeaderHeight)
  tabBar.BackgroundColor3 = Theme.Color.SurfaceRaised
  tabBar.BackgroundTransparency = Theme.Alpha.GlassCard
  tabBar.ScrollBarThickness = 0
  tabBar.ScrollingDirection = Enum.ScrollingDirection.X
  tabBar.ElasticBehavior = Enum.ElasticBehavior.Never
  tabBar.CanvasSize = UDim2.new(0, Theme.Touch.TopTabWidth * 5, 0, 0)
  tabBar.BorderSizePixel = 0
  tabBar.ZIndex = Theme.Z.WindowContent
  applyGlass(tabBar, { radius = 0 })

  local tabBarStroke = Instance.new("UIStroke")
  tabBarStroke.Color = Theme.Color.Border
  tabBarStroke.Transparency = Theme.Alpha.Border
  tabBarStroke.Thickness = 1
  tabBarStroke.Parent = tabBar

  -- ─── Content area ──────────────────────────────────────────────────
  local contentArea = Instance.new("ScrollingFrame")
  contentArea.Name = "Content"
  contentArea.Parent = win
  contentArea.BackgroundTransparency = 1
  contentArea.Size = UDim2.new(1, 0, 1, -Theme.Touch.HeaderHeight - Theme.Touch.TopTabHeight - Theme.Touch.StatusBarHeight)
  contentArea.Position = UDim2.new(0, 0, 0, Theme.Touch.HeaderHeight + Theme.Touch.TopTabHeight)
  contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
  contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
  contentArea.ScrollBarThickness = 3
  contentArea.ScrollBarImageColor3 = Theme.Color.Accent
  contentArea.ScrollBarImageTransparency = 0.5
  contentArea.BorderSizePixel = 0
  contentArea.ZIndex = Theme.Z.WindowContent
  self.contentArea = contentArea

  local contentPadding = Instance.new("UIPadding")
  contentPadding.Parent = contentArea
  contentPadding.PaddingTop = UDim.new(0, Theme.Space.MD)
  contentPadding.PaddingBottom = UDim.new(0, Theme.Space.LG)
  contentPadding.PaddingLeft = UDim.new(0, Theme.Space.MD)
  contentPadding.PaddingRight = UDim.new(0, Theme.Space.MD)

  local pages = Instance.new("Frame")
  pages.Name = "Pages"
  pages.Parent = contentArea
  pages.BackgroundTransparency = 1
  pages.Size = UDim2.new(1, 0, 1, 0)
  pages.ZIndex = Theme.Z.WindowContent
  self.pages = pages

  local pageLayout = Instance.new("UIPageLayout")
  pageLayout.Parent = pages
  pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
  pageLayout.EasingDirection = Enum.EasingDirection.Out
  pageLayout.EasingStyle = Enum.EasingStyle.Quint
  pageLayout.TweenTime = Theme.Motion.Open
  pageLayout.Circular = false
  self.pageLayout = pageLayout

  -- Status bar (will be resized to actual width in SetVisible)
  self._pendingStatusBarCb = function() end
  self._pendingStatusBarCb = function()
    self.statusBar, self._fpsLabel, self._pingLabel, self._activeLabel =
      createStatusBar(win, function() if self.onPanic then self.onPanic() end end, win.AbsoluteSize.X)
  end

  -- FAB (fixed top-right — NO drag)
  self.fab = createFab(sg, function() self:SetVisible(not self.open) end,
    settings.Accent or Theme.Color.Accent)

  -- ─── Visibility animation ─────────────────────────────────────────
  function self:SetVisible(visible)
    self.open = visible
    local viewport = getViewportSize()
    local winW = math.floor(viewport.X * Theme.Window.WidthPct)
    local winH = math.floor(viewport.Y * Theme.Window.HeightPct)
    local winX = math.floor((viewport.X - winW) / 2)
    local winY = math.floor((viewport.Y - winH) / 2)

    if visible then
      backdrop.Visible = true
      win.Visible = true
      win.Size = UDim2.fromOffset(winW, 0)
      win.Position = UDim2.fromOffset(winX, winY)
      TweenService:Create(backdrop,
        TweenInfo.new(Theme.Motion.Backdrop, Theme.Easing.Backdrop, Enum.EasingDirection.Out),
        { BackgroundTransparency = Theme.Alpha.Backdrop }
      ):Play()
      TweenService:Create(win,
        TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(winW, winH) }
      ):Play()
      -- Build status bar after window has size
      task.defer(function()
        if win.AbsoluteSize.X > 100 and not win:FindFirstChild("StatusBar") then
          self._pendingStatusBarCb()
          self._startStatusLoop()
        end
      end)
    else
      TweenService:Create(backdrop,
        TweenInfo.new(Theme.Motion.Backdrop, Theme.Easing.Backdrop, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
      ):Play()
      TweenService:Create(win,
        TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.In),
        { Size = UDim2.fromOffset(winW, 0) }
      ):Play()
      task.delay(Theme.Motion.Open + 0.02, function()
        if not self.open then
          win.Visible = false
          backdrop.Visible = false
          self._stopStatusLoop()
        end
      end)
    end
  end

  -- Status bar live update loop
  self._statusThread = nil
  function self._startStatusLoop()
    if self._statusThread then return end
    self._statusThread = task.spawn(function()
      while self.open do
        pcall(function()
          if self._fpsLabel then
            local fps = math.floor(1 / (RunService.RenderStepped:Wait() or 0.016))
            self._fpsLabel.Text = "FPS " .. fps
          end
          if self._pingLabel then
            local ping = math.floor(tonumber(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0)
            self._pingLabel.Text = "Ping " .. ping .. "ms"
          end
          if self._activeLabel then
            self._activeLabel.Text = self.activeCount .. "/14 ON"
          end
        end)
        task.wait(0.5)
      end
    end)
  end
  function self._stopStatusLoop()
    if self._statusThread then
      pcall(function() task.cancel(self._statusThread) end)
      self._statusThread = nil
    end
  end

  return self
end

-- ─── Tab ─────────────────────────────────────────────────────────────────────

function Library:CreateTab(name, iconSpec)
  local tab = {}
  tab.sections = {}

  local page = Instance.new("ScrollingFrame")
  page.Name = name .. "Page"
  page.Parent = self.pages
  page.BackgroundTransparency = 1
  page.Size = UDim2.new(1, 0, 1, 0)
  page.CanvasSize = UDim2.new(0, 0, 0, 0)
  page.AutomaticCanvasSize = Enum.AutomaticSize.Y
  page.ScrollBarThickness = 3
  page.ScrollBarImageColor3 = Theme.Color.TextMuted
  page.ScrollBarImageTransparency = 0.5
  page.BorderSizePixel = 0
  page.ZIndex = Theme.Z.WindowContent

  local padding = Instance.new("UIPadding")
  padding.Parent = page
  padding.PaddingTop = UDim.new(0, Theme.Space.MD)
  padding.PaddingBottom = UDim.new(0, Theme.Space.LG)
  padding.PaddingLeft = UDim.new(0, Theme.Space.MD)
  padding.PaddingRight = UDim.new(0, Theme.Space.MD)

  local list = Instance.new("UIListLayout")
  list.Parent = page
  list.SortOrder = Enum.SortOrder.LayoutOrder
  list.Padding = UDim.new(0, Theme.Space.SM)
  list.ZIndex = Theme.Z.WindowContent

  -- Tab button
  local tabBar = self.window:FindFirstChild("TabBar")
  local btn = Instance.new("TextButton")
  btn.Name = name .. "TabBtn"
  btn.Parent = tabBar
  btn.Size = UDim2.fromOffset(Theme.Touch.TopTabWidth, Theme.Touch.TopTabHeight)
  btn.Position = UDim2.new(0, #self.tabs * Theme.Touch.TopTabWidth, 0, 0)
  btn.BackgroundTransparency = 1
  btn.Text = ""
  btn.AutoButtonColor = false
  btn.BorderSizePixel = 0
  btn.ZIndex = Theme.Z.WindowContent + 1
  btn.LayoutOrder = #self.tabs + 1

  local icon = Instance.new("TextLabel")
  icon.Parent = btn
  icon.BackgroundTransparency = 1
  icon.Size = UDim2.new(0, Theme.Size.Icon, 0, Theme.Size.Icon)
  icon.Position = UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.Icon/2)
  icon.Font = Theme.Font.Icon
  icon.TextSize = Theme.Size.Icon
  icon.Text = tostring(iconSpec or "◆")
  icon.TextColor3 = Theme.Color.TabInactive
  icon.TextXAlignment = Enum.TextXAlignment.Center
  icon.TextYAlignment = Enum.TextYAlignment.Center
  icon.ZIndex = Theme.Z.WindowContent + 2

  local label = makeLabel(btn, name, {
    position = UDim2.new(0, Theme.Space.MD + Theme.Size.Icon + Theme.Space.SM, 0, 0),
    font = Theme.Font.Tab, textSize = Theme.Size.Tab,
    color = Theme.Color.TabInactive,
  })
  label.Size = UDim2.new(1, -Theme.Space.MD * 2 - Theme.Size.Icon - Theme.Space.SM, 1, 0)

  local indicator = Instance.new("Frame")
  indicator.Parent = btn
  indicator.Size = UDim2.new(0.7, 0, 0, 2)
  indicator.Position = UDim2.new(0.15, 0, 1, -2)
  indicator.BackgroundColor3 = Theme.Color.Accent
  indicator.Visible = (#self.tabs == 0)
  indicator.ZIndex = Theme.Z.WindowContent + 3
  indicator.BorderSizePixel = 0
  local indCorner = Instance.new("UICorner")
  indCorner.CornerRadius = UDim.new(1, 0)
  indCorner.Parent = indicator

  Input.onTap(btn, function()
    Input.haptic(0.2, 0.05)
    for _, t in ipairs(self.tabs) do
      Anim.tabSwitch(t, t == tab and tab or nil)
    end
    self.pageLayout:JumpTo(page)
  end)

  tab.page = page
  tab.button = btn
  tab.icon = icon
  tab.label = label
  tab.indicator = indicator
  tab.list = list

  if #self.tabs == 0 then
    self.pageLayout:JumpTo(page)
    -- Visual audit: was TabActive (emerald) for both icon and label — created
    -- triple-green noise. Now: icon ACCENT, label WHITE, indicator ACCENT.
    icon.TextColor3 = Theme.Color.TabActive
    label.TextColor3 = Theme.Color.TextPrimary
    indicator.Visible = true
  end

  table.insert(self.tabs, tab)
  function tab:CreateSection(name) return Library._createSection(self, name) end
  return tab
end

-- ─── Section ───────────────────────────────────────────────────────────────

function Library._createSection(tab, name)
  local section = {}
  section.elements = {}

  -- Visual audit: section title was Accent (emerald) — competed with active tab
  -- indicator. Now: Gold (secondary) — reads as "section header" not "active state".
  local title = makeLabel(tab.page, name, {
    position = UDim2.new(0, Theme.Space.XS, 0, 0),
    font = Theme.Font.Heading, textSize = Theme.Size.Heading,
    color = Theme.Color.Gold,
  })
  title.Size = UDim2.new(1, -Theme.Space.XS * 2, 0, 24)
  title.LayoutOrder = #tab.sections * 1000

  local container = Instance.new("Frame")
  container.Name = name .. "Container"
  container.Parent = tab.page
  container.BackgroundColor3 = Theme.Color.Surface
  container.BackgroundTransparency = Theme.Alpha.GlassCard
  container.Size = UDim2.new(1, 0, 0, 0)
  container.AutomaticSize = Enum.AutomaticSize.Y
  container.LayoutOrder = (#tab.sections * 1000) + 1
  container.ClipsDescendants = true
  container.BorderSizePixel = 0
  container.ZIndex = Theme.Z.WindowContent
  applyGlass(container, { radius = Theme.Radius.Card, transparency = Theme.Alpha.GlassCard })

  local cl = Instance.new("UIListLayout")
  cl.Parent = container
  cl.SortOrder = Enum.SortOrder.LayoutOrder
  cl.Padding = UDim.new(0, 1)
  cl.ZIndex = Theme.Z.WindowContent

  section.container = container
  section.layout = cl
  table.insert(tab.sections, section)

  function section:CreateToggle(opts)   return Library._createToggle(self, opts) end
  function section:CreateSlider(opts)   return Library._createSlider(self, opts) end
  function section:CreateButton(opts)   return Library._createButton(self, opts) end
  function section:CreateKeybind(opts)  return Library._createKeybind(self, opts) end
  function section:CreateDropdown(opts) return Library._createDropdown(self, opts) end
  function section:CreateLabel(text)    return Library._createLabel(self, text) end
  return section
end

-- ─── Toggle ────────────────────────────────────────────────────────────────

function Library._createToggle(section, opts)
  opts = opts or {}
  local row = Instance.new("TextButton")
  row.Name = opts.Name .. "Toggle"
  row.Parent = section.container
  row.BackgroundColor3 = Theme.Color.SurfaceRaised
  row.BackgroundTransparency = Theme.Alpha.GlassCard
  row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
  row.Text = ""
  row.AutoButtonColor = false
  row.LayoutOrder = #section.elements + 1
  row.BorderSizePixel = 0
  row.ZIndex = Theme.Z.WindowContent

  if opts.Icon then
    Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
      UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
  end

  local label = makeLabel(row, opts.Name or "Toggle", {
    position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                      or UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -120, 1, 0)

  local track = Instance.new("Frame")
  track.Parent = row
  track.BackgroundColor3 = Theme.Color.SurfaceInset
  track.Size = UDim2.fromOffset(44, 24)
  track.Position = UDim2.new(1, -Theme.Space.LG - 44, 0.5, -12)
  track.BorderSizePixel = 0
  track.ZIndex = Theme.Z.WindowContent + 1
  local trackCorner = Instance.new("UICorner")
  trackCorner.CornerRadius = UDim.new(1, 0)
  trackCorner.Parent = track

  local knob = Instance.new("Frame")
  knob.Parent = track
  knob.BackgroundColor3 = Theme.Color.TextMuted
  knob.Size = UDim2.fromOffset(18, 18)
  knob.BorderSizePixel = 0
  knob.ZIndex = Theme.Z.WindowContent + 2
  local knobCorner = Instance.new("UICorner")
  knobCorner.CornerRadius = UDim.new(1, 0)
  knobCorner.Parent = knob

  local state = opts.CurrentValue or false
  local function render() Anim.toggle(track, knob, state) end
  -- iOS pattern: WHITE knob on ACCENT track
  knob.Position = UDim2.new(0, state and (44 - 18 - 3) or 3, 0.5, -9)
  if state then
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
  end

  local toggle = { state = state, row = row, knob = knob, track = track }

  function toggle:Set(value)
    state = value
    render()
    if opts.Callback then task.spawn(opts.Callback, value) end
  end

  Input.onTap(row, function()
    Input.haptic(0.3, 0.08)
    Anim.press(row)
    task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
    state = not state
    render()
    if opts.Callback then task.spawn(opts.Callback, state) end
  end)

  table.insert(section.elements, toggle)
  return toggle
end

-- ─── Slider ────────────────────────────────────────────────────────────────

function Library._createSlider(section, opts)
  opts = opts or {}
  local range = opts.Range or {0, 100}
  local value = opts.CurrentValue or range[1]
  local increment = opts.Increment or 1

  local row = Instance.new("Frame")
  row.Name = opts.Name .. "Slider"
  row.Parent = section.container
  row.BackgroundColor3 = Theme.Color.SurfaceRaised
  row.BackgroundTransparency = Theme.Alpha.GlassCard
  row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight + 12)
  row.LayoutOrder = #section.elements + 1
  row.BorderSizePixel = 0
  row.ZIndex = Theme.Z.WindowContent

  if opts.Icon then
    Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
      UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM)
  end

  local label = makeLabel(row, opts.Name or "Slider", {
    position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, Theme.Space.SM)
                      or UDim2.new(0, Theme.Space.LG, 0, Theme.Space.SM),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -120, 0, 20)

  local valueLabel = Instance.new("TextLabel")
  valueLabel.Parent = row
  valueLabel.BackgroundTransparency = 1
  valueLabel.Position = UDim2.new(1, -Theme.Space.LG - 60, 0, Theme.Space.SM)
  valueLabel.Size = UDim2.new(0, 60, 0, 20)
  valueLabel.Font = Theme.Font.Mono
  valueLabel.Text = tostring(value)
  valueLabel.TextColor3 = Theme.Color.Gold
  valueLabel.TextSize = Theme.Size.Value
  valueLabel.TextXAlignment = Enum.TextXAlignment.Right
  valueLabel.TextYAlignment = Enum.TextYAlignment.Center

  local track = Instance.new("Frame")
  track.Parent = row
  track.BackgroundColor3 = Theme.Color.SurfaceInset
  -- Visual audit: track was 6pt — felt flimsy. 8pt is more substantial,
  -- feels more premium, easier to tap-target.
  track.Size = UDim2.new(1, -Theme.Space.LG * 2, 0, 8)
  track.Position = UDim2.new(0, Theme.Space.LG, 0, 34)
  track.BorderSizePixel = 0
  track.ZIndex = Theme.Z.WindowContent
  local trackCorner = Instance.new("UICorner")
  trackCorner.CornerRadius = UDim.new(1, 0)
  trackCorner.Parent = track

  local fill = Instance.new("Frame")
  fill.Parent = track
  fill.BackgroundColor3 = Theme.Color.Accent
  fill.Size = UDim2.new(0, 0, 1, 0)
  fill.BorderSizePixel = 0
  local fillCorner = Instance.new("UICorner")
  fillCorner.CornerRadius = UDim.new(1, 0)
  fillCorner.Parent = fill

  local hitbox = Instance.new("TextButton")
  hitbox.Parent = track
  hitbox.BackgroundTransparency = 1
  hitbox.Size = UDim2.new(1, 0, 0, Theme.Touch.MinTarget)
  hitbox.Position = UDim2.new(0, 0, 0.5, -Theme.Touch.MinTarget/2)
  hitbox.Text = ""
  hitbox.BorderSizePixel = 0
  hitbox.ZIndex = 5

  local slider = { value = value, row = row, fill = fill, valueLabel = valueLabel }

  local function render()
    local ratio = (value - range[1]) / (range[2] - range[1])
    Anim.slider(fill, ratio)
    valueLabel.Text = tostring(math.floor(value * 100) / 100) .. (opts.Suffix or "")
  end
  render()

  function slider:Set(newVal)
    value = math.clamp(newVal, range[1], range[2])
    render()
    if opts.Callback then task.spawn(opts.Callback, value) end
  end

  local dragging = false
  hitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      Input.haptic(0.15, 0.04)
    end
  end)
  hitbox.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging = false
    end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
      local absPos = track.AbsolutePosition
      local absSize = track.AbsoluteSize
      local ratio = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
      local stepped = math.floor((ratio * (range[2] - range[1]) + range[1]) / increment + 0.5) * increment
      if stepped ~= value then
        value = stepped
        render()
        if opts.Callback then task.spawn(opts.Callback, value) end
      end
    end
  end)

  table.insert(section.elements, slider)
  return slider
end

-- ─── Button ────────────────────────────────────────────────────────────────

function Library._createButton(section, opts)
  opts = opts or {}
  local row = Instance.new("TextButton")
  row.Name = opts.Name .. "Button"
  row.Parent = section.container
  row.BackgroundColor3 = Theme.Color.SurfaceRaised
  row.BackgroundTransparency = Theme.Alpha.GlassCard
  row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
  row.Text = ""
  row.AutoButtonColor = false
  row.LayoutOrder = #section.elements + 1
  row.BorderSizePixel = 0
  row.ZIndex = Theme.Z.WindowContent

  if opts.Icon then
    Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
      UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
  end

  local label = makeLabel(row, opts.Name or "Button", {
    position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                      or UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -Theme.Space.LG * 2, 1, 0)
  label.TextXAlignment = Enum.TextXAlignment.Center

  local button = { row = row }
  function button:Set(newName) label.Text = newName end

  Input.onTap(row, function()
    Input.haptic(0.3, 0.08)
    Anim.press(row)
    task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
    if opts.Callback then
      local ok, err = pcall(opts.Callback)
      if not ok then
        Library:Notify({ Title = "⚠ Error", Content = tostring(err), Duration = 4 })
      end
    end
  end)

  table.insert(section.elements, button)
  return button
end

-- ─── Keybind ──────────────────────────────────────────────────────────────

function Library._createKeybind(section, opts)
  opts = opts or {}
  local currentKey = opts.CurrentKeybind or "RightShift"

  local row = Instance.new("TextButton")
  row.Name = opts.Name .. "Keybind"
  row.Parent = section.container
  row.BackgroundColor3 = Theme.Color.SurfaceRaised
  row.BackgroundTransparency = Theme.Alpha.GlassCard
  row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
  row.Text = ""
  row.AutoButtonColor = false
  row.LayoutOrder = #section.elements + 1
  row.BorderSizePixel = 0
  row.ZIndex = Theme.Z.WindowContent

  if opts.Icon then
    Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
      UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
  end

  local label = makeLabel(row, opts.Name or "Keybind", {
    position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                      or UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -120, 1, 0)

  local keyLabel = Instance.new("TextLabel")
  keyLabel.Parent = row
  keyLabel.BackgroundTransparency = 1
  keyLabel.Position = UDim2.new(1, -Theme.Space.LG - 80, 0, 0)
  keyLabel.Size = UDim2.new(0, 80, 1, 0)
  keyLabel.Font = Theme.Font.Mono
  keyLabel.Text = currentKey
  keyLabel.TextColor3 = Theme.Color.Gold
  keyLabel.TextSize = Theme.Size.Value
  keyLabel.TextXAlignment = Enum.TextXAlignment.Right
  keyLabel.TextYAlignment = Enum.TextYAlignment.Center

  local keybind = { key = currentKey, row = row, keyLabel = keyLabel }
  function keybind:Set(newKey)
    currentKey = newKey
    keyLabel.Text = newKey
  end

  local listening = false
  Input.onTap(row, function()
    Input.haptic(0.2, 0.05)
    keyLabel.Text = "..."
    listening = true
  end)

  UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not listening then
      if input.KeyCode.Name == currentKey and opts.Callback then
        task.spawn(opts.Callback)
      end
      return
    end
    if input.KeyCode ~= Enum.KeyCode.Unknown then
      currentKey = input.KeyCode.Name
      keyLabel.Text = currentKey
      listening = false
    end
  end)

  table.insert(section.elements, keybind)
  return keybind
end

-- ─── Dropdown ─────────────────────────────────────────────────────────────

function Library._createDropdown(section, opts)
  opts = opts or {}
  local options = opts.Options or {}
  local current = opts.CurrentOption or (options[1] or "")

  local row = Instance.new("TextButton")
  row.Name = opts.Name .. "Dropdown"
  row.Parent = section.container
  row.BackgroundColor3 = Theme.Color.SurfaceRaised
  row.BackgroundTransparency = Theme.Alpha.GlassCard
  row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
  row.Text = ""
  row.AutoButtonColor = false
  row.LayoutOrder = #section.elements + 1
  row.BorderSizePixel = 0
  row.ZIndex = Theme.Z.WindowContent

  if opts.Icon then
    Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
      UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
  end

  local label = makeLabel(row, opts.Name or "Dropdown", {
    position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                      or UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -100, 1, 0)

  local valueLabel = Instance.new("TextLabel")
  valueLabel.Parent = row
  valueLabel.BackgroundTransparency = 1
  valueLabel.Position = UDim2.new(1, -Theme.Space.LG - 80, 0, 0)
  valueLabel.Size = UDim2.new(0, 80, 1, 0)
  valueLabel.Font = Theme.Font.Mono
  valueLabel.Text = tostring(current)
  valueLabel.TextColor3 = Theme.Color.Gold
  valueLabel.TextSize = Theme.Size.Value
  valueLabel.TextXAlignment = Enum.TextXAlignment.Right
  valueLabel.TextYAlignment = Enum.TextYAlignment.Center

  local dropdown = { value = current, options = options, row = row, valueLabel = valueLabel }
  function dropdown:Set(val)
    current = val
    valueLabel.Text = tostring(val)
    if opts.Callback then task.spawn(opts.Callback, val) end
  end
  function dropdown:Refresh(newOptions)
    options = newOptions
    current = options[1] or ""
    valueLabel.Text = tostring(current)
  end

  Input.onTap(row, function()
    Input.haptic(0.2, 0.05)
    Anim.press(row)
    task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
    local idx = table.find(options, current) or 0
    local nextOpt = options[(idx % #options) + 1]
    if nextOpt then dropdown:Set(nextOpt) end
  end)

  table.insert(section.elements, dropdown)
  return dropdown
end

-- ─── Label ─────────────────────────────────────────────────────────────────

function Library._createLabel(section, text)
  local lbl = makeLabel(section.container, text, {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Label, textSize = Theme.Size.Label,
    color = Theme.Color.TextSecondary,
  })
  lbl.Size = UDim2.new(1, -Theme.Space.LG * 2, 0, 24)
  lbl.LayoutOrder = #section.elements + 1
  return lbl
end

return Library
