-- loader.lua
-- v1.5: Hardened stub. Fetches main.lua + 29 modules from the repo
-- in PARALLEL, populates the _BW registry, and runs main.lua.
--
-- What's new in v1.5:
--   1. Boot splash (Phase 6) — user sees "Loading Bedwars Script… 1/31"
--      immediately, so they know the script is working
--   2. Parallel HttpGet (Phase 5) — all 29 modules fetched concurrently
--      with task.spawn, boot drops from ~30s to ~3-5s
--   3. Per-module pcall (Phase 3) — a single module error doesn't kill
--      the entire loader; failed modules are listed in the error overlay
--   4. Stays in the right ZIndex layer (DisplayOrder=9999999 + Global)
--
-- If anything fails, shows a visible error overlay on screen.
-- This loader is AUTO-UPDATED on every commit. One paste = always latest.

local MAIN_URL    = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/main.lua"
local GITHUB_BASE = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/src"

-- ─── v1.5: Boot splash (Phase 6) ──────────────────────────────────────────
-- A minimal matte-dark card that shows "Loading Bedwars Script… 1/31…"
-- BEFORE the first HttpGet. Visible from the moment the loader runs.
-- v1.4.1 lesson: set FINAL state immediately, never "start invisible +
-- tween to visible" — the tween can fail. So the splash is fully opaque
-- and visible the instant it exists.
local _splashGui, _splashText, _splashProgress

local function installSplash()
  local ok, parent = pcall(function()
    local s, h = pcall(function() return gethui() end)
    if s and h then return h end
    return game:GetService("CoreGui")
  end)
  if not ok then return end

  _splashGui = Instance.new("ScreenGui")
  _splashGui.Name = "BWSplash"
  _splashGui.ResetOnSpawn = false
  _splashGui.DisplayOrder = 9999999
  _splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
  _splashGui.IgnoreGuiInset = true
  _splashGui.Parent = parent

  local card = Instance.new("Frame")
  card.Name = "Card"
  card.Parent = _splashGui
  card.Size = UDim2.fromOffset(280, 64)
  card.Position = UDim2.new(0.5, -140, 0, 80)
  card.AnchorPoint = Vector2.new(0, 0)
  card.BackgroundColor3 = Color3.fromRGB(11, 15, 24)  -- matte dark
  card.BackgroundTransparency = 0.08                   -- visible immediately
  card.BorderSizePixel = 0
  card.ZIndex = 100
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 14)
  corner.Parent = card

  -- Top highlight line (1pt white, very transparent — liquid glass edge)
  local topLine = Instance.new("Frame")
  topLine.Parent = card
  topLine.Size = UDim2.new(1, -16, 0, 1)
  topLine.Position = UDim2.new(0, 8, 0, 0)
  topLine.BackgroundColor3 = Color3.fromRGB(16, 185, 129)  -- emerald
  topLine.BackgroundTransparency = 0.50
  topLine.BorderSizePixel = 0
  topLine.ZIndex = 101

  -- Title
  local title = Instance.new("TextLabel")
  title.Parent = card
  title.Name = "Title"
  title.Size = UDim2.new(1, -24, 0, 22)
  title.Position = UDim2.new(0, 12, 0, 8)
  title.BackgroundTransparency = 1
  title.Text = "⚡ Bedwars Script"
  title.TextColor3 = Color3.fromRGB(240, 242, 248)
  title.Font = Enum.Font.GothamBold
  title.TextSize = 14
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.TextYAlignment = Enum.TextYAlignment.Center
  title.ZIndex = 101

  _splashText = Instance.new("TextLabel")
  _splashText.Parent = card
  _splashText.Name = "Progress"
  _splashText.Size = UDim2.new(1, -24, 0, 18)
  _splashText.Position = UDim2.new(0, 12, 0, 32)
  _splashText.BackgroundTransparency = 1
  _splashText.Text = "Loading modules… 0/31"
  _splashText.TextColor3 = Color3.fromRGB(148, 163, 184)
  _splashText.Font = Enum.Font.GothamMedium
  _splashText.TextSize = 12
  _splashText.TextXAlignment = Enum.TextXAlignment.Left
  _splashText.TextYAlignment = Enum.TextYAlignment.Center
  _splashText.ZIndex = 101

  _splashProgress = Instance.new("Frame")
  _splashProgress.Parent = card
  _splashProgress.Name = "Bar"
  _splashProgress.Size = UDim2.new(0, 0, 0, 2)
  _splashProgress.Position = UDim2.new(0, 12, 1, -6)
  _splashProgress.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
  _splashProgress.BackgroundTransparency = 0.20
  _splashProgress.BorderSizePixel = 0
  _splashProgress.ZIndex = 101
