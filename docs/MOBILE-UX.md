# Mobile UX Decisions

Target device: **Motorola Edge 20** (1080×2400, 6.7", 393pt logical width, 144Hz, Snapdragon 778G, 8GB RAM).

## Touch targets

| Element | Size | Why |
|---|---|---|
| Floating Action Button (FAB) | 56×56 pt | Apple HIG: 44pt min. We use 56pt for thumb comfort. |
| Tab bar buttons | 70×48 pt | 5 tabs fit in 380pt window width. |
| Toggle / Slider / Button rows | Full width × 56 pt | One row = one thumb tap. |
| Close button | 28×28 pt | Smaller OK because it's a destructive secondary action with a confirm. |

## Layout

- **Bottom tab bar** (mobile pattern), not left side. 48pt tall. 5 tabs: Combat, Visuals, Move, World, Misc.
- **Window size**: 380×480pt. Centered on screen, but draggable anywhere.
- **Snap-to-edge on release**: when the user drags the FAB, it snaps to the nearest horizontal edge with padding 16pt. Animates with `Quint.Out` over 280ms.
- **Sticky header**: 56pt tall, draggable (to move the window).
- **Content area**: scrollable, 12pt padding, 8pt gap between elements.

## Micro-interactions

| Interaction | Animation | Haptic |
|---|---|---|
| Tap FAB | Scale 0.96 → 1.0 over 100ms (Quint.Out) | 0.3 strength, 80ms |
| Tap toggle | Knob slides 18pt + color crossfade over 180ms (Quint.Out) | 0.25 strength, 80ms |
| Tap button | Scale 0.96 → 1.0 over 100ms | 0.3 strength, 80ms |
| Drag slider | Progress bar tweens 120ms (Quad.Out) | 0.15 strength, 40ms |
| Tab switch | Indicator slides + icon/text color crossfade over 250ms (Quint) | 0.2 strength, 50ms |
| Open menu | Window height 0 → 480 over 320ms (Quint.Out) | — |
| Close menu | Window height 480 → 0 over 320ms (Quint.In) | — |
| Notification | Slide in from top, expand 60pt over 350ms (Quint.Out) | — |

## Performance budgets (mobile)

| Loop | Rate | Why |
|---|---|---|
| Workspace entity refresh | 10 Hz | Combat + ESP both need fresh data; 10Hz is plenty |
| Killaura | 5–30 Hz (user-configurable) | Roblox swing cooldown is ~0.4s; 20Hz is the sweet spot |
| Magnet | 5 Hz | Don't spam the server |
| Generator | 10 Hz | Matches VapeV4 |
| BedAura | 2 Hz | Bed breaking doesn't need to be fast |
| ESP render | **30 Hz on touch / 60 Hz on desktop** | Throttled on mobile to save battery |
| Aimbot | Heartbeat (~60 Hz) | Camera lerp needs every frame |

Memory: < 5 MB extra. CPU: < 2% on Snapdragon 778G.

## Gestures

| Gesture | Action |
|---|---|
| Tap FAB | Open / close menu |
| Drag FAB | Move FAB (snaps to edge on release) |
| Drag header | Move window |
| Tap tab | Switch tab |
| Tap toggle | Toggle feature |
| Drag slider | Adjust value |
| Tap dropdown | Cycle to next option (mobile-friendly — no expand/collapse for v1) |

## One-handed usage

The window is 380pt wide, centered. On a 393pt screen (Edge 20), there's only 13pt of margin. The user can drag the window to any position. The FAB is initially at the bottom-left, draggable, and snaps to either edge.

All interactive elements are reachable with the right thumb when the window is in the lower half of the screen.

## What we deliberately DIDN'T do (for v1)

- **Pinch-to-resize the window.** Adds complexity; the fixed 380×480 works.
- **Pull-to-refresh on the spy log.** Not a core flow.
- **Two-finger swipe between tabs.** Tab taps are fine.
- **Long-press for "what does this do?"** Tooltips would be nice but add UI complexity.
- **Settings tab with theme picker.** The dark glassmorphic theme is the only theme for v1.

These are candidates for v1.1 once mobile UX is locked.

## PC responsiveness (v2 — not in v1)

When the script detects `UserInputService.TouchEnabled == false`:
- Window can be larger (500×600 default)
- Hover effects enabled (`MouseEnter`/`MouseLeave` → bg color tween)
- Keyboard shortcuts surfaced in the UI
- Tab bar can move to the left side (desktop pattern)

This is **after** mobile UX is locked and audited.
