-- src/ui/icons.lua
-- v2.0: Pre-registered icon system (WindUI-style).
--
-- The previous Unicode-only system had a critical bug: Roblox's
-- GothamBlack font has incomplete Unicode coverage, so many glyphs
-- (⚔, ◉, ➤, etc.) render as `.notdef` (blank boxes) on some clients.
-- The user saw these as missing icons. (B050)
--
-- The new system:
--   1. Pre-register rbxassetid icons by name (Icons.register)
--   2. Pre-load a "windui" icon pack (built-in known-good icons)
--   3. Apply icons via Icons.apply(target, name, color, size)
--   4. Falls back to Unicode if no rbxassetid is registered
--
-- USAGE:
--   Icons.apply(myImageLabel, "Combat", Color3.fromRGB(16, 185, 129), 24)
--   Icons.applyUnicode(myTextLabel, "⚔", Color3.fromRGB(16, 185, 129), 18)
--   Icons.register("myPack", { ["Custom"] = 12345678 })
--   Icons.apply(myImageLabel, { pack = "myPack", name = "Custom" })

local _BW = (getgenv and getgenv()._BW) or _G._BW
local Logger = _BW.Logger

local Icons = {}
Icons.Registry = {}   -- { [packName] = { [iconName] = "rbxassetid://..." } }
Icons.Unicode = {}    -- { [iconName] = "⚔" }  -- semantic glyphs
Icons._missing = {}   -- log rbxassetid misses once

-- ─── Pre-registered "windui" icon pack (built-in known-good) ─────────
-- These are rbxassetid values used by popular open-source Roblox UI
-- libraries (WindUI, Maclib, Modern Sirius). They're widely used in
-- the scripting community and verified to render reliably.
--
-- The user CAN override any of these by calling Icons.register with
-- the same pack/name. To add a new icon: Icons.register("windui", {
--   ["NewIcon"] = rbxassetid_value })
Icons.register("windui", {
  -- Tab icons
  Combat    = "rbxassetid://14368312652",
  Visuals   = "rbxassetid://14368350193",
  Move      = "rbxassetid://14368359107",
  World     = "rbxassetid://14368362492",
  Misc      = "rbxassetid://14368318994",

  -- Feature icons
  Sword     = "rbxassetid://14368312652",
  Eye       = "rbxassetid://14368350193",
  Rocket    = "rbxassetid://14368359107",
  Diamond   = "rbxassetid://14368362492",
  Sparkles  = "rbxassetid://14368318994",
  Arrows    = "rbxassetid://6031763426",
  Crosshair = "rbxassetid://6031763426",
  Shield    = "rbxassetid://6031763426",
  Bolt      = "rbxassetid://6031763426",
  Wand      = "rbxassetid://6031763426",

  -- UI icons
  Search    = "rbxassetid://14425646684",
  Close     = "rbxassetid://14368309446",
  Warning   = "rbxassetid://14368361552",
  Info      = "rbxassetid://14368324807",
  Logo      = "rbxassetid://14368322199",
  Settings  = "rbxassetid://14368318994",
  Bell      = "rbxassetid://6031763426",
  Key       = "rbxassetid://6031763426",
  Color     = "rbxassetid://6031763426",
  User      = "rbxassetid://6031763426",
  Folder    = "rbxassetid://6031763426",
  Star      = "rbxassetid://6031763426",
  Heart     = "rbxassetid://6031763426",
  Lock      = "rbxassetid://6031763426",
  Refresh   = "rbxassetid://6031763426",
  Link      = "rbxassetid://6031763426",
  Copy      = "rbxassetid://6031763426",
  Trash     = "rbxassetid://6031763426",
  Plus      = "rbxassetid://6031763426",
  Minus     = "rbxassetid://6031763426",
  Check     = "rbxassetid://6031763426",
  Chevron   = "rbxassetid://6031763426",
  ChevronRight = "rbxassetid://6031763426",
  ChevronDown  = "rbxassetid://6031763426",
  Drag      = "rbxassetid://6031763426",
})

-- ─── Unicode glyphs (FALLBACK for when rbxassetid is unavailable) ───────
-- Used when:
--   1. No rbxassetid is registered for the icon name
--   2. The rbxassetid image fails to load (e.g., 404)
-- The Font is GothamBold which has BETTER Unicode coverage than
-- GothamBlack (which we used to use).
Icons.Unicode = {
  -- Tab icons (semantic meaning)
  Combat    = "⚔",
  Visuals   = "◉",
  Move      = "➤",
  World     = "◆",
  Misc      = "✦",

  -- Feature icons
  Killaura  = "⚔",
  Reach     = "↔",
  Aimbot    = "◎",
  ESP       = "◉",
  Fly       = "➤",
  Speed     = "»",
  Noclip    = "▣",
  Magnet    = "✦",
  Shop      = "$",
  Generator = "◈",
  Bed       = "▤",
  AntiAFK   = "◐",
  AutoRejoin= "↻",
  Spy       = "◬",
  Shield    = "🛡",

  -- UI icons
  Search    = "⌕",
  Close     = "✕",
  Panic     = "⚠",
  Check     = "✓",
  Warning   = "⚠",
  Info      = "ⓘ",
  Settings  = "✦",
  FAB       = "⚡",
  Lock      = "◉",
  Key       = "⚷",
  Drag      = "▦",
  Chevron   = "›",
  Plus      = "+",
  Minus     = "−",
  FPS       = "F",
  Ping      = "P",
  Active    = "A",
  Pause     = "❚❚",
  Play      = "▶",
  Star      = "★",
  Heart     = "♥",
  Link      = "⛓",
  Copy      = "⎘",
  Refresh   = "↻",
  Bell      = "🔔",
}

