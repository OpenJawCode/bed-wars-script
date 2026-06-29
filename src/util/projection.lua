-- src/util/projection.lua
-- World -> screen projection helpers.
-- WHY: ESP features need to convert 3D world positions to 2D screen pixels.
-- Roblox gives us Camera:WorldToViewportPoint which returns (Vector3, bool isInFront).
local Workspace = game:GetService("Workspace")

local Projection = {}

-- Project a Vector3 world position to Vector2 screen position.
-- Returns (Vector2, isVisible) — isVisible is false if the point is behind the camera.
function Projection.worldToScreen(worldPos)
  local camera = Workspace.CurrentCamera
  if not camera then return Vector2.new(0, 0), false end
  local screen, visible = camera:WorldToViewportPoint(worldPos)
  return Vector2.new(screen.X, screen.Y), visible
end

-- Project the top + bottom of an entity box (used for 2D box ESP).
-- Returns (topVec2, bottomVec2, isVisible).
-- WHY this pattern: Vape uses it — box height derived from HipHeight projected at
-- a CFrame offset from the root along the camera's look vector.
function Projection.entityBox(rootPos, hipHeight, camera)
  camera = camera or Workspace.CurrentCamera
  if not camera then return Vector2.new(0,0), Vector2.new(0,0), false end
  local look = camera.CFrame.LookVector
  local topCF    = CFrame.lookAlong(rootPos, look) * CFrame.new(2, hipHeight, 0)
  local bottomCF = CFrame.lookAlong(rootPos, look) * CFrame.new(-2, -hipHeight - 1, 0)
  local topScreen, topVis = camera:WorldToViewportPoint(topCF.Position)
  local botScreen, botVis = camera:WorldToViewportPoint(bottomCF.Position)
  local visible = topVis and botVis
  return Vector2.new(topScreen.X, topScreen.Y),
         Vector2.new(botScreen.X, botScreen.Y),
         visible
end

-- Distance in studs between two Vector3 positions.
function Projection.distance(a, b)
  return (a - b).Magnitude
end

return Projection
