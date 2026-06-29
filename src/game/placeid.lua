-- src/game/placeid.lua
-- Easy.gg Bedwars PlaceIds. The script auto-detects which one the player is in.
-- WHY: Bedwars has 4 PlaceIds (lobby + 3 match variants). Features should only
-- activate in match places. Web dev mental model: this is our route matcher.

local PlaceId = {
  LOBBY   = 6872265039,
  MATCH   = 6872274481,
  MEGA    = 8444591321,
  MICRO   = 8560631822,
}

-- All known Bedwars PlaceIds.
PlaceId.all = { PlaceId.LOBBY, PlaceId.MATCH, PlaceId.MEGA, PlaceId.MICRO }

-- Match PlaceIds (where features should activate).
PlaceId.matches = { PlaceId.MATCH, PlaceId.MEGA, PlaceId.MICRO }

-- Is the current game a Bedwars place?
function PlaceId.isBedwars(pid)
  pid = pid or game.PlaceId
  for _, id in ipairs(PlaceId.all) do
    if id == pid then return true end
  end
  return false
end

-- Is the player in an active match (not the lobby)?
function PlaceId.isMatch(pid)
  pid = pid or game.PlaceId
  for _, id in ipairs(PlaceId.matches) do
    if id == pid then return true end
  end
  return false
end

return PlaceId
