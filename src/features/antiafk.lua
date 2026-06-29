-- src/features/antiafk.lua
-- Prevents the AFK kick. Bedwars has an AfkController that sets an AFK flag
-- after ~20s of no input. We:
--   1. Fire the AfkStatus remote every 10s to reset the flag
--   2. Wiggle the camera by 0.01 radians every 30s as backup
-- Web dev mental model: this is our "keep-alive ping".


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService = game:GetService("RunService")
local Services   = _BW.Services
local Remotes     = _BW.Remotes
local Logger      = _BW.Logger

local AntiAFK = {
  enabled = false,
  _thread = nil,
}

function AntiAFK._loop()
  local lastWiggle = tick()
  while AntiAFK.enabled do
    pcall(function()
      -- Fire the AfkStatus remote to reset AFK flag
      Remotes.fire("AfkStatus", { isAfk = false })

      -- Backup: wiggle the camera every 30s
      if tick() - lastWiggle > 30 then
        local camera = Services.camera()
        if camera then
          local cf = camera.CFrame
          camera.CFrame = cf * CFrame.Angles(0, 0.01, 0)
          task.wait(0.05)
          camera.CFrame = cf
        end
        lastWiggle = tick()
      end
    end)
    task.wait(10)
  end
end

function AntiAFK.setEnabled(state)
  AntiAFK.enabled = state
  if state and not AntiAFK._thread then
    AntiAFK._thread = task.spawn(Logger.guard(AntiAFK._loop, "antiafk"))
  end
  Logger.info("Anti-AFK " .. (state and "ON" or "OFF"))
end

return AntiAFK
