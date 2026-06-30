-- src/ui/error_overlay.lua
-- Visible BOOT FAILED overlay. Without this, any error in the boot
-- sequence gets swallowed by pcall and the user sees nothing.
--
-- Usage:
--   local ErrorOverlay = require("ui/error_overlay")
--   local ok, err = pcall(function() ... end)
--   if not ok then ErrorOverlay.show(err) end
--
-- Or at the start of boot:
--   ErrorOverlay.install()   -- shows a "Loading..." splash immediately
--   ... do boot ...
--   ErrorOverlay.success()   -- dismiss the splash

local _BW = (getgenv and getgenv()._BW) or _G._BW
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")

local ErrorOverlay = {}

-- Get a safe GUI parent (same logic as the library)
local function getGuiParent()
  local ok, hui = pcall(function() return gethui() end)
  if ok and hui then return hui end
  local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
  if ok2 and cg then return cg end
  return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Build the splash screen (shown during boot, dismissed on success)
local function buildSplash(parent, title, subtitle)
  local splash = Instance.new("Frame")
  splash.Name = "BWSplash"
  splash.Parent = parent
  splash.Size = UDim2.new(1, 0, 1, 0)
  splash.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
  splash.BackgroundTransparency = 0
  splash.BorderSizePixel = 0
  splash.ZIndex = 1000
  return splash
end

-- Install the splash — call at the VERY START of boot, before anything else.
-- Returns the splash Frame so you can dismiss it later with :success().
function ErrorOverlay.install()
  local ok, parent = pcall(getGuiParent)
  if not ok or not parent then return nil end

  local splash = buildSplash(parent)
  -- Center logo
  local center = Instance.new("Frame")
  center.Parent = splash
  center.BackgroundTransparency = 1
  center.Size = UDim2.fromOffset(280, 120)
  center.Position = UDim2.new(0.5, -140, 0.5, -60)
  center.BorderSizePixel = 0
  center.ZIndex = 1001

  local logo = Instance.new("TextLabel")
  logo.Parent = center
  logo.BackgroundTransparency = 1
  logo.Size = UDim2.fromOffset(280, 60)
  logo.Position = UDim2.new(0, 0, 0, 0)
  logo.Text = "✦"
  logo.TextColor3 = Color3.fromRGB(16, 185, 129)
  logo.Font = Enum.Font.GothamBlack
  logo.TextSize = 48
  logo.TextXAlignment = Enum.TextXAlignment.Center
  logo.ZIndex = 1001

  local title = Instance.new("TextLabel")
  title.Parent = center
  title.BackgroundTransparency = 1
  title.Size = UDim2.fromOffset(280, 24)
  title.Position = UDim2.new(0, 0, 0, 60)
  title.Text = "Bedwars Script"
  title.TextColor3 = Color3.fromRGB(240, 242, 248)
  title.Font = Enum.Font.GothamBold
  title.TextSize = 18
  title.TextXAlignment = Enum.TextXAlignment.Center
  title.ZIndex = 1001

  local sub = Instance.new("TextLabel")
  sub.Parent = center
  sub.BackgroundTransparency = 1
  sub.Size = UDim2.fromOffset(280, 20)
  sub.Position = UDim2.new(0, 0, 0, 88)
  sub.Text = "Loading…"
  sub.TextColor3 = Color3.fromRGB(160, 170, 188)
  sub.Font = Enum.Font.GothamMedium
  sub.TextSize = 13
  sub.TextXAlignment = Enum.TextXAlignment.Center
  sub.ZIndex = 1001

  -- Spinner (a pulsing dot)
  local spinner = Instance.new("Frame")
  spinner.Parent = center
  spinner.Size = UDim2.fromOffset(20, 20)
  spinner.Position = UDim2.new(0.5, -10, 0, 112)
  spinner.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
  spinner.BorderSizePixel = 0
  spinner.ZIndex = 1001
  local sc = Instance.new("UICorner")
  sc.CornerRadius = UDim.new(1, 0)
  sc.Parent = spinner
  -- Pulse the spinner
  task.spawn(function()
    while spinner and spinner.Parent do
      TweenService:Create(spinner,
        TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundTransparency = 0.3, Size = UDim2.fromOffset(28, 28) }
      ):Play()
      task.wait(0.6)
      if not spinner.Parent then return end
      TweenService:Create(spinner,
        TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundTransparency = 0.7, Size = UDim2.fromOffset(20, 20) }
      ):Play()
      task.wait(0.6)
    end
  end)

  ErrorOverlay._splash = splash
  ErrorOverlay._subtitle = sub
  return splash
end

-- Dismiss the splash with a fade out
function ErrorOverlay.success()
  if not ErrorOverlay._splash then return end
  local splash = ErrorOverlay._splash
  TweenService:Create(splash,
    TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    { BackgroundTransparency = 1 }
  ):Play()
  task.delay(0.5, function()
    if splash.Parent then splash:Destroy() end
  end)
  ErrorOverlay._splash = nil
end

