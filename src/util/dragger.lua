-- src/util/dragger.lua
-- Makes any GuiObject draggable with both mouse AND touch.
-- FIXED: drag only triggers AFTER 8pt of movement (iOS HIG threshold).
--   v1 set `dragging = true` on InputBegan, so any tap on the FAB moved it.
--   v1.1 requires 8pt of movement before drag activates.
-- Snap-to-edge on release (mobile UX). Bounds clamped to viewport.
-- New: `dragZone` option (only top Npt of frame accepts drag).
-- New: `onDragStart` / `onDragEnd` callbacks.

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local DRAG_THRESHOLD = 8  -- pt

local Dragger = {}

-- Dragger:enable(frame, opts)
function Dragger.enable(frame, opts)
  opts = opts or {}
  local snapping      = opts.snapToEdge ~= false
  local padding       = opts.snapPadding or 12
  local threshold     = opts.threshold or DRAG_THRESHOLD
  local dragZoneTop   = opts.dragZone and opts.dragZone.top
  local target        = opts.target or frame
  local onDragStart   = opts.onDragStart
  local onDragEnd     = opts.onDragEnd

  local tracking      = false
  local dragging      = false
  local startInputPos = Vector2.new()
  local startTargetPos= UDim2.new()
  local connections   = {}

  local function isInDragZone(input)
    if not dragZoneTop then return true end
    local absY = frame.AbsolutePosition.Y
    return (input.Position.Y - absY) <= dragZoneTop
  end

  local function onInputBegan(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
      return
    end
    if not isInDragZone(input) then return end
    tracking = true
    dragging = false
    startInputPos  = input.Position
    startTargetPos = target.Position
  end

  local function onInputChanged(input)
    if not tracking then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then
      return
    end
    local delta = input.Position - startInputPos
    if not dragging then
      if delta.Magnitude < threshold then return end
      dragging = true
      if onDragStart then onDragStart() end
    end
    target.Position = UDim2.new(
      startTargetPos.X.Scale, startTargetPos.X.Offset + delta.X,
      startTargetPos.Y.Scale, startTargetPos.Y.Offset + delta.Y
    )
  end

  local function onInputEnded(input)
    if not tracking then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
      return
    end
    local wasDragging = dragging
    tracking = false
    dragging = false
    if wasDragging and onDragEnd then onDragEnd() end
    if not snapping then return end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    local absPos = target.AbsolutePosition
    local absSize = target.AbsoluteSize
    local centerX = absPos.X + absSize.X / 2
    local targetX
    if centerX < viewport.X / 2 then
      targetX = padding
    else
      targetX = viewport.X - absSize.X - padding
    end
    local targetY = math.clamp(absPos.Y, padding, viewport.Y - absSize.Y - padding)
    TweenService:Create(
      target,
      TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
      { Position = UDim2.new(0, targetX, 0, targetY) }
    ):Play()
  end

  table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
  table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
  table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))

  return function()
    for _, c in ipairs(connections) do c:Disconnect() end
  end
end

return Dragger
