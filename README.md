# Bedwars Script

> Premium dark luxe glassmorphic Lua script for **Easy.gg Bedwars** on Roblox.
> Mobile-first (Motorola Edge 20 reference). Runs in **Delta** and **Codex** executors.
> Built with the VapeV4 remote-extraction technique + a custom Rayfield-inspired UI library.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
```

---

## ⚠️ Disclaimer

This script violates Roblox's Terms of Service. Use it on an **alt account** on a private server. The authors are not responsible for bans, ToS strikes, or any consequence. See [`docs/DISCLAIMER.md`](docs/DISCLAIMER.md).

---

## What this is

A single loadstring script for the Easy.gg Bedwars game (PlaceId `6872265039` lobby / `6872274481` match / `8444591321` mega / `8560631822` micro). It does **not** inject DLLs or read process memory — it runs inside the Roblox Lua runtime via a mobile executor (Delta, Codex, Fluxus, etc.) and uses the same Knit/Flamework remote-extraction technique that VapeV4 uses.

The UI is **custom-built from scratch** with `Instance.new()` — no Rayfield dependency, no `rbxassetid://` asset loading. Dark glassmorphic, 56pt touch targets, bottom tab bar, snap-to-edge FAB, haptic feedback, spring-ish micro-interactions.

---

## Features (v1.0)

### Combat
| Feature | Description |
|---|---|
| **Killaura** | Auto-attacks nearby enemies with the equipped sword. Range + speed sliders. Uses the `AttackEntity` remote with the reach-extension math (`selfPosition += lookVector * max(distance - 14.399, 0)`). |
| **Reach** | Extends melee reach beyond the legit 14.399 studs. |
| **Aimbot** | Smooth camera lerp toward the nearest enemy in FOV. Heartbeat-driven, configurable smoothness. |

### Visuals
| Feature | Description |
|---|---|
| **Player ESP** | Box + health bar + name + distance + optional tracer. Team-colored. Drawing API. |
| **Bed ESP** | Text marker on every bed, colored by team. |
| **Generator / Item ESP** | Text marker on every `ItemDrop` (iron/gold/diamond/emerald), color-coded by tier. |
| **Tracers** | Line from screen bottom to each player. |
| **Distance filter** | Slider 50–500 studs. |

### Movement
| Feature | Description |
|---|---|
| **Fly** | `PlatformStand = true` + velocity from camera look. WASD + Space/Shift. Noclip through walls. |
| **Speed** | Sticky `Humanoid.WalkSpeed` override. 16–200. |
| **Noclip** | Walk through walls (keeps gravity). |

### World
| Feature | Description |
|---|---|
| **Magnet** | Pulls **all** `ItemDrop` parts in the workspace to your feet. Default radius 9999 (whole map). 5Hz. |
| **Generator Auto-Collect** | Same as Magnet but smaller radius (30 studs) + 3-second spawn guard. 10Hz. |
| **Bed Aura** | Auto-breaks nearby enemy beds via `BedwarsBedBreak` remote (fallback: `DamageBlock`). |
| **Shop Auto-Buy** | Fires `BedwarsPurchaseItem` remote for the selected item. |

### Misc
| Feature | Description |
|---|---|
| **Anti-AFK** | Fires `AfkStatus` remote every 10s + camera wiggle every 30s. |
| **Auto-Rejoin** | Re-teleports to the same JobId on disconnect. |
| **Remote Spy** | Hooks `__namecall` to log every `FireServer`/`InvokeServer`. For discovering new remotes after Bedwars updates. |
| **Panic key** | `RightCtrl` disables every feature instantly. |

---

## Hotkeys

| Key | Action |
|---|---|
| Tap FAB (floating button) | Open / close the menu |
| `RightCtrl` | **Panic** — disable all features |
| `RightShift` | Toggle UI (rebindable in Misc tab) |

---

## How to use

