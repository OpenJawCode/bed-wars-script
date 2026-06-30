-- main.lua
-- Entry point. loadstring-compatible: loadstring(game:HttpGet(URL))()
--
-- Boots the script in this order:
--   1. Load config
--   2. Init the Workspace entity library (10Hz refresh loop)
--   3. Bootstrap Knit + extract all remote names (asynchronously — Bedwars may
--      still be loading when the script runs)
--   4. Build the UI (window, tabs, sections, toggles/sliders per feature)
--   5. Wire each toggle to its feature
--   6. Show the FAB (floating action button) — user taps it to open the menu
--
-- All features are off by default. The user enables them via the UI.

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ─── Package registry ───────────────────────────────────────────────────────
-- CRITICAL: modules loaded via loadstring have no `script` instance, so they
-- can't use `require(script.Parent...)`. Instead, we register every module
-- in a global table (getgenv()._BW or _G._BW) that modules read from.
-- This is the dependency injection layer.
if getgenv then
  getgenv()._BW = {}
else
  _G._BW = {}
end

local function setPkg(name, module)
  if getgenv then
    getgenv()._BW[name] = module
  else
    _G._BW[name] = module
  end
  return module
end

-- ─── Resolve local paths ────────────────────────────────────────────────────
-- When loaded via loadstring, `script` is nil. We fetch each module from the
-- GitHub raw URL, execute it, and register it in the package table.

local SOURCE_BASE = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/src"

-- Generic loader: fetches a module, executes it, registers it in _BW, returns it.
local function loadModule(name, path)
  local url = SOURCE_BASE .. "/" .. path
  local ok, source = pcall(function()
    return game:HttpGet(url, true)
  end)
  if not ok or not source then
    warn("[bw-script] Failed to load: " .. path)
    return nil
  end
  local fn, err = loadstring(source, path)
  if not fn then
    warn("[bw-script] Parse error in " .. path .. ": " .. tostring(err))
    return nil
  end
  local mod = fn()
  if mod then setPkg(name, mod) end
  return mod
end

-- ─── Load order (dependencies first) ────────────────────────────────────────
-- Each loadModule(NAME, path) registers the module as _BW.NAME for later lookups.
local Logger      = loadModule("Logger",     "util/logger.lua")
local Theme       = loadModule("Theme",      "ui/theme.lua")
local Tween       = loadModule("Tween",      "util/tween.lua")
local Dragger     = loadModule("Dragger",    "util/dragger.lua")
local Input       = loadModule("Input",      "util/input.lua")
local Projection  = loadModule("Projection", "util/projection.lua")
local Anim        = loadModule("Anim",       "ui/animations.lua")
local Icons       = loadModule("Icons",      "ui/icons.lua")
local Toast       = loadModule("Toast",      "ui/toast.lua")
local Rotation    = loadModule("Rotation",   "ui/rotation.lua")
local Library     = loadModule("Library",    "ui/library.lua")
local Config      = loadModule("Config",     "config.lua")
local PlaceId     = loadModule("PlaceId",    "game/placeid.lua")
local Services    = loadModule("Services",   "game/services.lua")
local Remotes     = loadModule("Remotes",    "game/remotes.lua")
local GameWksp    = loadModule("GameWksp",   "game/workspace.lua")
local Anticheat  = loadModule("Anticheat",  "game/bedwars_anticheat.lua")
if Anticheat and Anticheat.init then Anticheat.init() end

-- Features
local Killaura    = loadModule("Killaura",   "features/killaura.lua")
local Reach       = loadModule("Reach",      "features/reach.lua")
local Aimbot      = loadModule("Aimbot",     "features/aimbot.lua")
local Fly         = loadModule("Fly",        "features/fly.lua")
local Speed       = loadModule("Speed",      "features/speed.lua")
local Noclip      = loadModule("Noclip",     "features/noclip.lua")
local Magnet      = loadModule("Magnet",     "features/magnet.lua")
local Generator   = loadModule("Generator",  "features/generator.lua")
local BedAura     = loadModule("BedAura",    "features/bedaura.lua")
local Shop        = loadModule("Shop",       "features/shop.lua")
local AntiAFK     = loadModule("AntiAFK",    "features/antiafk.lua")
local AutoRejoin  = loadModule("AutoRejoin", "features/autorejoin.lua")
local Spy         = loadModule("Spy",        "features/spy.lua")
local ESP         = loadModule("ESP",        "features/esp.lua")

