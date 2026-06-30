-- src/ui/rotation.lua
-- Listen to viewport size changes (phone rotation) and re-clamp the window.
-- Also listen to the GuiService inset for safe-area changes.
--
-- The window is scale-anchored to the viewport, so rotation should
-- "just work" — but we need to rebuild the window's UDim2 from the
-- new viewport dimensions on every change. This module re-fires
-- the Library's "onViewportChanged" hook so the window re-clamps.

local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService  = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local GuiService   = game:GetService("GuiService")

local Theme = _BW.Theme
local Logger = _BW.Logger

local Rotation = {}

Rotation._conn = nil
Rotation._guiInsetConn = nil
Rotation._onChange = nil
Rotation._lastSize = nil

function Rotation.start(onChange)
  Rotation._onChange = onChange
  Rotation._lastSize = Vector2.new(Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.X or 393,
                                  Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or 852)
  -- Listen to viewport size changes (phone rotation)
  if Rotation._conn then
    pcall(function() Rotation._conn:Disconnect() end)
  end
  local ok_cam, cam = pcall(function() return Workspace.CurrentCamera end)
  if ok_cam and cam then
    Rotation._conn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
      local c = Workspace.CurrentCamera
      if not c then return end
      local newSize = Vector2.new(c.ViewportSize.X, c.ViewportSize.Y)
      if Rotation._lastSize and
         math.abs(newSize.X - Rotation._lastSize.X) < 1 and
         math.abs(newSize.Y - Rotation._lastSize.Y) < 1 then
        return  -- no real change
      end
      Rotation._lastSize = newSize
      Logger.info("Viewport changed: " .. tostring(newSize))
      if Rotation._onChange then
        pcall(Rotation._onChange, newSize)
      end
    end)
  end

  -- v1.5.2: B042 — REMOVED the broken GuiService:GetPropertyChangedSignal("GuiInset")
  -- listener. GuiInset is a METHOD (GuiService:GetGuiInset()), not a property,
  -- so GetPropertyChangedSignal("GuiInset") throws "GuiInset is not a valid
  -- property name." and halts the entire boot.
  --
  -- The ViewportSize listener above is sufficient for rotation handling.
  -- Notch / cutout / safe-area changes are rare and the ViewportSize
  -- signal will fire on any meaningful geometry change anyway.

  Logger.info("Rotation listener started")
end

function Rotation.stop()
  if Rotation._conn then
    pcall(function() Rotation._conn:Disconnect() end)
    Rotation._conn = nil
  end
  if Rotation._guiInsetConn then
    pcall(function() Rotation._guiInsetConn:Disconnect() end)
    Rotation._guiInsetConn = nil
  end
end

-- Helper: detect if viewport is landscape (wider than tall)
function Rotation.isLandscape(size)
  if not size then return false end
  return size.X > size.Y
end

-- Helper: compute the window dimensions for a given viewport size
function Rotation.computeWindowSize(size)
  if not size then
    size = Vector2.new(393, 852)
  end
  if Rotation.isLandscape(size) then
    -- Landscape: 80% wide, 92% tall (the menu is wider than tall)
    return {
      width  = math.floor(size.X * 0.80),
      height = math.floor(size.Y * 0.92),
      x      = math.floor((size.X - size.X * 0.80) / 2),
      y      = math.floor((size.Y - size.Y * 0.92) / 2),
    }
  else
    -- Portrait: 94% wide, 82% tall (current default)
    return {
      width  = math.floor(size.X * 0.94),
      height = math.floor(size.Y * 0.82),
      x      = math.floor((size.X - size.X * 0.94) / 2),
      y      = math.floor((size.Y - size.Y * 0.82) / 2),
    }
  end
end

return Rotation
