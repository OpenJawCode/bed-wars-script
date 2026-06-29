-- src/features/autorejoin.lua
-- Rejoins the same server on disconnect / kick.
-- Uses TeleportService:TeleportToPlaceInstance with the current JobId.
-- WHY: Bedwars kicks you on death (sometimes) or you might DC. Auto-rejoin
-- keeps you in the same match.

local TeleportService = game:GetService("TeleportService")
local Services        = require(script.Parent.Parent.services)
local Logger          = require(script.Parent.Parent.util.logger)

local AutoRejoin = {
  enabled = false,
  _conn   = nil,
}

function AutoRejoin._onDisconnect()
  if not AutoRejoin.enabled then return end
  local plr = Services.localPlayer()
  local placeId = game.PlaceId
  local jobId = game.JobId
  pcall(function()
    TeleportService:TeleportToPlaceInstance(placeId, jobId, plr)
  end)
end

function AutoRejoin.setEnabled(state)
  AutoRejoin.enabled = state
  if state and not AutoRejoin._conn then
    -- Listen for the LocalPlayer's connection events.
    -- Roblox doesn't have a clean "disconnect" event, so we listen for
    -- CharacterRemoving with no CharacterAdded follow-up within 10s.
    local plr = Services.localPlayer()
    if plr then
      AutoRejoin._conn = plr.CharacterRemoving:Connect(function(char)
        task.delay(10, function()
          if not plr.Character and AutoRejoin.enabled then
            AutoRejoin._onDisconnect()
          end
        end)
      end)
    end
  elseif not state and AutoRejoin._conn then
    AutoRejoin._conn:Disconnect()
    AutoRejoin._conn = nil
  end
  Logger.info("AutoRejoin " .. (state and "ON" or "OFF"))
end

return AutoRejoin
