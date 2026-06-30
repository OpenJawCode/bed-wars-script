-- src/util/dragger.lua
-- Makes any GuiObject draggable with both mouse AND touch.
-- v1.1: drag only triggers AFTER 8pt of movement (iOS HIG threshold).
--   v1 set `dragging = true` on InputBegan, so any tap on the FAB moved it.
--   v1.1 requires 8pt of movement before drag activates.
-- Snap-to-edge on release (mobile UX). Bounds clamped to viewport.
-- New in v2.0 (B047):
--   - `dragFrame` option: a separate frame (e.g. window header) whose
--     InputBegan triggers the drag. Lets the header be the drag handle
--     while the rest of the window is content.
--   - `clampToScreen`: keep the window within the viewport while dragging.

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local DRAG_THRESHOLD = 8  -- pt

local Dragger = {}

-- Dragger:enable(frame, opts)
-- opts:
--   dragFrame:     a separate frame whose InputBegan triggers the drag (e.g. window header)
--   dragZone:      { top = N } — only top Npt of the frame accepts drag
--   snapToEdge:    bool (default true)
--   snapPadding:   pt (default 12)
--   threshold:     pt (default 8)
--   target:        frame to actually move (default = frame)
--   clampToScreen: bool (default true)
--   onDragStart:   function() end
--   onDragEnd:     function() end
function Dragger.enable(frame, opts)
  opts = opts or {}
  local snapping      = opts.snapToEdge ~= false
  local padding       = opts.snapPadding or 12
  local threshold     = opts.threshold or DRAG_THRESHOLD
  local dragZoneTop   = opts.dragZone and opts.dragZone.top
  local dragFrame     = opts.dragFrame or frame
  local target        = opts.target or frame
  local clampToScreen = opts.clampToScreen ~= false
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
      if onDragStart then pcall(onDragStart) end
    end
    local newX = startTargetPos.X.Offset + delta.X
    local newY = startTargetPos.Y.Offset + delta.Y
    if clampToScreen then
      local camera = workspace.CurrentCamera
      if camera then
        local viewport = camera.ViewportSize
        local maxX = viewport.X - target.AbsoluteSize.X
        local maxY = viewport.Y - target.AbsoluteSize.Y
        newX = math.clamp(newX, -target.AbsoluteSize.X * 0.3, maxX)
        newY = math.clamp(newY, 0, maxY)
      end
    end
    target.Position = UDim2.new(
      startTargetPos.X.Scale, newX,
      startTargetPos.Y.Scale, newY
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
    if wasDragging and onDragEnd then pcall(onDragEnd) end
    if not snapping then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
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

  -- Always bind to UserInputService (so drag can continue even if
  -- the cursor leaves the dragFrame)
  table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
  table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
  table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))

  -- If a separate dragFrame is provided, also listen to it directly
  -- so touch-down on the header starts the drag (UserInputService may
  -- not fire on touch in some executors)
  if dragFrame and dragFrame ~= frame then
    table.insert(connections, dragFrame.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.Touch
      or input.UserInputType == Enum.UserInputType.MouseButton1 then
        onInputBegan(input)
      end
    end))
  end

  return function()
    for _, c in ipairs(connections) do c:Disconnect() end
  end
end

return Dragger
