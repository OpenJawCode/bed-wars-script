-- src/ui/toast.lua
-- Premium toast notification system — v1.4.1 redesign.
--
-- Design language: "Liquid glass neon" — matte frosted glass card with
-- a chromatic halo glow behind it. NO border (replaced by the glow).
-- Inspired by iOS 26 / macOS Sequoia 2025 notification cards, but with
-- a cyberpunk neon edge.
--
-- 5 semantic types: info, success, accent, neutral, danger.
-- Each has a different glow color (cyan/emerald/gold/gray/red).
--
-- Usage:
--   local Toast = require("ui/toast")
--   Toast.success("Killaura", "Enabled — 28 studs")
--   Toast.danger("Boot failed", "Knit bootstrap timeout")
--   Toast.setParent(screengui)  -- call once at boot
--
-- CRITICAL: v1.4.1 fixes B032 — toasts no longer start at transparency
-- 1. If the tween failed, toasts were invisible. Now toasts are ALWAYS
-- visible the moment they're created.

local _BW = (getgenv and getgenv()._BW) or _G._BW
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = _BW.Theme
local Logger = _BW.Logger

local Toast = {}

-- 5 semantic types — color drives the GLOW (not a border)
Toast.TYPES = {
  info = {
    color     = Color3.fromRGB(56, 189, 248),   -- sky/cyan
    icon      = "i",
    label     = "INFO",
    duration  = 2.6,
  },
  success = {
    color     = Color3.fromRGB(16, 185, 129),   -- emerald
    icon      = "✓",
    label     = "ON",
    duration  = 1.8,
  },
  accent = {
    color     = Color3.fromRGB(245, 183, 0),    -- gold
    icon      = "✦",
    label     = "",
    duration  = 2.0,
  },
  neutral = {
    color     = Color3.fromRGB(148, 163, 184),  -- slate
    icon      = "·",
    label     = "",
    duration  = 1.8,
  },
  danger = {
    color     = Color3.fromRGB(239, 68, 68),    -- red
    icon      = "!",
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
  Toast._container.AnchorPoint = Vector2.new(1, 0)
  Toast._container.Position = UDim2.new(1, -12, 0, 56)  -- top-right, below header
  Toast._container.Size = UDim2.new(0, 304, 1, -68)
  Toast._container.ZIndex = Theme.Z.Notifications + 10
  Toast._container.BorderSizePixel = 0

  local layout = Instance.new("UIListLayout")
  layout.Parent = Toast._container
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Padding = UDim.new(0, 8)
  layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
  layout.VerticalAlignment = Enum.VerticalAlignment.Top
end

-- Build a single toast card. Returns the card frame.
-- B032 fix: card is FULLY VISIBLE from creation. The slide-in animation
-- is a bonus — if it fails, the card is still visible.
local function buildToast(toastType, title, text)
  if not Toast._container then
    Logger.warn("Toast container not set — call Toast.setParent(screengui) first")
    return nil
  end
  local cfg = Toast.TYPES[toastType] or Toast.TYPES.neutral
  local accent = cfg.color

  -- ─── Glow frame (BEHIND the card, creates neon halo) ──────────
  -- Larger than the card, accent color, very transparent.
  local glow = Instance.new("Frame")
  glow.Name = "Glow"
  glow.Parent = Toast._container
  glow.Size = UDim2.new(1, 12, 0, 64)
  glow.Position = UDim2.new(0, -6, 0, -4)
  glow.BackgroundColor3 = accent
  glow.BackgroundTransparency = 0.88  -- very transparent (soft halo)
  glow.BorderSizePixel = 0
  glow.ZIndex = Theme.Z.Notifications
  glow.LayoutOrder = -math.floor(tick() * 1000)
  local glowCorner = Instance.new("UICorner")
  glowCorner.CornerRadius = UDim.new(0, 18)
  glowCorner.Parent = glow

  -- ─── Card (matte frosted glass) ──────────────────────────────────
  local card = Instance.new("Frame")
  card.Name = "Toast_" .. (title or "untitled")
  card.Parent = glow
  card.Size = UDim2.new(1, 0, 0, 56)
  card.BackgroundColor3 = Color3.fromRGB(11, 15, 24)  -- deeper than Theme.Color.Surface for matte
  card.BackgroundTransparency = 0.08  -- MATTE — mostly opaque, not glossy
  card.BorderSizePixel = 0
  card.LayoutOrder = -math.floor(tick() * 1000)
  card.ZIndex = Theme.Z.Notifications + 2
  card.ClipsDescendants = true
  local cardCorner = Instance.new("UICorner")
  cardCorner.CornerRadius = UDim.new(0, 14)
  cardCorner.Parent = card

  -- Top highlight line (white, 1pt, very transparent) — liquid glass
  -- edge effect, no border. Just the top 1pt.
  local topLine = Instance.new("Frame")
  topLine.Parent = card
  topLine.Size = UDim2.new(1, -16, 0, 1)
  topLine.Position = UDim2.new(0, 8, 0, 0)
  topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  topLine.BackgroundTransparency = 0.78
  topLine.BorderSizePixel = 0
  topLine.ZIndex = card.ZIndex + 2

  -- ─── Chromatic gradient overlay (refraction feel) ─────────────
  -- Subtle multi-color sweep on the card. Very low alpha so it doesn't
  -- make the card look glossy.
  local chromatic = Instance.new("UIGradient")
  chromatic.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.3, accent),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
  })
  chromatic.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.97),
    NumberSequenceKeypoint.new(0.5, 0.92),
    NumberSequenceKeypoint.new(1,   0.97),
  })
  chromatic.Rotation = 35
  chromatic.Parent = card

  -- ─── Icon disk (left) — circular, accent color, no border ─────
  local iconBg = Instance.new("Frame")
  iconBg.Parent = card
  iconBg.Size = UDim2.fromOffset(32, 32)
  iconBg.Position = UDim2.new(0, 12, 0.5, -16)
  iconBg.BackgroundColor3 = accent
  iconBg.BackgroundTransparency = 0.20
  iconBg.BorderSizePixel = 0
  iconBg.ZIndex = card.ZIndex + 3
  local iconBgCorner = Instance.new("UICorner")
  iconBgCorner.CornerRadius = UDim.new(1, 0)  -- circle
  iconBgCorner.Parent = iconBg

  -- Chromatic gradient on the icon disk
  local iconGrad = Instance.new("UIGradient")
  iconGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, accent),
  })
  iconGrad.Rotation = 145
  iconGrad.Parent = iconBg

  local icon = Instance.new("TextLabel")
  icon.Parent = iconBg
  icon.Size = UDim2.new(1, 0, 1, 0)
  icon.BackgroundTransparency = 1
  icon.Font = Theme.Font.Heading
  icon.TextSize = 16
  icon.TextColor3 = Color3.fromRGB(11, 15, 24)  -- dark on accent
  icon.Text = cfg.icon
  icon.TextXAlignment = Enum.TextXAlignment.Center
  icon.TextYAlignment = Enum.TextYAlignment.Center
  icon.ZIndex = card.ZIndex + 4

  -- ─── Title (right of icon) ─────────────────────────────────────
  local titleLbl = Instance.new("TextLabel")
  titleLbl.Parent = card
  titleLbl.Size = UDim2.new(1, -116, 0, 20)
  titleLbl.Position = UDim2.new(0, 56, 0, 10)
  titleLbl.BackgroundTransparency = 1
  titleLbl.Font = Theme.Font.Heading
  titleLbl.TextSize = 14
  titleLbl.TextColor3 = Color3.fromRGB(240, 242, 248)  -- near-white, no pure #FFF
  titleLbl.TextXAlignment = Enum.TextXAlignment.Left
  titleLbl.TextYAlignment = Enum.TextYAlignment.Center
  titleLbl.Text = tostring(title or "")
  titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
  titleLbl.ZIndex = card.ZIndex + 3

  -- ─── Subtext (below title) ────────────────────────────────────
  if text and text ~= "" then
    local sub = Instance.new("TextLabel")
    sub.Parent = card
    sub.Size = UDim2.new(1, -68, 0, 14)
    sub.Position = UDim2.new(0, 56, 0, 30)
    sub.BackgroundTransparency = 1
    sub.Font = Theme.Font.Body
    sub.TextSize = 11
    sub.TextColor3 = Color3.fromRGB(148, 163, 184)  -- slate
    sub.Text = tostring(text)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Center
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.ZIndex = card.ZIndex + 3
  end

  -- ─── Close "×" (top-right, only for danger/error) ─────────────
  if toastType == "danger" then
    local close = Instance.new("TextButton")
    close.Parent = card
    close.Size = UDim2.fromOffset(20, 20)
    close.Position = UDim2.new(1, -28, 0, 6)
    close.BackgroundTransparency = 1
    close.Font = Theme.Font.Icon
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(148, 163, 184)
    close.Text = "×"
    close.ZIndex = card.ZIndex + 4
    close.Text = "×"
    close.AutoButtonColor = false
    close.TextXAlignment = Enum.TextXAlignment.Center
    close.TextYAlignment = Enum.TextYAlignment.Center
  end

  -- ─── Progress bar (bottom, accent color) ──────────────────────
  -- Animated tween that shrinks width over `duration`. Shows how
  -- much time the notification has left. Distinguishes from generic
  -- Material toasts.
  local progress = Instance.new("Frame")
  progress.Parent = card
  progress.Size = UDim2.new(1, 0, 0, 1.5)
  progress.Position = UDim2.new(0, 0, 1, -1.5)
  progress.BackgroundColor3 = accent
  progress.BackgroundTransparency = 0.30
  progress.BorderSizePixel = 0
  progress.ZIndex = card.ZIndex + 3

  return glow, card, progress, cfg
