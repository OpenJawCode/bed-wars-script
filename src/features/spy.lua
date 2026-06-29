-- src/features/spy.lua
-- Live RemoteEvent/Function spy. Hooks __namecall to log every FireServer /
-- InvokeServer the client makes. Useful for discovering new remotes when
-- Bedwars updates.
--
-- Pattern: hookmetamethod on __namecall. When the method is FireServer or
-- InvokeServer, log the remote name + args. Filter by name to avoid spam.
--
-- Requires an executor with hookmetamethod (Delta + Codex both support it).

local Services  = require(script.Parent.Parent.services)
local Logger    = require(script.Parent.Parent.util.logger)

local Spy = {
  enabled   = false,
  filter    = "",       -- only log remotes whose name contains this
  _original = nil,
  _log      = {},       -- last N entries for UI display
}

-- Hook __namecall to intercept FireServer/InvokeServer.
function Spy.enable()
  if Spy.enabled then return end
  if not hookmetamethod then
    Logger.warn("hookmetamethod not available — Spy disabled")
    return false
  end

  local mt = getrawmetatable(game)
  Spy._original = getrawmetatable(game).__namecall
  setreadonly(mt, false)

  local original = Spy._original
  local function hookedNamecall(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
      local name = self.Name or tostring(self)
      if Spy.filter == "" or string.find(string.lower(name), string.lower(Spy.filter), 1, true) then
        local entry = {
          time = tick(),
          name = name,
          method = method,
          args = {...},
        }
        table.insert(Spy._log, entry)
        if #Spy._log > 100 then table.remove(Spy._log, 1) end
        print(string.format("[SPY] %s:%s(%d args)", name, method, select("#", ...)))
      end
    end
    return original(self, ...)
  end

  hookmetamethod(game, "__namecall", hookedNamecall)
  Spy.enabled = true
  Logger.info("Spy enabled (filter: '" .. Spy.filter .. "')")
  return true
end

function Spy.disable()
  if not Spy.enabled then return end
  if Spy._original and hookmetamethod then
    hookmetamethod(game, "__namecall", Spy._original)
  end
  Spy.enabled = false
  Spy._original = nil
  Logger.info("Spy disabled")
end

function Spy.setFilter(text)
  Spy.filter = text or ""
end

function Spy.getRecent(n)
  n = n or 20
  local start = math.max(1, #Spy._log - n + 1)
  local out = {}
  for i = start, #Spy._log do
    table.insert(out, Spy._log[i])
  end
  return out
end

return Spy