1. Open **Roblox Bedwars** on your phone (Delta or Codex executor).
2. Paste this in the executor's script box:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
   ```
3. Tap the floating emerald button to open the menu.
4. Toggle features on. Adjust sliders to taste.

---

## Project structure

```
bed-wars-script/
├── main.lua                  # loadstring entry — boots everything
├── loader.lua                # minimal stub (fetches main.lua)
├── src/
│   ├── config.lua            # settings + save/load
│   ├── ui/
│   │   ├── theme.lua         # dark luxe glassmorphic tokens
│   │   ├── library.lua       # custom UI library (Window, Tab, Toggle, Slider, ...)
│   │   ├── animations.lua    # micro-interactions
│   │   └── icons.lua         # Roblox asset IDs
│   ├── util/
│   │   ├── tween.lua         # TweenService wrapper
│   │   ├── dragger.lua       # mobile + desktop drag w/ snap-to-edge
│   │   ├── input.lua         # touch + key handler + haptic
│   │   ├── projection.lua    # WorldToScreen helpers
│   │   └── logger.lua        # leveled logging + pcall guard
│   ├── game/
│   │   ├── placeid.lua       # Bedwars PlaceIds
│   │   ├── services.lua      # cached game:GetService
│   │   ├── remotes.lua       # ⭐ Knit bootstrap + remote extraction
│   │   └── workspace.lua     # entity library + CollectionService walkers
│   └── features/
│       ├── killaura.lua
│       ├── reach.lua
│       ├── aimbot.lua
│       ├── fly.lua
│       ├── speed.lua
│       ├── noclip.lua
│       ├── magnet.lua
│       ├── generator.lua
│       ├── bedaura.lua
│       ├── shop.lua
│       ├── antiafk.lua
│       ├── autorejoin.lua
│       ├── spy.lua
│       └── esp.lua
├── external-reference/       # the Python external cheat, kept for learning
├── docs/
│   ├── ARCHITECTURE.md
│   ├── REMOTES.md
│   ├── GLOSSARY-FOR-WEB-DEVS.md
│   ├── MOBILE-UX.md
│   └── DISCLAIMER.md
└── .github/workflows/
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how the pieces fit together,
[`docs/REMOTES.md`](docs/REMOTES.md) for the remote-event table, and
[`docs/GLOSSARY-FOR-WEB-DEVS.md`](docs/GLOSSARY-FOR-WEB-DEVS.md) if Roblox file names are new to you.

---

## Compatibility

Tested (in theory) on:

| Executor | Status | Notes |
|---|---|---|
| **Delta** | ✅ Primary target | Disable animation module — Delta has a confirmed Animation bug. |
| **Codex** | ✅ Primary target | No known issues. |
| **Fluxus** | ✅ Should work | Same UNC standard. |
| **Hydrogen** | ⚠️ Untested | Has `hookmetamethod` + `Drawing.new`. |
| **KRNL** | ⚠️ Untested | Older — may lack some debug functions. |
| **Script-Ware** | ⚠️ Untested | Mobile version discontinued. |

Required executor functions: `debug.getupvalue`, `debug.getconstants`, `debug.getproto`, `hookmetamethod`, `getrawmetatable`, `Drawing.new`, `writefile`/`readfile` (for config save), `game:HttpGet` (for loadstring). All UNC-standard.

---

## Credits

Built on the public research of:
- **[7GrandDadPGN/VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox)** — the gold standard Bed Wars script. Our `remotes.lua` extraction technique mirrors theirs.
- **[sirius-menu/rayfield](https://github.com/sirius-menu/rayfield)** — the standard Roblox UI library. Our `library.lua` API surface is inspired by it (but built from scratch, no asset dependency).
- **[RajkoRSL/python-external-roblox](https://github.com/RajkoRSL/python-external-roblox)** — the external-memory approach (kept in `external-reference/` for comparison).

---

## License

MIT — see [`LICENSE`](LICENSE).