end

function Toast.show(toastType, title, text, opts)
  opts = opts or {}
  local glow, card, progress, cfg = buildToast(toastType, title, text)
  if not card then return nil end

  local duration = opts.duration or cfg.duration

  -- v1.4.1: CARD IS ALREADY VISIBLE. No "start invisible + tween in"
  -- pattern. Slide-in is a BONUS — if it fails, card stays visible.
  pcall(function()
    glow.Position = UDim2.new(0, 22, 0, -4)  -- start 28pt to the right
    TweenService:Create(glow, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
      { Position = UDim2.new(0, -6, 0, -4) }):Play()
  end)

  -- Pulse the glow (slow breathing) — gives the "neon" feel
  pcall(function()
    local pulse = TweenService:Create(glow,
      TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
      { BackgroundTransparency = 0.78 }
    )
    pulse:Play()
    -- Store for cancellation on dismiss
    glow:SetAttribute("_pulse", pulse)
  end)

  -- Progress bar shrink
  pcall(function()
    TweenService:Create(progress,
      TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
      { Size = UDim2.new(0, 0, 0, 1.5) }
    ):Play()
  end)

  -- Auto-dismiss
  task.delay(duration, function()
    if not card or not card.Parent then return end
    pcall(function()
      -- Cancel glow pulse
      local pulse = glow:GetAttribute("_pulse")
      if pulse then pcall(function() pulse:Cancel() end) end
      -- Fade out + slide right
      TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }):Play()
      TweenService:Create(glow, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0, -4) }):Play()
      -- Animate top line + chromatic + icon
      for _, child in ipairs(card:GetChildren()) do
        if child:IsA("TextLabel") then
          TweenService:Create(child, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { TextTransparency = 1 }):Play()
        end
      end
    end)
    task.delay(0.28, function()
      if glow and glow.Parent then glow:Destroy() end
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

-- When the menu window opens, move toasts to bottom-right so they
-- don't overlap the full-width window.
function Toast.setWindowOpen(isOpen)
  if not Toast._container then return end
  if isOpen then
    -- Window is open, move toasts to bottom-right
    Toast._container.AnchorPoint = Vector2.new(1, 1)
    Toast._container.Position = UDim2.new(1, -12, 1, -56)
  else
    -- Window is closed, toasts go top-right
    Toast._container.AnchorPoint = Vector2.new(1, 0)
    Toast._container.Position = UDim2.new(1, -12, 0, 56)
  end
end

function Toast.clear()
  if Toast._container then
    for _, child in ipairs(Toast._container:GetChildren()) do
      if child:IsA("Frame") and (child.Name == "Glow" or child.Name:match("^Toast_")) then
        pcall(function()
          local pulse = child:GetAttribute("_pulse")
          if pulse then pcall(function() pulse:Cancel() end) end
          TweenService:Create(child, TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }):Play()
        end)
        task.delay(0.22, function()
          if child and child.Parent then child:Destroy() end
        end)
      end
    end
  end
end

return Toast