end

local function updateSplash(current, total, label)
  if not _splashText then return end
  _splashText.Text = string.format("Loading %s… %d/%d", label, current, total)
  if _splashProgress then
    local pct = current / total
    _splashProgress.Size = UDim2.new(pct, -24, 0, 2)
  end
end

local function dismissSplash(success)
  if not _splashGui then return end
  if success then
    -- Quick fade out (transparency tween — safe, doesn't gate visibility)
    if _splashProgress then
      _splashProgress.Size = UDim2.new(1, -24, 0, 2)
    end
  end
  task.delay(success and 0.4 or 0, function()
    if _splashGui and _splashGui.Parent then
      _splashGui:Destroy()
      _splashGui = nil
    end
  end)
end

-- ─── Error overlay (unchanged behavior, but dismisses splash first) ───
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
  gui.DisplayOrder = 9999999
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
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
  hdr.Size = UDim2.new(1, -16, 0, 40)
  hdr.Position = UDim2.new(0, 8, 0, 0)
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

  dismissSplash(false)
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
  "game/bedwars_anticheat.lua",
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

-- ─── Boot entry ──────────────────────────────────────────────────────────
installSplash()
updateSplash(0, #MODULES + 1, "main.lua")

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
updateSplash(1, #MODULES + 1, "modules")

-- Step 2: PARALLEL fetch all modules (Phase 5)
-- Each module fetches in its own task.spawn. The total time is
-- max(single_fetch_time) instead of sum(single_fetch_time).
-- 30 sequential × 300ms = 9s → 30 parallel × 300ms = 300ms.
local sources = {}
local failed = {}
local completed = 0
local fetchDone = false
local fetchStartTime = tick()

local function onFetchComplete(path, src, err)
  completed = completed + 1
  updateSplash(completed + 1, #MODULES + 1, "modules")
  if src then
    sources[path] = src
  else
    table.insert(failed, { path = path, err = err })
  end
  if completed >= #MODULES then
    fetchDone = true
  end
end

for _, path in ipairs(MODULES) do
  task.spawn(function()
    local src, err = tryFetch(GITHUB_BASE .. "/" .. path, path)
    onFetchComplete(path, src, err)
  end)
end

-- Wait for all parallel fetches (with a generous timeout)
local FETCH_TIMEOUT = 60  -- seconds
while not fetchDone do
  if tick() - fetchStartTime > FETCH_TIMEOUT then
    showInlineError(
      "Module fetch timed out after " .. FETCH_TIMEOUT .. "s\n" ..
      "Fetched " .. completed .. " / " .. #MODULES .. " modules.",
      "Your executor may be slow or rate-limiting. Try again, or use the single-file:\n" ..
      "github.com/OpenJawCode/bed-wars-script/blob/main/docs/bw-singlefile.lua"
    )
    return
  end
  task.wait(0.1)
end

local fetchElapsed = tick() - fetchStartTime
print(string.format("[bw-loader] Fetched %d modules in %.1fs", completed, fetchElapsed))

-- If any modules failed, show a warning
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

updateSplash(#MODULES + 1, #MODULES + 1, "modules")
print("[bw-loader] All modules fetched. Initializing runtime…")

-- Step 3: build a runtime that injects the loaded sources into _BW
local getgenv = getgenv or function() return _G end
local _BW = getgenv()
if not _BW then _BW = _G end
_BW._BW = _BW

-- v1.5: Phase 3 — wrap each loadstring in pcall so a single module
-- error doesn't kill the entire loader. The error is logged and
-- the module is skipped.
for path, src in pairs(sources) do
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
  elseif name == "bedwars_anticheat" then var = "Anticheat"
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
    local ok, mod = pcall(function() return loadstring(src, name)() end)
    if ok and mod ~= nil then
      _BW[var] = mod
    else
      warn(string.format("[bw-loader] Module '%s' failed to load: %s",
        path, tostring(mod)))
      table.insert(failed, { path = path, err = tostring(mod) })
    end
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
    "If the FAB (green ⚡) doesn't appear, run bw.test() in the executor\n" ..
    "console to see which executor functions are available."
  )
  return
end

dismissSplash(true)
print("[bw-loader] Done.")