-- Show a FATAL ERROR overlay. This is the key fix — if anything in the
-- boot sequence fails, the user SEES the error instead of a blank screen.
function ErrorOverlay.show(errMsg)
  local ok, parent = pcall(getGuiParent)
  if not ok or not parent then
    warn("[bw-script] BOOT FAILED: " .. tostring(errMsg))
    return
  end

  -- Remove the splash if it's still up
  if ErrorOverlay._splash and ErrorOverlay._splash.Parent then
    ErrorOverlay._splash:Destroy()
    ErrorOverlay._splash = nil
  end

  local err = Instance.new("Frame")
  err.Name = "BWError"
  err.Parent = parent
  err.Size = UDim2.new(1, -32, 0, 0)
  err.Position = UDim2.new(0, 16, 0.5, 0)
  err.AnchorPoint = Vector2.new(0, 0.5)
  err.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
  err.BorderSizePixel = 0
  err.ZIndex = 9999
  err.AutomaticSize = Enum.AutomaticSize.Y
  err.ClipsDescendants = true

  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 12)
  corner.Parent = err

  local stroke = Instance.new("UIStroke")
  stroke.Color = Color3.fromRGB(239, 68, 68)
  stroke.Thickness = 1.5
  stroke.Parent = err

  -- Top bar: red title
  local titleBg = Instance.new("Frame")
  titleBg.Parent = err
  titleBg.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
  titleBg.BackgroundTransparency = 0.3
  titleBg.Size = UDim2.new(1, 0, 0, 40)
  titleBg.Position = UDim2.new(0, 0, 0, 0)
  titleBg.BorderSizePixel = 0
  titleBg.ZIndex = 10000

  local titleIcon = Instance.new("TextLabel")
  titleIcon.Parent = titleBg
  titleIcon.BackgroundTransparency = 1
  titleIcon.Size = UDim2.new(0, 40, 1, 0)
  titleIcon.Position = UDim2.new(0, 8, 0, 0)
  titleIcon.Text = "⚠"
  titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
  titleIcon.Font = Enum.Font.GothamBlack
  titleIcon.TextSize = 20
  titleIcon.TextXAlignment = Enum.TextXAlignment.Center
  titleIcon.TextYAlignment = Enum.TextYAlignment.Center
  titleIcon.ZIndex = 10001

  local titleLbl = Instance.new("TextLabel")
  titleLbl.Parent = titleBg
  titleLbl.BackgroundTransparency = 1
  titleLbl.Size = UDim2.new(1, -56, 1, 0)
  titleLbl.Position = UDim2.new(0, 48, 0, 0)
  titleLbl.Text = "BOOT FAILED"
  titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
  titleLbl.Font = Enum.Font.GothamBlack
  titleLbl.TextSize = 14
  titleLbl.TextXAlignment = Enum.TextXAlignment.Left
  titleLbl.TextYAlignment = Enum.TextYAlignment.Center
  titleLbl.ZIndex = 10001

  -- Error message body
  local body = Instance.new("TextLabel")
  body.Parent = err
  body.BackgroundTransparency = 1
  body.Size = UDim2.new(1, -24, 0, 0)
  body.Position = UDim2.new(0, 12, 0, 48)
  body.AutomaticSize = Enum.AutomaticSize.Y
  body.Text = tostring(errMsg or "Unknown error")
  body.TextColor3 = Color3.fromRGB(255, 200, 200)
  body.Font = Enum.Font.Code
  body.TextSize = 11
  body.TextXAlignment = Enum.TextXAlignment.Left
  body.TextYAlignment = Enum.TextYAlignment.Top
  body.TextWrapped = true
  body.ZIndex = 10000

  -- Animate the error: slide down from top, grow height
  err.Size = UDim2.new(1, -32, 0, 0)
  err.BackgroundTransparency = 1
  TweenService:Create(err,
    TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    { BackgroundTransparency = 0, Size = UDim2.new(1, -32, 0, 200) }
  ):Play()
  task.delay(0.4, function()
    if not err or not err.Parent then return end
    err.AutomaticSize = Enum.AutomaticSize.Y
  end)

  -- Add a "Copy error" button
  local btn = Instance.new("TextButton")
  btn.Parent = err
  btn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
  btn.Size = UDim2.new(1, -24, 0, 32)
  btn.Position = UDim2.new(0, 12, 1, -40)
  btn.Text = "Copy error to clipboard"
  btn.TextColor3 = Color3.fromRGB(255, 200, 200)
  btn.Font = Enum.Font.GothamMedium
  btn.TextSize = 12
  btn.AutoButtonColor = false
  btn.BorderSizePixel = 0
  btn.ZIndex = 10001
  local btnCorner = Instance.new("UICorner")
  btnCorner.CornerRadius = UDim.new(0, 6)
  btnCorner.Parent = btn
  btn.MouseButton1Click:Connect(function()
    if setclipboard then
      pcall(function() setclipboard(tostring(errMsg)) end)
    end
  end)

  print("[bw-script] BOOT FAILED: " .. tostring(errMsg))
  warn("[bw-script] BOOT FAILED: " .. tostring(errMsg))
end

return ErrorOverlay
