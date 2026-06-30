-- loader.lua
-- Minimal stub. Fetches the bundled main.lua and runs it.
-- If anything fails, shows a visible BOOT FAILED error on screen
-- (so the user knows what happened — no more silent failures).
--
-- Usage: loadstring(game:HttpGet(".../loader.lua"))()
--
-- This loader is AUTO-UPDATED on every commit. One paste = always latest.

local MAIN_URL  = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/main.lua"
local GITHUB_BASE = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/src"

-- Build a tiny inline error overlay (doesn't need HttpGet to work)
local function showInlineError(msg, hint)
  hint = hint or ""
  local ok, parent = pcall(function()
    local s, h = pcall(function() return gethui() end)
    if s and h then return h end
    return game:GetService("CoreGui")
  end)
  if not ok then return end

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
  local s2 = Instance.new("UIStroke"); s2.Color = Color3.fromRGB(239, 68, 68); s2.Thickness = 1.5; s2.Parent = bg

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
  body.Text = tostring(msg) .. (hint ~= "" and ("\n\n" .. hint) or "")
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

-- Helper: try to fetch a URL with a clear error message
local function tryFetch(url, name)
  local ok, source = pcall(function()
    return game:HttpGet(url, true)
  end)
  if not ok then
    return nil, "HttpGet error for " .. name .. ": " .. tostring(source)
  end
  if not source or source == "" then
    return nil, name .. ": empty response (URL may be 404 or executor blocked)"
  end
  return source
end

-- List of modules to fetch
-- CRITICAL: ui/toast.lua and ui/rotation.lua MUST be included here.
-- B033: Library.lua references _BW.Toast and _BW.Rotation. If they're
-- nil (loader never loaded them), the library silently skips
-- Toast.setParent(sg) AND Rotation.start(...), AND main.lua falls
-- back to Library:Notify (which works but uses a DIFFERENT system).
-- Result: no actual bug crash, but the user gets a half-broken UI.
local MODULES = {
  "util/logger.lua",
  "ui/theme.lua",
  "util/tween.lua",
  "util/dragger.lua",
  "util/input.lua",
  "util/projection.lua",
  "ui/animations.lua",
  "ui/icons.lua",
  "ui/toast.lua",
  "ui/rotation.lua",
  "ui/library.lua",
  "config.lua",
  "game/placeid.lua",
  "game/services.lua",
  "game/remotes.lua",
  "game/workspace.lua",
  "features/killaura.lua",
  "features/reach.lua",
  "features/aimbot.lua",
  "features/fly.lua",
  "features/speed.lua",
  "features/noclip.lua",
  "features/magnet.lua",
  "features/generator.lua",
  "features/bedaura.lua",
  "features/shop.lua",
  "features/antiafk.lua",
  "features/autorejoin.lua",
  "features/spy.lua",
  "features/esp.lua",
}

-- Step 1: fetch main.lua
local mainSource, mainErr = tryFetch(MAIN_URL, "main.lua")
if not mainSource then
  showInlineError(
    mainErr,
    "FIX: If your executor blocks HttpGet to GitHub, use the single-file:\n" ..
    "github.com/OpenJawCode/bed-wars-script/blob/main/docs/bw-singlefile.lua\n\n" ..
    "Or copy from the repo: docs/bw-singlefile.lua (paste the entire file)."
  )
  return
end

-- Step 2: fetch all modules
local sources = {}
local failed = {}
for i, path in ipairs(MODULES) do
  local src, err = tryFetch(GITHUB_BASE .. "/" .. path, path)
  if not src then
    table.insert(failed, { path = path, err = err })
  else
    sources[path] = src
  end
end

-- If any modules failed, show a prominent warning
if #failed > 0 then
  local list = ""
  for i, f in ipairs(failed) do
    if i > 5 then break end
    list = list .. "  • " .. f.path .. "\n"
  end
  if #failed > 5 then list = list .. "  ... and " .. (#failed - 5) .. " more\n" end
  showInlineError(
    "Failed to fetch " .. #failed .. " / " .. #MODULES .. " modules:\n" .. list,
    "The script may run with reduced functionality.\n" ..
    "FIX: If features are missing, use the single-file version:\n" ..
    "github.com/OpenJawCode/bed-wars-script/blob/main/docs/bw-singlefile.lua"
  )
  -- Still continue with whatever modules we got
end

-- Step 3: build a runtime that injects the loaded sources into _BW
-- main.lua uses `getgenv()._BW.X` to access modules, so we set them up
-- in getgenv() BEFORE running main.lua.
local getgenv = getgenv or function() return _G end
local _BW = getgenv()
if not _BW then _BW = _G end
_BW._BW = _BW
for path, src in pairs(sources) do
  -- Derive variable name (e.g., "util/logger.lua" -> "Logger")
  local name = path:match("([^/]+)%.lua$")
  local var
  if name == "logger" then var = "Logger"
  elseif name == "theme" then var = "Theme"
  elseif name == "tween" then var = "Tween"
  elseif name == "dragger" then var = "Dragger"
  elseif name == "input" then var = "Input"
  elseif name == "projection" then var = "Projection"
  elseif name == "animations" then var = "Anim"
  elseif name == "icons" then var = "Icons"
  elseif name == "toast" then var = "Toast"
  elseif name == "rotation" then var = "Rotation"
  elseif name == "library" then var = "Library"
  elseif name == "config" then var = "Config"
  elseif name == "placeid" then var = "PlaceId"
  elseif name == "services" then var = "Services"
  elseif name == "remotes" then var = "Remotes"
  elseif name == "workspace" then var = "GameWksp"
  elseif name == "killaura" then var = "Killaura"
  elseif name == "reach" then var = "Reach"
  elseif name == "aimbot" then var = "Aimbot"
  elseif name == "fly" then var = "Fly"
  elseif name == "speed" then var = "Speed"
  elseif name == "noclip" then var = "Noclip"
  elseif name == "magnet" then var = "Magnet"
  elseif name == "generator" then var = "Generator"
  elseif name == "bedaura" then var = "BedAura"
  elseif name == "shop" then var = "Shop"
  elseif name == "antiafk" then var = "AntiAFK"
  elseif name == "autorejoin" then var = "AutoRejoin"
  elseif name == "spy" then var = "Spy"
  elseif name == "esp" then var = "ESP"
  end
  if var then
    _BW[var] = loadstring(src, name) and (loadstring(src))()
  end
end

-- Step 4: run main.lua
local mainFn, parseErr = loadstring(mainSource, "main.lua")
if not mainFn then
  showInlineError(
    "Parse error in main.lua: " .. tostring(parseErr),
    "The repo might be in a broken state. Try the single-file version."
  )
  return
end

-- Wrap main.lua execution so any boot error is caught + shown
local ok, err = pcall(mainFn)
if not ok then
  showInlineError(
    "Boot failed: " .. tostring(err),
    "If this is a Knit/remote error, make sure you're IN the Bedwars game.\n" ..
    "If the FAB (green ⚡) doesn't appear, something failed before CreateWindow."
  )
  return
end
