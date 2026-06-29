-- src/features/fly.lua
-- Noclip + velocity lift. The classic Bedwars fly pattern:
--   - Set Humanoid.PlatformStand = true (so gravity doesn't apply)
--   - Each frame, set RootPart.Velocity based on camera look direction
--   - Disable Collides on character parts (noclip through walls)
--   - W/S to go forward/backward along camera look, A/D strafe, Space/Shift up/down
--
-- Mobile: we use on-screen joystick buttons (added to the UI) — but for v1
-- we use the camera look direction + a single "ascend" toggle.


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local Logger     = _BW.Logger

local Fly = {
  enabled  = false,
  speed    = 50,
  _conn    = nil,
  _originalCollisions = {},
}

function Fly._onHeartbeat(dt)
  local char = Services.character()
  local root = Services.rootPart()
  local hum  = Services.humanoid()
  local camera = Services.camera()
  if not char or not root or not hum or not camera then return end

  -- PlatformStand disables normal gravity + walk
  hum.PlatformStand = true

  -- Compute desired velocity from camera look + inputs
  local look = camera.CFrame.LookVector
  local right = camera.CFrame.RightVector
  local up = Vector3.new(0, 1, 0)

  local UIS = game:GetService("UserInputService")
  local move = Vector3.new()

  -- Forward/back
  if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + look end
  if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - look end
  -- Strafe
  if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
  if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
  -- Up/down
  if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
  if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
    move = move - up
  end

  if move.Magnitude > 0 then
    move = move.Unit * Fly.speed
  end

  -- Apply velocity (Roblox will integrate this for us)
  root.AssemblyLinearVelocity = move

  -- Disable collisions on all character parts (noclip while flying)
  for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") and part.CanCollide then
      part.CanCollide = false
    end
  end
end

function Fly.setEnabled(state)
  Fly.enabled = state
  if state and not Fly._conn then
    -- Save original collision state
    local char = Services.character()
    if char then
      Fly._originalCollisions = {}
      for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
          Fly._originalCollisions[part] = part.CanCollide
        end
      end
    end
    Fly._conn = RunService.Heartbeat:Connect(Logger.guard(Fly._onHeartbeat, "fly"))
  elseif not state then
    if Fly._conn then
      Fly._conn:Disconnect()
      Fly._conn = nil
    end
    -- Restore
    local hum = Services.humanoid()
    if hum then hum.PlatformStand = false end
    local char = Services.character()
    if char then
      for part, wasCollide in pairs(Fly._originalCollisions) do
        if part and part.Parent then
          part.CanCollide = wasCollide
        end
      end
    end
    Fly._originalCollisions = {}
  end
  Logger.info("Fly " .. (state and "ON" or "OFF"))
end

function Fly.setSpeed(value)
  Fly.speed = value
end

-- Re-apply on character respawn
function Fly.onCharacterAdded()
  if Fly.enabled then
    -- Re-save original collisions for the new character
    local char = Services.character()
    if char then
      Fly._originalCollisions = {}
      for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
          Fly._originalCollisions[part] = part.CanCollide
        end
      end
    end
  end
end

return Fly
