-- src/features/fly.lua
-- Fly that survives Bedwars anti-cheat.
--
-- The problem: Easy.gg's SprintController.constantSpeedMultiplier clamps
-- horizontal velocity to 23 studs/s, AND the server validates position
-- via a GroundHit heartbeat. Naive fly gets snapped back to your original
-- position.
--
-- The solution (v1.3, from VapeV4 internals + anti-cheat research):
--   1. Fire InflateBalloon once (legitimate game feature, opens the clamp)
--   2. Set rootPart.AssemblyLinearVelocity in PreSimulation (before server
--      physics tick), clamped to ±23 horiz / ±6 vert
--   3. Fire GroundHit heartbeat at ~30 Hz with correct timestamps + ±5ms jitter
--   4. Set bedwars.StatefulEntityKnockbackController.lastImpulseTime to math.huge
--      (disables server knockback)
--
-- Stealth considerations:
--   - Never name anything "Vape" or reference Vape-specific remotes
--   - Heartbeat only runs when Fly is enabled (no background signature)
--   - ±5ms jitter on GroundHit prevents pattern detection
--   - Use legitimate game features (InflateBalloon) not exploits

local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")

local Services    = _BW.Services
local GameWksp    = _BW.GameWksp
local PlaceId     = _BW.PlaceId
local Logger      = _BW.Logger
-- v1.5: B034 — Anticheat from registry. The require() fallback
-- below was a landmine: in loadstring context `script` is nil and
-- `nil.Parent` throws. The single-file version has Anticheat set
-- by build_singlefile.py at the top of the bundle, so this just
-- reads from the registry.
local Anticheat   = _BW.Anticheat

local Fly = {
  enabled  = false,
  speed    = 50,
  _preSimConn = nil,
  _heartbeatConn = nil,
}

function Fly._onPreSimulation()
  if not Fly.enabled then return end
  local localRoot = Services.rootPart()
  if not localRoot then return end
  local hum = Services.humanoid()
  if not hum or hum.Health <= 0 then return end

  local cam = Workspace.CurrentCamera
  local dir = Vector3.zero

  -- WASD: forward/back/strafe (relative to camera)
  if UserInputService:IsKeyDown(Enum.KeyCode.W) then
    dir = dir + cam.CFrame.LookVector
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.S) then
    dir = dir - cam.CFrame.LookVector
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.A) then
    dir = dir - cam.CFrame.RightVector
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.D) then
    dir = dir + cam.CFrame.RightVector
  end
  -- Space/Shift: up/down
  if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
    dir = dir + Vector3.yaxis
  end
  if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
  or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
    dir = dir - Vector3.yaxis
  end

  -- Scale by fly speed (clamped to 23 horiz / 6 vert by Anticheat.setFlyVelocity)
  local speed = Fly.speed
  Anticheat.setFlyVelocity(localRoot, dir.Unit * speed, { minVert = -6, maxVert = 6 })

  -- Disable server knockback (cheap, do every frame)
  Anticheat.disableKnockback()
end

function Fly.setEnabled(state)
  Fly.enabled = state
  if state then
    -- 1. Open the velocity clamp via legitimate game feature
    Anticheat.fireInflateBalloon()

    -- 2. Start the GroundHit heartbeat (stealth mode, ±5ms jitter)
    local localRoot = Services.rootPart()
    if localRoot then
      Anticheat.startGroundHitHeartbeat(localRoot)
    end

    -- 3. Start the PreSimulation velocity setter
    if not Fly._preSimConn then
      Fly._preSimConn = RunService.PreSimulation:Connect(Fly._onPreSimulation)
    end

    Logger.info("Fly ENABLED (anti-cheat bypass active: InflateBalloon + GroundHit + PreSim)")
  else
    -- Stop everything
    if Fly._preSimConn then
      pcall(function() Fly._preSimConn:Disconnect() end)
      Fly._preSimConn = nil
    end
    Anticheat.stopGroundHitHeartbeat()
    -- Restore normal physics
    local localRoot = Services.rootPart()
    if localRoot and localRoot.Parent then
      localRoot.AssemblyLinearVelocity = Vector3.zero
    end
    Logger.info("Fly DISABLED (anti-cheat heartbeat stopped)")
  end
end

function Fly.setSpeed(value)
  Fly.speed = value
end

function Fly.onCharacterAdded()
  -- If a character respawns while fly is on, restart the heartbeat
  if Fly.enabled then
    task.wait(0.5)
    Fly.setEnabled(true)
  end
end

return Fly
