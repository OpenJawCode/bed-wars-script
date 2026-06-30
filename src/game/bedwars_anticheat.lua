-- src/game/bedwars_anticheat.lua
-- Easy.gg Bedwars anti-cheat bypass + stealth helpers.
--
-- THE GOAL: Make Fly / Teleport / Killaura work without getting the
-- account banned. VapeV4 got detected and discontinued because it:
--   1. Used the obvious Vape-specific detection remotes
--   2. Fired GroundHit at perfectly-spaced 30 Hz (robotic timing)
--   3. Used Vape-prefixed function names in the source
--
-- OUR APPROACH (stealth):
--   - NEVER name anything "Vape" — use neutral names
--   - NEVER fire the detection remotes: SelfReport, VapeDetectionRedundancy,
--     DetectionTest, VapeBanWave2, VapeBanWave2Test
--   - Use the LEGITIMATE game feature "InflateBalloon" to open the
--     velocity clamp (this is a real in-game balloon power-up)
--   - Fire GroundHit heartbeat at 30 Hz but with ±5-10ms jitter so
--     it doesn't look robotic
--   - Only fire the heartbeat when actively moving (no background
--     signature)
--   - Use velocity-based teleport (not instant CFrame) so the server
--     can't distinguish from a fast fall
--
-- The technique is what VapeV4 used to do internally. We've just been
-- more careful about NOT firing the detection remotes.

local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")

-- v1.5.1: B041 — lazy-resolve _BW dependencies instead of capturing
-- at file-load time. The old `local Logger = _BW.Logger` captured
-- nil if this module was loaded before util/logger.lua (which was
-- the bug in B041 — the loader iterated with `pairs(sources)`
-- giving undefined order, so bedwars_anticheat could be processed
-- first and Logger would be nil forever).
-- FIX: use `_BW.X` lookups at function call time, not at file
-- load time. This way the order doesn't matter.
local function L() return _BW.Logger end

local Anticheat = {}

-- ─── Detection remotes — NEVER fire these ────────────────────────────────
-- Documented here so future agents never accidentally call them.
-- Even touching these remotes can flag the account.
Anticheat.DETECTION_REMOTES_NEVER_FIRE = {
  "SelfReport",                    -- honey-pot, only valid arg is "injection_detected"
  "VapeDetectionRedundancy",       -- batch-ban trigger
  "DetectionTest",                 -- pattern-match test
  "VapeBanWave2",                   -- wave 2 ban batch
  "VapeBanWave2Test",               -- wave 2 test
  "VapeBanWave2Internal",           -- internal
  "AntiCheatBypass",               -- name-flag
  "ReportInjection",                -- injection report
}

-- ─── Bypass technique 1: InflateBalloon (legitimate game feature) ─────
-- Easy.gg Bedwars has a balloon power-up. When inflated, it opens
-- the constantSpeedMultiplier clamp (23 studs/s horizontal, 1.5-6
-- vertical). We can fire this remote once when fly is enabled, and
-- the character can then move freely until the balloon "deflates".
-- This is a LEGITIMATE game feature, so it doesn't trip detection.
function Anticheat.fireInflateBalloon()
  if not PlaceId.isMatch() then return false end
  local ok = pcall(function()
    Remotes.fire("InflateBalloon")
  end)
  if ok then
    L().info("InflateBalloon fired (velocity clamp opened)")
  end
  return ok
end

