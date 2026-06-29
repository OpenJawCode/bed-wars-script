-- src/ui/library.lua
-- Custom UI library — dark luxe glassmorphic, mobile-first, zero dependencies.
-- Inspired by Rayfield's API surface but built entirely with Instance.new()
-- so we have no rbxassetid:// dependency (Rayfield loads from a hosted asset).
--
-- API (mirrors Rayfield so it's familiar):
--   local Window = Library:CreateWindow({ Name=..., Accent=... })
--   local Tab    = Window:CreateTab("Combat", Icons.Combat)
--   local Section = Tab:CreateSection("Offense")
--   local Toggle = Section:CreateToggle({ Name="Killaura", CurrentValue=false, Callback=... })
--   local Slider = Section:CreateSlider({ Name="Range", Range={5,30}, CurrentValue=18, Callback=... })
--   local Button = Section:CreateButton({ Name="Refresh", Callback=... })
--   local Keybind= Section:CreateKeybind({ Name="Toggle UI", CurrentKeybind="RightShift", Callback=... })
--   Library:Notify({ Title="...", Content="...", Duration=4 })
--
-- Mobile-first: bottom tabs, 56pt touch targets, snap-to-edge drag, haptic on tap.


local _BW = (getgenv and getgenv()._BW) or _G._BW
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")

local Theme   = _BW.Theme
local Tween   = _BW.Tween
local Dragger = _BW.Dragger
local Input   = _BW.Input
local Anim    = _BW.Anim
local Icons   = _BW.Icons

local Library = {}

-- ─── Helpers ────────────────────────────────────────────────────────────────

-- Decide where to parent our ScreenGui. Try gethui (executor), then CoreGui.
local function getGuiParent()
  local ok, hui = pcall(function() return gethui() end)
  if ok and hui then return hui end
  local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
  if ok2 and cg then return cg end
  return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Apply a glass effect to a frame: bg color, transparency, stroke, corner.
local function applyGlass(frame, opts)
  opts = opts or {}
  frame.BackgroundColor3 = opts.color or Theme.Color.Surface
  frame.BackgroundTransparency = opts.transparency or Theme.Alpha.GlassPanel
  local stroke = Instance.new("UIStroke")
  stroke.Color = Theme.Color.Border
  stroke.Transparency = opts.strokeTransparency or Theme.Alpha.Border
  stroke.Thickness = 1
  stroke.Parent = frame
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, opts.radius or Theme.Radius.Card)
  corner.Parent = frame
  return stroke, corner
end

-- Create a TextLabel with sane defaults.
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
  lbl.TextXAlignment = Enum.TextXAlignment.Left
  lbl.TextYAlignment = Enum.TextYAlignment.Center
  lbl.RichText = opts.richText or false
  return lbl
end

-- ─── Notifications ───────────────────────────────────────────────────────────
-- Top-anchored, stacked via UIListLayout, slide-in + auto-dismiss.

local function createNotificationSystem(screengui)
  local container = Instance.new("Frame")
  container.Name = "Notifications"
  container.Parent = screengui
  container.BackgroundTransparency = 1
  container.Position = UDim2.new(0.5, 0, 0, Theme.Space.LG)
  container.Size = UDim2.new(0, 320, 1, -Theme.Space.LG * 2)
  container.AnchorPoint = Vector2.new(0.5, 0)
  container.ZIndex = 100

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
  notif.ZIndex = 101
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

  -- Slide-in: tween height from 0 to computed.
  local targetHeight = 60
  TweenService:Create(notif,
    TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    { Size = UDim2.new(1, 0, 0, targetHeight), BackgroundTransparency = Theme.Alpha.GlassCard }
  ):Play()

  -- Auto-dismiss
  local duration = data.Duration or 4
  task.delay(duration, function()
    if not notif.Parent then return end
    TweenService:Create(notif,
      TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
      { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }
    ):Play()
    for _, child in ipairs(notif:GetChildren()) do
      if child:IsA("TextLabel") then
        TweenService:Create(child,
          TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
          { TextTransparency = 1 }
        ):Play()
      end
    end
    task.wait(0.45)
    notif:Destroy()
  end)
end

