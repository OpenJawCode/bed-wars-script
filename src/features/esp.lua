-- src/features/esp.lua
-- ESP for players, beds, generators, and item drops. Uses the Drawing API
-- (Drawing.new('Square'/'Line'/'Text')) which is UNC-standard and supported
-- on Delta + Codex.
--
-- Pattern from VapeV4 research:
--   - Runs on RenderStepped (every frame on desktop, throttled on mobile)
--   - Box sized from HipHeight: top + bottom CFrame offsets projected to screen
--   - Health bar = vertical Line on the left of the box
--   - Tracers = Line from screen center bottom to target
--   - Subscribe to entity add/remove events (we use Workspace.entities refresh)
--
-- Mobile throttle: 30Hz on touch devices to save battery. 60Hz on desktop.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Services  = require(script.Parent.Parent.services)
local GameWksp  = require(script.Parent.Parent.game.workspace)
local Theme     = require(script.Parent.ui.theme)
local Logger    = require(script.Parent.Parent.util.logger)
local PlaceId   = require(script.Parent.Parent.game.placeid)

local ESP = {
  enabled     = false,
  showPlayers  = true,
  showBeds     = true,
  showGens     = true,
  showItems    = true,
  showTracers  = false,
  maxDistance  = 200,
  _conn        = nil,
  _drawings    = {},   -- entity -> { square, line, text, tracer }
  _bedDrawings = {},
  _genDrawings = {},
  _itemDrawings= {},
  _lastFrame   = 0,
}

-- ─── Drawing factory ────────────────────────────────────────────────────────
-- Creates a Square + Line (health) + Text (name) + Line (tracer) for an entity.
local function makePlayerDrawings()
  if not Drawing then return nil end
  local square = Drawing.new("Square")
  square.Thickness = 1.5
  square.Filled = false
  square.Transparency = 1

  local healthLine = Drawing.new("Line")
  healthLine.Thickness = 2
  healthLine.Transparency = 1

  local healthBg = Drawing.new("Line")
  healthBg.Thickness = 2
  healthBg.Transparency = 1
  healthBg.Color = Color3.fromRGB(20, 20, 20)

  local text = Drawing.new("Text")
  text.Size = 13
  text.Font = 2  -- Gotham
  text.Center = true
  text.Outline = true
  text.Transparency = 1

  local tracer = Drawing.new("Line")
  tracer.Thickness = 1
  tracer.Transparency = 1

  return { square = square, health = healthLine, healthBg = healthBg, text = text, tracer = tracer }
end

local function makeSimpleDrawings()
  if not Drawing then return nil end
  local text = Drawing.new("Text")
  text.Size = 12
  text.Font = 2
  text.Center = true
  text.Outline = true
  text.Transparency = 1
  return { text = text }
end

-- ─── Team color helper ──────────────────────────────────────────────────────
local function teamColor(entity)
  -- Try Roblox TeamColor first (for visual coloring)
  if entity.Player and entity.Player.TeamColor then
    local tc = entity.Player.TeamColor.Color
    if tc then return tc end
  end
  -- Fall back to attribute-based team
  local team = entity.Team
  if team == 1 then return Theme.Color.TeamRed
  elseif team == 2 then return Theme.Color.TeamBlue
  elseif team == 3 then return Theme.Color.TeamGreen
  elseif team == 4 then return Theme.Color.TeamYellow
  end
  return Theme.Color.TeamNone
end

-- Generator tier color (by item drop name)
local function tierColor(dropName)
  local n = string.lower(dropName or "")
  if string.find(n, "emerald") then return Theme.Color.TierEmerald
  elseif string.find(n, "diamond") then return Theme.Color.TierDiamond
  elseif string.find(n, "gold") then return Theme.Color.TierGold
  elseif string.find(n, "iron") then return Theme.Color.TierIron
  end
  return Theme.Color.TextMuted
end

