-- src/game/services.lua
-- Cached game:GetService lookups. WHY: GetService is cheap but not free, and
-- every feature calls it. Cache once at boot. Web dev mental model: this is
-- our `import { foo } from 'bar'` — resolved once, used everywhere.

local Services = {}

local cache = {}

-- Get a service by name, cached. Returns the Instance.
function Services.get(name)
  if cache[name] then return cache[name] end
  local svc = game:GetService(name)
  cache[name] = svc
  return svc
end

-- Pre-resolved common services.
function Services.Players()         return Services.get("Players") end
function Services.Workspace()       return Services.get("Workspace") end
function Services.ReplicatedStorage() return Services.get("ReplicatedStorage") end
function Services.ReplicatedFirst()   return Services.get("ReplicatedFirst") end
function Services.Teams()           return Services.get("Teams") end
function Services.RunService()      return Services.get("RunService") end
function Services.UserInputService() return Services.get("UserInputService") end
function Services.TweenService()    return Services.get("TweenService") end
function Services.CollectionService() return Services.get("CollectionService") end
function Services.HttpService()     return Services.get("HttpService") end
function Services.TeleportService() return Services.get("TeleportService") end

-- LocalPlayer + Character helpers (re-resolved because they change).
function Services.localPlayer()
  return Services.Players().LocalPlayer
end

function Services.character()
  local plr = Services.localPlayer()
  return plr and plr.Character or nil
end

function Services.humanoid()
  local char = Services.character()
  return char and char:FindFirstChildOfClass("Humanoid") or nil
end

function Services.rootPart()
  local char = Services.character()
  return char and char:FindFirstChild("HumanoidRootPart") or nil
end

-- Camera (can change, so not cached).
function Services.camera()
  return Services.Workspace().CurrentCamera
end

return Services
