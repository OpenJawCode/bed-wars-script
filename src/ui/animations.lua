-- src/ui/animations.lua
-- Micro-interactions built on top of util/tween.lua + theme.lua.
-- All easing standardized on Quint (matches cubic-bezier(0.16, 1, 0.3, 1)).
-- Web dev mental model: this is our framer-motion variants.

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.theme)

local Anim = {}

-- ─── Press feedback (scale-on-press) ──────────────────────────────────────
-- Targets a UIScale child of the guiObject (so we don't tween Size which
-- causes layout reflow). Adds UIScale if missing.
function Anim.press(guiObject, opts)
  opts = opts or {}
  local scale = guiObject:FindFirstChildOfClass("UIScale")
  if not scale then
    scale = Instance.new("UIScale")
    scale.Parent = guiObject
  end
  TweenService:Create(
    scale,
    TweenInfo.new(Theme.Motion.Press, Theme.Easing.Press, Enum.EasingDirection.Out),
    { Scale = opts.scale or 0.96 }
  ):Play()
end

function Anim.release(guiObject)
  local scale = guiObject:FindFirstChildOfClass("UIScale")
  if not scale then
    scale = Instance.new("UIScale")
    scale.Parent = guiObject
  end
  TweenService:Create(
    scale,
    TweenInfo.new(Theme.Motion.Press + 0.05, Theme.Easing.Press, Enum.EasingDirection.Out),
    { Scale = 1 }
  ):Play()
end

-- ─── iOS-style toggle (WHITE knob on ACCENT track) ───────────────────────
function Anim.toggle(switchTrack, knob, isOn, color)
  color = color or Theme.Color.Accent
  local trackW = switchTrack.AbsoluteSize.X
  local knobW = knob.AbsoluteSize.X
  local targetX = isOn and (trackW - knobW - 3) or 3
  local trackColor = isOn and Color3.fromRGB(16, 185, 129) or Theme.Color.SurfaceInset
  -- iOS pattern: WHITE knob on ACCENT track
  local knobColor = isOn and Color3.fromRGB(255, 255, 255) or Theme.Color.TextMuted
  TweenService:Create(knob,
    TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
    { Position = UDim2.new(0, targetX, 0.5, -knobW / 2), BackgroundColor3 = knobColor }
  ):Play()
  TweenService:Create(switchTrack,
    TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
    { BackgroundColor3 = trackColor }
  ):Play()
end

-- ─── Slider progress fill ─────────────────────────────────────────────────
function Anim.slider(progressBar, ratio)
  TweenService:Create(progressBar,
    TweenInfo.new(0.12, Theme.Easing.Tap, Enum.EasingDirection.Out),
    { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }
  ):Play()
end

-- ─── Hover (desktop only) ─────────────────────────────────────────────────
function Anim.hover(guiObject, isHovering)
  if game:GetService("UserInputService").TouchEnabled then return end
  TweenService:Create(guiObject,
    TweenInfo.new(Theme.Motion.Hover, Theme.Easing.Hover, Enum.EasingDirection.Out),
    { BackgroundTransparency = isHovering and Theme.Alpha.GlassCardHover or Theme.Alpha.GlassCard }
  ):Play()
end

-- ─── Tab switch ───────────────────────────────────────────────────────────
function Anim.tabSwitch(fromTab, toTab)
  -- Visual audit: label was TabActive (emerald) on tap — created triple-green.
  -- Now: icon ACCENT, label WHITE (TextPrimary), indicator ACCENT.
  if fromTab and fromTab.indicator then
    TweenService:Create(fromTab.indicator,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { BackgroundTransparency = 1 }
    ):Play()
  end
  if fromTab and fromTab.icon then
    TweenService:Create(fromTab.icon,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { TextColor3 = Theme.Color.TabInactive }
    ):Play()
  end
  if fromTab and fromTab.label then
    TweenService:Create(fromTab.label,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { TextColor3 = Theme.Color.TabInactive }
    ):Play()
  end
  if toTab and toTab.indicator then
    TweenService:Create(toTab.indicator,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { BackgroundTransparency = Theme.Alpha.BorderAccent }
    ):Play()
  end
  if toTab and toTab.icon then
    TweenService:Create(toTab.icon,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { TextColor3 = Theme.Color.TabActive }
    ):Play()
  end
  if toTab and toTab.label then
    TweenService:Create(toTab.label,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { TextColor3 = Theme.Color.TextPrimary }
    ):Play()
  end
