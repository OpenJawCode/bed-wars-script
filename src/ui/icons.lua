-- src/ui/icons.lua
-- Hybrid icon strategy: Unicode text glyphs (default) + rbxassetid fallback.
-- WHY Unicode: zero asset risk, instant render, semantic.
-- WHY hybrid: VapeV4-style rbxassetid icons look more premium when they load.
-- Web dev mental model: this is our icon SVG sprite with a CDN fallback.

local Icons = {}

-- ─── Unicode glyphs (PRIMARY — used by default) ────────────────────────────
Icons.Unicode = {
  Combat    = "⚔";
  Visuals   = "◉";
  Move      = "➤";
  World     = "◆";
  Misc      = "✦";
  Killaura  = "⚔";
  Reach     = "↔";
  Aimbot    = "◎";
  ESP       = "◉";
  Fly       = "➤";
  Speed     = "»";
  Noclip    = "▣";
  Magnet    = "✦";
  Shop      = "$";
  Generator = "◈";
  Bed       = "▤";
  AntiAFK   = "◐";
  AutoRejoin= "↻";
  Spy       = "◬";
  Search    = "⌕";
  Close     = "✕";
  Panic     = "⚠";
  Check     = "✓";
  Warning   = "⚠";
  Info      = "ⓘ";
  Settings  = "✦";
  FAB       = "⚡";
  Lock      = "◉";
  Key       = "⚷";
  Drag      = "▦";
  Chevron   = "›";
  Plus      = "+";
  Minus     = "−";
  FPS       = "F";
  Ping      = "P";
  Active    = "A";
}

-- ─── Verified Roblox asset IDs (FALLBACK — v1.2 swap) ────────────────────
-- From VapeV4's public repo. Use Icons.applyIcon with a number spec.
Icons.Verified = {
  Combat    = 14368312652,
  Visuals   = 14368350193,
  Move      = 14368359107,
  World     = 14368362492,
  Misc      = 14368318994,
  Search    = 14425646684,
  Close     = 14368309446,
  Warning   = 14368361552,
  Info      = 14368324807,
  Logo      = 14368322199,
}

Icons.FabIcon = "⚡"

-- ─── applyIcon helper ─────────────────────────────────────────────────────
-- Single entry point for both text glyphs and rbxassetid.
function Icons.applyIcon(parent, spec, color, size)
  color = color or Color3.fromRGB(16, 185, 129)
  size  = size  or 18

  if type(spec) == "number" then
    local img = Instance.new("ImageLabel")
    img.Parent = parent
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. tostring(spec)
    img.ImageColor3 = color
    img.Size = UDim2.fromOffset(size, size)
    return img
  else
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(spec)
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = size
    lbl.Size = UDim2.fromOffset(size, size)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    return lbl
  end
end

-- ─── Tab metadata ──────────────────────────────────────────────────────────
Icons.Tabs = {
  { name = "Combat",  icon = "⚔" },
  { name = "Visuals", icon = "◉" },
  { name = "Move",    icon = "➤" },
  { name = "World",   icon = "◆" },
  { name = "Misc",    icon = "✦" },
}

-- ─── Feature icon lookup ──────────────────────────────────────────────────
Icons.Feature = {
  killaura       = "⚔",
  reach          = "↔",
  aimbot         = "◎",
  fly            = "➤",
  speed          = "»",
  noclip         = "▣",
  magnet         = "✦",
  generator      = "◈",
  bedaura        = "▤",
  shop           = "$",
  antiafk        = "◐",
  autorejoin     = "↻",
  spy            = "◬",
  esp_players    = "◉",
  esp_beds       = "▤",
  esp_generators = "◈",
  esp_items      = "✦",
  esp_tracers    = "➤",
}

return Icons
