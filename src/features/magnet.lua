-- src/features/magnet.lua
-- Pulls ALL ItemDrop parts in the workspace to the player's feet instantly.
-- User asked for "collect all diamonds across the whole map instantly like a
-- magnet and the emeralds too". This is the implementation.
--
-- Two modes:
--   1. CFrame TP: physically move each ItemDrop to the player (network-owner check)
--   2. Remote fire: call PickupItem remote for each drop in radius
--
-- We do BOTH — TP first (so the drop is at our feet), then fire the pickup
-- remote. This matches the VapeV4 PickupRange pattern but at a huge radius
-- (default 9999 = whole map).
--
-- Loop rate: 5Hz (every 0.2s) to avoid spamming the server.

local Services   = require(script.Parent.Parent.services)
local GameWksp   = require(script.Parent.Parent.game.workspace)
local Remotes     = require(script.Parent.Parent.game.remotes)
local Logger      = require(script.Parent.Parent.util.logger)
local PlaceId     = require(script.Parent.Parent.game.placeid)

local Magnet = {
  enabled  = false,
  radius   = 9999,   -- whole map by default
  _thread  = nil,
}

-- Check if the local player is the network owner of a part.
-- Vape uses `isnetworkowner` if available, else assumes true on non-AWP executors.
local function isNetworkOwner(part)
  if isnetworkowner then
    return pcall(function() return isnetworkowner(part) end)
  end
  -- Fallback: try :GetNetworkOwner() on the part's assembly root
  local ok, owner = pcall(function()
    local root = part.AssemblyRootPart or part
    return root:GetNetworkOwner()
  end)
  if not ok then return false end
  return owner == Services.localPlayer()
end

function Magnet._loop()
  while Magnet.enabled do
    pcall(function()
      if not PlaceId.isMatch() then return end
      local localRoot = Services.rootPart()
      if not localRoot then return end
      local hum = Services.humanoid()
      if not hum or hum.Health <= 0 then return end

      local drops = GameWksp.getItemDrops()
      local localPos = localRoot.Position
      local targetPos = localPos - Vector3.new(0, 3, 0)  -- at our feet

      for _, drop in ipairs(drops) do
        -- Skip freshly-spawned drops (< 2s old) to be anti-cheat friendly
        local dropTime = drop:GetAttribute("ClientDropTime")
        if dropTime and (tick() - dropTime) < 2 then
          -- still collect, but only if very close
          if (drop.Position - localPos).Magnitude > 10 then
            -- skip this drop
          else
            if isNetworkOwner(drop) then
              drop.CFrame = CFrame.new(targetPos)
            end
            task.spawn(function()
              Remotes.call("PickupItem", { itemDrop = drop })
            end)
          end
        else
          if (drop.Position - localPos).Magnitude <= Magnet.radius then
            if isNetworkOwner(drop) then
              drop.CFrame = CFrame.new(targetPos)
            end
            task.spawn(function()
              Remotes.call("PickupItem", { itemDrop = drop })
            end)
          end
        end
      end
    end)
    task.wait(0.2)  -- 5Hz
  end
end

function Magnet.setEnabled(state)
  Magnet.enabled = state
  if state and not Magnet._thread then
    Magnet._thread = task.spawn(Logger.guard(Magnet._loop, "magnet"))
  end
  Logger.info("Magnet " .. (state and "ON" or "OFF"))
end

function Magnet.setRadius(value)
  Magnet.radius = value
end

return Magnet
