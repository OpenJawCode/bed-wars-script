# External Reference (Archived)

This folder contains the **Python external memory cheat** from the first iteration of this project. It is kept for educational comparison — it shows the **other** approach to Roblox cheating (external process memory reading) vs the Lua executor approach used in the main script.

## Status

**ARCHIVED.** Not maintained. Not used by the main script. Read-only reference.

## What it is

A Python + PyQt5 external cheat that reads `RobloxPlayerBeta.exe` process memory to extract player positions, bed locations, and generator info, then draws an ESP overlay on top of the game window.

- `main.py` — PyQt5 GUI + ESP overlay
- `memory.py` — `pymem` process attach + read/write
- `classes.py` — `Vec3`, `Instance` wrapper, world-to-screen projection, scheduler traversal
- `bedwars.py` — Bedwars-aware: team filter, beds, generators, items
- `offsets.json` — Roblox struct offsets (version-pinned)
- `README.md` — original README

## How it differs from the main script

| Aspect | External (this folder) | Main script (Lua) |
|---|---|---|
| Language | Python | Luau |
| Approach | Read process memory from outside | Run inside the Roblox Lua runtime |
| Executor | None — runs as a standalone Windows exe | Delta / Codex / Fluxus |
| Memory access | `pymem` reads `RobloxPlayerBeta.exe` | `debug.getupvalue` reads Knit closures |
| Remotes | Cannot fire remotes (read-only) | Fires `AttackEntity`, `PickupItem`, etc. |
| Features | ESP only | ESP + Killaura + Aimbot + Fly + Magnet + Shop + ... |
| Platform | Windows only | Mobile (Android) + Windows |
| Anti-cheat | Bypassed by being external | Bypassed by executor (kernel-level) |
| Status | Archived | Active |

## Why we kept it

1. **Educational value.** Web devs new to Roblox often confuse "external cheat" (process memory) with "executor script" (Lua). Having both side-by-side makes the difference clear.
2. **Reference for offsets.** The `offsets.json` here has Roblox struct offsets that might be useful if anyone wants to revive the external approach.
3. **The original README** documents the open-source external-cheat community (RajkoRSL, nordlol, ViperX1919, etc.).

## How to run it (don't — use the main script instead)

```bash
# On Windows
pip install pymem psutil keyboard mouse PyQt5 pyautogui
python main.py
```

See `README.md` in this folder for the original docs.

## Credits

Based on [RajkoRSL/python-external-roblox](https://github.com/RajkoRSL/python-external-roblox) (MIT-style educational reference).
