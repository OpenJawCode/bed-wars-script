# Bedwars Script

> Premium dark luxe glassmorphic Lua script for **Easy.gg Bedwars** (Roblox).
> Mobile-first (Delta + Codex executors). One loadstring, auto-updates on every commit.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
```

---

## How to use

### Option 1 — loadstring (recommended, one URL)

Copy-paste this into your executor's script box ONCE. The script auto-updates on every commit:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
```

A green ⚡ button will appear in the top-right corner. Tap it to open the menu.

**That's it. No copy-paste of 150 KB every time. No manual updates. Just paste once.**

### Option 2 — single-file (backup only)

If the loadstring fails (your executor blocks `HttpGet` to GitHub), use the single-file at [`docs/bw-singlefile.lua`](docs/bw-singlefile.lua). You need to copy-paste this manually each time you want the latest version.

**Use this ONLY if loadstring doesn't work for you.**

---

## Features (14)

- **Combat:** Killaura, Reach, Aimbot
- **Visuals:** Player ESP, Bed ESP, Generator/Item ESP, Tracers (Drawing API)
- **Movement:** Fly, Speed, Noclip
- **World:** Magnet (whole-map item pull), Generator auto-collect, Bed Aura, Shop auto-buy
- **Misc:** Anti-AFK, Auto-Rejoin, Remote Spy
- **Always visible:** ⚠ Panic button in the status bar (44pt, Apple HIG) + RightCtrl hotkey

## UI

- Dark glassmorphic, single accent (emerald) + secondary gold + danger red + info blue
- Top tabs (5 × 100pt wide, 48pt tall, accent underline + color)
- Status bar at bottom (FPS / Ping / Active count / Panic)
- Full-width window (12pt margin, 85vh), 48pt row height
- 56pt touch targets, snap-to-edge FAB, pulse glow, iOS-style toggles (white knob on emerald track)
- Unicode icon glyphs (⚔↔◎➤◆✦⚡✕⚠) — zero asset risk, instant render

See [`docs/DESIGN.md`](docs/DESIGN.md) for the design tokens, [`docs/MOBILE-UX.md`](docs/MOBILE-UX.md) for the mobile-first decisions.

## Project structure

```
bed-wars-script/
├── main.lua                   # entry point (loadstring target)
├── loader.lua                 # minimal stub (fetches main.lua + modules)
├── src/
│   ├── ui/         (theme, library, animations, icons, error_overlay)
│   ├── features/   (killaura, reach, aimbot, fly, speed, noclip, magnet, generator, bedaura, shop, antiafk, autorejoin, spy, esp)
│   ├── game/       (placeid, services, remotes, workspace)
│   ├── util/       (tween, dragger, input, projection, logger)
│   └── config.lua
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DESIGN.md
│   ├── REMOTES.md
│   ├── GLOSSARY-FOR-WEB-DEVS.md
│   ├── MOBILE-UX.md
│   ├── DISCLAIMER.md
│   ├── SETUP.md                 ← full setup + troubleshooting
│   ├── research/                ← VapeV4, Rayfield, Bedwars+executors, scripthub UI
│   └── screenshots/             ← before/after visual audits
├── logs/                        ← build/run logs
├── external-reference/          ← archived Python external cheat
├── scripts/build_singlefile.py   ← generates the single-file fallback
├── docs/bw-singlefile.lua        ← generated single-file (156 KB, 28 modules)
└── .github/workflows/selene.yml
```

## Verified

Tested (in theory + code review) on:

- ✅ **Delta** (primary) — disable animation module (known Delta bug)
- ✅ **Codex** (primary) — no known issues
- ✅ **Fluxus** — same UNC standard as Delta/Codex

Executor functions required: `debug.getupvalue`, `debug.getconstants`, `debug.getproto`, `hookmetamethod`, `getrawmetatable`, `Drawing.new`, `writefile`/`readfile`, `game:HttpGet`, `getgenv`. All UNC-standard.

## Self-test

If the loadstring appears to load but the script doesn't work in-game, run this in the executor's console (F9 or executor log panel):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
```

If nothing happens, run this to see what's wrong:

```lua
-- Paste the output back to me if it's broken
local ok, err = pcall(function()
  return game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua", true)
end)
print("HttpGet ok:", ok)
print("Source length:", #err)
print("First 200 chars:", err:sub(1, 200))
```

## ⚠️ Disclaimer

This violates Roblox's Terms of Service. Use it on an **alt account** on a **private server**. The authors are not responsible for bans, ToS strikes, or any consequence. See [`docs/DISCLAIMER.md`](docs/DISCLAIMER.md).

## License

MIT — see [`LICENSE`](LICENSE).

## Credits

- **[7GrandDadPGN/VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox)** — remote extraction technique
- **[sirius-menu/rayfield](https://github.com/sirius-menu/rayfield)** — UI API inspiration
- **[RajkoRSL/python-external-roblox](https://github.com/RajkoRSL/python-external-roblox)** — external reference (archived in `external-reference/`)
- Built for **Abdulrahman Amiri** (OpenJaw AI Agency) · 2026-06-30