-- ─── Floating Action Button (always-visible toggle) ────────────────────────
-- The user taps this to open/close the menu. Draggable, snaps to edge.

local function createFab(screengui, openMenu)
  local fab = Instance.new("TextButton")
  fab.Name = "FAB"
  fab.Parent = screengui
  fab.BackgroundColor3 = Theme.Color.Accent
  fab.Size = UDim2.new(0, Theme.Touch.FloatingBtn, 0, Theme.Touch.FloatingBtn)
  fab.Position = UDim2.new(0, Theme.Space.LG, 1, -Theme.Touch.FloatingBtn - Theme.Space.LG)
  fab.Text = ""
  fab.ZIndex = 50
  fab.AutoButtonColor = false
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
  corner.Parent = fab
  local stroke = Instance.new("UIStroke")
  stroke.Color = Theme.Color.AccentGlow
  stroke.Transparency = 0.4
  stroke.Thickness = 1.5
  stroke.Parent = fab
  local icon = Instance.new("ImageLabel")
  icon.Parent = fab
  icon.BackgroundTransparency = 1
  icon.Size = UDim2.new(0, 24, 0, 24)
  icon.Position = UDim2.new(0.5, -12, 0.5, -12)
  icon.Image = "rbxassetid://" .. tostring(Icons.Logo)
  icon.ImageColor3 = Color3.fromRGB(10, 15, 26)
  Dragger.enable(fab, { snapToEdge = true, snapPadding = Theme.Space.LG, animate = true })
  Input.onTap(fab, function()
    Input.haptic(0.3, 0.08)
    Anim.press(fab)
    task.delay(0.1, function() Anim.release(fab) end)
    openMenu()
  end)
  return fab
end

-- ─── Window ──────────────────────────────────────────────────────────────────

