-- src/game/workspace.lua
-- Entity library + workspace walkers for Bedwars.
-- WHY: features (killaura, ESP, magnet) need a unified view of players, beds,
-- generators, and item drops. We centralize the scanning + team check here.
--
-- Key Bedwars-specific findings from research:
--   - Teams: Player:GetAttribute('Team') (numeric id), NOT Roblox Teams service
--   - Health: Character:GetAttribute('Health'), NOT Humanoid.Health
--   - Beds: CollectionService tag 'bed'
--   - Item drops: CollectionService tag 'ItemDrop'
--   - Item shops: CollectionService tag 'BedwarsItemShop'
--   - Generators: spawn ItemDrop parts (so we scan ItemDrop, not "generators")


local _BW = (getgenv and getgenv()._BW) or _G._BW
local Services = _BW.Services
local Logger   = _BW.Logger

local Workspace = {}

-- ─── Entity table ───────────────────────────────────────────────────────────
-- Cached per-player data so features don't re-scan every frame.
Workspace.entities = {}  -- Player -> entity table

-- Entity table shape:
-- {
--   Player    = Player instance,
--   Character = Character model,
--   Humanoid  = Humanoid,
--   RootPart  = HumanoidRootPart,
--   Head      = Head part,
--   Health    = number (from Character:GetAttribute('Health')),
--   MaxHealth = number,
--   HipHeight = number (for ESP box sizing),
--   Team      = number (from Player:GetAttribute('Team')),
--   IsAlive   = boolean,
--   IsLocal   = boolean,
--   IsEnemy   = boolean,
-- }

local CollectionService = Services.CollectionService()
local Players           = Services.Players()

-- ─── Team check ─────────────────────────────────────────────────────────────
-- In Bedwars, teams are a numeric attribute, not the Roblox Teams service.
local function getTeam(plr)
  if not plr then return nil end
  return plr:GetAttribute("Team")
end

function Workspace.isEnemy(plr)
  local localPlayer = Players.LocalPlayer
  if not localPlayer or not plr or plr == localPlayer then return false end
  local myTeam = getTeam(localPlayer)
  local theirTeam = getTeam(plr)
  if myTeam == nil or theirTeam == nil then return true end  -- no team = enemy
  return myTeam ~= theirTeam
end

-- ─── Build/update an entity from a character ────────────────────────────────
local function buildEntity(plr, char)
  if not plr or not char then return nil end
  local hum = char:FindFirstChildOfClass("Humanoid")
  local root = char:FindFirstChild("HumanoidRootPart")
  local head = char:FindFirstChild("Head")
  if not hum or not root then return nil end

  -- Bedwars stores Health on the Character as an attribute, not on Humanoid.
  -- Fall back to Humanoid.Health if attribute is missing.
  local health = char:GetAttribute("Health") or hum.Health
  local maxHealth = char:GetAttribute("MaxHealth") or hum.MaxHealth

  local hipHeight = hum.HipHeight + (root.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0)

  return {
    Player    = plr,
    Character = char,
    Humanoid  = hum,
    RootPart  = root,
    Head      = head,
    Health    = health,
    MaxHealth = maxHealth,
    HipHeight = hipHeight,
    Team      = getTeam(plr),
    IsAlive   = health > 0 and hum.Health > 0,
    IsLocal   = plr == Players.LocalPlayer,
    IsEnemy   = Workspace.isEnemy(plr),
  }
end

-- ─── Refresh all entities ───────────────────────────────────────────────────
-- Call this on a heartbeat (10Hz is plenty for combat targeting).
function Workspace.refresh()
  local fresh = {}
  for _, plr in ipairs(Players:GetPlayers()) do
    local char = plr.Character
    if char then
      local ent = buildEntity(plr, char)
      if ent then
        fresh[plr] = ent
      end
    end
  end
  Workspace.entities = fresh
end

-- ─── Get all alive enemy entities ───────────────────────────────────────────
-- Optionally filter by range (in studs) from the local player's root.
function Workspace.getEnemies(maxRange)
  local localRoot = Services.rootPart()
  if not localRoot then return {} end
  local out = {}
  for plr, ent in pairs(Workspace.entities) do
    if ent.IsEnemy and ent.IsAlive and ent.RootPart then
      if not maxRange or (ent.RootPart.Position - localRoot.Position).Magnitude <= maxRange then
        table.insert(out, ent)
      end
    end
  end
  -- Sort by distance (closest first)
  table.sort(out, function(a, b)
    return (a.RootPart.Position - localRoot.Position).Magnitude
         < (b.RootPart.Position - localRoot.Position).Magnitude
  end)
  return out
end

-- ─── Get the nearest enemy within range ─────────────────────────────────────
function Workspace.getNearestEnemy(maxRange)
  local enemies = Workspace.getEnemies(maxRange)
  return enemies[1] or nil
end

-- ─── Get all alive entities (including teammates, for ESP) ──────────────────
function Workspace.getAllEntities()
  local out = {}
  for _, ent in pairs(Workspace.entities) do
    if ent.IsAlive and ent.RootPart then
      table.insert(out, ent)
    end
  end
  return out
end

-- ─── Beds (CollectionService tag 'bed') ─────────────────────────────────────
function Workspace.getBeds()
  local ok, beds = pcall(function()
    return CollectionService:GetTagged("bed")
  end)
  if not ok then return {} end
  return beds or {}
end

-- ─── Item drops (CollectionService tag 'ItemDrop') ──────────────────────────
-- These are the spinning items spawned by generators + death drops.
function Workspace.getItemDrops()
  local ok, drops = pcall(function()
    return CollectionService:GetTagged("ItemDrop")
  end)
  if not ok then return {} end
  return drops or {}
end

-- ─── Item shops (CollectionService tag 'BedwarsItemShop') ───────────────────
function Workspace.getItemShops()
  local ok, shops = pcall(function()
    return CollectionService:GetTagged("BedwarsItemShop")
  end)
  if not ok then return {} end
  return shops or {}
end

-- ─── Initialize: wire player add/remove + character events ──────────────────
function Workspace.init()
  -- Initial scan
  Workspace.refresh()

  -- Wire player add/remove
  Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
      -- Will be picked up on next refresh
    end)
  end)

  -- Refresh on a steady cadence (10Hz — combat + ESP both need fresh data,
  -- but we don't need 60Hz which would burn mobile battery)
  task.spawn(function()
    while true do
      pcall(Workspace.refresh)
      task.wait(0.1)
    end
  end)

  Logger.info("Workspace entity library initialized")
end

return Workspace