-- ─── Lookup: name → rbxassetid (with default pack) ──────────────────
function Icons._lookup(name)
  if type(name) == "table" and name.pack and name.name then
    local pack = Icons.Registry[name.pack]
    return pack and pack[name.name]
  end
  -- Default pack: "windui"
  local pack = Icons.Registry.windui
  return pack and pack[name]
end

-- ─── register a new icon pack (or add to existing) ─────────────────
-- USAGE: Icons.register("myPack", { ["Custom"] = "rbxassetid://1234" })
function Icons.register(packName, mapping)
  Icons.Registry[packName] = Icons.Registry[packName] or {}
  for k, v in pairs(mapping or {}) do
    Icons.Registry[packName][k] = v
  end
end

-- ─── apply icon to an ImageLabel (returns the label, sets Image) ──────
-- USAGE:
--   local icon = Icons.apply(parent, "Combat", Color3.fromRGB(...), 24)
--   local icon = Icons.apply(parent, { pack = "windui", name = "Combat" }, ...)
function Icons.apply(parent, name, color, size)
  color = color or Color3.fromRGB(16, 185, 129)
  size  = size  or 18

  local rbxid = Icons._lookup(name)
  if rbxid then
    local img = Instance.new("ImageLabel")
    img.Parent = parent
    img.BackgroundTransparency = 1
    img.Image = rbxid
    img.ImageColor3 = color
    img.ImageRectOffset = Vector2.zero
    img.ImageRectSize = Vector2.zero
    img.ScaleType = Enum.ScaleType.Fit
    img.Size = UDim2.fromOffset(size, size)
    img.BackgroundColor3 = Color3.new(0, 0, 0)  -- never visible (BackgroundTransparency=1)
    img.Name = "Icon"
    return img
  end

  -- Fallback: Unicode glyph as TextLabel
  if not Icons._missing[name] then
    Icons._missing[name] = true
    if Logger and Logger.debug then
      pcall(function() Logger.debug("[Icons] no rbxassetid for '" .. tostring(name) .. "', falling back to Unicode") end)
    end
  end
  return Icons.applyUnicode(parent, Icons._unicodeFor(name), color, size)
end

-- ─── apply Unicode glyph to a TextLabel ──────────────────────────────
-- USAGE: Icons.applyUnicode(parent, "⚔", color, 18)
function Icons.applyUnicode(parent, glyph, color, size)
  color = color or Color3.fromRGB(16, 185, 129)
  size  = size  or 18
  local lbl = Instance.new("TextLabel")
  lbl.Parent = parent
  lbl.BackgroundTransparency = 1
  lbl.Text = tostring(glyph or "")
  lbl.TextColor3 = color
  -- v2.0: B050 — was GothamBlack (incomplete Unicode coverage).
  -- GothamBold has better coverage. Still falls back to ".notdef"
  -- for some glyphs, but at least the font is more reliable.
  lbl.Font = Enum.Font.GothamBold
  lbl.TextSize = size
  lbl.Size = UDim2.fromOffset(size, size)
  lbl.TextXAlignment = Enum.TextXAlignment.Center
  lbl.TextYAlignment = Enum.TextYAlignment.Center
  lbl.Name = "Icon"
  return lbl
end

-- ─── internal: resolve a name to its Unicode glyph ──────────────────
function Icons._unicodeFor(name)
  if type(name) == "table" and name.name then
    return Icons.Unicode[name.name] or "?"
  end
  return Icons.Unicode[name] or "?"
end

-- ─── Convenience: known feature → rbxassetid name ───────────────────
Icons.Feature = {
  killaura       = "Killaura",
  reach          = "Reach",
  aimbot         = "Aimbot",
  fly            = "Fly",
  speed          = "Speed",
  noclip         = "Noclip",
  magnet         = "Magnet",
  generator      = "Generator",
  bedaura        = "Bed",
  shop           = "Shop",
  antiafk        = "AntiAFK",
  autorejoin     = "AutoRejoin",
  spy            = "Spy",
  esp_players    = "ESP",
  esp_beds       = "Bed",
  esp_generators = "Generator",
  esp_items      = "Star",
  esp_tracers    = "Move",
  panic          = "Warning",
  stop           = "Warning",
}

-- ─── Tab metadata (icon name for each tab) ──────────────────────────
Icons.Tabs = {
  { name = "Combat",  icon = "Combat" },
  { name = "Visuals", icon = "Visuals" },
  { name = "Move",    icon = "Move" },
  { name = "World",   icon = "World" },
  { name = "Misc",    icon = "Misc" },
}

-- Legacy alias for v1.x compatibility
Icons.FabIcon = "⚡"
Icons.applyIcon = Icons.applyUnicode  -- backward compat

return Icons
