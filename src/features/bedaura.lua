-- src/features/bedaura.lua
-- Auto-break nearby enemy beds. Walks CollectionService:GetTagged('bed'),
-- filters to enemy team, fires the BedwarsBedBreak remote (or falls back to
-- DamageBlock on the bed's parts).
--
-- Bedwars beds: a Model tagged 'bed' containing a Base Part. To destroy, we
-- either call the BedwarsBedBreak remote (via Client:Get) or DamageBlock on
-- each bed part's position. The remote is cleaner; DamageBlock is the fallback.

local Services   = require(script.Parent.Parent.services)
local GameWksp   = require(script.Parent.Parent.game.workspace)
local Remotes     = require(script.Parent.Parent.game.remotes)
local Logger      = require(script.Parent.Parent.util.logger)
local PlaceId     = require(script.Parent.Parent.game.placeid)

local BedAura = {
  enabled  = false,
  radius   = 30,
  _thread  = nil,
}

-- Determine if a bed belongs to an enemy team.
-- Bed models in Bedwars have a GetAttribute('Team') like players do.
local function isEnemyBed(bedModel)
  local localPlayer = Services.localPlayer()
  if not localPlayer then return false end
  local myTeam = localPlayer:GetAttribute("Team")
  local bedTeam = bedModel:GetAttribute("Team")
  if myTeam == nil or bedTeam == nil then return true end
  return myTeam ~= bedTeam
end

function BedAura._loop()
  while BedAura.enabled do
    pcall(function()
      if not PlaceId.isMatch() then return end
      local localRoot = Services.rootPart()
      if not localRoot then return end

      local beds = GameWksp.getBeds()
      for _, bed in ipairs(beds) do
        if isEnemyBed(bed) then
          -- Find the primary part or any Part in the bed model
          local part = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
          if not part then continue end
          local dist = (part.Position - localRoot.Position).Magnitude
          if dist > BedAura.radius then continue end

          -- Try the bed break remote first
          local ok = pcall(function()
            if Remotes.Client then
              Remotes.Client:WaitFor("BedwarsBedBreak")
              local remote = Remotes.Client:Get("BedwarsBedBreak")
              if remote and remote.instance then
                remote.instance:FireServer({ bed = bed })
              end
            end
          end)

          -- Fallback: damage each part via the block engine remote
          if not ok then
            for _, p in ipairs(bed:GetDescendants()) do
              if p:IsA("BasePart") then
                Remotes.damageBlock(p.Position, p.Position, Vector3.FromNormalId(Enum.NormalId.Top))
              end
            end
          end
        end
      end
    end)
    task.wait(0.5)  -- 2Hz (bed breaking doesn't need to be fast)
  end
end

function BedAura.setEnabled(state)
  BedAura.enabled = state
  if state and not BedAura._thread then
    BedAura._thread = task.spawn(Logger.guard(BedAura._loop, "bedaura"))
  end
  Logger.info("BedAura " .. (state and "ON" or "OFF"))
end

function BedAura.setRadius(value)
  BedAura.radius = value
end

return BedAura