-- ─── Boot sequence ──────────────────────────────────────────────────────────
local function boot()
  -- 1. Config
  Config.load()
  Logger.info("Config loaded")

  -- 2. Workspace entity library
  GameWksp.init()

  -- 3. Knit bootstrap (async — Bedwars may still be loading)
  task.spawn(function()
    local ok = Remotes.bootstrap(60)
    if ok then
      Remotes.extractAll()
    end
  end)

  -- 4. Build UI
  local Window = Library:CreateWindow({
    Name = "Bedwars Script",
    Accent = Theme.Color.Accent,
  })

  -- Panic callback (called by status bar ⚠ PANIC button + RightCtrl)
  Window.onPanic = function()
    Killaura.setEnabled(false)
    Reach.setEnabled(false)
    Aimbot.setEnabled(false)
    Fly.setEnabled(false)
    Speed.setEnabled(false)
    Noclip.setEnabled(false)
    Magnet.setEnabled(false)
    Generator.setEnabled(false)
    BedAura.setEnabled(false)
    Shop.setEnabled(false)
    ESP.setEnabled(false)
    Library:Notify({ Title = "⚠ PANIC", Content = "All features disabled.", Duration = 3 })
  end
  Input.onKeyDown("RightControl", Window.onPanic)

  -- ─── Combat tab ──────────────────────────────────────────────────────
  local combatTab = Window:CreateTab("Combat", Icons.Unicode.Combat)
  local combatSec = combatTab:CreateSection("Offense")

  combatSec:CreateToggle({
    Name = "Killaura",
    Icon = "⚔",
    CurrentValue = Config.get("killaura_enabled"),
    Callback = function(v) Killaura.setEnabled(v) end,
  })
  combatSec:CreateSlider({
    Name = "Killaura Range",
    Range = {5, 40},
    CurrentValue = Config.get("killaura_range"),
    Suffix = " studs",
    Callback = function(v) Killaura.setRange(v) end,
  })
  combatSec:CreateSlider({
    Name = "Killaura Speed",
    Range = {5, 30},
    CurrentValue = Config.get("killaura_speed"),
    Suffix = " Hz",
    Callback = function(v) Killaura.setSpeed(v) end,
  })
  combatSec:CreateToggle({
    Name = "Reach Extension",
    Icon = "↔",
    CurrentValue = Config.get("reach_enabled"),
    Callback = function(v) Reach.setEnabled(v) end,
  })
  combatSec:CreateSlider({
    Name = "Reach Distance",
    Range = {15, 50},
    CurrentValue = Config.get("reach_distance"),
    Suffix = " studs",
    Callback = function(v) Reach.setDistance(v) end,
  })
  combatSec:CreateToggle({
    Name = "Aimbot (smooth)",
    Icon = "◎",
    CurrentValue = Config.get("aimbot_enabled"),
    Callback = function(v) Aimbot.setEnabled(v) end,
  })
  combatSec:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {1, 20},
    CurrentValue = Config.get("aimbot_smoothness"),
    Callback = function(v) Aimbot.setSmoothness(v) end,
  })

  -- ─── Visuals tab ─────────────────────────────────────────────────────
  local visTab = Window:CreateTab("Visuals", Icons.Unicode.Visuals)
  local visSec = visTab:CreateSection("ESP")

  visSec:CreateToggle({
    Name = "Player ESP",
    Icon = "◉",
    CurrentValue = Config.get("esp_players"),
    Callback = function(v)
      ESP.setShowPlayers(v)
      ESP.setEnabled(v or Config.get("esp_beds") or Config.get("esp_generators") or Config.get("esp_items"))
    end,
  })
  visSec:CreateToggle({
    Name = "Bed ESP",
    Icon = "▤",
    CurrentValue = Config.get("esp_beds"),
    Callback = function(v)
      ESP.setShowBeds(v)
      ESP.setEnabled(Config.get("esp_players") or v or Config.get("esp_generators") or Config.get("esp_items"))
    end,
  })
  visSec:CreateToggle({
    Name = "Generator / Item ESP",
    Icon = "◈",
    CurrentValue = Config.get("esp_generators"),
    Callback = function(v)
      ESP.setShowGens(v)
      ESP.setShowItems(v)
      ESP.setEnabled(Config.get("esp_players") or Config.get("esp_beds") or v)
    end,
  })
  visSec:CreateToggle({
    Name = "Tracers",
    Icon = "➤",
    CurrentValue = Config.get("esp_tracers"),
    Callback = function(v) ESP.setShowTracers(v) end,
  })
  visSec:CreateSlider({
    Name = "ESP Distance",
    Range = {50, 500},
    CurrentValue = Config.get("esp_distance"),
    Suffix = " studs",
    Callback = function(v) ESP.setMaxDistance(v) end,
  })

  -- ─── Movement tab ────────────────────────────────────────────────────
  local moveTab = Window:CreateTab("Move", Icons.Unicode.Move)
  local moveSec = moveTab:CreateSection("Movement")

  moveSec:CreateToggle({
    Name = "Fly (noclip + velocity)",
    Icon = "➤",
    CurrentValue = Config.get("fly_enabled"),
    Callback = function(v) Fly.setEnabled(v) end,
  })
  moveSec:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    CurrentValue = Config.get("fly_speed"),
    Suffix = " studs/s",
    Callback = function(v) Fly.setSpeed(v) end,
  })
  moveSec:CreateToggle({
    Name = "Speed",
    Icon = "»",
    CurrentValue = Config.get("speed_enabled"),
    Callback = function(v) Speed.setEnabled(v) end,
  })
  moveSec:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    CurrentValue = Config.get("speed_value"),
    Callback = function(v) Speed.setValue(v) end,
  })
  moveSec:CreateToggle({
    Name = "Noclip",
    Icon = "▣",
    CurrentValue = Config.get("noclip_enabled"),
    Callback = function(v) Noclip.setEnabled(v) end,
  })

  -- ─── World tab ───────────────────────────────────────────────────────
  local worldTab = Window:CreateTab("World", Icons.Unicode.World)
  local worldSec = worldTab:CreateSection("Resources")

  worldSec:CreateToggle({
    Name = "Magnet (whole map)",
    Icon = "✦",
    CurrentValue = Config.get("magnet_enabled"),
    Callback = function(v) Magnet.setEnabled(v) end,
  })
  worldSec:CreateSlider({
    Name = "Magnet Radius",
    Range = {50, 9999},
    CurrentValue = Config.get("magnet_radius"),
    Suffix = " studs",
    Callback = function(v) Magnet.setRadius(v) end,
  })
  worldSec:CreateToggle({
    Name = "Generator Auto-Collect",
    Icon = "◈",
    CurrentValue = Config.get("generator_enabled"),
    Callback = function(v) Generator.setEnabled(v) end,
  })
  worldSec:CreateSlider({
    Name = "Generator Radius",
    Range = {10, 100},
    CurrentValue = 30,
    Suffix = " studs",
    Callback = function(v) Generator.setRadius(v) end,
  })
  worldSec:CreateToggle({
    Name = "Bed Aura (auto-break)",
    Icon = "▤",
    CurrentValue = Config.get("bedaura_enabled"),
    Callback = function(v) BedAura.setEnabled(v) end,
  })
  worldSec:CreateSlider({
    Name = "Bed Aura Radius",
    Range = {10, 100},
    CurrentValue = 30,
    Suffix = " studs",
    Callback = function(v) BedAura.setRadius(v) end,
  })

  local shopSec = worldTab:CreateSection("Shop")
  shopSec:CreateToggle({
    Name = "Auto-Buy",
    Icon = "$",
    CurrentValue = Config.get("shop_enabled"),
    Callback = function(v) Shop.setEnabled(v) end,
  })
  shopSec:CreateDropdown({
    Name = "Item",
    Options = {"iron_sword", "diamond_sword", "wool_white", "stone", "end_stone", "obsidian", "golden_apple"},
    CurrentOption = Config.get("shop_item"),
    Callback = function(v) Shop.setItem(v) end,
  })

  -- ─── Misc tab ────────────────────────────────────────────────────────
  local miscTab = Window:CreateTab("Misc", Icons.Unicode.Misc)
  local miscSec = miscTab:CreateSection("Quality of life")

  -- PANIC BUTTON — big, red, always-visible on touch devices.
  -- Disables every feature instantly. Also wired to RightCtrl on desktop.
  miscSec:CreateButton({
    Name = "⚠ PANIC — disable everything",
    Icon = "⚠",
    Callback = function()
      Killaura.setEnabled(false)
      Aimbot.setEnabled(false)
      Fly.setEnabled(false)
      Speed.setEnabled(false)
      Noclip.setEnabled(false)
      Magnet.setEnabled(false)
      Generator.setEnabled(false)
      BedAura.setEnabled(false)
      Shop.setEnabled(false)
      Library:Notify({ Title = "PANIC", Content = "All features disabled.", Duration = 3 })
    end,
  })

  miscSec:CreateToggle({
    Name = "Anti-AFK",
    Icon = "◐",
    CurrentValue = Config.get("antiafk_enabled"),
    Callback = function(v) AntiAFK.setEnabled(v) end,
  })
  miscSec:CreateToggle({
    Name = "Auto-Rejoin",
    Icon = "↻",
    CurrentValue = Config.get("autorejoin_enabled"),
    Callback = function(v) AutoRejoin.setEnabled(v) end,
  })

  local devSec = miscTab:CreateSection("Developer")
  devSec:CreateToggle({
    Name = "Remote Spy (log FireServer/InvokeServer)",
    Icon = "◬",
    CurrentValue = Config.get("spy_enabled"),
    Callback = function(v)
      if v then Spy.enable() else Spy.disable() end
    end,
  })
  devSec:CreateButton({
    Name = "Print Remote Log to Console",
    Icon = "◬",
    Callback = function()
      local recent = Spy.getRecent(50)
      print("=== Spy Log (last 50) ===")
      for _, e in ipairs(recent) do
        print(string.format("[%s] %s:%s", os.date("%H:%M:%S", e.time), e.name, e.method))
      end
    end,
  })
  devSec:CreateButton({
    Name = "Re-extract Remotes",
    Icon = "↻",
    Callback = function()
      task.spawn(function()
        Remotes.extractAll()
        Library:Notify({ Title = "Remotes", Content = "Re-extraction complete", Duration = 3 })
      end)
    end,
  })
  devSec:CreateButton({
    Name = "Save Config",
    Icon = "✦",
    Callback = function() Config.save() end,
  })

  -- (panic moved to Window.onPanic + status bar button)

  -- ─── Re-wire Fly on character respawn ────────────────────────────────
  Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    Fly.onCharacterAdded()
  end)

  -- ─── Boot notification (v1.3 — uses Toast module) ───────────────────
  if _BW.Toast and _BW.Toast.success then
    _BW.Toast.success("Loaded", "Tap ⚡ to open · ⚠ STOP to disable all")
  else
    Library:Notify({
      Title = "Bedwars Script",
      Content = "Loaded. Tap ⚡ to open. Use ⚠ PANIC to disable all.",
      Duration = 6,
    })
  end

  Logger.info("Boot complete — UI ready")
  return Window
