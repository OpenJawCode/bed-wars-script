-- src/features/aimbot.lua
-- Smooth camera lerp aimbot. From VapeV4 AimAssist pattern:
--   - Runs on Heartbeat with dt
--   - Uses entitylib.EntityPosition (nearest enemy in FOV)
--   - Lerp: camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, targetPos), speed * dt)
--   - FOV gate: angle between camera look and target < maxAngle/2
--   - Only active when a sword is held


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local GameWksp   = _BW.GameWksp
local Logger     = _BW.Logger
local PlaceId    = _BW.PlaceId

local Aimbot = {
  enabled     = false,
  smoothness  = 6,      -- lerp speed multiplier
  maxAngle    = 90,     -- FOV gate (degrees, full cone)
  _conn       = nil,
}

function Aimbot._onHeartbeat(dt)
  if not Aimbot.enabled then return end
  if not PlaceId.isMatch() then return end

  local camera = Services.camera()
  local localRoot = Services.rootPart()
  if not camera or not localRoot then return end

  -- Only aimbot when a tool is equipped (sword in hand)
  local char = Services.character()
  if not char then return end
  local hasTool = false
  for _, child in ipairs(char:GetChildren()) do
    if child:IsA("Tool") then hasTool = true; break end
  end
  if not hasTool then return end

  -- Find nearest enemy within a generous range (aimbot doesn't need the
  -- killaura range — we use 80 studs and rely on the FOV gate)
  local target = GameWksp.getNearestEnemy(80)
  if not target or not target.RootPart then return end

  -- FOV gate: angle between camera look (horizontal) and target direction
  local localFacing = localRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
  local delta = (target.RootPart.Position - localRoot.Position) * Vector3.new(1, 0, 1)
  if delta.Magnitude < 0.1 then return end
  local angle = math.acos(math.clamp(localFacing:Dot(delta.Unit), -1, 1))

  if angle > math.rad(Aimbot.maxAngle / 2) then return end

  -- Smooth lerp toward target
  local targetCF = CFrame.lookAt(camera.CFrame.Position, target.RootPart.Position)
  camera.CFrame = camera.CFrame:Lerp(targetCF, Aimbot.smoothness * dt)
end

function Aimbot.setEnabled(state)
  Aimbot.enabled = state
  if state and not Aimbot._conn then
    Aimbot._conn = RunService.Heartbeat:Connect(Logger.guard(Aimbot._onHeartbeat, "aimbot"))
  elseif not state and Aimbot._conn then
    Aimbot._conn:Disconnect()
    Aimbot._conn = nil
  end
  Logger.info("Aimbot " .. (state and "ON" or "OFF"))
end

function Aimbot.setSmoothness(value)
  Aimbot.smoothness = value
end

return Aimbot
