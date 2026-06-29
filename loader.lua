-- loader.lua
-- Minimal stub for executors that prefer a separate loader file.
-- Usage: loadstring(game:HttpGet(".../loader.lua"))()
-- This file just fetches main.lua and runs it.

local MAIN_URL = "https://raw.githubusercontent.com/OpenJawCode/bed-wars-script/main/main.lua"

local ok, source = pcall(function()
  return game:HttpGet(MAIN_URL, true)
end)

if not ok or not source then
  warn("[bw-script] Failed to fetch main.lua from " .. MAIN_URL)
  return
end

local fn, err = loadstring(source, "main.lua")
if not fn then
  warn("[bw-script] Parse error in main.lua: " .. tostring(err))
  return
end

fn()
