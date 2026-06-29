-- src/util/input.lua
-- Unified touch + mouse + keyboard input helpers.
-- WHY: every feature needs to know "is the user pressing X" —
-- we centralize so features don't each wire UserInputService.
local UserInputService = game:GetService("UserInputService")

local Input = {}

-- True if the user is on a touch device (mobile).
function Input.isTouch()
  return UserInputService.TouchEnabled
end

-- True if a key is currently down. Accepts Enum.KeyCode or string.
function Input.isKeyDown(key)
  if type(key) == "string" then
    key = Enum.KeyCode[key]
  end
  return UserInputService:IsKeyDown(key)
end

-- Listen for a key press. Returns cleanup function.
-- usage: Input.onKeyDown("P", function() ... end)
function Input.onKeyDown(key, callback)
  if type(key) == "string" then
    key = Enum.KeyCode[key]
  end
  local conn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == key then
      task.spawn(callback)
    end
  end)
  return function() conn:Disconnect() end
end

-- Listen for a touch/click on a GuiObject. Handles both Mouse and Touch.
-- Returns cleanup function.
function Input.onTap(guiObject, callback)
  local conns = {}
  table.insert(conns, guiObject.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      task.spawn(callback, input)
    end
  end))
  return function()
    for _, c in ipairs(conns) do c:Disconnect() end
  end
end

-- Haptic feedback (vibration) — silently no-ops on desktop.
-- strength: 0..1, duration: seconds (capped to 1s).
function Input.haptic(strength, duration)
  if not UserInputService.TouchEnabled then return end
  if not UserInputService.VibrationEnabled then return end
  pcall(function()
    UserInputService:SetMotorVibration(
      Enum.UserInputType.Gamepad1,
      Enum.VibrationMotor.Small,
      math.clamp(strength, 0, 1)
    )
    task.delay(math.min(duration or 0.1, 1), function()
      pcall(function()
        UserInputService:SetMotorVibration(
          Enum.UserInputType.Gamepad1,
          Enum.VibrationMotor.Small, 0
        )
      end)
    end)
  end)
end

return Input
