-- src/ui/theme.lua
-- Design tokens — single source of truth for ALL UI code.
-- Markdown mirror lives at docs/DESIGN.md.
--
-- Design DNA: deep dark + emerald accent (primary), gold (secondary), red (danger), blue (info).
-- One easing function everywhere (Quint). Heavy glass (low alpha).

local Theme = {}

-- ─── Colors ─────────────────────────────────────────────────────────────────
Theme.Color = {
  -- Surfaces
  Background      = Color3.fromRGB(10,  15,  26);
  Surface         = Color3.fromRGB(18,  22,  32);
  SurfaceRaised   = Color3.fromRGB(24,  30,  42);
  SurfaceInset    = Color3.fromRGB(14,  18,  26);
  SurfacePressed  = Color3.fromRGB(30,  36,  50);

  -- Borders
  Border          = Color3.fromRGB(255, 255, 255);
  BorderStrong    = Color3.fromRGB(255, 255, 255);

  -- Text
  TextPrimary     = Color3.fromRGB(240, 242, 248);
  TextSecondary   = Color3.fromRGB(160, 170, 188);
  TextMuted       = Color3.fromRGB(110, 120, 138);
  TextDisabled    = Color3.fromRGB( 80,  90, 108);

  -- Accent (emerald — primary)
  Accent          = Color3.fromRGB(16,  185, 129);
  AccentHover     = Color3.fromRGB(20,  205, 140);
  AccentPressed   = Color3.fromRGB(13,  160, 110);
  AccentGlow      = Color3.fromRGB(16,  185, 129);

  -- Accent secondary (gold)
  Gold            = Color3.fromRGB(245, 183,   0);
  GoldHover       = Color3.fromRGB(255, 195,  20);
  GoldPressed     = Color3.fromRGB(220, 160,   0);

  -- Status
  Success         = Color3.fromRGB(34,  197,  94);
  Danger          = Color3.fromRGB(239,  68,  68);
  DangerHover     = Color3.fromRGB(255,  90,  90);
  Info            = Color3.fromRGB(59,  130, 246);
  Warning         = Color3.fromRGB(245, 158,  11);

  -- Tab colors
  TabActive       = Color3.fromRGB(16,  185, 129);
  TabInactive     = Color3.fromRGB(140, 150, 168);

  -- Backdrop
  Backdrop        = Color3.fromRGB(0,   0,   0);

  -- Team colors
  TeamRed         = Color3.fromRGB(239,  68,  68);
  TeamBlue        = Color3.fromRGB(59,  130, 246);
  TeamGreen       = Color3.fromRGB(34,  197,  94);
  TeamYellow      = Color3.fromRGB(250, 204,  21);
  TeamNone        = Color3.fromRGB(160, 170, 188);

  -- Generator tiers
  TierIron        = Color3.fromRGB(180, 188, 200);
  TierGold        = Color3.fromRGB(250, 204,  21);
  TierDiamond     = Color3.fromRGB(96,  213, 255);
  TierEmerald     = Color3.fromRGB(52,  211, 153);
}

-- ─── Transparency (glass) — heavy glass so gameplay is visible ───────────
Theme.Alpha = {
  BackgroundOpaque  = 0;
  GlassPanel        = 0.06;
  GlassCard         = 0.10;
  GlassCardHover    = 0.06;
  GlassCardPressed  = 0.02;
  GlassInput        = 0.20;
  Backdrop          = 0.55;
  Border            = 0.92;
  BorderStrong      = 0.86;
  BorderAccent      = 0.20;  -- v2.0: B051 — was 0.50, too transparent to see
  AccentGlowOuter   = 0.60;
  AccentGlowInner   = 0.30;
  Overlay           = 0.40;
}

-- ─── Gradients (v1.3 — premium emerald + multi-tone gold) ────────────────
Theme.Gradient = {
  -- Emerald: diagonal gradient (top-left bright → bottom-right dark)
  Emerald = {
    Top    = Color3.fromRGB(20, 200, 140),    -- bright
    Bot    = Color3.fromRGB(13, 160, 110),    -- dark
    Angle  = 45,
  },
  -- Gold: multi-stop (champagne → standard → dark)
  Gold = {
    Light = Color3.fromRGB(255, 240, 180),    -- champagne
    Mid   = Color3.fromRGB(245, 183, 0),      -- standard gold
    Dark  = Color3.fromRGB(180, 130, 0),      -- dark gold
  },
}

-- ─── Typography ────────────────────────────────────────────────────────────
Theme.Font = {
  Display   = Enum.Font.GothamBlack;
  Heading   = Enum.Font.GothamBold;
  Body      = Enum.Font.GothamMedium;
  Label     = Enum.Font.Gotham;
  Caption   = Enum.Font.GothamMedium;
  Mono      = Enum.Font.Code;
  Tab       = Enum.Font.GothamBold;
  Icon      = Enum.Font.GothamBlack;
  IconSmall = Enum.Font.GothamBlack;
}

Theme.Size = {
  Display   = 18;
  Heading   = 15;
  Body      = 13;
  Label     = 12;
  Caption   = 10;
  Tab       = 13;
  Icon      = 18;
  IconSmall = 14;
  Title     = 16;
  Value     = 13;
}

