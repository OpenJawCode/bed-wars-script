-- src/features/speed.lua
-- WalkSpeed modifier. Simple — set Humanoid.WalkSpeed each frame.
-- WHY each frame: Bedwars may reset WalkSpeed on various events (kit abilities,
-- slowdowns, etc.). Setting it every Heartbeat keeps it sticky.


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local Logger     = _BW.Logger

local Speed = {
  enabled = false,
  value   = 32,
  _conn   = nil,
}

function Speed._onHeartbeat()
  if not Speed.enabled then return end
  local hum = Services.humanoid()
  if not hum then return end
  -- Only override if the game's current walkspeed is lower than our target
  -- (so we don't fight speed-boost kits that legitimately exceed our value)
  if hum.WalkSpeed < Speed.value then
    hum.WalkSpeed = Speed.value
  end
end

function Speed.setEnabled(state)
  Speed.enabled = state
  if state and not Speed._conn then
    Speed._conn = RunService.Heartbeat:Connect(Logger.guard(Speed._onHeartbeat, "speed"))
  elseif not state and Speed._conn then
    Speed._conn:Disconnect()
    Speed._conn = nil
    -- Restore default
    local hum = Services.humanoid()
    if hum then hum.WalkSpeed = 16 end
  end
  Logger.info("Speed " .. (state and "ON" or "OFF"))
end

function Speed.setValue(value)
  Speed.value = value
end

return Speed
