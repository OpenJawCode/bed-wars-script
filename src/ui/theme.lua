-- src/ui/theme.lua
-- Dark luxe glassmorphic design tokens. Single source of truth for all colors,
-- fonts, sizes, radii, motion durations. Inspired by Abdulrahman's design DNA
-- (deep dark bg, one strong accent, glass surfaces, rounded everything).
--
-- Web dev mental model: this is our tailwind.config.js + design-tokens.json.

local Theme = {}

-- ─── Colors ─────────────────────────────────────────────────────────────────
-- All colors are Color3.fromRGB. Transparency is separate (we want glass).
Theme.Color = {
  -- Surfaces (deep dark, never white)
  Background      = Color3.fromRGB(10,  15,  26);  -- #0A0F1A — app bg
  Surface         = Color3.fromRGB(18,  22,  32);  -- glass panel base
  SurfaceRaised   = Color3.fromRGB(24,  30,  42);  -- cards, hover
  SurfaceInset    = Color3.fromRGB(14,  18,  26);  -- inputs, wells

  -- Borders / hairlines
  Border          = Color3.fromRGB(255, 255, 255); -- used at 0.08 transparency
  BorderStrong    = Color3.fromRGB(255, 255, 255); -- used at 0.14 transparency

  -- Text
  TextPrimary     = Color3.fromRGB(240, 242, 248);
  TextSecondary   = Color3.fromRGB(160, 170, 188);
  TextMuted       = Color3.fromRGB(110, 120, 138);

  -- Accent (single strong color — emerald for "premium")
  Accent          = Color3.fromRGB(16,  185, 129); -- #10B981 emerald
  AccentHover     = Color3.fromRGB(20,  205, 140);
  AccentPressed   = Color3.fromRGB(13,  160, 110);
  AccentGlow      = Color3.fromRGB(16,  185, 129); -- for neon box-shadow effect

  -- Status
  Success         = Color3.fromRGB(34,  197, 94);
  Warning         = Color3.fromRGB(245, 158, 11);
  Danger          = Color3.fromRGB(239, 68,  68);
  Info            = Color3.fromRGB(59,  130, 246);

  -- Team colors (for ESP)
  TeamRed         = Color3.fromRGB(239, 68,  68);
  TeamBlue        = Color3.fromRGB(59,  130, 246);
  TeamGreen       = Color3.fromRGB(34,  197, 94);
  TeamYellow      = Color3.fromRGB(250, 204, 21);
  TeamNone        = Color3.fromRGB(160, 170, 188);

  -- Generator tiers
  TierIron        = Color3.fromRGB(180, 188, 200);
  TierGold        = Color3.fromRGB(250, 204, 21);
  TierDiamond     = Color3.fromRGB(96,  213, 255);
  TierEmerald     = Color3.fromRGB(52,  211, 153);
}

-- ─── Transparency (glass) ──────────────────────────────────────────────────
-- Roblox uses 0 = opaque, 1 = invisible. So 0.72 = 28% visible (heavy glass).
Theme.Alpha = {
  BackgroundOpaque = 0;     -- app bg (no glass)
  GlassPanel       = 0.18;  -- main window — slight transparency
  GlassCard        = 0.28;  -- element rows
  GlassCardHover   = 0.18;
  GlassInput       = 0.45;  -- text inputs, wells
  Border           = 0.92;  -- subtle hairline (mostly transparent)
  BorderStrong     = 0.86;
  Overlay          = 0.40;  -- modal backdrop
}

-- ─── Typography ────────────────────────────────────────────────────────────
-- Roblox built-in fonts. We use Gotham family for premium feel.
Theme.Font = {
  Display   = Enum.Font.GothamBlack;
  Heading   = Enum.Font.GothamBold;
  Body      = Enum.Font.GothamMedium;
  Label     = Enum.Font.Gotham;
  Mono      = Enum.Font.Code;
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
}

-- ─── Radii (rounded everything) ────────────────────────────────────────────
Theme.Radius = {
  Pill    = 9999;   -- buttons (rounded-full)
  Card    = 12;     -- cards, panels
  Input   = 8;      -- inputs, wells
  Toggle  = 9999;   -- iOS-style switch
  Small   = 6;      -- subtle rounding
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
-- Apple HIG: 44pt min. We use 56pt for thumb comfort on Motorola Edge 20.
Theme.Touch = {
  MinTarget   = 56;    -- buttons, toggles
  RowHeight   = 56;    -- list rows
  TabHeight   = 48;    -- bottom tab bar
  FloatingBtn = 56;    -- floating action button
}

-- ─── Motion (spring-ish) ───────────────────────────────────────────────────
Theme.Motion = {
  Press     = 0.10;   -- scale-on-press
  Tap       = 0.18;   -- toggle knob
  Open      = 0.32;   -- panel open
  Reveal    = 0.45;   -- staggered reveal
  Boot      = 0.60;   -- window boot
}

-- Easing styles matched to motion durations.
Theme.Easing = {
  Press   = Enum.EasingStyle.Quint;
  Tap     = Enum.EasingStyle.Quint;
  Open    = Enum.EasingStyle.Quint;
  Reveal  = Enum.EasingStyle.Exponential;
  Boot    = Enum.EasingStyle.Quint;
}

return Theme
