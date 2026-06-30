-- src/features/speed.lua
-- v1.3: WalkSpeed modifier that survives Bedwars anti-cheat.
--
-- The problem: Bedwars's SprintController.constantSpeedMultiplier clamps
-- horizontal velocity to 23 studs/s server-side, regardless of the
-- Humanoid.WalkSpeed value. Just setting WalkSpeed doesn't bypass it.
--
-- The solution: combine WalkSpeed with the Anticheat.GroundHit heartbeat
-- (which is started by Fly.setEnabled — but for Speed-only, we also need
-- to fire InflateBalloon to open the clamp + start the heartbeat).
--
-- Stealth: same as Fly — ±5ms jitter on heartbeat, only when active,
-- never fire detection remotes.

local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local GameWksp   = _BW.GameWksp
local PlaceId    = _BW.PlaceId
local Logger     = _BW.Logger
-- v1.5: B034 — Anticheat from registry. No require() fallback
-- (it was a landmine that threw in loadstring context).
local Anticheat  = _BW.Anticheat

local Speed = {
  enabled = false,
  value   = 32,
  _conn   = nil,
}

function Speed._onHeartbeat()
  if not Speed.enabled then return end
  local hum = Services.humanoid()
  local localRoot = Services.rootPart()
  if not hum or not localRoot then return end
  -- 1. Set WalkSpeed (the game side)
  if hum.WalkSpeed < Speed.value then
    hum.WalkSpeed = Speed.value
  end
  -- 2. Force the actual velocity to match (the server clamps at 23,
  --    so this is the "cheating beyond the cap" — InflateBalloon opens it)
  if Anticheat then
    -- If the character is moving, push velocity up to 23 (or speed value)
    local vel = localRoot.AssemblyLinearVelocity
    local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    if horizSpeed < 23 and hum.MoveDirection.Magnitude > 0.1 then
      -- Player is pressing WASD. The server will clamp to 23 max, so
      -- we set our target to 23 (the clamp ceiling). The GroundHit
      -- heartbeat keeps the server believing our position is real.
      local target = math.min(Speed.value, 23)
      local dir = hum.MoveDirection.Unit * target
      localRoot.AssemblyLinearVelocity = Vector3.new(dir.X, vel.Y, dir.Z)
    end
  end
end

function Speed.setEnabled(state)
  Speed.enabled = state
  if state and not Speed._conn then
    -- 1. Open the velocity clamp (one-time per enable)
    if Anticheat then Anticheat.fireInflateBalloon() end
    -- 2. Start the GroundHit heartbeat (stealth mode, ±5ms jitter)
    if Anticheat then
      local localRoot = Services.rootPart()
      if localRoot then
        Anticheat.startGroundHitHeartbeat(localRoot)
      end
    end
    -- 3. Start the per-frame WalkSpeed + velocity setter
    Speed._conn = RunService.Heartbeat:Connect(Speed._onHeartbeat)
    Logger.info("Speed ENABLED (anti-cheat bypass active)")
  elseif not state and Speed._conn then
    pcall(function() Speed._conn:Disconnect() end)
    Speed._conn = nil
    -- Stop the heartbeat (only if Fly isn't also using it)
    if Anticheat and not (_BW.Fly and _BW.Fly.enabled) then
      Anticheat.stopGroundHitHeartbeat()
    end
    -- Restore default
    local hum = Services.humanoid()
    if hum then hum.WalkSpeed = 16 end
    Logger.info("Speed DISABLED")
  end
end

function Speed.setValue(value)
  Speed.value = value
end

return Speed