end

-- ─── Pulse glow (for FAB + active tab indicator) ─────────────────────────
-- Looping expanding shadow pulse. Sine easing for smooth ambient feel.
function Anim.pulseGlow(uiObject, period, color)
  color = color or Theme.Color.Accent
  period = period or Theme.Motion.Glow

  if not uiObject:IsA("UIStroke") then
    local glow = uiObject:FindFirstChild("GlowStroke")
    if not glow then
      glow = Instance.new("UIStroke")
      glow.Name = "GlowStroke"
      glow.Parent = uiObject
    end
    uiObject = glow
  end

  local function pulse()
    TweenService:Create(uiObject,
      TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.In),
      { Color = color, Transparency = Theme.Alpha.AccentGlowInner }
    ):Play()
    task.delay(period / 2, function()
      TweenService:Create(uiObject,
        TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.Out),
        { Color = color, Transparency = Theme.Alpha.AccentGlowOuter }
      ):Play()
      if uiObject and uiObject.Parent then
        task.delay(period / 2, pulse)
      end
    end)
  end
  pulse()
end

-- ─── Staggered row reveal ─────────────────────────────────────────────────
function Anim.staggerReveal(rows, stagger)
  stagger = stagger or 0.04
  for i, row in ipairs(rows) do
    if row and row.Parent then
      row.BackgroundTransparency = 1
      for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
          child.TextTransparency = 1
        end
      end
      task.delay((i - 1) * stagger, function()
        if not row.Parent then return end
        TweenService:Create(row,
          TweenInfo.new(0.35, Theme.Easing.Open, Enum.EasingDirection.Out),
          { BackgroundTransparency = Theme.Alpha.GlassCard }
        ):Play()
        for _, child in ipairs(row:GetChildren()) do
          if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child,
              TweenInfo.new(0.35, Theme.Easing.Open, Enum.EasingDirection.Out),
              { TextTransparency = 0 }
            ):Play()
          end
        end
      end)
    end
  end
end

-- ─── popIn (v1.3) — scale 0 → 1 with overshoot ────────────────────────────
-- Used by the FAB on first appear. Uses Back easing for the overshoot.
-- opts: { duration = 0.42, scale = 1 } — final scale (default 1)
function Anim.popIn(guiObject, opts)
  opts = opts or {}
  local duration = opts.duration or 0.42
  local targetScale = opts.scale or 1
  -- Capture original size
  local originalSize = guiObject.Size
  -- Start at 0
  guiObject.Size = UDim2.fromOffset(originalSize.X.Offset * 0, originalSize.Y.Offset * 0)
  TweenService:Create(guiObject,
    TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Size = originalSize }
  ):Play()
end

-- ─── pulseBloom (v1.3) — pulse inner + outer UIStroke for the "bloom" effect ─
-- Used by the FAB. The inner stroke pulses fast, the outer slow (offset).
function Anim.pulseBloom(innerStroke, outerStroke, color, period)
  period = period or 1.8
  color = color or Theme.Color.Accent
  local function pulseInner()
    if not innerStroke or not innerStroke.Parent then return end
    TweenService:Create(innerStroke,
      TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.In),
      { Color = color, Transparency = 0.20 }
    ):Play()
    task.delay(period / 2, function()
      if not innerStroke or not innerStroke.Parent then return end
      TweenService:Create(innerStroke,
        TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.Out),
        { Color = color, Transparency = 0.55 }
      ):Play()
      if innerStroke and innerStroke.Parent then
        task.delay(period / 2, pulseInner)
      end
    end)
  end
  local function pulseOuter()
    if not outerStroke or not outerStroke.Parent then return end
    -- Offset by half a period for depth effect
    task.delay(period * 0.4, function()
      while outerStroke and outerStroke.Parent do
        TweenService:Create(outerStroke,
          TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.In),
          { Color = color, Transparency = 0.65 }
        ):Play()
        task.wait(period / 2)
        if not outerStroke or not outerStroke.Parent then return end
        TweenService:Create(outerStroke,
          TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.Out),
          { Color = color, Transparency = 0.90 }
        ):Play()
        task.wait(period / 2)
      end
    end)
  end
  pulseInner()
  pulseOuter()
end

return Anim
