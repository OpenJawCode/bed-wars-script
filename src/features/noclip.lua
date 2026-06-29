-- src/features/noclip.lua
-- Walk through walls. Disables CanCollide on all character parts each frame.
-- Pairs with Fly (which also nocliips), but Noclip standalone keeps walking
-- physics on (so you can walk through walls but still fall with gravity).


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local Logger     = _BW.Logger

local Noclip = {
  enabled = false,
  _conn   = nil,
}

function Noclip._onHeartbeat()
  if not Noclip.enabled then return end
  local char = Services.character()
  if not char then return end
  for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") and part.CanCollide then
      part.CanCollide = false
    end
  end
end

function Noclip.setEnabled(state)
  Noclip.enabled = state
  if state and not Noclip._conn then
    Noclip._conn = RunService.Heartbeat:Connect(Logger.guard(Noclip._onHeartbeat, "noclip"))
  elseif not state and Noclip._conn then
    Noclip._conn:Disconnect()
    Noclip._conn = nil
    -- Restore collisions (Bedwars defaults)
    local char = Services.character()
    if char then
      for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
          part.CanCollide = true
        end
      end
    end
  end
  Logger.info("Noclip " .. (state and "ON" or "OFF"))
end

return Noclip
