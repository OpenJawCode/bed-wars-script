# Bedwars External (Educational)

> External memory reader + overlay for Roblox Bedwars. Pure Python. No DLL injection, no Lua hooks — every feature reads the running `RobloxPlayerBeta.exe` process from outside.

> **Heads up:** this violates Roblox's ToS. Use it on an alt account on a private server, never on your main. The author and contributors are not responsible for your account.

---

## Why this exists

This is the code form of the Serton Mods video **"Make Your First ROBLOX External Cheat With AI"** — built off the same architecture as [RajkoRSL/python-external-roblox](https://github.com/RajkoRSL/python-external-roblox) but **specific to Bedwars**: beds, generators, dropped items, team filtering, color-coded ESP, triggerbot, and a colorbot aimbot. No more "red dot for every player" — you see enemy team color, bed status (alive/dead), and which generator is at what tier.

It is a learning project. If you want to:

- understand how external cheats attach to a process without injecting,
- learn how the Roblox data model is laid out in memory (DataModel → Workspace → Players),
- practice reading a view matrix and projecting world points to screen,
- ship a polished overlay with PyQt5,

this is for you.

---

## Features

| Group | Feature | Notes |
|---|---|---|
| **ESP** | Player boxes, names, health bars, distance, snaplines | Team-color coded. Box shrinks with distance. |
| **ESP** | Bed status | Green = alive, red ✕ = destroyed. |
| **ESP** | Generator markers | Color-coded by tier (iron/gold/diamond/emerald). |
| **ESP** | Dropped item markers | Swords, pickaxes, blocks — orange / purple. |
| **Combat** | Triggerbot | Auto-clicks when an enemy player is on crosshair. |
| **Combat** | Colorbot Aimbot | Scans a small ROI around the cursor for a red enemy pixel and nudges the mouse toward it. |
| **Movement** | Walk speed slider | 16 → 200. |
| **Movement** | Fly hack | Cheap loop: keep `WalkSpeed=120` and bounce `JumpPower`. |
| **Quality of life** | Anti-AFK | 1px mouse wiggle every 60s. |
| **UI** | Transparent overlay (click-through) | PyQt5. |
| **UI** | Draggable control panel | INSERT toggles. |

---

## Architecture

```
main.py              # app loop, hotkeys, overlay wiring
├── bedwars.py       # game-aware layer: players, beds, generators, items
├── classes.py       # math types, Instance wrapper, world->screen, scheduler
├── memory.py        # process attach + read/write (pymem)
└── offsets.json     # Roblox struct offsets (version-pinned)
```

`main` runs a ~16 Hz tick:
1. attach to `RobloxPlayerBeta.exe` (auto-retry if it isn't running)
2. walk the DataModel via the TaskScheduler → RenderJob → VisualEngine + DataModel
3. classify the Workspace by class+name into players / beds / generators / items
4. project every world point to screen via the view matrix
5. hand the flat list to the Overlay; the Overlay paints it on a click-through QWidget

---

## Setup

```bash
# 1. Python 3.10+ on Windows
python -m venv .venv
.venv\Scripts\activate

# 2. Install
pip install pymem psutil keyboard mouse PyQt5 pyautogui
# optional, for the colorbot aimbot:
pip install numpy mss

# 3. Run (with Roblox already open and Bedwars loaded)
python main.py
```

INSERT shows/hides the panel. END cleanly exits (releases the hotkeys + overlay).

---

## Offsets

`offsets.json` is a curated subset of the offsets published by the community (canonical Bedwars-friendly version pinned: `version-2a06298afe3947ab`). When Roblox updates, the only thing that breaks is `task_scheduler_offset` + the few DataModel pointers. Bump those in the JSON and you should be back online.

---

## References (open source)

This project wouldn't exist without the work of the external cheat-dev community. Start here:

- [RajkoRSL/python-external-roblox](https://github.com/RajkoRSL/python-external-roblox) — the **direct** base for `memory.py` + `classes.py` and the layout of `main.py`
- [nordlol/nord-external](https://github.com/nordlol/nord-external) — C++ external with a glfw overlay (good blueprint if you want to go lower-level)
- [Russtels/Layuh-Roblox](https://github.com/Russtels/Layuh-Roblox) — C++ external, more advanced
- [ViperX1919/ProSuiteCheat](https://github.com/ViperX1919/ProSuiteCheat) — the **AI-themed** colorbot pattern this repo's `_do_aimbot` was inspired by
- [havunted/quasar-cheat](https://github.com/havunted/quasar-cheat) — another AI-themed external
- [Lunar-Eclipse111/SK](https://github.com/Lunar-Eclipse111/SK) — kernel-level external (educational only)
- [roblox-cheatbook/roblox-cheatbook](https://github.com/roblox-cheatbook/roblox-cheatbook) — comprehensive reference doc

The original video this is inspired by: **"Make Your First ROBLOX External Cheat With AI (Undetected) How to actualy do it!"** by Serton Mods.

---

## Limitations

- **Linux/macOS won't run this** — `pymem` and the process target are Windows-only. Run from Windows.
- **Cloud IPs get blocked by YouTube** — the transcript of the source video couldn't be fetched from this build environment. The video title, channel, and the well-documented structure of the cheat-dev community were enough to recreate the walkthrough.
- **Offsets rot** — every Roblox version bump changes one or two pointers. Keep `offsets.json` close.
- **No anti-cheat bypass** — byfron / hyperion is not bypassed. This works because nothing is injected into the process. It can still be detected server-side from server-authoritative checks (e.g. speedhack) — don't expect it to last in public matches.

---

## Disclaimer

This is an **educational** project. By using it you agree:

- You will not use it on your main account.
- You will not use it in a way that harms other players' experience.
- The authors are not responsible for bans, ToS strikes, or any other consequence.

If you want a more robust build, port `classes.py` to C++ via `pybind11` and run the snapshot loop in a worker thread — the current Python implementation is bottlenecked by ~60 reads per player per tick.