end

-- ─── Boot entry point with visible error handling ────────────────────────
-- Install a splash FIRST (so the user sees feedback even if boot is slow).
-- If boot errors, show a visible BOOT FAILED overlay (so it's not silent).
local function showBootError(errMsg)
  -- Inline minimal error overlay (no dependencies, must work even if
  -- modules failed to load).
  local ok_p, parent = pcall(function()
    if gethui then return gethui() end
    return game:GetService("CoreGui")
  end)
  if not ok_p then return end

  local gui = Instance.new("ScreenGui")
  gui.Name = "BWBootError"
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
  hdr.Size = UDim2.new(1, -16, 0, 40)
  hdr.Position = UDim2.new(0, 8, 0, 0)
  hdr.BackgroundTransparency = 1
  hdr.Text = "  ⚠  BOOT FAILED"
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
  body.Text = tostring(errMsg or "Unknown error")
  body.TextColor3 = Color3.fromRGB(255, 200, 200)
  body.Font = Enum.Font.Code
  body.TextSize = 11
  body.TextXAlignment = Enum.TextXAlignment.Left
  body.TextYAlignment = Enum.TextYAlignment.Top
  body.TextWrapped = true
  body.ZIndex = 101

  warn("[bw-script] BOOT FAILED: " .. tostring(errMsg))
  print("[bw-script] BOOT FAILED: " .. tostring(errMsg))
end

local ok, err = pcall(boot)
if not ok then
  showBootError(err)
end

-- Expose a console helper for debugging
-- Usage in executor console:
--   bw.verify()      — show what's loaded, what's missing
--   bw.fix()         — re-run remote extraction
--   bw.reload()      — destroy + recreate the UI
--   bw.panic()       — manually trigger panic
if getgenv then
  getgenv().bw = getgenv().bw or {}
  getgenv().bw.verify = function()
    local BW = getgenv()._BW
    if not BW then
      return print("[bw] No _BW registry. Script never loaded.")
    end
    print("[bw] === Script Status ===")
    print("[bw] Registry size: " .. tostring(#(function() local c = 0 for _ in pairs(BW) do c = c + 1 end return c end)()))
    local modules = { "Logger", "Theme", "Tween", "Dragger", "Input",
                      "Anim", "Icons", "Library", "Config", "PlaceId",
                      "Services", "Remotes", "GameWksp", "Killaura",
                      "Reach", "Aimbot", "Fly", "Speed", "Noclip",
                      "Magnet", "Generator", "BedAura", "Shop",
                      "AntiAFK", "AutoRejoin", "Spy", "ESP" }
    for _, name in ipairs(modules) do
      local ok = BW[name] ~= nil
      print("[bw]   " .. name .. ": " .. (ok and "OK" or "MISSING"))
    end
  end
  getgenv().bw.fix = function()
    print("[bw] Re-extracting remotes...")
    if Remotes and Remotes.extractAll then
      Remotes.extractAll()
    end
  end
  getgenv().bw.panic = function()
    if Window and Window.onPanic then
      Window.onPanic()
    end
  end
  print("[bw] Loaded. Run bw.verify() in console to check status.")
end