-- ─── The render loop ────────────────────────────────────────────────────────
function ESP._onRenderStepped()
  if not ESP.enabled then return end
  if not PlaceId.isMatch() then return end
  if not Drawing then return end  -- executor doesn't support Drawing API

  local camera = Services.camera()
  local localRoot = Services.rootPart()
  local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
  if not camera or not localRoot then return end

  -- ─── Players ─────────────────────────────────────────────────────────
  if ESP.showPlayers then
    local entities = GameWksp.getAllEntities()
    for _, ent in ipairs(entities) do
      if not ent.IsLocal and ent.RootPart then
        local dist = (ent.RootPart.Position - localRoot.Position).Magnitude
        if dist > ESP.maxDistance then
          -- hide
          if ESP._drawings[ent] then
            for _, d in pairs(ESP._drawings[ent]) do d.Visible = false end
          end
          continue
        end

        -- Get or create drawings for this entity
        if not ESP._drawings[ent] then
          ESP._drawings[ent] = makePlayerDrawings()
        end
        local d = ESP._drawings[ent]
        if not d then continue end

        -- Project top + bottom of box
        local look = camera.CFrame.LookVector
        local topCF = CFrame.lookAlong(ent.RootPart.Position, look) * CFrame.new(2, ent.HipHeight, 0)
        local botCF = CFrame.lookAlong(ent.RootPart.Position, look) * CFrame.new(-2, -ent.HipHeight - 1, 0)
        local topScreen, topVis = camera:WorldToViewportPoint(topCF.Position)
        local botScreen, botVis = camera:WorldToViewportPoint(botCF.Position)
        local visible = topVis and botVis

        if not visible then
          d.square.Visible = false
          d.health.Visible = false
          d.healthBg.Visible = false
          d.text.Visible = false
          d.tracer.Visible = false
          continue
        end

        local sizeX = topScreen.X - botScreen.X
        local sizeY = topScreen.Y - botScreen.Y
        local posX = topScreen.X - sizeX / 2
        local posY = topScreen.Y - sizeY / 2

        -- Box
        local color = teamColor(ent)
        d.square.Visible = true
        d.square.Size = Vector2.new(math.abs(sizeX), math.abs(sizeY))
        d.square.Position = Vector2.new(posX, posY)
        d.square.Color = color
        d.square.Transparency = 1

        -- Health bar (left of box)
        local healthRatio = ent.MaxHealth > 0 and math.clamp(ent.Health / ent.MaxHealth, 0, 1) or 0
        d.healthBg.Visible = true
        d.healthBg.From = Vector2.new(posX - 6, posY)
        d.healthBg.To = Vector2.new(posX - 6, posY + math.abs(sizeY))
        d.health.Visible = true
        d.health.From = Vector2.new(posX - 6, posY + math.abs(sizeY) * (1 - healthRatio))
        d.health.To = Vector2.new(posX - 6, posY + math.abs(sizeY))
        d.health.Color = Color3.fromHSV(healthRatio / 2.5, 0.89, 0.75)

        -- Name + distance
        d.text.Visible = true
        d.text.Text = string.format("%s [%dm]", ent.Player and ent.Player.Name or "?", math.floor(dist))
        d.text.Position = Vector2.new(posX, posY - 16)
        d.text.Color = color
        d.text.Transparency = 1

        -- Tracer (from screen bottom center to target)
        if ESP.showTracers then
          d.tracer.Visible = true
          d.tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
          d.tracer.To = Vector2.new(topScreen.X, topScreen.Y)
          d.tracer.Color = color
        else
          d.tracer.Visible = false
        end
      end
    end
  end

  -- ─── Beds ────────────────────────────────────────────────────────────
  if ESP.showBeds then
    local beds = GameWksp.getBeds()
    for i, bed in ipairs(beds) do
      local part = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
      if not part then continue end
      local dist = (part.Position - localRoot.Position).Magnitude
      if dist > ESP.maxDistance then continue end

      if not ESP._bedDrawings[bed] then
        ESP._bedDrawings[bed] = makeSimpleDrawings()
      end
      local d = ESP._bedDrawings[bed]
      if not d then continue end

      local screen, vis = camera:WorldToViewportPoint(part.Position)
      if not vis then
        d.text.Visible = false
        continue
      end

      -- Determine if bed is alive (has visible parts) and team color
      local bedTeam = bed:GetAttribute("Team")
      local color = bedTeam == 1 and Theme.Color.TeamRed
                 or bedTeam == 2 and Theme.Color.TeamBlue
                 or bedTeam == 3 and Theme.Color.TeamGreen
                 or bedTeam == 4 and Theme.Color.TeamYellow
                 or Theme.Color.TeamNone

      d.text.Visible = true
      d.text.Text = string.format("BED [%dm]", math.floor(dist))
      d.text.Position = Vector2.new(screen.X, screen.Y - 14)
      d.text.Color = color
      d.text.Transparency = 1
    end
  end

  -- ─── Item drops (generators spawn these) ─────────────────────────────
  if ESP.showItems or ESP.showGens then
    local drops = GameWksp.getItemDrops()
    for _, drop in ipairs(drops) do
      local dist = (drop.Position - localRoot.Position).Magnitude
      if dist > ESP.maxDistance then continue end

      if not ESP._itemDrawings[drop] then
        ESP._itemDrawings[drop] = makeSimpleDrawings()
      end
      local d = ESP._itemDrawings[drop]
      if not d then continue end

      local screen, vis = camera:WorldToViewportPoint(drop.Position)
      if not vis then
        d.text.Visible = false
        continue
      end

      local color = tierColor(drop.Name)
      d.text.Visible = true
      d.text.Text = string.format("%s [%dm]", drop.Name or "item", math.floor(dist))
      d.text.Position = Vector2.new(screen.X, screen.Y - 10)
      d.text.Color = color
      d.text.Transparency = 1
    end
  end
