# Setup & Troubleshooting

## Quick start (recommended — single-file)

1. Open **Roblox Bedwars** in your mobile executor (Delta / Codex / Fluxus / etc.)
2. Copy the entire contents of [`bw-singlefile.lua`](bw-singlefile.lua) (156 KB, 4443 lines)
3. Paste it into your executor's script box
4. Tap **Execute**

A green ⚡ button will appear in the top-right corner of the screen. Tap it to open the menu.

**That's it. No internet, no `HttpGet`, no module loading. One paste = works.**

---

## Quick start (alternative — loadstring)

If your executor can `HttpGet` GitHub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/loader.lua"))()
```

The loader fetches all modules from the repo, boots the script, and shows a green ⚡ button.

---

## If nothing happens when you execute

**The script isn't silent anymore.** If anything goes wrong, you'll see a red ⚠ BOOT FAILED box in the middle of the screen with the actual error message.

Common errors and fixes:

| Error | Cause | Fix |
|---|---|---|
| `HttpGet to GitHub blocked` | Your executor's `HttpGet` is sandboxed or rate-limited | Use the single-file version (paste directly) |
| `HttpGet is not a function` | Old executor without `game:HttpGet` | Update your executor (Delta ≥ 2.0, Codex ≥ latest) |
| `gethui is not a function` | Old executor without `gethui()` | Update your executor |
| `HapticService: IsMotorSupported` returned false | No vibration hardware | Ignore — the script still works, just no haptic feedback |
| `Knit bootstrap timeout` | Bedwars still loading | Wait 30s after joining the game, then re-execute |
| `Hookmetamethod is not a function` | Executor doesn't support metamethod hooking | Spy feature disabled automatically; everything else works |
| `Drawing.new is not a function` | Old executor without Drawing API | Update your executor (Delta ≥ 1.5) |

If the BOOT FAILED box says "Unknown error", open the executor's console (F9 in Roblox Studio, or the executor's log panel) — the full error stack trace is there.

---

## Updating the single-file

If you forked the repo and edited source files, regenerate the single-file:

```bash
python3 scripts/build_singlefile.py
```

This re-inlines all 28 modules into `docs/bw-singlefile.lua`. Re-paste it into your executor.

---

## How the build works

```
src/                       ← multi-file source (this is what you edit)
├── ui/library.lua
├── features/killaura.lua
└── ...

        ↓  python3 scripts/build_singlefile.py  ↓

docs/bw-singlefile.lua     ← paste this into your executor
                           (no HttpGet needed)
```

The build script inlines each module as an IIFE, registers the return value into a shared `_BW` package table, then runs the (slightly stripped) `main.lua` at the end. Total: 28 modules inlined, 4443 lines, 156 KB.

---

## How the boot works (multi-file)

```
loader.lua  (loadstring target)
  └─ HttpGet main.lua
       └─ HttpGet each src/ module
            └─ register in _BW package table
                 └─ main.lua uses _BW.X
                      └─ Library:CreateWindow()
                           └─ FAB (⚡) appears top-right
```

If any `HttpGet` fails, the loader shows a visible BOOT FAILED box pointing to the single-file fallback.

---

## Debug checklist

1. ✅ Are you in the Bedwars game (not main menu)?
2. ✅ Did the executor actually execute? (Check the executor's log for `[bw-loader]` or `[bw-script]` lines)
3. ✅ Is the green ⚡ visible in the top-right corner? (If yes, the script is running — tap it)
4. ✅ If you see a red ⚠ BOOT FAILED box, read the error message and check the troubleshooting table above
5. ✅ Still broken? Use the single-file version (paste `docs/bw-singlefile.lua` directly)

---

## Privacy / Permissions

The script needs:
- `game:GetService("Players")` — to read your character + team
- `game:GetService("Workspace")` — to find enemies, beds, items
- `game:GetService("ReplicatedStorage")` — to call the game's remotes (Knit)
- `game:HttpGet` — to fetch modules (loadstring mode only — single-file mode needs no internet)
- `debug.getupvalue` / `debug.getconstants` / `debug.getproto` — to extract remote names from Knit
- `hookmetamethod` — for the Spy feature only (degrades gracefully if missing)

It does NOT:
- Send your data anywhere
- Access your account
- Modify your Roblox client outside the game session
- Persist after the executor ends the session