function Library:CreateWindow(settings)
  settings = settings or {}
  local self = setmetatable({}, { __index = Library })
  self.tabs = {}
  self.open = false
  self.theme = Theme

  -- ScreenGui
  local sg = Instance.new("ScreenGui")
  sg.Name = settings.Name or "BedwarsScript"
  sg.ResetOnSpawn = false
  sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  sg.DisplayOrder = 100
  sg.Parent = getGuiParent()
  self.screengui = sg

  -- Notifications container
  self._notifContainer = createNotificationSystem(sg)

  -- Main window (hidden until FAB tapped)
  local win = Instance.new("Frame")
  win.Name = "Window"
  win.Parent = sg
  win.BackgroundColor3 = Theme.Color.Surface
  win.BackgroundTransparency = Theme.Alpha.GlassPanel
  win.Size = UDim2.new(0, 380, 0, 480)
  win.Position = UDim2.new(0.5, -190, 0.5, -240)
  win.Visible = false
  win.ZIndex = 10
  win.ClipsDescendants = true  -- CRITICAL: clips header/tabs during open/close animation
  applyGlass(win, { radius = Theme.Radius.Card, transparency = Theme.Alpha.GlassPanel })
  self.window = win

  -- Header
  local header = Instance.new("Frame")
  header.Name = "Header"
  header.Parent = win
  header.BackgroundColor3 = Theme.Color.SurfaceRaised
  header.BackgroundTransparency = Theme.Alpha.GlassCard
  header.Size = UDim2.new(1, 0, 0, 56)
  header.Position = UDim2.new(0, 0, 0, 0)
  applyGlass(header, { radius = 0 })
  self.header = header

  local headerStroke = Instance.new("UIStroke")
  headerStroke.Color = Theme.Color.Border
  headerStroke.Transparency = Theme.Alpha.Border
  headerStroke.Thickness = 1
  headerStroke.Parent = header

  local title = makeLabel(header, settings.Name or "Bedwars Script", {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Heading, textSize = Theme.Size.Heading,
    color = Theme.Color.TextPrimary,
  })
  title.Size = UDim2.new(1, -120, 1, 0)

  local accentDot = Instance.new("Frame")
  accentDot.Parent = header
  accentDot.BackgroundColor3 = Theme.Color.Accent
  accentDot.Size = UDim2.new(0, 8, 0, 8)
  accentDot.Position = UDim2.new(1, -Theme.Space.LG - 8, 0.5, -4)
  local dotCorner = Instance.new("UICorner")
  dotCorner.CornerRadius = UDim.new(1, 0)
  dotCorner.Parent = accentDot

  local closeBtn = Instance.new("TextButton")
  closeBtn.Parent = header
  closeBtn.BackgroundColor3 = Theme.Color.Danger
  closeBtn.BackgroundTransparency = 0.5
  closeBtn.Size = UDim2.new(0, 28, 0, 28)
  closeBtn.Position = UDim2.new(1, -Theme.Space.LG - 24, 0.5, -14)
  closeBtn.Text = "X"
  closeBtn.TextColor3 = Theme.Color.TextPrimary
  closeBtn.Font = Theme.Font.Heading
  closeBtn.TextSize = 12
  closeBtn.ZIndex = 11
  closeBtn.AutoButtonColor = false
  local closeCorner = Instance.new("UICorner")
  closeCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
  closeCorner.Parent = closeBtn
  Input.onTap(closeBtn, function()
    Input.haptic(0.3, 0.08)
    self:SetVisible(false)
  end)

  -- Tab content area (above the bottom tab bar)
  local contentArea = Instance.new("Frame")
  contentArea.Name = "Content"
  contentArea.Parent = win
  contentArea.BackgroundTransparency = 1
  contentArea.Position = UDim2.new(0, 0, 0, 56)
  contentArea.Size = UDim2.new(1, 0, 1, -56 - Theme.Touch.TabHeight)
  self.contentArea = contentArea

  local pages = Instance.new("Frame")
  pages.Name = "Pages"
  pages.Parent = contentArea
  pages.BackgroundTransparency = 1
  pages.Size = UDim2.new(1, 0, 1, 0)
  self.pages = pages

  local pageLayout = Instance.new("UIPageLayout")
  pageLayout.Parent = pages
  pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
  pageLayout.EasingDirection = Enum.EasingDirection.In
  pageLayout.EasingStyle = Enum.EasingStyle.Quint
  pageLayout.TweenTime = 0.25
  pageLayout.Circular = false
  self.pageLayout = pageLayout

  -- Bottom tab bar
  local tabBar = Instance.new("Frame")
  tabBar.Name = "TabBar"
  tabBar.Parent = win
  tabBar.BackgroundColor3 = Theme.Color.SurfaceRaised
  tabBar.BackgroundTransparency = Theme.Alpha.GlassCard
  tabBar.Size = UDim2.new(1, 0, 0, Theme.Touch.TabHeight)
  tabBar.Position = UDim2.new(0, 0, 1, -Theme.Touch.TabHeight)
  applyGlass(tabBar, { radius = 0 })
  self.tabBar = tabBar

  local tabLayout = Instance.new("UIListLayout")
  tabLayout.Parent = tabBar
  tabLayout.FillDirection = Enum.FillDirection.Horizontal
  tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
  tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
  tabLayout.Padding = UDim.new(0, 0)

  -- FAB (floating action button) — always visible
  self.fab = createFab(sg, function() self:SetVisible(not self.open) end)

  -- Drag the window by header
  Dragger.enable(header, { snapToEdge = false, animate = false })

  return self
end

function Library:SetVisible(visible)
  self.open = visible
  if visible then
    self.window.Visible = true
    self.window.Size = UDim2.new(0, 380, 0, 0)
    TweenService:Create(self.window,
      TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.Out),
      { Size = UDim2.new(0, 380, 0, 480) }
    ):Play()
  else
    TweenService:Create(self.window,
      TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.In),
      { Size = UDim2.new(0, 380, 0, 0) }
    ):Play()
    task.delay(Theme.Motion.Open + 0.05, function()
      if not self.open then self.window.Visible = false end
    end)
  end
end

-- ─── Tab ─────────────────────────────────────────────────────────────────────

