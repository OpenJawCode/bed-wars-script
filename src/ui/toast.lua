-- src/ui/toast.lua
-- Premium toast notification system. Top-right column, stacked downward.
-- 5 semantic types: info, success, accent, neutral, danger.
--
-- Per the v1.3 design spec: slide-in 280ms Quint.Out, stay 1.8-5.5s
-- depending on type, auto-dismiss with fade + collapse.
--
-- Usage:
--   local Toast = require("ui/toast")
--   Toast.success("Killaura", "Enabled — 28 studs")
--   Toast.danger("Boot failed", "Knit bootstrap timeout")
--   Toast.setParent(screengui)  -- call once at boot

local _BW = (getgenv and getgenv()._BW) or _G._BW
local TweenService = game:GetService("TweenService")

local Theme = _BW.Theme
local Logger = _BW.Logger

local Toast = {}

-- 5 semantic types with config
Toast.TYPES = {
  info = {
    color     = Color3.fromRGB(59, 130, 246),    -- blue
    icon      = "ⓘ",
    label     = "INFO",
    duration  = 2.5,
  },
  success = {
    color     = Color3.fromRGB(16, 185, 129),    -- emerald
    icon      = "✓",
    label     = "ON",
    duration  = 1.8,
  },
  accent = {
    color     = Color3.fromRGB(245, 183, 0),     -- gold
    icon      = "✦",
    label     = "",
    duration  = 1.8,
  },
  neutral = {
    color     = Color3.fromRGB(160, 170, 188),   -- muted gray
    icon      = "",
    label     = "",
    duration  = 1.8,
  },
  danger = {
    color     = Color3.fromRGB(239, 68, 68),     -- red
    icon      = "⚠",
    label     = "ERROR",
    duration  = 5.5,
  },
}

Toast._parent = nil
Toast._container = nil
Toast._active = {}

function Toast.setParent(screengui)
  Toast._parent = screengui
  if Toast._container and Toast._container.Parent then
    Toast._container:Destroy()
  end
  Toast._container = Instance.new("Frame")
  Toast._container.Name = "ToastContainer"
  Toast._container.Parent = screengui
  Toast._container.BackgroundTransparency = 1
  Toast._container.Position = UDim2.new(0, 12, 0, 60 + 8)  -- below header
  Toast._container.Size = UDim2.new(0, 300, 1, -76)
  Toast._container.ZIndex = Theme.Z.Notifications
  Toast._container.BorderSizePixel = 0

  local layout = Instance.new("UIListLayout")
  layout.Parent = Toast._container
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Padding = UDim.new(0, 8)
  layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  layout.VerticalAlignment = Enum.VerticalAlignment.Top
end

local function buildToast(toastType, title, text)
  if not Toast._container then
    Logger.warn("Toast container not set — call Toast.setParent(screengui) first")
    return
  end
  local cfg = Toast.TYPES[toastType] or Toast.TYPES.neutral
  local duration = cfg.duration

  local card = Instance.new("Frame")
  card.Name = "Toast_" .. title
  card.Parent = Toast._container
  card.Size = UDim2.new(1, 0, 0, 56)
  card.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
  card.BackgroundTransparency = 1  -- starts invisible for slide-in
  card.BorderSizePixel = 0
  card.LayoutOrder = -math.floor(tick() * 1000)  -- newest first
  card.ZIndex = Theme.Z.Notifications + 1
  card.ClipsDescendants = true

  -- Corner radius (matches the rest of the UI)
  local cardCorner = Instance.new("UICorner")
  cardCorner.CornerRadius = UDim.new(0, 12)
  cardCorner.Parent = card

  -- 1pt accent border (left edge)
  local accent = Instance.new("Frame")
  accent.Name = "AccentEdge"
  accent.Parent = card
  accent.Size = UDim2.new(0, 4, 1, 0)
  accent.Position = UDim2.new(0, 0, 0, 0)
  accent.BackgroundColor3 = cfg.color
  accent.BorderSizePixel = 0
  accent.ZIndex = card.ZIndex + 1

  -- Glass border + background (matches the rest of the UI)
  local stroke = Instance.new("UIStroke")
  stroke.Color = Theme.Color.Border
  stroke.Transparency = Theme.Alpha.Border
  stroke.Thickness = 1
  stroke.Parent = card

  -- Icon
  local icon = Instance.new("TextLabel")
  icon.Name = "Icon"
  icon.Parent = card
  icon.Size = UDim2.new(0, 24, 0, 24)
  icon.Position = UDim2.new(0, 14, 0.5, -12)
  icon.BackgroundTransparency = 1
  icon.Font = Theme.Font.Icon
  icon.TextSize = 18
  icon.TextColor3 = cfg.color
  icon.Text = cfg.icon
  icon.TextXAlignment = Enum.TextXAlignment.Center
  icon.TextYAlignment = Enum.TextYAlignment.Center
  icon.ZIndex = card.ZIndex + 1

  -- Title
  local titleLbl = Instance.new("TextLabel")
  titleLbl.Name = "Title"
  titleLbl.Parent = card
  titleLbl.Size = UDim2.new(1, -100, 0, 18)
  titleLbl.Position = UDim2.new(0, 46, 0, 10)
  titleLbl.BackgroundTransparency = 1
  titleLbl.Font = Theme.Font.Heading
  titleLbl.TextSize = Theme.Size.Body
  titleLbl.TextColor3 = Theme.Color.TextPrimary
  titleLbl.TextXAlignment = Enum.TextXAlignment.Left
  titleLbl.TextYAlignment = Enum.TextYAlignment.Center
  titleLbl.Text = tostring(title or "")
  titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
  titleLbl.ZIndex = card.ZIndex + 1

  -- Type label (small, accent color, on the right)
  if cfg.label and cfg.label ~= "" then
    local typeLbl = Instance.new("TextLabel")
    typeLbl.Name = "TypeLabel"
    typeLbl.Parent = card
    typeLbl.Size = UDim2.new(0, 36, 0, 14)
    typeLbl.Position = UDim2.new(1, -44, 0, 12)
    typeLbl.BackgroundTransparency = 1
    typeLbl.Font = Theme.Font.Label
    typeLbl.TextSize = Theme.Size.Caption
    typeLbl.TextColor3 = cfg.color
    typeLbl.Text = cfg.label
    typeLbl.TextXAlignment = Enum.TextXAlignment.Right
    typeLbl.TextYAlignment = Enum.TextYAlignment.Center
    typeLbl.ZIndex = card.ZIndex + 1
  end

  -- Subtext
  if text and text ~= "" then
    local sub = Instance.new("TextLabel")
    sub.Name = "Sub"
    sub.Parent = card
    sub.Size = UDim2.new(1, -54, 0, 14)
    sub.Position = UDim2.new(0, 46, 0, 32)
    sub.BackgroundTransparency = 1
    sub.Font = Theme.Font.Body
    sub.TextSize = Theme.Size.Caption
    sub.TextColor3 = Theme.Color.TextSecondary
    sub.Text = tostring(text)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Center
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.ZIndex = card.ZIndex + 1
  end

  return card, duration, cfg
