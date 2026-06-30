-- src/util/input.lua
-- Unified touch + mouse + keyboard input helpers.
-- Haptic fallback chain: executor-specific vibrate() → HapticService → gamepad motor.

local UserInputService = game:GetService("UserInputService")

local Input = {}

function Input.isTouch()
  return UserInputService.TouchEnabled
end

function Input.isKeyDown(key)
  if type(key) == "string" then
    key = Enum.KeyCode[key]
  end
  return UserInputService:IsKeyDown(key)
end

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

-- v2.0: B048 — Input.onHold(guiObject, thresholdMs, onHold, onRelease)
-- Distinguishes between a quick tap and a hold:
--   - Released before thresholdMs: nothing happens (use Input.onTap for taps)
--   - Held for thresholdMs: onHold() fires
--   - onRelease(wasHold) fires on release
--
-- Used by the FAB: quick tap = open menu, hold = start drag.
-- This is the standard Delta/Codex executor pattern.
function Input.onHold(guiObject, thresholdMs, onHold, onRelease)
  thresholdMs = thresholdMs or 250
  local conns = {}
  local startTime = 0
  local heldFired = false
  local tracking = false

  table.insert(conns, guiObject.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    startTime = tick()
    heldFired = false
    tracking = true
    task.delay(thresholdMs / 1000, function()
      if tracking and not heldFired and onHold then
        heldFired = true
        pcall(onHold)
      end
    end)
  end))

  table.insert(conns, guiObject.InputEnded:Connect(function(input)
    if not tracking then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    tracking = false
    if onRelease then
      pcall(onRelease, heldFired)
    end
  end))

  -- If the cursor leaves the FAB while held, still fire onRelease
  table.insert(conns, guiObject.MouseLeave:Connect(function()
    if not tracking then return end
    tracking = false
    if onRelease then
      pcall(onRelease, heldFired)
    end
  end))

  return function()
    for _, c in ipairs(conns) do c:Disconnect() end
  end
end

-- Haptic feedback (vibration) — tries executor-specific first, then gamepad.
function Input.haptic(strength, duration)
  strength = math.clamp(strength or 0.3, 0, 1)
  duration = math.min(duration or 0.1, 1)

  -- 1. Try executor-specific vibrate()
  if vibrate then
    pcall(function() vibrate(duration * 1000) end)
    return
  end

  -- 2. Try HapticService (Roblox iOS/Android native)
  pcall(function()
    local HapticService = game:GetService("HapticService")
    if HapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small) then
      HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, strength)
      task.delay(duration, function()
        pcall(function()
          HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
        end)
      end)
      return
    end
  end)

  -- 3. Fall back to UserInputService (gamepad)
  if not UserInputService.GamepadEnabled then return end
  pcall(function()
    UserInputService:SetMotorVibration(
      Enum.UserInputType.Gamepad1,
      Enum.VibrationMotor.Small,
      strength
    )
    task.delay(duration, function()
      pcall(function()
        UserInputService:SetMotorVibration(
          Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0
        )
      end)
    end)
  end)
end

function Input.isTapInput(input)
  return input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.Touch
end

return Input
