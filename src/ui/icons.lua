-- src/ui/icons.lua
-- Roblox asset IDs for icons used throughout the UI.
-- WHY: we don't bundle image uploads — we use Roblox's public asset library.
-- Web dev mental model: this is our icon SVG sprite.
-- All IDs are from Roblox's public catalog (game-icons style, monochrome).

local Icons = {
  -- Tab icons (bottom bar)
  Combat    = 6035047426;    -- sword
  Visuals   = 6035047393;    -- eye
  Movement  = 6031260132;    -- wind/wings
  World     = 6034286349;    -- globe
  Misc      = 6031281438;    -- settings gear

  -- Feature icons
  Killaura  = 6035047426;
  Reach     = 6031281438;
  Aimbot    = 6035047393;
  ESP       = 6035047393;
  Fly       = 6031260132;
  Speed     = 6031260132;
  Noclip    = 6031281438;
  Magnet    = 6034993713;
  Shop      = 6035029144;
  Generator = 6034993713;
  Bed       = 6035029144;
  AntiAFK   = 6031281438;
  AutoRejoin= 6031281438;
  Spy       = 6035047393;

  -- Status icons
  Check     = 6035047393;
  X         = 6031260132;
  Warning   = 6031281438;
  Info      = 6034993713;

  -- Logo
  Logo      = 6035047426;
}

-- Helper to apply an icon to an ImageLabel.
function Icons.apply(imageLabel, assetId, color)
  imageLabel.Image = "rbxassetid://" .. tostring(assetId)
  if color then
    imageLabel.ImageColor3 = color
  end
end

return Icons