end

function Toast.show(toastType, title, text, opts)
  opts = opts or {}
  local card, duration, cfg = buildToast(toastType, title, text)
  if not card then return nil end

  -- Slide-in: BackgroundTransparency 1 → 0.10 (almost solid)
  -- Use a tween for that premium feel
  local targetTransp = opts.transparency or 0.10
  TweenService:Create(card,
    TweenInfo.new(0.28, Theme.Easing.Open, Enum.EasingDirection.Out),
    { BackgroundTransparency = targetTransp }
  ):Play()

  -- Animate the title/sub/label text in (opacity 0 → 1)
  for _, child in ipairs(card:GetChildren()) do
    if child:IsA("TextLabel") then
      child.TextTransparency = 1
      TweenService:Create(child,
        TweenInfo.new(0.22, Theme.Easing.Open, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
      ):Play()
    end
  end

  -- Auto-dismiss: fade out + collapse
  task.delay(duration, function()
    if not card or not card.Parent then return end
    -- Fade out
    TweenService:Create(card,
      TweenInfo.new(0.30, Theme.Easing.Open, Enum.EasingDirection.In),
      { BackgroundTransparency = 1 }
    ):Play()
    for _, child in ipairs(card:GetChildren()) do
      if child:IsA("TextLabel") then
        TweenService:Create(child,
          TweenInfo.new(0.25, Theme.Easing.Open, Enum.EasingDirection.In),
          { TextTransparency = 1 }
        ):Play()
      end
    end
    -- Destroy
    task.delay(0.32, function()
      if card and card.Parent then card:Destroy() end
    end)
  end)

  Logger.debug(string.format("Toast [%s] %s: %s", toastType, title, text or ""))
  return card
end

-- Convenience wrappers
function Toast.info(title, text, opts)    return Toast.show("info", title, text, opts) end
function Toast.success(title, text, opts) return Toast.show("success", title, text, opts) end
function Toast.accent(title, text, opts)  return Toast.show("accent", title, text, opts) end
function Toast.neutral(title, text, opts) return Toast.show("neutral", title, text, opts) end
function Toast.danger(title, text, opts)  return Toast.show("danger", title, text, opts) end

-- Clear all toasts (used on panic)
function Toast.clear()
  if Toast._container then
    for _, child in ipairs(Toast._container:GetChildren()) do
      if child:IsA("Frame") and child.Name:match("^Toast_") then
        TweenService:Create(child,
          TweenInfo.new(0.20, Theme.Easing.Open, Enum.EasingDirection.In),
          { BackgroundTransparency = 1 }
        ):Play()
        for _, c in ipairs(child:GetChildren()) do
          if c:IsA("TextLabel") then
            TweenService:Create(c,
              TweenInfo.new(0.15, Theme.Easing.Open, Enum.EasingDirection.In),
              { TextTransparency = 1 }
            ):Play()
          end
        end
        task.delay(0.22, function()
          if child and child.Parent then child:Destroy() end
        end)
      end
    end
  end
end

return Toast
