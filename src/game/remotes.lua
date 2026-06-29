-- src/game/remotes.lua
-- THE critical file. Bedwars is built on Knit + Flamework + Roblox-TS + @rbxts/net.
-- Remotes are NOT static RemoteEvent instances in ReplicatedStorage. They are
-- created dynamically by the Knit client and referenced by string name inside
-- controller methods. We extract those names using the Luau `debug` library.
--
-- Technique (from VapeV4 research):
--   1. Get Knit from `require(PlayerScripts.TS.knit).setup` via debug.getupvalue
--   2. For each controller method, call debug.getconstants on it
--   3. Find the string 'Client' in the constants, take the NEXT constant as the remote name
--   4. Get the remote handle via `Client:Get(remoteName).instance`
--
-- This file is version-fragile — when Easy.gg updates Bedwars, controller paths
-- may shift. The Spy feature (features/spy.lua) helps discover new remotes live.

local Services = require(script.Parent.services)
local Logger   = require(script.Parent.Parent.util.logger)

local Remotes = {}

-- The extracted Knit + Client + remote-name table.
Remotes.Knit    = nil
Remotes.Client  = nil
Remotes.names   = {}    -- key -> remote name string
Remotes.handles = {}    -- key -> remote handle (Instance)

-- ─── Bootstrap: get Knit + Client ───────────────────────────────────────────
-- Waits up to 30s for Knit to load (game might still be loading).
function Remotes.bootstrap(timeout)
  timeout = timeout or 30
  local plr = Services.localPlayer()
  local replicatedStorage = Services.ReplicatedStorage()
  local deadline = tick() + timeout

  repeat
    local ok, result = pcall(function()
      -- Get Knit from the knit setup function's 9th upvalue
      local knitModule = plr:WaitForChild("PlayerScripts"):WaitForChild("TS"):WaitForChild("knit")
      local Knit = debug.getupvalue(require(knitModule).setup, 9)
      -- Get the @rbxts/net Client
      local Client = require(replicatedStorage.TS.remotes).default.Client
      return Knit, Client
    end)
    if ok and result then
      Remotes.Knit, Remotes.Client = result, result and result.Client or result
      -- Re-extract Client cleanly
      if result then
        local ok2, client = pcall(function()
          return require(replicatedStorage.TS.remotes).default.Client
        end)
        if ok2 then Remotes.Client = client end
      end
      Logger.info("Knit + Client acquired")
      return true
    end
    task.wait(0.2)
  until tick() > deadline

  Logger.error("Failed to bootstrap Knit within " .. timeout .. "s")
  return false
end

-- ─── Remote name extraction ─────────────────────────────────────────────────
-- Given a Knit controller function, find the remote name string in its constants.
-- The pattern: constants contain 'Client' followed immediately by the remote name.
local function extractRemoteName(fn)
  if not fn then return nil end
  local ok, constants = pcall(debug.getconstants, fn)
  if not ok or not constants then return nil end
  for i, v in ipairs(constants) do
    if v == "Client" and constants[i + 1] and type(constants[i + 1]) == "string" then
      return constants[i + 1]
    end
  end
  return nil
end

-- ─── The remote name table ──────────────────────────────────────────────────
-- Each entry is a function that returns the Knit controller method/proto from
-- which we extract the remote name. Mirrors VapeV4's remoteNames table.
-- These are the remotes we need for v1 features.
RemoteSources = {
  -- Combat
  AttackEntity = function()
    return Remotes.Knit.Controllers.SwordController.sendServerRequest
  end,
  -- Inventory
  EquipItem = function()
    local InventoryEntity = require(Services.ReplicatedStorage().TS.entity.entities["inventory-entity"]).InventoryEntity
    return debug.getupvalue(InventoryEntity.equipItem, 4)
  end,
  -- World (generators, item drops)
  PickupItem = function()
    return Remotes.Knit.Controllers.ItemDropController.checkForPickup
  end,
  DropItem = function()
    return Remotes.Knit.Controllers.ItemDropController.dropItemInHand
  end,
  -- Bed break
  -- Block engine (for breaking blocks)
  -- Consume
  ConsumeItem = function()
    return debug.getproto(Remotes.Knit.Controllers.ConsumeController.onEnable, 1)
  end,
  -- Reset
  ResetCharacter = function()
    return debug.getproto(Remotes.Knit.Controllers.ResetController.createBindable, 1)
  end,
  -- AFK
  AfkStatus = function()
    return debug.getproto(Remotes.Knit.Controllers.AfkController.KnitStart, 1)
  end,
}

