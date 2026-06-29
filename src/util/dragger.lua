-- src/util/dragger.lua
-- Makes any GuiObject draggable with both mouse AND touch.
-- Snap-to-edge on release (mobile UX). Bounds clamped to viewport.
-- WHY: Rayfield's drag handler is the cleanest pattern — UserInputService
-- InputBegan/Changed/Ended with relative offset. We add touch + snap.
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local Dragger = {}

-- Dragger:enable(frame, opts)
-- opts: { snapToEdge = true, snapPadding = 16, animate = true }
function Dragger.enable(frame, opts)
  opts = opts or {}
  local snapping = opts.snapToEdge ~= false
  local padding  = opts.snapPadding or 16
  local dragging = false
  local startInputPos = Vector2.new()
  local startFramePos = UDim2.new()
  local connections = {}

  local function getInputPos(input)
    return input.Position
  end

  local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      startInputPos = getInputPos(input)
      startFramePos = frame.Position
    end
  end

  local function onInputChanged(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
      local delta = input.Position - startInputPos
      frame.Position = UDim2.new(
        startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
        startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
      )
    end
  end

  local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging = false
      if not snapping then return end
      -- Snap to nearest horizontal edge.
      local viewport = workspace.CurrentCamera.ViewportSize
      local absPos = frame.AbsolutePosition
      local absSize = frame.AbsoluteSize
      local centerX = absPos.X + absSize.X / 2
      local targetX
      if centerX < viewport.X / 2 then
        targetX = padding
      else
        targetX = viewport.X - absSize.X - padding
      end
      -- Keep Y in bounds.
      local targetY = math.clamp(absPos.Y, padding, viewport.Y - absSize.Y - padding)
      if opts.animate ~= false then
        TweenService:Create(
          frame,
          TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
          { Position = UDim2.new(0, targetX, 0, targetY) }
        ):Play()
      else
        frame.Position = UDim2.new(0, targetX, 0, targetY)
      end
    end
  end

  table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
  table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
  table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))

  -- Return a cleanup function so callers can destroy connections on teardown.
  return function()
    for _, c in ipairs(connections) do c:Disconnect() end
  end
end

return Dragger