-- ─── Radii (rounded everything) ────────────────────────────────────────────
Theme.Radius = {
  Pill       = 9999;   -- buttons, switches (full round)
  Card       = 12;     -- cards, panels
  Input      = 8;      -- text inputs, keybinds, dropdowns
  Toggle     = 9999;   -- iOS-style switch
  Small      = 6;      -- subtle rounding
  Bar        = 3;      -- thin bars
  FABShape   = 14;     -- v1.3: soft rounded square (NOT pill, NOT full round)
}

-- ─── Spacing (8pt grid) ────────────────────────────────────────────────────
Theme.Space = {
  XS   = 4;
  SM   = 8;
  MD   = 12;
  LG   = 16;
  XL   = 24;
  XXL  = 32;
}

-- ─── Touch targets (mobile-first) ──────────────────────────────────────────
Theme.Touch = {
  MinTarget       = 44;
  RowHeight       = 48;
  HeaderHeight    = 56;
  TopTabHeight    = 48;
  TopTabWidth     = 100;
  StatusBarHeight = 36;
  FABSize         = 56;
  FABMargin       = 12;
  PanicBtnHeight  = 44;
  SearchHeight    = 36;
}

-- ─── Motion (Quint everywhere) ─────────────────────────────────────────────
Theme.Motion = {
  Press      = 0.10;
  Tap        = 0.18;
  Open       = 0.32;
  Reveal     = 0.45;
  Boot       = 0.55;
  Glow       = 1.80;
  Hover      = 0.18;
  Snap       = 0.28;
  Backdrop   = 0.18;
}

Theme.Easing = {
  Press    = Enum.EasingStyle.Quint;
  Tap      = Enum.EasingStyle.Quint;
  Open     = Enum.EasingStyle.Quint;
  Reveal   = Enum.EasingStyle.Quint;
  Boot     = Enum.EasingStyle.Quint;
  Glow     = Enum.EasingStyle.Sine;     -- exception: sine for ambient breathing
  Hover    = Enum.EasingStyle.Quint;
  Snap     = Enum.EasingStyle.Quint;
  Backdrop = Enum.EasingStyle.Quint;
}

-- ─── Z-index scale ─────────────────────────────────────────────────────────
Theme.Z = {
  Base          = 1;
  Backdrop      = 40;
  FAB           = 50;
  Window        = 60;
  WindowContent = 61;
  Notifications = 100;
  Panicked      = 200;
}

-- ─── Window dimensions ─────────────────────────────────────────────────────
Theme.Window = {
  WidthPctPortrait  = 0.94;   -- 94% wide in portrait
  HeightPctPortrait = 0.82;   -- 82% tall in portrait
  WidthPctLandscape = 0.80;   -- 80% wide in landscape (wider UI)
  HeightPctLandscape= 0.92;   -- 92% tall in landscape
  -- Legacy (for back-compat with the existing CreateWindow):
  WidthPct  = 0.94;
  HeightPct = 0.82;
  Margin    = 12;
  CornerRadius = Theme.Radius.Card;
  HeaderH   = 56;
  TopTabH   = 48;
  StatusH   = 36;
}

-- ─── Theme presets (v2.0) ──────────────────────────────────────────────────
-- 4 named presets. User can switch via Theme.apply(name).
-- The Emerald preset is the default (matches the user's brand).
Theme.Presets = {
  Emerald = {
    Accent        = Color3.fromRGB(16,  185, 129),
    AccentHover   = Color3.fromRGB(20,  205, 140),
    AccentPressed = Color3.fromRGB(13,  160, 110),
    AccentGlow    = Color3.fromRGB(16,  185, 129),
    Gold          = Color3.fromRGB(245, 183,   0),
  },
  Amethyst = {
    Accent        = Color3.fromRGB(139,  92, 246),
    AccentHover   = Color3.fromRGB(155, 110, 255),
    AccentPressed = Color3.fromRGB(122,  78, 220),
    AccentGlow    = Color3.fromRGB(139,  92, 246),
    Gold          = Color3.fromRGB(245, 183,   0),
  },
  Sapphire = {
    Accent        = Color3.fromRGB(59,  130, 246),
    AccentHover   = Color3.fromRGB(75,  145, 255),
    AccentPressed = Color3.fromRGB(45,  110, 220),
    AccentGlow    = Color3.fromRGB(59,  130, 246),
    Gold          = Color3.fromRGB(245, 183,   0),
  },
  Rose = {
    Accent        = Color3.fromRGB(244,  63,  94),
    AccentHover   = Color3.fromRGB(255,  80, 110),
    AccentPressed = Color3.fromRGB(220,  44,  72),
    AccentGlow    = Color3.fromRGB(244,  63,  94),
    Gold          = Color3.fromRGB(245, 183,   0),
  },
}

Theme.CurrentPreset = "Emerald"

-- Apply a preset to Theme.Color. The user can also call this
-- at runtime to switch themes (e.g., from a Colorpicker).
function Theme.apply(presetName)
  local preset = Theme.Presets[presetName] or Theme.Presets.Emerald
  Theme.CurrentPreset = presetName
  for k, v in pairs(preset) do
    Theme.Color[k] = v
  end
end

-- Apply the default preset on load so Theme.Color.Accent is correct
Theme.apply("Emerald")

return Theme