function Library:CreateTab(name, iconAssetId)
  local tab = {}
  tab.sections = {}

  -- Tab page (the scrollable content)
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
  page.CanvasPosition = Vector2.new(0, 0)

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

  -- Tab button in the bottom bar
  local btn = Instance.new("TextButton")
  btn.Name = name .. "TabBtn"
  btn.Parent = self.tabBar
  btn.BackgroundColor3 = Theme.Color.Transparent and Theme.Color.Surface or Theme.Color.Surface
  btn.BackgroundTransparency = 1
  btn.Size = UDim2.new(0, 70, 1, 0)
  btn.Text = ""
  btn.AutoButtonColor = false
  btn.LayoutOrder = #self.tabs + 1

  local icon = Instance.new("ImageLabel")
  icon.Parent = btn
  icon.BackgroundTransparency = 1
  icon.Size = UDim2.new(0, Theme.Size.Icon, 0, Theme.Size.Icon)
  icon.Position = UDim2.new(0.5, -Theme.Size.Icon/2, 0.5, -Theme.Size.Icon/2 - 8)
  icon.Image = "rbxassetid://" .. tostring(iconAssetId or Icons.Misc)
  icon.ImageColor3 = Theme.Color.TextSecondary

  local label = Instance.new("TextLabel")
  label.Parent = btn
  label.BackgroundTransparency = 1
  label.Size = UDim2.new(1, 0, 0, 14)
  label.Position = UDim2.new(0, 0, 1, -14)
  label.Font = Theme.Font.Label
  label.Text = name
  label.TextColor3 = Theme.Color.TextSecondary
  label.TextSize = Theme.Size.Caption
  label.TextXAlignment = Enum.TextXAlignment.Center

  local indicator = Instance.new("Frame")
  indicator.Parent = btn
  indicator.BackgroundColor3 = Theme.Color.Accent
  indicator.Size = UDim2.new(0, 24, 0, 2)
  indicator.Position = UDim2.new(0.5, -12, 0, 0)
  indicator.Visible = (#self.tabs == 0)
  local indCorner = Instance.new("UICorner")
  indCorner.CornerRadius = UDim.new(1, 0)
  indCorner.Parent = indicator

  Input.onTap(btn, function()
    Input.haptic(0.2, 0.05)
    self.pageLayout:JumpTo(page)
    -- Update indicators
    for _, t in ipairs(self.tabs) do
      t.indicator.Visible = false
      t.icon.ImageColor3 = Theme.Color.TextSecondary
      t.label.TextColor3 = Theme.Color.TextSecondary
    end
    indicator.Visible = true
    icon.ImageColor3 = Theme.Color.Accent
    label.TextColor3 = Theme.Color.Accent
  end)

  tab.page = page
  tab.button = btn
  tab.icon = icon
  tab.label = label
  tab.indicator = indicator
  tab.list = list

  -- If first tab, jump to it
  if #self.tabs == 0 then
    self.pageLayout:JumpTo(page)
    icon.ImageColor3 = Theme.Color.Accent
    label.TextColor3 = Theme.Color.Accent
  end

  table.insert(self.tabs, tab)

  -- Add tab methods
  function tab:CreateSection(name)
    return Library._createSection(self, name)
  end

  return tab
end

-- ─── Section ─────────────────────────────────────────────────────────────────

function Library._createSection(tab, name)
  local section = {}
  section.elements = {}

  -- Section title
  local title = makeLabel(tab.page, name, {
    position = UDim2.new(0, Theme.Space.XS, 0, 0),
    font = Theme.Font.Heading, textSize = Theme.Size.Heading,
    color = Theme.Color.TextSecondary,
  })
  title.Size = UDim2.new(1, -Theme.Space.XS * 2, 0, 24)
  title.LayoutOrder = #tab.sections * 1000

  -- Container for elements
  local container = Instance.new("Frame")
  container.Name = name .. "Container"
  container.Parent = tab.page
  container.BackgroundColor3 = Theme.Color.Surface
  container.BackgroundTransparency = Theme.Alpha.GlassCard
  container.Size = UDim2.new(1, 0, 0, 0)
  container.AutomaticSize = Enum.AutomaticSize.Y
  container.LayoutOrder = (#tab.sections * 1000) + 1
  container.ClipsDescendants = true  -- clips flat rows to the rounded container shape
  applyGlass(container, { radius = Theme.Radius.Card, transparency = Theme.Alpha.GlassCard })

  local cl = Instance.new("UIListLayout")
  cl.Parent = container
  cl.SortOrder = Enum.SortOrder.LayoutOrder
  cl.Padding = UDim.new(0, 1)

  section.container = container
  section.layout = cl

  table.insert(tab.sections, section)

  -- Methods
  function section:CreateToggle(opts)   return Library._createToggle(section, opts) end
  function section:CreateSlider(opts)   return Library._createSlider(section, opts) end
  function section:CreateButton(opts)   return Library._createButton(section, opts) end
  function section:CreateKeybind(opts)  return Library._createKeybind(section, opts) end
  function section:CreateDropdown(opts) return Library._createDropdown(section, opts) end
  function section:CreateLabel(text)    return Library._createLabel(section, text) end

  return section
end

-- ─── Element: Toggle ────────────────────────────────────────────────────────

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
  applyGlass(row, { radius = 0 })

  local label = makeLabel(row, opts.Name or "Toggle", {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -100, 1, 0)

  -- iOS-style switch
  local track = Instance.new("Frame")
  track.Parent = row
  track.BackgroundColor3 = Theme.Color.SurfaceInset
  track.Size = UDim2.new(0, 44, 0, 24)
  track.Position = UDim2.new(1, -Theme.Space.LG - 44, 0.5, -12)
  local trackCorner = Instance.new("UICorner")
  trackCorner.CornerRadius = UDim.new(1, 0)
  trackCorner.Parent = track

  local knob = Instance.new("Frame")
  knob.Parent = track
  knob.BackgroundColor3 = Theme.Color.TextMuted
  knob.Size = UDim2.new(0, 18, 0, 18)
  local knobCorner = Instance.new("UICorner")
  knobCorner.CornerRadius = UDim.new(1, 0)
  knobCorner.Parent = knob

  local state = opts.CurrentValue or false
  local function render()
    local targetX = state and (44 - 18 - 3) or 3
    TweenService:Create(knob,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { Position = UDim2.new(0, targetX, 0.5, -9),
        BackgroundColor3 = state and Theme.Color.Accent or Theme.Color.TextMuted }
    ):Play()
    TweenService:Create(track,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { BackgroundColor3 = state and Color3.fromRGB(16, 185, 129, 0.3) or Theme.Color.SurfaceInset }
    ):Play()
  end
  -- Initial position
  knob.Position = UDim2.new(0, state and (44 - 18 - 3) or 3, 0.5, -9)
  if state then
    knob.BackgroundColor3 = Theme.Color.Accent
    track.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    track.BackgroundTransparency = 0.7
  end

  local toggle = { state = state, row = row, knob = knob, track = track }

  function toggle:Set(value)
    state = value
    render()
    if opts.Callback then task.spawn(opts.Callback, value) end
  end

  Input.onTap(row, function()
    Input.haptic(0.25, 0.08)
    Anim.press(row)
    task.delay(0.1, function() Anim.release(row) end)
    state = not state
    render()
    if opts.Callback then task.spawn(opts.Callback, state) end
  end)

  table.insert(section.elements, toggle)
  return toggle
end

-- ─── Element: Slider ────────────────────────────────────────────────────────

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
  applyGlass(row, { radius = 0 })

  local label = makeLabel(row, opts.Name or "Slider", {
    position = UDim2.new(0, Theme.Space.LG, 0, Theme.Space.SM),
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
  valueLabel.TextColor3 = Theme.Color.Accent
  valueLabel.TextSize = Theme.Size.Body
  valueLabel.TextXAlignment = Enum.TextXAlignment.Right

  -- Track
  local track = Instance.new("Frame")
  track.Parent = row
  track.BackgroundColor3 = Theme.Color.SurfaceInset
  track.Size = UDim2.new(1, -Theme.Space.LG * 2, 0, 6)
  track.Position = UDim2.new(0, Theme.Space.LG, 0, 34)
  local trackCorner = Instance.new("UICorner")
  trackCorner.CornerRadius = UDim.new(1, 0)
  trackCorner.Parent = track

  local fill = Instance.new("Frame")
  fill.Parent = track
  fill.BackgroundColor3 = Theme.Color.Accent
  fill.Size = UDim2.new(0, 0, 1, 0)
  local fillCorner = Instance.new("UICorner")
  fillCorner.CornerRadius = UDim.new(1, 0)
  fillCorner.Parent = fill

  local hitbox = Instance.new("TextButton")
  hitbox.Parent = track
  hitbox.BackgroundTransparency = 1
  hitbox.Size = UDim2.new(1, 0, 0, Theme.Touch.MinTarget)
  hitbox.Position = UDim2.new(0, 0, 0.5, -Theme.Touch.MinTarget/2)
  hitbox.Text = ""
  hitbox.ZIndex = 5

  local slider = { value = value, row = row, fill = fill, valueLabel = valueLabel }

  local function render()
    local ratio = (value - range[1]) / (range[2] - range[1])
    TweenService:Create(fill,
      TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
      { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }
    ):Play()
    valueLabel.Text = tostring(math.floor(value * 100) / 100) .. (opts.Suffix or "")
  end
  render()

  function slider:Set(newVal)
    value = math.clamp(newVal, range[1], range[2])
    render()
    if opts.Callback then task.spawn(opts.Callback, value) end
  end

  -- Drag handler
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

-- ─── Element: Button ─────────────────────────────────────────────────────────

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
  applyGlass(row, { radius = 0 })

  local label = makeLabel(row, opts.Name or "Button", {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -Theme.Space.LG * 2, 1, 0)
  label.TextXAlignment = Enum.TextXAlignment.Center

  local button = { row = row }
  function button:Set(newName)
    label.Text = newName
  end

  Input.onTap(row, function()
    Input.haptic(0.3, 0.08)
    Anim.press(row)
    task.delay(0.1, function() Anim.release(row) end)
    if opts.Callback then
      local ok, err = pcall(opts.Callback)
      if not ok then
        Library:Notify({ Title = "Callback Error", Content = tostring(err), Duration = 4 })
      end
    end
  end)

  table.insert(section.elements, button)
  return button
end

-- ─── Element: Keybind ───────────────────────────────────────────────────────

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
  applyGlass(row, { radius = 0 })

  local label = makeLabel(row, opts.Name or "Keybind", {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
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
  keyLabel.TextColor3 = Theme.Color.Accent
  keyLabel.TextSize = Theme.Size.Body
  keyLabel.TextXAlignment = Enum.TextXAlignment.Right

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
      -- Normal keybind trigger
      if input.KeyCode.Name == currentKey and opts.Callback then
        task.spawn(opts.Callback)
      end
      return
    end
    -- Listening for new key
    if input.KeyCode ~= Enum.KeyCode.Unknown then
      currentKey = input.KeyCode.Name
      keyLabel.Text = currentKey
      listening = false
    end
  end)

  table.insert(section.elements, keybind)
  return keybind
end

-- ─── Element: Dropdown ──────────────────────────────────────────────────────

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
  applyGlass(row, { radius = 0 })

  local label = makeLabel(row, opts.Name or "Dropdown", {
    position = UDim2.new(0, Theme.Space.LG, 0, 0),
    font = Theme.Font.Body, textSize = Theme.Size.Body,
    color = Theme.Color.TextPrimary,
  })
  label.Size = UDim2.new(1, -120, 1, 0)

  local valueLabel = Instance.new("TextLabel")
  valueLabel.Parent = row
  valueLabel.BackgroundTransparency = 1
  valueLabel.Position = UDim2.new(1, -Theme.Space.LG - 80, 0, 0)
  valueLabel.Size = UDim2.new(0, 80, 1, 0)
  valueLabel.Font = Theme.Font.Mono
  valueLabel.Text = tostring(current)
  valueLabel.TextColor3 = Theme.Color.Accent
  valueLabel.TextSize = Theme.Size.Body
  valueLabel.TextXAlignment = Enum.TextXAlignment.Right

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

  -- Simple cycle on tap (mobile-friendly — no expand/collapse menu for v1)
  Input.onTap(row, function()
    Input.haptic(0.2, 0.05)
    Anim.press(row)
    task.delay(0.1, function() Anim.release(row) end)
    local idx = table.find(options, current) or 0
    local next = options[(idx % #options) + 1]
    if next then dropdown:Set(next) end
  end)

  table.insert(section.elements, dropdown)
  return dropdown
end

-- ─── Element: Label ─────────────────────────────────────────────────────────

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