end

-- ─── Mobile-throttled render loop ───────────────────────────────────────────
-- On mobile (touch), we run at ~30Hz to save battery. Desktop runs full 60Hz.
function ESP._onRenderThrottled()
  if not ESP.enabled then return end
  local now = tick()
  local minInterval = UserInputService.TouchEnabled and (1/30) or 0
  if now - ESP._lastFrame < minInterval then return end
  ESP._lastFrame = now
  ESP._onRenderStepped()
end

function ESP.setEnabled(state)
  ESP.enabled = state
  if state and not ESP._conn then
    if not Drawing then
      Logger.warn("Drawing API not available — ESP requires an executor with Drawing.new (Delta/Codex/Fluxus)")
      return false
    end
    ESP._conn = RunService.RenderStepped:Connect(Logger.guard(ESP._onRenderThrottled, "esp"))
  elseif not state and ESP._conn then
    ESP._conn:Disconnect()
    ESP._conn = nil
    -- Hide all drawings
    for _, d in pairs(ESP._drawings) do
      for _, obj in pairs(d) do obj.Visible = false end
    end
    for _, d in pairs(ESP._bedDrawings) do
      for _, obj in pairs(d) do obj.Visible = false end
    end
    for _, d in pairs(ESP._itemDrawings) do
      for _, obj in pairs(d) do obj.Visible = false end
    end
  end
  Logger.info("ESP " .. (state and "ON" or "OFF"))
  return true
end

function ESP.setShowPlayers(v) ESP.showPlayers = v end
function ESP.setShowBeds(v)    ESP.showBeds    = v end
function ESP.setShowGens(v)    ESP.showGens    = v end
function ESP.setShowItems(v)   ESP.showItems   = v end
function ESP.setShowTracers(v) ESP.showTracers = v end
function ESP.setMaxDistance(v) ESP.maxDistance = v end

return ESP
