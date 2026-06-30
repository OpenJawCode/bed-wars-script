-- src/config.lua
-- Settings + save/load. Every feature reads/writes through here.
-- WHY: centralized config so the user can save presets and all features
-- stay in sync. Web dev mental model: this is our localStorage + Zustand store.

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

local Config = {}

-- Default settings shape. Features add their own keys.
Config.defaults = {
  -- Combat
  killaura_enabled   = false,
  killaura_range     = 18,
  killaura_speed     = 20,    -- Hz
  reach_enabled      = false,
  reach_distance     = 22,
  aimbot_enabled     = false,
  aimbot_smoothness  = 6,

  -- Movement
  fly_enabled        = false,
  fly_speed          = 50,
  speed_enabled      = false,
  speed_value        = 32,
  noclip_enabled     = false,

  -- World
  magnet_enabled     = false,
  magnet_radius      = 9999,  -- whole map
  generator_enabled  = false,
  bedaura_enabled    = false,
  shop_enabled       = false,
  shop_item          = "iron_sword",

  -- Visuals
  esp_players        = true,
  esp_beds           = true,
  esp_generators     = true,
  esp_items          = true,
  esp_tracers        = false,
  esp_distance       = 200,

  -- Misc
  antiafk_enabled    = true,
  autorejoin_enabled = false,
  spy_enabled        = false,
  ui_visible         = true,
  ui_keybind         = "RightShift",
}

Config.values = {}

-- Load from a JSON file in writefile's directory (executor-only).
-- Silently falls back to defaults if no file or no executor.
function Config.load()
  Config.values = table.clone(Config.defaults)
  pcall(function()
    if not isfile then return end
    local data = isfile("bedwars_config.json") and readfile("bedwars_config.json") or nil
    if data then
      local parsed = HttpService:JSONDecode(data)
      for k, v in pairs(parsed) do
        Config.values[k] = v
      end
    end
  end)
end

function Config.save()
  pcall(function()
    if not writefile then return end
    writefile("bedwars_config.json", HttpService:JSONEncode(Config.values))
  end)
end

function Config.get(key)
  return Config.values[key]
end

function Config.set(key, value)
  Config.values[key] = value
  Config.save()
end

-- ─── ConfigManager (v2.0) ──────────────────────────────────────────────
-- Multiple named configs (WindUI-style).
-- USAGE:
--   local mgr = Config.Manager
--   local cfg = mgr:Config("my_setup")
--   cfg:Set("killaura_range", 25)
--   cfg:Save()
--   local all = mgr:AllConfigs()  -- {"my_setup", "default", ...}
Config.Manager = {}
Config.Manager._folder = "bedwars_configs"
Config.Manager._active = "default"

function Config.Manager:_path(name)
  return self._folder .. "/" .. name .. ".json"
end

-- Save the current Config.values to a named config
function Config.Manager:Save(name)
  name = name or self._active
  local ok = pcall(function()
    if not writefile or not makefolder then return end
    if not isfile(self._folder) then makefolder(self._folder) end
    writefile(self:_path(name), HttpService:JSONEncode(Config.values))
  end)
  if ok then self._active = name end
  return ok
end

-- Load a named config into Config.values
function Config.Manager:Load(name)
  name = name or self._active
  local ok, data = pcall(function()
    if not isfile then return nil end
    return isfile(self:_path(name)) and readfile(self:_path(name)) or nil
  end)
  if ok and data then
    local parsedOk, parsed = pcall(function() return HttpService:JSONDecode(data) end)
    if parsedOk and parsed then
      for k, v in pairs(parsed) do
        Config.values[k] = v
      end
      self._active = name
      return true
    end
  end
  return false
end

-- List all saved config names
function Config.Manager:AllConfigs()
  local out = {}
  pcall(function()
    if not isfile or not listfiles then return end
    if not isfile(self._folder) then return end
    for _, file in ipairs(listfiles(self._folder)) do
      local name = file:match("/([^/]+)%.json$") or file:match("([^/]+)%.json$")
      if name then table.insert(out, name) end
    end
  end)
  return out
end

-- Create a Config object bound to a name
function Config.Manager:Config(name)
  return {
    Name = name,
    Set  = function(self, key, value) Config.values[key] = value end,
    Get  = function(self, key) return Config.values[key] end,
    Save = function(self) return Config.Manager:Save(self.Name) end,
    Load = function(self) return Config.Manager:Load(self.Name) end,
    Delete = function(self)
      pcall(function()
        if delfile then delfile(Config.Manager:_path(self.Name)) end
      end)
    end,
  }
end

return Config
