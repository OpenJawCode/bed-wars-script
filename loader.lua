-- loader.lua
-- Minimal stub. Fetches the bundled main.lua and runs it.
-- If anything fails, shows a visible BOOT FAILED error on screen
-- (so the user knows what happened — no more silent failures).
--
-- Usage: loadstring(game:HttpGet(".../loader.lua"))()

local ERROR_URL = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/src/ui/error_overlay.lua"
local MAIN_URL   = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/main.lua"

-- Build a tiny inline error overlay (doesn't need HttpGet to work)
local function showInlineError(msg)
  local ok, Players = pcall(function() return game:GetService("Players") end)
  if not ok then return end
  local ok2, parent = pcall(function()
    local s, h = pcall(function() return gethui() end)
    if s and h then return h end
    return game:GetService("CoreGui")
  end)
  if not ok2 then return end

  local gui = Instance.new("ScreenGui")
  gui.Name = "BWInlineError"
  gui.ResetOnSpawn = false
  gui.DisplayOrder = 99999
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  gui.Parent = parent

  local bg = Instance.new("Frame")
  bg.Parent = gui
  bg.Size = UDim2.new(1, -32, 0, 0)
  bg.Position = UDim2.new(0, 16, 0.5, 0)
  bg.AnchorPoint = Vector2.new(0, 0.5)
  bg.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
  bg.AutomaticSize = Enum.AutomaticSize.Y
  bg.BorderSizePixel = 0
  bg.ZIndex = 100
  local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = bg
  local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(239, 68, 68); s.Thickness = 1.5; s.Parent = bg

  local hdr = Instance.new("TextLabel")
  hdr.Parent = bg
  hdr.Size = UDim2.new(1, 0, 0, 40)
  hdr.Position = UDim2.new(0, 0, 0, 0)
  hdr.BackgroundTransparency = 1
  hdr.Text = "  ⚠  LOADER FAILED"
  hdr.TextColor3 = Color3.fromRGB(255, 255, 255)
  hdr.Font = Enum.Font.GothamBlack
  hdr.TextSize = 14
  hdr.TextXAlignment = Enum.TextXAlignment.Left
  hdr.TextYAlignment = Enum.TextYAlignment.Center
  hdr.ZIndex = 101

  local body = Instance.new("TextLabel")
  body.Parent = bg
  body.Size = UDim2.new(1, -24, 0, 0)
  body.Position = UDim2.new(0, 12, 0, 48)
  body.AutomaticSize = Enum.AutomaticSize.Y
  body.Text = tostring(msg)
  body.TextColor3 = Color3.fromRGB(255, 200, 200)
  body.Font = Enum.Font.Code
  body.TextSize = 11
  body.TextXAlignment = Enum.TextXAlignment.Left
  body.TextYAlignment = Enum.TextYAlignment.Top
  body.TextWrapped = true
  body.ZIndex = 101

  print("[bw-loader] " .. tostring(msg))
  warn("[bw-loader] " .. tostring(msg))
end

-- Step 1: try to load the error overlay module (may itself fail if HttpGet is blocked)
local overlaySrc = nil
local overlayOk, overlayResult = pcall(function()
  return game:HttpGet(ERROR_URL, true)
end)
if overlayOk and overlayResult then
  local fn, err = loadstring(overlayResult, "error_overlay")
  if fn then
    -- Store for main.lua to use
    if getgenv then getgenv()._BW_ERROR_OVERLAY_SRC = overlayResult end
  end
end

-- Step 2: fetch main.lua
local ok, source = pcall(function()
  return game:HttpGet(MAIN_URL, true)
end)

if not ok or not source or source == "" then
  showInlineError(
    "Failed to fetch main.lua from:\n" .. MAIN_URL .. "\n\n" ..
    "Error: " .. tostring(ok and "empty response" or source) .. "\n\n" ..
    "Your executor (Delta/Codex) may be blocking HttpGet to GitHub.\n\n" ..
    "FIX: Use the single-file version at\n" ..
    "docs/bw-singlefile.lua (paste it directly into your executor)."
  )
  return
end

local fn, err = loadstring(source, "main.lua")
if not fn then
  showInlineError("Parse error in main.lua:\n" .. tostring(err))
  return
end

fn()