-- ─── Bypass technique 2: PreSimulation + Velocity ──────────────────────
-- Easy.gg's SprintController clamps horizontal velocity to 23 studs/s.
-- We bypass this by:
--   1. Setting rootPart.AssemblyLinearVelocity per frame in PreSimulation
--      (runs BEFORE the server's physics tick)
--   2. Clamping the velocity we set to ±23 (so the server's clamp sees
--      a value within limits)
--   3. Setting bedwars.StatefulEntityKnockbackController.lastImpulseTime
--      to math.huge to disable server knockback

-- PreSimulation fly velocity setter
function Anticheat.setFlyVelocity(rootPart, direction, options)
  options = options or {}
  if not rootPart then return end
  -- Clamp horizontal to 23 (server's constantSpeedMultiplier)
  local horiz = Vector3.new(direction.X, 0, direction.Z)
  if horiz.Magnitude > 23 then
    horiz = horiz.Unit * 23
  end
  -- Vertical: clamp 1.5-6 (balloon mass range)
  local vert = math.clamp(direction.Y * 30, options.minVert or -6, options.maxVert or 6)
  -- Apply
  rootPart.AssemblyLinearVelocity = horiz + Vector3.yaxis * vert
end

-- Disable server knockback
function Anticheat.disableKnockback()
  if not PlaceId.isMatch() then return false end
  local ok = pcall(function()
    local bedwars = _BW.BEDWARS_STATEFUL
    if bedwars and bedwars.StatefulEntityKnockbackController then
      bedwars.StatefulEntityKnockbackController.lastImpulseTime = math.huge
    end
  end)
  return ok
end

-- ─── Bypass technique 3: GroundHit heartbeat (with jitter) ──────────────
-- The server compares client Y-velocity with the timestamp the client
-- sends. If the client fires at exactly 30 Hz with no jitter, the
-- server detects it as a script. We add ±5ms jitter.
Anticheat._groundHitConn = nil
Anticheat._groundHitActive = false

function Anticheat.startGroundHitHeartbeat(rootPart)
  if Anticheat._groundHitActive then return end
  Anticheat._groundHitActive = true
  Anticheat._groundHitConn = RunService.Heartbeat:Connect(function()
    if not Anticheat._groundHitActive or not rootPart or not rootPart.Parent then
      Anticheat.stopGroundHitHeartbeat()
      return
    end
    -- Get current velocity
    local vel = rootPart.AssemblyLinearVelocity
    -- Fire with correct timestamp + ±5ms jitter
    local jitter = (math.random() - 0.5) * 0.01
    task.delay(jitter, function()
      pcall(function()
        Remotes.fire("GroundHit", nil, vel, workspace:GetServerTimeNow())
      end)
    end)
  end)
  L().info("GroundHit heartbeat started (stealth mode, ±5ms jitter)")
end

function Anticheat.stopGroundHitHeartbeat()
  Anticheat._groundHitActive = false
  if Anticheat._groundHitConn then
    pcall(function() Anticheat._groundHitConn:Disconnect() end)
    Anticheat._groundHitConn = nil
  end
end

-- ─── AttackEntity fire (killaura bypass) ────────────────────────────────
-- Standard killaura fires with selfPosition at rootPart.Position. But
-- the server validates reach (14.399 studs). To bypass: extend
-- selfPosition along LookVector by (distance - 14.399) so the server
-- thinks we're closer than we are.
function Anticheat.fireAttackEntity(weapon, entityInstance, selfPosition, targetPosition)
  if not PlaceId.isMatch() then return end
  if not weapon or not entityInstance then return end
  local root = selfPosition
  local target = targetPosition
  local distance = (root - target).Magnitude
  local dir = CFrame.lookAt(root, target).LookVector
  -- Extend selfPosition along LookVector by the surplus over 14.399
  local legitReach = 14.399
  local extendedPos = root + dir * math.max(distance - legitReach, 0)
  local ok = pcall(function()
    Remotes.fire("AttackEntity", {
      weapon = weapon,
      chargedAttack = { chargeRatio = 0 },
      entityInstance = entityInstance,
      validate = {
        raycast = {
          cameraPosition = { value = extendedPos },
          cursorDirection = { value = dir },
        },
        targetPosition = { value = target },
        selfPosition = { value = extendedPos },
      },
    })
  end)
  return ok
end

-- ─── Velocity-based teleport (not instant CFrame) ─────────────────────
-- A sudden CFrame change is detectable. Instead, set a high velocity
-- in the direction of the target for a short duration. The server sees
-- a fast-moving character, not a teleport.
function Anticheat.velocityTeleport(rootPart, targetPosition, speed)
  if not rootPart then return end
  speed = speed or 80  -- studs/s, way above the 23 clamp so we need
                       -- to "puff" the balloon harder. We do this by
                       -- firing InflateBalloon multiple times in quick
                       -- succession. Each call opens the clamp for
                       -- ~0.3s.
  local dir = (targetPosition - rootPart.Position)
  if dir.Magnitude < 0.1 then return end
  -- For 0.3s window, fire 3 InflateBalloon calls
  for _ = 1, 3 do
    Anticheat.fireInflateBalloon()
  end
  -- Set velocity for 0.3s
  local velDir = dir.Unit * speed
  Anticheat.setFlyVelocity(rootPart, velDir, { maxVert = math.abs(velDir.Y) })
  task.delay(0.3, function()
    -- After 0.3s, the balloon effect ends. Decelerate.
    if rootPart and rootPart.Parent then
      Anticheat.setFlyVelocity(rootPart, Vector3.zero)
    end
  end)
end

-- ─── Bedwars state access (lazy) ────────────────────────────────────────
-- The StatefulEntityKnockbackController is a runtime object inside
-- the Bedwars Roact state. Accessing it is fragile. We use a lazy
-- lookup that retries on heartbeat if not found.
function Anticheat.getBedwarsState()
  -- Try the common paths (varies by Bedwars version)
  if _BW.BEDWARS_STATEFUL then return _BW.BEDWARS_STATEFUL end
  -- Lazy search via game:GetService("ReplicatedStorage").TS
  local ok, state = pcall(function()
    local replicated = game:GetService("ReplicatedStorage")
    local ts = replicated:FindFirstChild("TS")
    if ts then
      -- Bedwars stores state in TS.state
      local stateMod = ts:FindFirstChild("state")
      if stateMod then
        local ok2, mod = pcall(require, stateMod)
        if ok2 and mod then return mod end
      end
    end
    return nil
  end)
  if ok and state then
    _BW.BEDWARS_STATEFUL = state
    return state
  end
  return nil
end

-- ─── Init ───────────────────────────────────────────────────────────────
function Anticheat.init()
  L().info("Anticheat module loaded (stealth mode)")
  L().warn("Detection remotes documented — DO NOT FIRE: "
    .. table.concat(Anticheat.DETECTION_REMOTES_NEVER_FIRE, ", "))
end

return Anticheat
