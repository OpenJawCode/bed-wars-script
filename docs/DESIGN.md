# DESIGN.md

> Design tokens for the Bedwars Script. This is a **markdown mirror** of `src/ui/theme.lua` for non-Lua readers (designers, reviewers, AI agents reading docs). The Lua source is authoritative.

**Reference device:** Motorola Edge 20 (1080×2400 portrait, 393pt logical width, 144Hz, Snapdragon 778G).

**Design DNA source:** [jensen-vvs](../) and [grannsjovvs](../) — Abdulrahman's existing premium client sites.

---

## Color

| Token | Hex | RGB | Usage |
|---|---|---|---|
| **Background** | `#0A0F1A` | 10, 15, 26 | App bg (never white) |
| **Surface** | `#121620` | 18, 22, 32 | Glass panel base |
| **SurfaceRaised** | `#181E2A` | 24, 30, 42 | Cards, hover |
| **SurfaceInset** | `#0E121A` | 14, 18, 26 | Inputs, wells |
| **Border** | `#FFFFFF` (alpha 0.08) | 255, 255, 255 | Hairline (mostly transparent) |
| **BorderStrong** | `#FFFFFF` (alpha 0.14) | 255, 255, 255 | Emphasized hairline |
| **TextPrimary** | `#F0F2F8` | 240, 242, 248 | Main text |
| **TextSecondary** | `#A0AAB C` | 160, 170, 188 | Subheadings, values |
| **TextMuted** | `#6E788A` | 110, 120, 138 | Captions, disabled |
| **Accent** | `#10B981` | 16, 185, 129 | Emerald — active state, FAB, tab indicator |
| **AccentHover** | `#14CD8C` | 20, 205, 140 | Hover state |
| **AccentPressed** | `#0DA06E` | 13, 160, 110 | Pressed state |
| **AccentGlow** | `#10B981` (alpha 0.4) | 16, 185, 129 | Glow shadow on active state |
| **Gold** | `#F5B700` | 245, 183, 0 | Secondary — slider fill, value display, badges |
| **Danger** | `#EF4444` | 239, 68, 68 | Panic button, errors |
| **Info** | `#3B82F6` | 59, 130, 246 | Status readouts, neutral data |
| **TeamRed** | `#EF4444` | 239, 68, 68 | Bedwars team color |
| **TeamBlue** | `#3B82F6` | 59, 130, 246 | |
| **TeamGreen** | `#22C55E` | 34, 197, 94 | |
| **TeamYellow** | `#FACC15` | 250, 204, 21 | |
| **TeamNone** | `#A0AABC` | 160, 170, 188 | No team assigned |
| **TierIron** | `#B4BCC8` | 180, 188, 200 | Generator tier color |
| **TierGold** | `#FACC15` | 250, 204, 21 | |
| **TierDiamond** | `#60D5FF` | 96, 213, 255 | |
| **TierEmerald** | `#34D399` | 52, 211, 153 | |
| **Backdrop** | `#000000` (alpha 0.55) | 0, 0, 0 | Dim layer behind the window when open |

**Color strategy:** Committed. Emerald carries 30-50% of the surface (active states, FAB, tab indicator, toggle ON, primary CTA). Gold provides accent for value display and badges. Red is reserved for danger (panic only). Blue is for neutral information. Neutrals are tinted (no `#000` or `#fff` — chroma 0.005-0.01 toward emerald).

---

## Transparency (glass)

| Token | Value | Usage |
|---|---|---|
| `BackgroundOpaque` | 0 | App bg |
| `GlassPanel` | **0.06** | Main window (heavy glass, more transparent than v1) |
| `GlassCard` | 0.10 | Section cards, element rows |
| `GlassCardHover` | 0.06 | Hovered rows |
| `GlassInput` | 0.20 | Text inputs, wells |
| `Backdrop` | 0.55 | Full-screen dim behind window |
| `Border` | 0.92 | Hairline (mostly transparent) |
| `BorderStrong` | 0.86 | Emphasized |
| `Overlay` | 0.40 | Modal backdrop (unused in v1) |

**Why 0.06 and not 0.18:** v1 was 0.18-0.28 which is too opaque over gameplay. The user sees the game clearly behind the glass. This matches jensen-vvs's `bg-white/0.04` baseline.

---

## Typography

| Token | Font | Size | Usage |
|---|---|---|---|
| `Display` | GothamBlack | 18 | Hero headers, big numbers |
| `Heading` | GothamBold | 15 | Section titles, tab labels |
| `Body` | GothamMedium | 13 | Row labels, control text |
| `Label` | Gotham | 12 | Captions, sub-labels |
| `Caption` | GothamMedium | 10 | Status bar values, hints |
| `Tab` | GothamBold | 13 | Tab bar labels |
| `Icon` | GothamBlack | 18 | Unicode icon glyphs |
| `IconSmall` | GothamBlack | 14 | Inline icons in rows |

