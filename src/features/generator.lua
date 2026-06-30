-- src/features/generator.lua
-- Auto-collect from generators. Same as Magnet but with a smaller radius
-- (default 30 studs) + a 3-second spawn guard — so you walk near a
-- generator and it auto-collects without being too aggressive.
--
-- Bedwars generators spawn ItemDrop parts tagged 'ItemDrop'. We reuse the
-- VapeV4 PickupRange pattern at 10Hz.

local Services   = require(script.Parent.Parent.services)
local GameWksp   = require(script.Parent.Parent.game.workspace)
local Remotes     = require(script.Parent.Parent.game.remotes)
local Logger      = require(script.Parent.Parent.util.logger)
local PlaceId     = require(script.Parent.Parent.game.placeid)

local Generator = {
  enabled  = false,
  radius   = 30,
  _thread  = nil,
}

function Generator._loop()
  while Generator.enabled do
    pcall(function()
      if not PlaceId.isMatch() then return end
      local localRoot = Services.rootPart()
      if not localRoot then return end
      local hum = Services.humanoid()
      if not hum or hum.Health <= 0 then return end

      local drops = GameWksp.getItemDrops()
      local localPos = localRoot.Position

      for _, drop in ipairs(drops) do
        -- 3-second spawn guard (be anti-cheat friendly)
        local dropTime = drop:GetAttribute("ClientDropTime")
        if dropTime and (tick() - dropTime) < 3 then
          -- Skip this drop
        else
          local dist = (drop.Position - localPos).Magnitude
          if dist <= Generator.radius then
            task.spawn(function()
              Remotes.call("PickupItem", { itemDrop = drop })
            end)
          end
        end
      end
    end)
    task.wait(0.1)  -- 10Hz
  end
end

function Generator.setEnabled(state)
  Generator.enabled = state
  if state and not Generator._thread then
    Generator._thread = task.spawn(Logger.guard(Generator._loop, "generator"))
  end
  Logger.info("Generator auto-collect " .. (state and "ON" or "OFF"))
end

function Generator.setRadius(value)
  Generator.radius = value
end

return Generator
