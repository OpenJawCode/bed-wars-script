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

return Config
