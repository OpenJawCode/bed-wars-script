# Architecture

## Boot sequence

```
loadstring(game:HttpGet("loader.lua"))()
  └── loader.lua fetches main.lua
       └── main.lua
            1. Loads every module via loadModule() (HttpGet + loadstring)
            2. Config.load()           — read bedwars_config.json
            3. GameWksp.init()         — starts 10Hz entity refresh loop
            4. Remotes.bootstrap()     — async, waits for Knit
               └── Remotes.extractAll() — populates Remotes.names + .handles
            5. Library:CreateWindow()  — builds the ScreenGui + FAB
            6. Creates tabs: Combat, Visuals, Move, World, Misc
            7. Wires every toggle/slider to its feature's setEnabled/setValue
            8. Panic key (RightCtrl) — disables all features
            9. CharacterAdded — re-wires Fly on respawn
           10. Notify "Loaded" — user taps FAB to open menu
```

## Module dependency graph

```
main.lua
  ├── util/logger.lua          (no deps)
  ├── ui/theme.lua             (no deps)
  ├── util/tween.lua           (TweenService)
  ├── util/dragger.lua         (UserInputService, TweenService)
  ├── util/input.lua           (UserInputService)
  ├── util/projection.lua      (Workspace)
  ├── ui/animations.lua        (util/tween, ui/theme)
  ├── ui/icons.lua             (no deps)
  ├── ui/library.lua           (ui/theme, util/tween, util/dragger, util/input, ui/animations, ui/icons)
  ├── config.lua               (HttpService for JSON)
  ├── game/placeid.lua         (no deps)
  ├── game/services.lua        (game:GetService cache)
  ├── game/remotes.lua         (game/services, util/logger) — ⭐ critical
  ├── game/workspace.lua       (game/services, util/logger)
  └── features/*
       ├── killaura.lua        (game/services, game/workspace, game/remotes, game/placeid, util/logger)
       ├── reach.lua           (no deps — just a config struct)
       ├── aimbot.lua          (game/services, game/workspace, game/placeid, util/logger)
       ├── fly.lua             (game/services, util/logger)
       ├── speed.lua           (game/services, util/logger)
       ├── noclip.lua          (game/services, util/logger)
       ├── magnet.lua          (game/services, game/workspace, game/remotes, game/placeid, util/logger)
       ├── generator.lua       (game/services, game/workspace, game/remotes, game/placeid, util/logger)
       ├── bedaura.lua         (game/services, game/workspace, game/remotes, game/placeid, util/logger)
       ├── shop.lua            (game/services, game/workspace, game/remotes, game/placeid, util/logger)
       ├── antiafk.lua         (game/services, game/remotes, util/logger)
       ├── autorejoin.lua      (game/services, util/logger)
       ├── spy.lua             (util/logger) — needs hookmetamethod
       └── esp.lua             (game/services, game/workspace, ui/theme, util/logger, game/placeid) — needs Drawing.new
```

## Data flow (per frame)

```
Workspace._refreshLoop (10Hz task.spawn)
  └── Workspace.refresh()
       └── for each Player: buildEntity() -> Workspace.entities[plr]

ESP._onRenderThrottled (RenderStepped, 30Hz on mobile / 60Hz on desktop)
  ├── reads Workspace.getAllEntities()
  ├── projects each entity.RootPart.Position via Camera:WorldToViewportPoint
  └── updates Drawing.new("Square"/"Line"/"Text") instances

Killaura._loop (task.spawn, 1/speed Hz)
  ├── reads Workspace.getEnemies(range)
  ├── finds best sword in character
  └── Remotes.fire("AttackEntity", { weapon, chargedAttack, entityInstance, validate })

Magnet._loop (task.spawn, 5Hz)
  ├── reads Workspace.getItemDrops() (CollectionService tag 'ItemDrop')
  ├── TPs each drop to player feet (if network owner)
  └── Remotes.call("PickupItem", { itemDrop = part })
```

## Why this design

1. **Single loadstring entry** — the user pastes one URL. No file management.
2. **Modules loaded via HttpGet** — the script works on mobile executors that don't have a file system. Each module is fetched on demand from the GitHub raw URL.
3. **Cached services** — `game:GetService` is called once per service. Every feature uses `Services.Players()` etc.
4. **10Hz entity refresh** — features don't each scan `Players:GetPlayers()`. One loop populates `Workspace.entities` and everyone reads from it.
5. **pcall armor** — every feature loop is wrapped in `Logger.guard` so one bad feature never crashes the script.
6. **No Rayfield dependency** — Rayfield loads its UI from `rbxassetid://10804731440` (a hosted asset). We build with `Instance.new()` so the script is self-contained.
7. **Mobile-first UI** — 56pt touch targets, bottom tab bar, snap-to-edge FAB, haptic feedback, 30Hz ESP throttle on touch devices.

## Adding a new feature

1. Create `src/features/<name>.lua`:
   ```lua
   local MyFeature = { enabled = false, _thread = nil }
   function MyFeature._loop() ... end
   function MyFeature.setEnabled(state) ... end
   return MyFeature
   ```
2. Add to `main.lua` load order:
   ```lua
   local MyFeature = loadModule("features/my_feature.lua")
   ```
3. Add a toggle in the relevant tab:
   ```lua
   someSec:CreateToggle({
     Name = "My Feature",
     CurrentValue = false,
     Callback = function(v) MyFeature.setEnabled(v) end,
   })
   ```
4. Test by running the loadstring and toggling the feature.

## Performance budget

| Loop | Rate | Why |
|---|---|---|
| Workspace.refresh | 10 Hz | Combat + ESP both need fresh data; 10Hz is plenty |
| Killaura | 5–30 Hz (user) | Roblox swing cooldown is ~0.4s; 20Hz is the sweet spot |
| Magnet | 5 Hz | Don't spam the server with PickupItem calls |
| Generator | 10 Hz | Matches VapeV4 |
| BedAura | 2 Hz | Bed breaking doesn't need to be fast |
| ESP render | 30 Hz mobile / 60 Hz desktop | Throttled on touch to save battery |
| Aimbot | Heartbeat (~60 Hz) | Camera lerp needs every frame for smoothness |

Memory: < 5 MB extra. CPU: < 2% on Motorola Edge 20 (Snapdragon 778G).
