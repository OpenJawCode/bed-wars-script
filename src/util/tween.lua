-- src/util/tween.lua
-- Thin wrapper around TweenService with sane defaults for micro-interactions.
-- WHY: every UI animation in the script goes through here so we have ONE place
-- to tune easing/duration. Web dev mental model: this is our gsap.to().
local TweenService = game:GetService("TweenService")

local Tween = {}

-- Spring-ish easing. Cubic/Quint/Exponential feel close to CSS spring physics.
Tween.Easing = {
  Snappy   = Enum.EasingStyle.Quint;
  Smooth   = Enum.EasingStyle.Quad;
  Bouncy   = Enum.EasingStyle.Back;
  Soft     = Enum.EasingStyle.Sine;
}

-- Common durations (seconds). Tuned for mobile feel.
Tween.Duration = {
  Micro    = 0.12;   -- press feedback
  Fast     = 0.20;   -- toggle knob, hover
  Default  = 0.32;   -- panel open, section reveal
  Slow     = 0.55;   -- window boot
}

-- Tween a single property of an Instance.
-- usage: Tween:to(frame, {Position = UDim2.new(...)}, {easing = Tween.Easing.Snappy})
function Tween.to(instance, props, opts)
  opts = opts or {}
  local duration = opts.duration or Tween.Duration.Default
  local easing   = opts.easing   or Tween.Easing.Smooth
  local direction = opts.direction or Enum.EasingDirection.Out
  local info = TweenInfo.new(duration, easing, direction)
  local t = TweenService:Create(instance, info, props)
  t:Play()
  return t
end

-- Tween multiple instances with the same props (staggered reveal).
-- usage: Tween:stagger(frames, {BackgroundTransparency = 0}, {stagger = 0.05})
function Tween.stagger(instances, props, opts)
  opts = opts or {}
  local stagger = opts.stagger or 0.05
  local tweens = {}
  for i, inst in ipairs(instances) do
    local copy = table.clone(opts)
    copy.duration = (opts.duration or Tween.Duration.Default) + (i - 1) * 0
    task.delay((i - 1) * stagger, function()
      table.insert(tweens, Tween.to(inst, props, copy))
    end)
  end
  return tweens
end

return Tween
