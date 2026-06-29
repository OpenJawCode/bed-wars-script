-- src/features/shop.lua
-- Auto-buy from the Bedwars item shop. Uses the BedwarsPurchaseItem remote:
--   Client:Get('BedwarsPurchaseItem'):CallServerAsync({ shopItem = ..., shopId = ... })
--
-- The user picks an item (e.g. "iron_sword") from a dropdown and we buy one
-- every few seconds. ShopId is the nearest BedwarsItemShop (CollectionService tag).
--
-- Note: VapeV4 doesn't have a direct autobuy module — it relies on the game's
-- shop UI. We implement autobuy by firing the purchase remote directly.

local Services   = require(script.Parent.Parent.services)
local GameWksp   = require(script.Parent.Parent.game.workspace)
local Remotes     = require(script.Parent.Parent.game.remotes)
local Logger      = require(script.Parent.Parent.util.logger)
local PlaceId     = require(script.Parent.Parent.game.placeid)

local Shop = {
  enabled  = false,
  item     = "iron_sword",
  interval = 2,   -- seconds between purchases
  _thread  = nil,
}

-- Find the nearest item shop and return its id attribute.
local function getNearestShopId()
  local localRoot = Services.rootPart()
  if not localRoot then return nil end
  local shops = GameWksp.getItemShops()
  local nearest, nearestDist = nil, math.huge
  for _, shop in ipairs(shops) do
    local part = shop:IsA("Model") and (shop.PrimaryPart or shop:FindFirstChildWhichIsA("BasePart")) or shop
    if part then
      local dist = (part.Position - localRoot.Position).Magnitude
      if dist < nearestDist then
        nearestDist = dist
        nearest = shop
      end
    end
  end
  if not nearest then return nil end
  -- The shop id is stored as an attribute
  return nearest:GetAttribute("ShopId") or nearest:GetAttribute("Id") or nearest.Name
end

function Shop._loop()
  while Shop.enabled do
    pcall(function()
      if not PlaceId.isMatch() then return end
      local localRoot = Services.rootPart()
      if not localRoot then return end

      local shopId = getNearestShopId()
      if not shopId then return end

      -- Fire the purchase remote
      if Remotes.Client then
        pcall(function()
          Remotes.Client:Get("BedwarsPurchaseItem"):CallServerAsync({
            shopItem = Shop.item,
            shopId = shopId,
          })
        end)
      end
    end)
    task.wait(Shop.interval)
  end
end

function Shop.setEnabled(state)
  Shop.enabled = state
  if state and not Shop._thread then
    Shop._thread = task.spawn(Logger.guard(Shop._loop, "shop"))
  end
  Logger.info("Shop auto-buy " .. (state and "ON" or "OFF"))
end

function Shop.setItem(itemName)
  Shop.item = itemName
end

return Shop
