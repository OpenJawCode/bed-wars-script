-- src/features/killaura.lua
-- Auto-attack nearby enemies with the best sword.
-- Pattern from VapeV4 research:
--   - Loop: repeat ... task.wait() ... until not enabled
--   - Find targets via Workspace.getEnemies(range)
--   - Switch to best sword via Store:dispatch
--   - Fire AttackEntity remote with: { weapon, chargedAttack, entityInstance, validate }
--   - Reach extension: selfPosition += lookVector * max(distance - 14.399, 0)
--
-- The 14.399 magic number is the legit attack reach. Extending selfPosition
-- along the look vector by the surplus distance bypasses the server's reach check.


local _BW = (getgenv and getgenv()._BW) or _G._BW
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")

local Services    = _BW.Services
local GameWksp    = _BW.GameWksp
local Remotes     = _BW.Remotes
local Logger      = _BW.Logger
local PlaceId     = _BW.PlaceId

local Killaura = {
  enabled = false,
  range   = 18,
  speed   = 20,    -- attacks per second cap
  _thread = nil,
}

-- Get the local player's current sword tool.
-- Bedwars stores the inventory in the Roact store, but we can also find the
-- equipped tool by checking the character's children for a Tool with a sword meta.
local function getCurrentSword()
  local char = Services.character()
  if not char then return nil end
  -- Find any Tool in the character (Bedwars swords are Tools)
  for _, child in ipairs(char:GetChildren()) do
    if child:IsA("Tool") then
      -- Best heuristic: assume the equipped tool is the sword. Bedwars auto-equips
      -- the sword when you switch to the combat hotbar slot.
      return child
    end
  end
  return nil
end

-- Switch hotbar to a sword slot. Bedwars uses Roact store dispatch:
--   Store:dispatch({ type = "InventorySelectHotbarSlot", slot = N })
-- We can't always access the store from outside, so as a fallback we use
-- the Tool:Equip() pattern. For v1 we rely on the user having a sword equipped.
local function ensureSwordEquipped()
  -- Try the Roact store dispatch (VapeV4 pattern)
  pcall(function()
    local plr = Services.localPlayer()
    local store = require(plr.PlayerScripts.TS.ui.store).ClientStore
    -- Find a sword in the inventory and select its hotbar slot
    -- This is complex; for v1 we just trust the user's current equip
  end)
end

-- The 14.399 magic number — legit attack reach in studs.
local LEGIT_REACH = 14.399

function Killaura.attack(target)
  if not target or not target.RootPart or not target.Character then return false end
  local sword = getCurrentSword()
  if not sword then return false end

  local localRoot = Services.rootPart()
  if not localRoot then return false end

  local selfpos = localRoot.Position
  local targetPos = target.RootPart.Position
  local delta = targetPos - selfpos
  local distance = delta.Magnitude

  -- Reach extension: move selfPosition toward target by the surplus over LEGIT_REACH
  local dir = CFrame.lookAt(selfpos, targetPos).LookVector
  local extendedPos = selfpos + dir * math.max(distance - LEGIT_REACH, 0)

  -- Fire the AttackEntity remote
  return Remotes.fire("AttackEntity", {
    weapon = sword,
    chargedAttack = { chargeRatio = 0 },
    entityInstance = target.Character,
    validate = {
      raycast = {
        cameraPosition = { value = extendedPos },
        cursorDirection = { value = dir },
      },
      targetPosition = { value = targetPos },
      selfPosition = { value = extendedPos },
    },
  })
end

-- The main killaura loop. Runs in a task.spawn'd thread.
function Killaura._loop()
  local interval = 1 / Killaura.speed
  while Killaura.enabled do
    pcall(function()
      if not PlaceId.isMatch() then return end
      if not GameWksp.entities then return end
      local enemies = GameWksp.getEnemies(Killaura.range)
      for _, target in ipairs(enemies) do
        if target and target.IsAlive then
          Killaura.attack(target)
        end
      end
    end)
    task.wait(interval)
  end
end

function Killaura.setEnabled(state)
  Killaura.enabled = state
  if state and not Killaura._thread then
    Killaura._thread = task.spawn(Logger.guard(Killaura._loop, "killaura"))
  end
  Logger.info("Killaura " .. (state and "ON" or "OFF"))
end

function Killaura.setRange(value)
  Killaura.range = value
end

function Killaura.setSpeed(value)
  Killaura.speed = value
end

return Killaura