**Why Gotham family:** it's the only font set Roblox guarantees. We pick Display+Body within the family to create hierarchy without leaving the Roblox font ecosystem.

**Tracking:** no tracking adjustment (Roblox doesn't support it cleanly). We compensate with size contrast (≥1.25 ratio between Display → Heading → Body).

---

## Radii (rounded everything)

| Token | Value | Usage |
|---|---|---|
| `Pill` | 9999 | Buttons, FAB, switches, accent badges |
| `Card` | 12 | Section cards, window |
| `Input` | 8 | Text inputs, keybinds, dropdowns |
| `Toggle` | 9999 | iOS-style switch (full round) |
| `Small` | 6 | Subtle rounding (separators, inset controls) |

---

## Spacing (8pt grid)

| Token | Value | Usage |
|---|---|---|
| `XS` | 4 | Tight gaps (icon to label) |
| `SM` | 8 | Default gap (between elements in a row) |
| `MD` | 12 | Section internal padding |
| `LG` | 16 | Card padding, row padding |
| `XL` | 24 | Section gaps |
| `XXL` | 32 | Major separation (top bar to content) |

---

## Touch targets (mobile-first)

| Token | Value | Usage |
|---|---|---|
| `MinTarget` | 44 | Absolute minimum (Apple HIG) |
| `RowHeight` | **48** | Element row height (was 56 — tighter) |
| `HeaderHeight` | 56 | Window top bar |
| `TopTabHeight` | 48 | Tab bar |
| `TopTabWidth` | 100 | Each tab button (5 tabs × 100pt = 500pt, scrollable) |
| `StatusBarHeight` | 36 | Bottom status bar |
| `FABSize` | 56 | Floating action button |
| `FABMargin` | 12 | Distance from screen edge |
| `PanicBtnHeight` | 32 | Panic button in status bar |

---

## Motion

**One easing function everywhere:** `Enum.EasingStyle.Quint` (cubic-bezier(0.16, 1, 0.3, 1) — matches jensen-vvs).

| Token | Value | Easing | Usage |
|---|---|---|---|
| `Press` | 0.10s | Quint | Scale-on-press feedback |
| `Tap` | 0.18s | Quint | Toggle knob, keybind pick |
| `Open` | 0.32s | Quint | Panel open/close, tab switch |
| `Reveal` | 0.45s | Exponential | Staggered row reveal |
| `Boot` | 0.55s | Quint | Window first open |
| `Glow` | 1.80s | Sine (loop) | FAB pulse glow |

**Easing direction rules (Emil Kowalski framework):**
- **Entering** (element appears): `Out` — feels responsive (starts fast)
- **Exiting** (element disappears): `In` — fast cleanup
- **On-screen** (morph/move while visible): `InOut` — natural
- **Hover/color change**: default
- **Constant motion** (pulse): `Sine` — smooth, calm

**Press feedback:** every pressable element gets `scale(0.96)` over 0.10s then back. Subtle but essential.

**Pulse glow:** FAB and active tab indicator get a 15px expanding shadow at 0.4 alpha, looping every 1.8s with Sine easing. The "alive" feeling.

---

## Z-index scale

| Layer | Z | Usage |
|---|---|---|
| Base | 1-9 | Content (auto-managed) |
| Window | 10 | Main window |
| Overlay (UI elements inside window) | 11-50 | Per-element stacking |
| Backdrop | 40 | Dim layer (below window content but above game) |
| Notifications | 100 | Top-anchored, always on top |
| FAB | 50 | Above window but below notifications |
| Panicked overlay | 200 | Emergency red flash (not used in v1) |

---

## Design DNA checklist

When adding a new element, verify:

- [ ] Deep dark bg (no white, no light gray)
- [ ] Emerald accent only for active states + FAB + tab indicator
- [ ] Gold for value display + badges
- [ ] Red only for danger (panic)
- [ ] Blue only for neutral info
- [ ] Glass is `bg-white/0.06` + `blur(24px)` + `border white/0.08`
- [ ] Rounded: buttons = `rounded-full`, cards = `rounded-2xl`
- [ ] Touch target ≥ 44pt
- [ ] One easing function (Quint) — never Linear for UI
- [ ] Press scale 0.96 over 0.10s
- [ ] Entering elements start at `scale(0.95) + opacity 0` (not `scale(0)`)
- [ ] No animation on rapidly-triggered actions (use transitions, not keyframes)
- [ ] Drag requires movement threshold (8pt on touch)
- [ ] No emoji in code (only in UI labels for status indicators)
- [ ] No `Inter` font
- [ ] No horizontal scroll on mobile

---

## See also

- `src/ui/theme.lua` — the Lua source of truth
- [AGENTS.md](../AGENTS.md) — design DNA + immutables
- [MOBILE-UX.md](MOBILE-UX.md) — mobile-specific decisions
