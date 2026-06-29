-- src/features/reach.lua
-- Extends melee attack range by rewriting selfPosition in the AttackEntity
-- validate table. Pairs with Killaura (or works standalone by hooking the
-- remote fire).
--
-- VapeV4 pattern: hook Client:Get to rewrite selfPosition in attack calls.
-- For v1 we implement it as a Killaura modifier — Killaura checks Reach.enabled
-- and uses the extended distance.

local Reach = {
  enabled  = false,
  distance = 22,
}

function Reach.setEnabled(state)
  Reach.enabled = state
end

function Reach.setDistance(value)
  Reach.distance = value
end

-- Returns the effective reach to use in Killaura.
-- When enabled, we extend the search range + the selfPosition extension math.
function Reach.getEffectiveRange(baseRange)
  if Reach.enabled then
    return math.max(Reach.distance, baseRange or 18)
  end
  return baseRange or 18
end

return Reach
