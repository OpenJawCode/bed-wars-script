# Bedwars Remote Events

Bedwars is built on **Knit + Flamework + Roblox-TS + @rbxts/net + Zap networking**.
Remotes are **NOT** static `RemoteEvent` instances in `ReplicatedStorage`.
They are created dynamically by the Knit client and referenced by string name
inside controller methods.

## Extraction technique

We use the same technique VapeV4 uses:

1. Get Knit from `debug.getupvalue(require(PlayerScripts.TS.knit).setup, 9)`
2. Get the @rbxts/net Client: `require(ReplicatedStorage.TS.remotes).default.Client`
3. For each Knit controller method, call `debug.getconstants(method)`
4. Find the string `'Client'` in the constants, take the **next** constant as the remote name
5. Get the remote handle: `Client:Get(remoteName).instance`
6. Fire it: `handle:FireServer(args)` or `Client:Get(name):CallServerAsync(args)`

This is implemented in [`src/game/remotes.lua`](../src/game/remotes.lua).

## Known remotes (v1)

| Key | Source | Args | Purpose |
|---|---|---|---|
| `AttackEntity` | `Knit.Controllers.SwordController.sendServerRequest` | `{ weapon, chargedAttack={chargeRatio=0}, entityInstance, validate={raycast, targetPosition, selfPosition} }` | Melee attack a player/NPC |
| `EquipItem` | upvalue 4 of `InventoryEntity.equipItem` | `{ hand = toolInstance }` | Move item to hand |
| `PickupItem` | `Knit.Controllers.ItemDropController.checkForPickup` | `{ itemDrop = part }` | Collect a dropped item (generator drops, death drops) |
| `DropItem` | `Knit.Controllers.ItemDropController.dropItemInHand` | — | Drop held item |
| `ConsumeItem` | proto 1 of `ConsumeController.onEnable` | — | Eat/consume consumable |
| `ResetCharacter` | proto 1 of `ResetController.createBindable` | — | Reset character |
| `AfkStatus` | proto 1 of `AfkController.KnitStart` | `{ isAfk = false }` | AFK toggle |
| `DamageBlock` | `BlockEngineRemotes.Client:Get('DamageBlock')` | `{ blockRef={blockPosition}, hitPosition, hitNormal }` | Break/damage a block |
| `BedwarsBedBreak` | `Client:WaitFor('BedwarsBedBreak')` | `{ bed = bedModel }` | Break a bed |
| `BedwarsPurchaseItem` | `Client:Get('BedwarsPurchaseItem')` | `{ shopItem = "iron_sword", shopId = ... }` | Buy from item shop |

## The 5 lines you must get right

```lua
-- 1. Get Knit
local Knit = debug.getupvalue(require(game.Players.LocalPlayer.PlayerScripts.TS.knit).setup, 9)

-- 2. Get a remote NAME from a controller function
local remoteName
for i, v in debug.getconstants(Knit.Controllers.SwordController.sendServerRequest) do
  if v == 'Client' then
    remoteName = debug.getconstants(Knit.Controllers.SwordController.sendServerRequest)[i + 1]
    break
  end
end

-- 3. Get the remote handle
local Client = require(game:GetService('ReplicatedStorage').TS.remotes).default.Client
local AttackRemote = Client:Get(remoteName).instance

-- 4. Team check (Bedwars-specific — uses attributes, not Roblox Teams)
local function isEnemy(plr)
  return plr:GetAttribute('Team') ~= game.Players.LocalPlayer:GetAttribute('Team')
end

-- 5. Fire attack with reach extension
local selfpos = rootPart.Position
local dir = CFrame.lookAt(selfpos, targetRoot.Position).LookVector
local pos = selfpos + dir * math.max((selfpos - targetRoot.Position).Magnitude - 14.399, 0)
AttackRemote:FireServer({
  weapon = swordTool,
  chargedAttack = { chargeRatio = 0 },
  entityInstance = targetCharacter,
  validate = {
    raycast = { cameraPosition = { value = pos }, cursorDirection = { value = dir } },
    targetPosition = { value = targetRoot.Position },
    selfPosition = { value = pos },
  },
})
```

## Object location (NOT via folder paths)

Bedwars uses **CollectionService tags**, not folder hierarchies:

| Object | Tag | Example |
|---|---|---|
| Beds | `'bed'` | `CollectionService:GetTagged('bed')` |
| Item drops (generators, death drops) | `'ItemDrop'` | `CollectionService:GetTagged('ItemDrop')` |
| Item shops | `'BedwarsItemShop'` | `CollectionService:GetTagged('BedwarsItemShop')` |

## Team + health

| What | How | NOT how |
|---|---|---|
| Player team | `Player:GetAttribute('Team')` (numeric id) | ❌ `Player.Team` |
| Player health | `Character:GetAttribute('Health')` | ❌ `Humanoid.Health` |
| Team color (for ESP) | `Player.TeamColor.Color` | (use this only for visuals) |

## Hotbar switch (no remote needed)

```lua
local Store = require(game.Players.LocalPlayer.PlayerScripts.TS.ui.store).ClientStore
Store:dispatch({ type = 'InventorySelectHotbarSlot', slot = 1 })
```

## Discovering new remotes (after a Bedwars update)

1. Enable the **Spy** feature in the Misc tab.
2. Play the game normally — open shop, attack, collect items.
3. The console will log every `FireServer`/`InvokeServer` call with the remote name.
4. Add new entries to `RemoteSources` in `src/game/remotes.lua`.
5. Tap "Re-extract Remotes" in the Misc tab to test.

## Why this is version-fragile

When Easy.gg updates Bedwars, controller paths can shift (e.g. `SwordController` might be renamed). The extraction will fail for those remotes. The Spy feature lets you discover the new names live. The script logs warnings for any remote it can't extract — check the console (F9 in Roblox, or the executor's log panel).

## References

- [VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox) — the source of this technique
- [SnipxyVape/CrystalVape](https://github.com/SnipxyVape) — community fork with Bedwars-specific overrides
- [luau/Executor-API-Docs](https://github.com/luau/Executor-API-Docs) — UNC standard