-- ─── Extract all remote names ───────────────────────────────────────────────
-- Call this after bootstrap. Populates Remotes.names + Remotes.handles.
function Remotes.extractAll()
  if not Remotes.Knit or not Remotes.Client then
    Logger.error("Cannot extract remotes — Knit/Client not bootstrapped")
    return false
  end
  local found, missed = 0, 0
  for key, sourceFn in pairs(RemoteSources) do
    local ok, fn = pcall(sourceFn)
    if ok and fn then
      local name = extractRemoteName(fn)
      if name then
        Remotes.names[key] = name
        -- Get the handle
        local okHandle, handle = pcall(function()
          return Remotes.Client:Get(name).instance
        end)
        if okHandle and handle then
          Remotes.handles[key] = handle
          found = found + 1
        else
          Logger.warn("Got name '" .. name .. "' for " .. key .. " but handle failed")
          missed = missed + 1
        end
      else
        Logger.warn("Could not extract remote name for " .. key)
        missed = missed + 1
      end
    else
      Logger.warn("Source function failed for " .. key .. ": " .. tostring(fn))
      missed = missed + 1
    end
  end
  Logger.info(string.format("Remotes extracted: %d found, %d missed", found, missed))
  return found > 0
end

-- ─── Fire a remote by key ───────────────────────────────────────────────────
-- usage: Remotes.fire("AttackEntity", { weapon=..., chargedAttack=..., ... })
function Remotes.fire(key, args)
  local handle = Remotes.handles[key]
  if not handle then
    Logger.warn("No handle for remote: " .. key)
    return false
  end
  local ok, err = pcall(function()
    handle:FireServer(args)
  end)
  if not ok then
    Logger.error("Fire " .. key .. " failed: " .. tostring(err))
    return false
  end
  return true
end

-- Call a remote async (returns a promise-like via CallServerAsync).
-- usage: Remotes.call("PickupItem", { itemDrop = part }):andThen(cb)
function Remotes.call(key, args)
  local name = Remotes.names[key]
  if not name then
    Logger.warn("No name for remote: " .. key)
    return nil
  end
  local ok, promise = pcall(function()
    return Remotes.Client:Get(name):CallServerAsync(args)
  end)
  if not ok then
    Logger.error("Call " .. key .. " failed: " .. tostring(promise))
    return nil
  end
  return promise
end

-- ─── Block damage remote (separate from Knit — uses block-engine) ───────────
function Remotes.damageBlock(blockPosition, hitPosition, hitNormal)
  local rs = Services.ReplicatedStorage()
  local ok, BlockEngineRemotes = pcall(function()
    return require(rs["rbxts_include"]["node_modules"]["@easy-ggs"]["block-engine"].out.shared.remotes).BlockEngineRemotes.Client
  end)
  if not ok or not BlockEngineRemotes then
    Logger.warn("BlockEngineRemotes not available")
    return nil
  end
  return pcall(function()
    return BlockEngineRemotes:Get("DamageBlock"):CallServerAsync({
      blockRef = { blockPosition = blockPosition },
      hitPosition = hitPosition,
      hitNormal = hitNormal or Vector3.FromNormalId(Enum.NormalId.Top),
    })
  end)
end

return Remotes
