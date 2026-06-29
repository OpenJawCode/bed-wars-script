-- src/ui/animations.lua
-- Micro-interactions built on top of util/tween.lua + theme.lua.
-- WHY: every component (button, toggle, slider) needs consistent press/hover/
-- reveal feedback. Web dev mental model: this is our framer-motion variants.

local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.theme)
local Tween = require(script.Parent.Parent.util.tween)

local Anim = {}

-- Press-down scale (button feels pushed in). Pair with :release().
-- usage: Anim.press(button); ... later ... Anim.release(button)
function Anim.press(guiObject)
  TweenService:Create(
    guiObject,
    TweenInfo.new(Theme.Motion.Press, Theme.Easing.Press, Enum.EasingDirection.Out),
    { Size = guiObject.Size - UDim2.new(0, 0, 0, 0) }  -- subtle: we tween a UIScale instead
  ):Play()
  -- Scale via UIScale for crisp press without layout reflow.
  local scale = guiObject:FindFirstChildOfClass("UIScale")
  if not scale then
    scale = Instance.new("UIScale")
    scale.Parent = guiObject
  end
  TweenService:Create(
    scale,
    TweenInfo.new(Theme.Motion.Press, Theme.Easing.Press, Enum.EasingDirection.Out),
    { Scale = 0.96 }
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

-- iOS-style toggle knob slide + color crossfade.
function Anim.toggle(switchTrack, knob, isOn, theme)
  local knobPos = isOn and UDim2.new(1, -knob.AbsoluteSize.X - 4, 0.5, -knob.AbsoluteSize.Y/2)
                       or UDim2.new(0, 4, 0.5, -knob.AbsoluteSize.Y/2)
  TweenService:Create(knob,
    TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
    { Position = knobPos, BackgroundColor3 = isOn and Theme.Color.Accent or Theme.Color.TextMuted }
  ):Play()
  TweenService:Create(switchTrack,
    TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
    { BackgroundColor3 = isOn and Color3.fromRGB(16, 185, 129) or Theme.Color.SurfaceInset }
  ):Play()
end

-- Slider progress fill tween.
function Anim.slider(progressBar, ratio)
  TweenService:Create(progressBar,
    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }
  ):Play()
end

-- Hover lift (desktop only — mobile has no hover).
function Anim.hover(guiObject, isHovering)
  if game:GetService("UserInputService").TouchEnabled then return end
  TweenService:Create(guiObject,
    TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    { BackgroundColor3 = isHovering and Theme.Color.SurfaceRaised or Theme.Color.Surface }
  ):Play()
end

-- Staggered fade-in for a list of frames (children of a container).
function Anim.staggerReveal(frames, stagger)
  stagger = stagger or 0.04
  for i, frame in ipairs(frames) do
    frame.BackgroundTransparency = 1
    for _, child in ipairs(frame:GetChildren()) do
      if child:IsA("TextLabel") or child:IsA("TextButton") then
        child.TextTransparency = 1
      elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
        child.ImageTransparency = 1
      end
    end
    task.delay((i - 1) * stagger, function()
      TweenService:Create(frame,
        TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
        { BackgroundTransparency = Theme.Alpha.GlassCard }
      ):Play()
      for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
          TweenService:Create(child,
            TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { TextTransparency = 0 }
          ):Play()
        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
          TweenService:Create(child,
            TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
            { ImageTransparency = 0 }
          ):Play()
        end
      end
    end)
  end
end

-- Glow pulse for accent buttons (subtle "look at me" effect).
function Anim.glow(guiObject, color)
  local stroke = guiObject:FindFirstChildOfClass("UIStroke")
  if not stroke then
    stroke = Instance.new("UIStroke")
    stroke.Parent = guiObject
  end
  stroke.Color = color or Theme.Color.Accent
  stroke.Transparency = 0.6
  stroke.Thickness = 1
  TweenService:Create(stroke,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    { Transparency = 0 }
  ):Play()
  TweenService:Create(stroke,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    { Transparency = 0.6 }
  ):Play()
end

return Anim
