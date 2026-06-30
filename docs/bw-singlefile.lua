-- docs/bw-singlefile.lua
-- Bedwars Script — SINGLE FILE version. No HttpGet required.
-- Paste this entire string into your executor (Delta/Codex/etc).
--
-- Generated from the multi-file project by scripts/build_singlefile.py
-- Total: 28 modules inlined.

-- ═══ SETUP: package registry ═══
local _BW = (getgenv and getgenv()) or _G
_BW._BW = _BW

-- ─── util/logger.lua ───
do
  local _module = (function()
  -- src/util/logger.lua
  -- Lightweight logger with level filtering + executor console output.
  -- WHY: features need to log without spamming. We centralize so the user can
  -- silence everything from one place.
  local Logger = {
    level = 3,  -- 1=error, 2=warn, 3=info, 4=debug
    prefix = "[bw-script]",
  }
  
  local function fmt(level, msg)
    return string.format("%s [%s] %s", Logger.prefix, level, tostring(msg))
  end
  
  function Logger.error(msg)
    if Logger.level >= 1 then
      warn(fmt("ERROR", msg))
    end
  end
  
  function Logger.warn(msg)
    if Logger.level >= 2 then
      warn(fmt("WARN", msg))
    end
  end
  
  function Logger.info(msg)
    if Logger.level >= 3 then
      print(fmt("INFO", msg))
    end
  end
  
  function Logger.debug(msg)
    if Logger.level >= 4 then
      print(fmt("DEBUG", msg))
    end
  end
  
  -- Wrap a function in pcall + log on error. Returns the same signature.
  -- WHY: every feature loop should be pcall-armored so one bad feature never
  -- crashes the whole script. This is the helper.
  function Logger.guard(fn, label)
    label = label or "anonymous"
    return function(...)
      local results = table.pack(pcall(fn, ...))
      if not results[1] then
        Logger.error(label .. ": " .. tostring(results[2]))
        return nil
      end
      return table.unpack(results, 2, results.n)
    end
  end
  
  return Logger
  
  end)()
  if _module then _BW.Logger = _module end
end

-- ─── ui/theme.lua ───
do
  local _module = (function()
  -- src/ui/theme.lua
  -- Design tokens — single source of truth for ALL UI code.
  -- Markdown mirror lives at docs/DESIGN.md.
  --
  -- Design DNA: deep dark + emerald accent (primary), gold (secondary), red (danger), blue (info).
  -- One easing function everywhere (Quint). Heavy glass (low alpha).
  
  local Theme = {}
  
  -- ─── Colors ─────────────────────────────────────────────────────────────────
  Theme.Color = {
    -- Surfaces
    Background      = Color3.fromRGB(10,  15,  26);
    Surface         = Color3.fromRGB(18,  22,  32);
    SurfaceRaised   = Color3.fromRGB(24,  30,  42);
    SurfaceInset    = Color3.fromRGB(14,  18,  26);
    SurfacePressed  = Color3.fromRGB(30,  36,  50);
  
    -- Borders
    Border          = Color3.fromRGB(255, 255, 255);
    BorderStrong    = Color3.fromRGB(255, 255, 255);
  
    -- Text
    TextPrimary     = Color3.fromRGB(240, 242, 248);
    TextSecondary   = Color3.fromRGB(160, 170, 188);
    TextMuted       = Color3.fromRGB(110, 120, 138);
    TextDisabled    = Color3.fromRGB( 80,  90, 108);
  
    -- Accent (emerald — primary)
    Accent          = Color3.fromRGB(16,  185, 129);
    AccentHover     = Color3.fromRGB(20,  205, 140);
    AccentPressed   = Color3.fromRGB(13,  160, 110);
    AccentGlow      = Color3.fromRGB(16,  185, 129);
  
    -- Accent secondary (gold)
    Gold            = Color3.fromRGB(245, 183,   0);
    GoldHover       = Color3.fromRGB(255, 195,  20);
    GoldPressed     = Color3.fromRGB(220, 160,   0);
  
    -- Status
    Success         = Color3.fromRGB(34,  197,  94);
    Danger          = Color3.fromRGB(239,  68,  68);
    DangerHover     = Color3.fromRGB(255,  90,  90);
    Info            = Color3.fromRGB(59,  130, 246);
    Warning         = Color3.fromRGB(245, 158,  11);
  
    -- Tab colors
    TabActive       = Color3.fromRGB(16,  185, 129);
    TabInactive     = Color3.fromRGB(140, 150, 168);
  
    -- Backdrop
    Backdrop        = Color3.fromRGB(0,   0,   0);
  
    -- Team colors
    TeamRed         = Color3.fromRGB(239,  68,  68);
    TeamBlue        = Color3.fromRGB(59,  130, 246);
    TeamGreen       = Color3.fromRGB(34,  197,  94);
    TeamYellow      = Color3.fromRGB(250, 204,  21);
    TeamNone        = Color3.fromRGB(160, 170, 188);
  
    -- Generator tiers
    TierIron        = Color3.fromRGB(180, 188, 200);
    TierGold        = Color3.fromRGB(250, 204,  21);
    TierDiamond     = Color3.fromRGB(96,  213, 255);
    TierEmerald     = Color3.fromRGB(52,  211, 153);
  }
  
  -- ─── Transparency (glass) — heavy glass so gameplay is visible ───────────
  Theme.Alpha = {
    BackgroundOpaque  = 0;
    GlassPanel        = 0.06;
    GlassCard         = 0.10;
    GlassCardHover    = 0.06;
    GlassCardPressed  = 0.02;
    GlassInput        = 0.20;
    Backdrop          = 0.55;
    Border            = 0.92;
    BorderStrong      = 0.86;
    BorderAccent      = 0.50;
    AccentGlowOuter   = 0.60;
    AccentGlowInner   = 0.30;
    Overlay           = 0.40;
  }
  
  -- ─── Typography ────────────────────────────────────────────────────────────
  Theme.Font = {
    Display   = Enum.Font.GothamBlack;
    Heading   = Enum.Font.GothamBold;
    Body      = Enum.Font.GothamMedium;
    Label     = Enum.Font.Gotham;
    Caption   = Enum.Font.GothamMedium;
    Mono      = Enum.Font.Code;
    Tab       = Enum.Font.GothamBold;
    Icon      = Enum.Font.GothamBlack;
    IconSmall = Enum.Font.GothamBlack;
  }
  
  Theme.Size = {
    Display   = 18;
    Heading   = 15;
    Body      = 13;
    Label     = 12;
    Caption   = 10;
    Tab       = 13;
    Icon      = 18;
    IconSmall = 14;
    Title     = 16;
    Value     = 13;
  }
  
  -- ─── Radii (rounded everything) ────────────────────────────────────────────
  Theme.Radius = {
    Pill    = 9999;
    Card    = 12;
    Input   = 8;
    Toggle  = 9999;
    Small   = 6;
    Bar     = 3;
  }
  
  -- ─── Spacing (8pt grid) ────────────────────────────────────────────────────
  Theme.Space = {
    XS   = 4;
    SM   = 8;
    MD   = 12;
    LG   = 16;
    XL   = 24;
    XXL  = 32;
  }
  
  -- ─── Touch targets (mobile-first) ──────────────────────────────────────────
  Theme.Touch = {
    MinTarget       = 44;
    RowHeight       = 48;
    HeaderHeight    = 56;
    TopTabHeight    = 48;
    TopTabWidth     = 100;
    StatusBarHeight = 36;
    FABSize         = 56;
    FABMargin       = 12;
    PanicBtnHeight  = 44;
    SearchHeight    = 36;
  }
  
  -- ─── Motion (Quint everywhere) ─────────────────────────────────────────────
  Theme.Motion = {
    Press      = 0.10;
    Tap        = 0.18;
    Open       = 0.32;
    Reveal     = 0.45;
    Boot       = 0.55;
    Glow       = 1.80;
    Hover      = 0.18;
    Snap       = 0.28;
    Backdrop   = 0.18;
  }
  
  Theme.Easing = {
    Press    = Enum.EasingStyle.Quint;
    Tap      = Enum.EasingStyle.Quint;
    Open     = Enum.EasingStyle.Quint;
    Reveal   = Enum.EasingStyle.Quint;
    Boot     = Enum.EasingStyle.Quint;
    Glow     = Enum.EasingStyle.Sine;     -- exception: sine for ambient breathing
    Hover    = Enum.EasingStyle.Quint;
    Snap     = Enum.EasingStyle.Quint;
    Backdrop = Enum.EasingStyle.Quint;
  }
  
  -- ─── Z-index scale ─────────────────────────────────────────────────────────
  Theme.Z = {
    Base          = 1;
    Backdrop      = 40;
    FAB           = 50;
    Window        = 60;
    WindowContent = 61;
    Notifications = 100;
    Panicked      = 200;
  }
  
  -- ─── Window dimensions ─────────────────────────────────────────────────────
  Theme.Window = {
    WidthPct  = 0.94;
    HeightPct = 0.82;
    Margin    = 12;
    CornerRadius = Theme.Radius.Card;
    HeaderH   = 56;
    TopTabH   = 48;
    StatusH   = 36;
  }
  
  return Theme
  
  end)()
  if _module then _BW.Theme = _module end
end

-- ─── util/tween.lua ───
do
  local _module = (function()
  -- src/util/tween.lua
  -- Thin wrapper around TweenService with sane defaults for micro-interactions.
  -- WHY: every UI animation in the script goes through here so we have ONE place
  -- to tune easing/duration. Web dev mental model: this is our gsap.to().
  local TweenService = game:GetService("TweenService")
  
  local Tween = {}
  
  -- Spring-ish easing. Cubic/Quint/Exponential feel close to CSS spring physics.
  Tween.Easing = {
    Snappy   = Enum.EasingStyle.Quint;
    Smooth   = Enum.EasingStyle.Quad;
    Bouncy   = Enum.EasingStyle.Back;
    Soft     = Enum.EasingStyle.Sine;
  }
  
  -- Common durations (seconds). Tuned for mobile feel.
  Tween.Duration = {
    Micro    = 0.12;   -- press feedback
    Fast     = 0.20;   -- toggle knob, hover
    Default  = 0.32;   -- panel open, section reveal
    Slow     = 0.55;   -- window boot
  }
  
  -- Tween a single property of an Instance.
  -- usage: Tween:to(frame, {Position = UDim2.new(...)}, {easing = Tween.Easing.Snappy})
  function Tween.to(instance, props, opts)
    opts = opts or {}
    local duration = opts.duration or Tween.Duration.Default
    local easing   = opts.easing   or Tween.Easing.Smooth
    local direction = opts.direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration, easing, direction)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
  end
  
  -- Tween multiple instances with the same props (staggered reveal).
  -- usage: Tween:stagger(frames, {BackgroundTransparency = 0}, {stagger = 0.05})
  function Tween.stagger(instances, props, opts)
    opts = opts or {}
    local stagger = opts.stagger or 0.05
    local tweens = {}
    for i, inst in ipairs(instances) do
      local copy = table.clone(opts)
      copy.duration = (opts.duration or Tween.Duration.Default) + (i - 1) * 0
      task.delay((i - 1) * stagger, function()
        table.insert(tweens, Tween.to(inst, props, copy))
      end)
    end
    return tweens
  end
  
  return Tween
  
  end)()
  if _module then _BW.Tween = _module end
end

-- ─── util/dragger.lua ───
do
  local _module = (function()
  -- src/util/dragger.lua
  -- Makes any GuiObject draggable with both mouse AND touch.
  -- FIXED: drag only triggers AFTER 8pt of movement (iOS HIG threshold).
  --   v1 set `dragging = true` on InputBegan, so any tap on the FAB moved it.
  --   v1.1 requires 8pt of movement before drag activates.
  -- Snap-to-edge on release (mobile UX). Bounds clamped to viewport.
  -- New: `dragZone` option (only top Npt of frame accepts drag).
  -- New: `onDragStart` / `onDragEnd` callbacks.
  
  local UserInputService = game:GetService("UserInputService")
  local TweenService     = game:GetService("TweenService")
  
  local DRAG_THRESHOLD = 8  -- pt
  
  local Dragger = {}
  
  -- Dragger:enable(frame, opts)
  function Dragger.enable(frame, opts)
    opts = opts or {}
    local snapping      = opts.snapToEdge ~= false
    local padding       = opts.snapPadding or 12
    local threshold     = opts.threshold or DRAG_THRESHOLD
    local dragZoneTop   = opts.dragZone and opts.dragZone.top
    local target        = opts.target or frame
    local onDragStart   = opts.onDragStart
    local onDragEnd     = opts.onDragEnd
  
    local tracking      = false
    local dragging      = false
    local startInputPos = Vector2.new()
    local startTargetPos= UDim2.new()
    local connections   = {}
  
    local function isInDragZone(input)
      if not dragZoneTop then return true end
      local absY = frame.AbsolutePosition.Y
      return (input.Position.Y - absY) <= dragZoneTop
    end
  
    local function onInputBegan(input)
      if input.UserInputType ~= Enum.UserInputType.MouseButton1
      and input.UserInputType ~= Enum.UserInputType.Touch then
        return
      end
      if not isInDragZone(input) then return end
      tracking = true
      dragging = false
      startInputPos  = input.Position
      startTargetPos = target.Position
    end
  
    local function onInputChanged(input)
      if not tracking then return end
      if input.UserInputType ~= Enum.UserInputType.MouseMovement
      and input.UserInputType ~= Enum.UserInputType.Touch then
        return
      end
      local delta = input.Position - startInputPos
      if not dragging then
        if delta.Magnitude < threshold then return end
        dragging = true
        if onDragStart then onDragStart() end
      end
      target.Position = UDim2.new(
        startTargetPos.X.Scale, startTargetPos.X.Offset + delta.X,
        startTargetPos.Y.Scale, startTargetPos.Y.Offset + delta.Y
      )
    end
  
    local function onInputEnded(input)
      if not tracking then return end
      if input.UserInputType ~= Enum.UserInputType.MouseButton1
      and input.UserInputType ~= Enum.UserInputType.Touch then
        return
      end
      local wasDragging = dragging
      tracking = false
      dragging = false
      if wasDragging and onDragEnd then onDragEnd() end
      if not snapping then return end
      local camera = workspace.CurrentCamera
      local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
      local absPos = target.AbsolutePosition
      local absSize = target.AbsoluteSize
      local centerX = absPos.X + absSize.X / 2
      local targetX
      if centerX < viewport.X / 2 then
        targetX = padding
      else
        targetX = viewport.X - absSize.X - padding
      end
      local targetY = math.clamp(absPos.Y, padding, viewport.Y - absSize.Y - padding)
      TweenService:Create(
        target,
        TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, targetX, 0, targetY) }
      ):Play()
    end
  
    table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
    table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
    table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))
  
    return function()
      for _, c in ipairs(connections) do c:Disconnect() end
    end
  end
  
  return Dragger
  
  end)()
  if _module then _BW.Dragger = _module end
end

-- ─── util/input.lua ───
do
  local _module = (function()
  -- src/util/input.lua
  -- Unified touch + mouse + keyboard input helpers.
  -- Haptic fallback chain: executor-specific vibrate() → HapticService → gamepad motor.
  
  local UserInputService = game:GetService("UserInputService")
  
  local Input = {}
  
  function Input.isTouch()
    return UserInputService.TouchEnabled
  end
  
  function Input.isKeyDown(key)
    if type(key) == "string" then
      key = Enum.KeyCode[key]
    end
    return UserInputService:IsKeyDown(key)
  end
  
  function Input.onKeyDown(key, callback)
    if type(key) == "string" then
      key = Enum.KeyCode[key]
    end
    local conn = UserInputService.InputBegan:Connect(function(input, processed)
      if processed then return end
      if input.KeyCode == key then
        task.spawn(callback)
      end
    end)
    return function() conn:Disconnect() end
  end
  
  function Input.onTap(guiObject, callback)
    local conns = {}
    table.insert(conns, guiObject.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.Touch then
        task.spawn(callback, input)
      end
    end))
    return function()
      for _, c in ipairs(conns) do c:Disconnect() end
    end
  end
  
  -- Haptic feedback (vibration) — tries executor-specific first, then gamepad.
  function Input.haptic(strength, duration)
    strength = math.clamp(strength or 0.3, 0, 1)
    duration = math.min(duration or 0.1, 1)
  
    -- 1. Try executor-specific vibrate()
    if vibrate then
      pcall(function() vibrate(duration * 1000) end)
      return
    end
  
    -- 2. Try HapticService (Roblox iOS/Android native)
    pcall(function()
      local HapticService = game:GetService("HapticService")
      if HapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small) then
        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, strength)
        task.delay(duration, function()
          pcall(function()
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
          end)
        end)
        return
      end
    end)
  
    -- 3. Fall back to UserInputService (gamepad)
    if not UserInputService.GamepadEnabled then return end
    pcall(function()
      UserInputService:SetMotorVibration(
        Enum.UserInputType.Gamepad1,
        Enum.VibrationMotor.Small,
        strength
      )
      task.delay(duration, function()
        pcall(function()
          UserInputService:SetMotorVibration(
            Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0
          )
        end)
      end)
    end)
  end
  
  function Input.isTapInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
  end
  
  return Input
  
  end)()
  if _module then _BW.Input = _module end
end

-- ─── util/projection.lua ───
do
  local _module = (function()
  -- src/util/projection.lua
  -- World -> screen projection helpers.
  -- WHY: ESP features need to convert 3D world positions to 2D screen pixels.
  -- Roblox gives us Camera:WorldToViewportPoint which returns (Vector3, bool isInFront).
  local Workspace = game:GetService("Workspace")
  
  local Projection = {}
  
  -- Project a Vector3 world position to Vector2 screen position.
  -- Returns (Vector2, isVisible) — isVisible is false if the point is behind the camera.
  function Projection.worldToScreen(worldPos)
    local camera = Workspace.CurrentCamera
    if not camera then return Vector2.new(0, 0), false end
    local screen, visible = camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screen.X, screen.Y), visible
  end
  
  -- Project the top + bottom of an entity box (used for 2D box ESP).
  -- Returns (topVec2, bottomVec2, isVisible).
  -- WHY this pattern: Vape uses it — box height derived from HipHeight projected at
  -- a CFrame offset from the root along the camera's look vector.
  function Projection.entityBox(rootPos, hipHeight, camera)
    camera = camera or Workspace.CurrentCamera
    if not camera then return Vector2.new(0,0), Vector2.new(0,0), false end
    local look = camera.CFrame.LookVector
    local topCF    = CFrame.lookAlong(rootPos, look) * CFrame.new(2, hipHeight, 0)
    local bottomCF = CFrame.lookAlong(rootPos, look) * CFrame.new(-2, -hipHeight - 1, 0)
    local topScreen, topVis = camera:WorldToViewportPoint(topCF.Position)
    local botScreen, botVis = camera:WorldToViewportPoint(bottomCF.Position)
    local visible = topVis and botVis
    return Vector2.new(topScreen.X, topScreen.Y),
           Vector2.new(botScreen.X, botScreen.Y),
           visible
  end
  
  -- Distance in studs between two Vector3 positions.
  function Projection.distance(a, b)
    return (a - b).Magnitude
  end
  
  return Projection
  
  end)()
  if _module then _BW.Projection = _module end
end

-- ─── ui/animations.lua ───
do
  local _module = (function()
  -- src/ui/animations.lua
  -- Micro-interactions built on top of util/tween.lua + theme.lua.
  -- All easing standardized on Quint (matches cubic-bezier(0.16, 1, 0.3, 1)).
  -- Web dev mental model: this is our framer-motion variants.
  
  local TweenService = game:GetService("TweenService")
  local Theme = require(script.Parent.theme)
  
  local Anim = {}
  
  -- ─── Press feedback (scale-on-press) ──────────────────────────────────────
  -- Targets a UIScale child of the guiObject (so we don't tween Size which
  -- causes layout reflow). Adds UIScale if missing.
  function Anim.press(guiObject, opts)
    opts = opts or {}
    local scale = guiObject:FindFirstChildOfClass("UIScale")
    if not scale then
      scale = Instance.new("UIScale")
      scale.Parent = guiObject
    end
    TweenService:Create(
      scale,
      TweenInfo.new(Theme.Motion.Press, Theme.Easing.Press, Enum.EasingDirection.Out),
      { Scale = opts.scale or 0.96 }
    ):Play()
  end
  
  function Anim.release(guiObject)
    local scale = guiObject:FindFirstChildOfClass("UIScale")
    if not scale then
      scale = Instance.new("UIScale")
      scale.Parent = guiObject
    end
    TweenService:Create(
      scale,
      TweenInfo.new(Theme.Motion.Press + 0.05, Theme.Easing.Press, Enum.EasingDirection.Out),
      { Scale = 1 }
    ):Play()
  end
  
  -- ─── iOS-style toggle (WHITE knob on ACCENT track) ───────────────────────
  function Anim.toggle(switchTrack, knob, isOn, color)
    color = color or Theme.Color.Accent
    local trackW = switchTrack.AbsoluteSize.X
    local knobW = knob.AbsoluteSize.X
    local targetX = isOn and (trackW - knobW - 3) or 3
    local trackColor = isOn and Color3.fromRGB(16, 185, 129) or Theme.Color.SurfaceInset
    -- iOS pattern: WHITE knob on ACCENT track
    local knobColor = isOn and Color3.fromRGB(255, 255, 255) or Theme.Color.TextMuted
    TweenService:Create(knob,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { Position = UDim2.new(0, targetX, 0.5, -knobW / 2), BackgroundColor3 = knobColor }
    ):Play()
    TweenService:Create(switchTrack,
      TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { BackgroundColor3 = trackColor }
    ):Play()
  end
  
  -- ─── Slider progress fill ─────────────────────────────────────────────────
  function Anim.slider(progressBar, ratio)
    TweenService:Create(progressBar,
      TweenInfo.new(0.12, Theme.Easing.Tap, Enum.EasingDirection.Out),
      { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }
    ):Play()
  end
  
  -- ─── Hover (desktop only) ─────────────────────────────────────────────────
  function Anim.hover(guiObject, isHovering)
    if game:GetService("UserInputService").TouchEnabled then return end
    TweenService:Create(guiObject,
      TweenInfo.new(Theme.Motion.Hover, Theme.Easing.Hover, Enum.EasingDirection.Out),
      { BackgroundTransparency = isHovering and Theme.Alpha.GlassCardHover or Theme.Alpha.GlassCard }
    ):Play()
  end
  
  -- ─── Tab switch ───────────────────────────────────────────────────────────
  function Anim.tabSwitch(fromTab, toTab)
    -- Visual audit: label was TabActive (emerald) on tap — created triple-green.
    -- Now: icon ACCENT, label WHITE (TextPrimary), indicator ACCENT.
    if fromTab and fromTab.indicator then
      TweenService:Create(fromTab.indicator,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
      ):Play()
    end
    if fromTab and fromTab.icon then
      TweenService:Create(fromTab.icon,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { TextColor3 = Theme.Color.TabInactive }
      ):Play()
    end
    if fromTab and fromTab.label then
      TweenService:Create(fromTab.label,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { TextColor3 = Theme.Color.TabInactive }
      ):Play()
    end
    if toTab and toTab.indicator then
      TweenService:Create(toTab.indicator,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { BackgroundTransparency = Theme.Alpha.BorderAccent }
      ):Play()
    end
    if toTab and toTab.icon then
      TweenService:Create(toTab.icon,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { TextColor3 = Theme.Color.TabActive }
      ):Play()
    end
    if toTab and toTab.label then
      TweenService:Create(toTab.label,
        TweenInfo.new(Theme.Motion.Tap, Theme.Easing.Tap, Enum.EasingDirection.Out),
        { TextColor3 = Theme.Color.TextPrimary }
      ):Play()
    end
  end
  
  -- ─── Pulse glow (for FAB + active tab indicator) ─────────────────────────
  -- Looping expanding shadow pulse. Sine easing for smooth ambient feel.
  function Anim.pulseGlow(uiObject, period, color)
    color = color or Theme.Color.Accent
    period = period or Theme.Motion.Glow
  
    if not uiObject:IsA("UIStroke") then
      local glow = uiObject:FindFirstChild("GlowStroke")
      if not glow then
        glow = Instance.new("UIStroke")
        glow.Name = "GlowStroke"
        glow.Parent = uiObject
      end
      uiObject = glow
    end
  
    local function pulse()
      TweenService:Create(uiObject,
        TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.In),
        { Color = color, Transparency = Theme.Alpha.AccentGlowInner }
      ):Play()
      task.delay(period / 2, function()
        TweenService:Create(uiObject,
          TweenInfo.new(period / 2, Theme.Easing.Glow, Enum.EasingDirection.Out),
          { Color = color, Transparency = Theme.Alpha.AccentGlowOuter }
        ):Play()
        if uiObject and uiObject.Parent then
          task.delay(period / 2, pulse)
        end
      end)
    end
    pulse()
  end
  
  -- ─── Staggered row reveal ─────────────────────────────────────────────────
  function Anim.staggerReveal(rows, stagger)
    stagger = stagger or 0.04
    for i, row in ipairs(rows) do
      if row and row.Parent then
        row.BackgroundTransparency = 1
        for _, child in ipairs(row:GetChildren()) do
          if child:IsA("TextLabel") or child:IsA("TextButton") then
            child.TextTransparency = 1
          end
        end
        task.delay((i - 1) * stagger, function()
          if not row.Parent then return end
          TweenService:Create(row,
            TweenInfo.new(0.35, Theme.Easing.Open, Enum.EasingDirection.Out),
            { BackgroundTransparency = Theme.Alpha.GlassCard }
          ):Play()
          for _, child in ipairs(row:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
              TweenService:Create(child,
                TweenInfo.new(0.35, Theme.Easing.Open, Enum.EasingDirection.Out),
                { TextTransparency = 0 }
              ):Play()
            end
          end
        end)
      end
    end
  end
  
  return Anim
  
  end)()
  if _module then _BW.Anim = _module end
end

-- ─── ui/icons.lua ───
do
  local _module = (function()
  -- src/ui/icons.lua
  -- Hybrid icon strategy: Unicode text glyphs (default) + rbxassetid fallback.
  -- WHY Unicode: zero asset risk, instant render, semantic.
  -- WHY hybrid: VapeV4-style rbxassetid icons look more premium when they load.
  -- Web dev mental model: this is our icon SVG sprite with a CDN fallback.
  
  local Icons = {}
  
  -- ─── Unicode glyphs (PRIMARY — used by default) ────────────────────────────
  Icons.Unicode = {
    Combat    = "⚔";
    Visuals   = "◉";
    Move      = "➤";
    World     = "◆";
    Misc      = "✦";
    Killaura  = "⚔";
    Reach     = "↔";
    Aimbot    = "◎";
    ESP       = "◉";
    Fly       = "➤";
    Speed     = "»";
    Noclip    = "▣";
    Magnet    = "✦";
    Shop      = "$";
    Generator = "◈";
    Bed       = "▤";
    AntiAFK   = "◐";
    AutoRejoin= "↻";
    Spy       = "◬";
    Search    = "⌕";
    Close     = "✕";
    Panic     = "⚠";
    Check     = "✓";
    Warning   = "⚠";
    Info      = "ⓘ";
    Settings  = "✦";
    FAB       = "⚡";
    Lock      = "◉";
    Key       = "⚷";
    Drag      = "▦";
    Chevron   = "›";
    Plus      = "+";
    Minus     = "−";
    FPS       = "F";
    Ping      = "P";
    Active    = "A";
  }
  
  -- ─── Verified Roblox asset IDs (FALLBACK — v1.2 swap) ────────────────────
  -- From VapeV4's public repo. Use Icons.applyIcon with a number spec.
  Icons.Verified = {
    Combat    = 14368312652,
    Visuals   = 14368350193,
    Move      = 14368359107,
    World     = 14368362492,
    Misc      = 14368318994,
    Search    = 14425646684,
    Close     = 14368309446,
    Warning   = 14368361552,
    Info      = 14368324807,
    Logo      = 14368322199,
  }
  
  Icons.FabIcon = "⚡"
  
  -- ─── applyIcon helper ─────────────────────────────────────────────────────
  -- Single entry point for both text glyphs and rbxassetid.
  function Icons.applyIcon(parent, spec, color, size)
    color = color or Color3.fromRGB(16, 185, 129)
    size  = size  or 18
  
    if type(spec) == "number" then
      local img = Instance.new("ImageLabel")
      img.Parent = parent
      img.BackgroundTransparency = 1
      img.Image = "rbxassetid://" .. tostring(spec)
      img.ImageColor3 = color
      img.Size = UDim2.fromOffset(size, size)
      return img
    else
      local lbl = Instance.new("TextLabel")
      lbl.Parent = parent
      lbl.BackgroundTransparency = 1
      lbl.Text = tostring(spec)
      lbl.TextColor3 = color
      lbl.Font = Enum.Font.GothamBlack
      lbl.TextSize = size
      lbl.Size = UDim2.fromOffset(size, size)
      lbl.TextXAlignment = Enum.TextXAlignment.Center
      lbl.TextYAlignment = Enum.TextYAlignment.Center
      return lbl
    end
  end
  
  -- ─── Tab metadata ──────────────────────────────────────────────────────────
  Icons.Tabs = {
    { name = "Combat",  icon = "⚔" },
    { name = "Visuals", icon = "◉" },
    { name = "Move",    icon = "➤" },
    { name = "World",   icon = "◆" },
    { name = "Misc",    icon = "✦" },
  }
  
  -- ─── Feature icon lookup ──────────────────────────────────────────────────
  Icons.Feature = {
    killaura       = "⚔",
    reach          = "↔",
    aimbot         = "◎",
    fly            = "➤",
    speed          = "»",
    noclip         = "▣",
    magnet         = "✦",
    generator      = "◈",
    bedaura        = "▤",
    shop           = "$",
    antiafk        = "◐",
    autorejoin     = "↻",
    spy            = "◬",
    esp_players    = "◉",
    esp_beds       = "▤",
    esp_generators = "◈",
    esp_items      = "✦",
    esp_tracers    = "➤",
  }
  
  return Icons
  
  end)()
  if _module then _BW.Icons = _module end
end

-- ─── ui/library.lua ───
do
  local _module = (function()
  -- src/ui/library.lua
  -- Custom UI library — dark luxe glassmorphic, mobile-first, zero dependencies.
  -- v1.1 rewrite: full-width window, top tabs, search bar, status bar, fixed FAB.
  --
  -- API (mirrors Rayfield):
  --   local Window = Library:CreateWindow({ Name=..., Accent=... })
  --   local Tab    = Window:CreateTab("Combat")
  --   local Section = Tab:CreateSection("Offense")
  --   local Toggle = Section:CreateToggle({ Name=..., CurrentValue=false, Callback=... })
  --   local Slider = Section:CreateSlider({ Name=..., Range={5,30}, CurrentValue=18, Callback=... })
  --   local Button = Section:CreateButton({ Name=..., Callback=... })
  --   local Keybind= Section:CreateKeybind({ Name=..., CurrentKeybind=..., Callback=... })
  --   Library:Notify({ Title=..., Content=..., Duration=4 })
  --   Window:SetVisible(true/false)
  --   Window.onPanic = function() end   -- panic callback
  
  local Players            = game:GetService("Players")
  local UserInputService   = game:GetService("UserInputService")
  local TweenService       = game:GetService("TweenService")
  local RunService         = game:GetService("RunService")
  local Stats              = game:GetService("Stats")
  
  local Theme   = _BW.Theme
  local Input   = _BW.Input
  local Anim    = _BW.Anim
  local Icons   = _BW.Icons
  
  local Library = {}
  
  -- ─── Helpers ────────────────────────────────────────────────────────────────
  
  local function getGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
  end
  
  local function makeLabel(parent, text, opts)
    opts = opts or {}
    local lbl = Instance.new("TextLabel")
    lbl.Name = opts.name or "Label"
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Position = opts.position or UDim2.new(0, Theme.Space.LG, 0, 0)
    lbl.Size = opts.size or UDim2.new(1, -Theme.Space.LG * 2, 0, 20)
    lbl.Font = opts.font or Theme.Font.Body
    lbl.Text = text
    lbl.TextColor3 = opts.color or Theme.Color.TextPrimary
    lbl.TextSize = opts.textSize or Theme.Size.Body
    lbl.TextXAlignment = opts.textXAlignment or Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.RichText = opts.richText or false
    return lbl
  end
  
  local function applyGlass(frame, opts)
    opts = opts or {}
    frame.BackgroundColor3 = opts.color or Theme.Color.Surface
    frame.BackgroundTransparency = opts.transparency or Theme.Alpha.GlassPanel
    local stroke = Instance.new("UIStroke")
    stroke.Color = opts.borderColor or Theme.Color.Border
    stroke.Transparency = opts.borderTransparency or Theme.Alpha.Border
    stroke.Thickness = opts.thickness or 1
    stroke.Parent = frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, opts.radius or Theme.Radius.Card)
    corner.Parent = frame
    return stroke, corner
  end
  
  -- ─── Notifications ──────────────────────────────────────────────────────────
  local function createNotificationSystem(screengui)
    local container = Instance.new("Frame")
    container.Name = "Notifications"
    container.Parent = screengui
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0.5, 0, 0, Theme.Space.LG + Theme.Touch.HeaderHeight)
    container.Size = UDim2.new(0, 320, 1, -Theme.Space.LG * 2)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.ZIndex = Theme.Z.Notifications
  
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, Theme.Space.SM)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    return container
  end
  
  function Library:Notify(data)
    if not self._notifContainer then return end
    local container = self._notifContainer
    local notif = Instance.new("Frame")
    notif.Name = "Notif"
    notif.Parent = container
    notif.BackgroundColor3 = Theme.Color.Surface
    notif.BackgroundTransparency = Theme.Alpha.GlassPanel
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.AnchorPoint = Vector2.new(0.5, 0)
    notif.Position = UDim2.new(0.5, 0, 0, 0)
    notif.ZIndex = Theme.Z.Notifications + 1
    applyGlass(notif, { radius = Theme.Radius.Card })
  
    local title = makeLabel(notif, data.Title or "Notification", {
      position = UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM),
      font = Theme.Font.Heading, textSize = Theme.Size.Heading,
      color = Theme.Color.TextPrimary,
    })
    title.Size = UDim2.new(1, -Theme.Space.MD * 2, 0, 18)
  
    local content = makeLabel(notif, data.Content or "", {
      position = UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM + 20),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextSecondary,
    })
    content.Size = UDim2.new(1, -Theme.Space.MD * 2, 0, 16)
    content.TextWrapped = true
  
    TweenService:Create(notif,
      TweenInfo.new(0.32, Theme.Easing.Open, Enum.EasingDirection.Out),
      { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = Theme.Alpha.GlassCard }
    ):Play()
  
    local duration = data.Duration or 4
    task.delay(duration, function()
      if not notif.Parent then return end
      TweenService:Create(notif,
        TweenInfo.new(0.30, Theme.Easing.Open, Enum.EasingDirection.In),
        { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }
      ):Play()
      for _, child in ipairs(notif:GetChildren()) do
        if child:IsA("TextLabel") then
          TweenService:Create(child,
            TweenInfo.new(0.25, Theme.Easing.Open, Enum.EasingDirection.In),
            { TextTransparency = 1 }
          ):Play()
        end
      end
      task.delay(0.32, function() if notif.Parent then notif:Destroy() end end)
    end)
  end
  
  -- ─── FAB (Floating Action Button — fixed, no drag) ────────────────────────
  local function createFab(screengui, openMenu, accentColor)
    local fab = Instance.new("TextButton")
    fab.Name = "FAB"
    fab.Parent = screengui
    fab.BackgroundColor3 = accentColor or Theme.Color.Accent
    fab.Size = UDim2.fromOffset(Theme.Touch.FABSize, Theme.Touch.FABSize)
    -- FIXED top-right corner, never moves
    fab.Position = UDim2.new(1, -Theme.Touch.FABSize - Theme.Touch.FABMargin,
                            0, Theme.Touch.FABMargin + 12)
    fab.Text = Icons.FabIcon
    fab.TextColor3 = Color3.fromRGB(10, 15, 26)
    fab.Font = Theme.Font.Icon
    fab.TextSize = 26
    fab.TextXAlignment = Enum.TextXAlignment.Center
    fab.TextYAlignment = Enum.TextYAlignment.Center
    fab.ZIndex = Theme.Z.FAB
    fab.AutoButtonColor = false
    fab.BorderSizePixel = 0
    local fabCorner = Instance.new("UICorner")
    fabCorner.CornerRadius = UDim.new(1, 0)
    fabCorner.Parent = fab
    local fabStroke = Instance.new("UIStroke")
    fabStroke.Color = accentColor or Theme.Color.Accent
    fabStroke.Thickness = 2
    fabStroke.Transparency = Theme.Alpha.AccentGlowOuter
    fabStroke.Parent = fab
    Anim.pulseGlow(fabStroke, Theme.Motion.Glow, accentColor or Theme.Color.Accent)
    Input.onTap(fab, function()
      Input.haptic(0.4, 0.08)
      Anim.press(fab)
      task.delay(Theme.Motion.Press + 0.02, function() Anim.release(fab) end)
      openMenu()
    end)
    return fab
  end
  
  -- ─── Status bar (always visible at bottom) ─────────────────────────
  local function createStatusBar(parent, onPanic, viewportWidth)
    local bar = Instance.new("Frame")
    bar.Name = "StatusBar"
    bar.Parent = parent
    bar.Size = UDim2.new(1, 0, 0, Theme.Touch.StatusBarHeight)
    bar.Position = UDim2.new(0, 0, 1, -Theme.Touch.StatusBarHeight)
    bar.BackgroundColor3 = Theme.Color.SurfaceRaised
    bar.BackgroundTransparency = Theme.Alpha.GlassCard
    bar.ZIndex = Theme.Z.WindowContent + 1
    bar.BorderSizePixel = 0
    applyGlass(bar, { radius = 0 })
  
    local topStroke = Instance.new("UIStroke")
    topStroke.Color = Theme.Color.Border
    topStroke.Transparency = Theme.Alpha.Border
    topStroke.Thickness = 1
    topStroke.Parent = bar
  
    local panicWidth = 96
    local cellW = (viewportWidth - panicWidth - 16) / 3
    local function makeCell(idx, label, color)
      local cell = Instance.new("Frame")
      cell.Parent = bar
      cell.BackgroundTransparency = 1
      cell.Size = UDim2.new(0, cellW, 1, 0)
      cell.Position = UDim2.new(0, idx * cellW, 0, 0)
      cell.BorderSizePixel = 0
  
      local dot = Instance.new("Frame")
      dot.Parent = cell
      dot.Size = UDim2.fromOffset(6, 6)
      dot.Position = UDim2.new(0, Theme.Space.MD, 0.5, -3)
      dot.BackgroundColor3 = color
      dot.BorderSizePixel = 0
      local dotCorner = Instance.new("UICorner")
      dotCorner.CornerRadius = UDim.new(1, 0)
      dotCorner.Parent = dot
  
      local lbl = Instance.new("TextLabel")
      lbl.Parent = cell
      lbl.BackgroundTransparency = 1
      lbl.Size = UDim2.new(1, -Theme.Space.MD * 2 - 12, 1, 0)
      lbl.Position = UDim2.new(0, Theme.Space.MD + 12, 0, 0)
      lbl.Font = Theme.Font.Mono
      lbl.TextSize = Theme.Size.Caption
      lbl.Text = label
      lbl.TextColor3 = color
      lbl.TextXAlignment = Enum.TextXAlignment.Left
      lbl.TextYAlignment = Enum.TextYAlignment.Center
      return lbl
    end
  
    local fpsLabel    = makeCell(0, "FPS —",  Theme.Color.Accent)
    local pingLabel   = makeCell(1, "Ping —", Theme.Color.Info)
    local activeLabel = makeCell(2, "0/14 ON", Theme.Color.Gold)
  
    -- Panic button (44pt tall, Apple HIG touch target)
    local panicBtn = Instance.new("TextButton")
    panicBtn.Parent = bar
    panicBtn.Size = UDim2.new(0, panicWidth, 0, 44)
    panicBtn.Position = UDim2.new(1, -panicWidth - 8, 0.5, -22)
    panicBtn.BackgroundColor3 = Theme.Color.Danger
    panicBtn.BackgroundTransparency = 0.2
    -- Visual audit: "⚠ PANIC" relied on Unicode that varies by Roblox client.
    -- "STOP" is word-only — reliable across all clients. Red bg = danger signal.
    panicBtn.Text = "STOP"
    panicBtn.TextColor3 = Theme.Color.TextPrimary
    panicBtn.Font = Theme.Font.Heading
    panicBtn.TextSize = 11
    panicBtn.ZIndex = Theme.Z.WindowContent + 2
    panicBtn.AutoButtonColor = false
    panicBtn.BorderSizePixel = 0
    local panicCorner = Instance.new("UICorner")
    panicCorner.CornerRadius = UDim.new(0, Theme.Radius.Input)
    panicCorner.Parent = panicBtn
    Input.onTap(panicBtn, function()
      Input.haptic(0.6, 0.15)
      Anim.press(panicBtn)
      task.delay(0.1, function() Anim.release(panicBtn) end)
      if onPanic then onPanic() end
    end)
  
    return bar, fpsLabel, pingLabel, activeLabel
  end
  
  -- ─── Window ──────────────────────────────────────────────────────────────────
  function Library:CreateWindow(settings)
    settings = settings or {}
    local self = setmetatable({}, { __index = Library })
    self.tabs = {}
    self.open = false
    self.activeCount = 0
    self.onPanic = settings.onPanic
    self._viewportSize = Vector2.new(393, 852)
  
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = settings.Name or "BedwarsScript"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 100
    sg.Parent = getGuiParent()
    self.screengui = sg
  
    local function getViewportSize()
      local camera = workspace.CurrentCamera
      if camera then
        self._viewportSize = camera.ViewportSize
      end
      return self._viewportSize
    end
  
    -- ─── Backdrop ───────────────────────────────────────────────────────
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Parent = sg
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Theme.Color.Backdrop
    backdrop.BackgroundTransparency = 1
    backdrop.ZIndex = Theme.Z.Backdrop
    backdrop.BorderSizePixel = 0
    backdrop.Visible = false
    self.backdrop = backdrop
  
    -- ─── Window frame (full-width, 85% tall) ──────────────────────────
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.Parent = sg
    win.BackgroundColor3 = Theme.Color.Surface
    win.BackgroundTransparency = Theme.Alpha.GlassPanel
    win.AnchorPoint = Vector2.new(0, 0)
    win.ClipsDescendants = true
    win.ZIndex = Theme.Z.Window
    win.BorderSizePixel = 0
    win.Visible = false
    self.window = win
    applyGlass(win, { radius = Theme.Window.CornerRadius, transparency = Theme.Alpha.GlassPanel })
  
    -- ─── Header (logo + title + search + close) ───────────────────────
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = win
    header.Size = UDim2.new(1, 0, 0, Theme.Touch.HeaderHeight)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Theme.Color.SurfaceRaised
    header.BackgroundTransparency = Theme.Alpha.GlassCard
    header.ZIndex = Theme.Z.WindowContent
    header.BorderSizePixel = 0
    applyGlass(header, { radius = 0 })
  
    local headerStroke = Instance.new("UIStroke")
    headerStroke.Color = Theme.Color.Border
    headerStroke.Transparency = Theme.Alpha.Border
    headerStroke.Thickness = 1
    headerStroke.Parent = header
  
    local logoBtn = Instance.new("TextButton")
    logoBtn.Parent = header
    logoBtn.BackgroundTransparency = 1
    logoBtn.Size = UDim2.new(0, Theme.Touch.HeaderHeight, 1, 0)
    logoBtn.Position = UDim2.new(0, 0, 0, 0)
    -- Visual audit: was Icons.FabIcon (⚡) — duplicates the FAB icon visually.
    -- Changed to ✦ (sparkle) — different glyph, no user confusion.
    logoBtn.Text = "✦"
    logoBtn.TextColor3 = Theme.Color.Accent
    logoBtn.Font = Theme.Font.Icon
    logoBtn.TextSize = 22
    logoBtn.AutoButtonColor = false
    logoBtn.ZIndex = Theme.Z.WindowContent + 1
  
    -- Visual audit: was "BEDWARS" (all-caps) — reads aggressive. Title case "Bedwars"
    -- matches jensen-vvs / grannsjovvs brand voice.
    local title = makeLabel(header, settings.Name or "Bedwars", {
      position = UDim2.new(0, Theme.Touch.HeaderHeight + Theme.Space.SM, 0, 0),
      font = Theme.Font.Heading, textSize = Theme.Size.Title,
      color = Theme.Color.TextPrimary,
    })
    title.Size = UDim2.new(0.4, 0, 1, 0)
  
    local searchBg = Instance.new("Frame")
    searchBg.Parent = header
    searchBg.BackgroundColor3 = Theme.Color.SurfaceInset
    searchBg.BackgroundTransparency = Theme.Alpha.GlassInput
    searchBg.Size = UDim2.new(0, 140, 0, Theme.Touch.SearchHeight)
    searchBg.Position = UDim2.new(1, -Theme.Space.MD - 44 - 8 - 140, 0.5, -Theme.Touch.SearchHeight/2)
    searchBg.ZIndex = Theme.Z.WindowContent + 1
    searchBg.BorderSizePixel = 0
    applyGlass(searchBg, { radius = Theme.Radius.Input })
  
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Parent = searchBg
    searchIcon.BackgroundTransparency = 1
    searchIcon.Size = UDim2.new(0, Theme.Touch.SearchHeight, 1, 0)
    searchIcon.Position = UDim2.new(0, Theme.Space.SM, 0, 0)
    -- Visual audit: was Icons.Unicode.Search (⌕) — renders inconsistently.
    -- Removed the icon — text-only placeholder is more reliable.
    searchIcon.Text = ""
    searchIcon.TextColor3 = Theme.Color.TextMuted
    searchIcon.Font = Theme.Font.IconSmall
    searchIcon.TextSize = 14
    searchIcon.TextXAlignment = Enum.TextXAlignment.Center
    searchIcon.TextYAlignment = Enum.TextYAlignment.Center
    searchIcon.ZIndex = Theme.Z.WindowContent + 2
  
    local searchBox = Instance.new("TextBox")
    searchBox.Parent = searchBg
    searchBox.BackgroundTransparency = 1
    searchBox.Size = UDim2.new(1, -Theme.Touch.SearchHeight - 8, 1, 0)
    searchBox.Position = UDim2.new(0, Theme.Touch.SearchHeight + 4, 0, 0)
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search…"
    searchBox.PlaceholderColor3 = Theme.Color.TextMuted
    searchBox.TextColor3 = Theme.Color.TextPrimary
    searchBox.Font = Theme.Font.Body
    searchBox.TextSize = Theme.Size.Body
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = Theme.Z.WindowContent + 2
    self._searchBox = searchBox
  
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.fromOffset(44, 44)
    closeBtn.Position = UDim2.new(1, -44 - Theme.Space.SM, 0.5, -22)
    closeBtn.Text = Icons.Unicode.Close
    closeBtn.TextColor3 = Theme.Color.TextSecondary
    closeBtn.Font = Theme.Font.Icon
    closeBtn.TextSize = 20
    closeBtn.ZIndex = Theme.Z.WindowContent + 1
    closeBtn.AutoButtonColor = false
    Input.onTap(closeBtn, function()
      Input.haptic(0.3, 0.08)
      self:SetVisible(false)
    end)
  
    -- ─── Top tab bar ───────────────────────────────────────────────────
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.Parent = win
    tabBar.Size = UDim2.new(1, 0, 0, Theme.Touch.TopTabHeight)
    tabBar.Position = UDim2.new(0, 0, 0, Theme.Touch.HeaderHeight)
    tabBar.BackgroundColor3 = Theme.Color.SurfaceRaised
    tabBar.BackgroundTransparency = Theme.Alpha.GlassCard
    tabBar.ScrollBarThickness = 0
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.ElasticBehavior = Enum.ElasticBehavior.Never
    tabBar.CanvasSize = UDim2.new(0, Theme.Touch.TopTabWidth * 5, 0, 0)
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = Theme.Z.WindowContent
    applyGlass(tabBar, { radius = 0 })
  
    local tabBarStroke = Instance.new("UIStroke")
    tabBarStroke.Color = Theme.Color.Border
    tabBarStroke.Transparency = Theme.Alpha.Border
    tabBarStroke.Thickness = 1
    tabBarStroke.Parent = tabBar
  
    -- ─── Content area ──────────────────────────────────────────────────
    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "Content"
    contentArea.Parent = win
    contentArea.BackgroundTransparency = 1
    contentArea.Size = UDim2.new(1, 0, 1, -Theme.Touch.HeaderHeight - Theme.Touch.TopTabHeight - Theme.Touch.StatusBarHeight)
    contentArea.Position = UDim2.new(0, 0, 0, Theme.Touch.HeaderHeight + Theme.Touch.TopTabHeight)
    contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentArea.ScrollBarThickness = 3
    contentArea.ScrollBarImageColor3 = Theme.Color.Accent
    contentArea.ScrollBarImageTransparency = 0.5
    contentArea.BorderSizePixel = 0
    contentArea.ZIndex = Theme.Z.WindowContent
    self.contentArea = contentArea
  
    local contentPadding = Instance.new("UIPadding")
    contentPadding.Parent = contentArea
    contentPadding.PaddingTop = UDim.new(0, Theme.Space.MD)
    contentPadding.PaddingBottom = UDim.new(0, Theme.Space.LG)
    contentPadding.PaddingLeft = UDim.new(0, Theme.Space.MD)
    contentPadding.PaddingRight = UDim.new(0, Theme.Space.MD)
  
    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.Parent = contentArea
    pages.BackgroundTransparency = 1
    pages.Size = UDim2.new(1, 0, 1, 0)
    pages.ZIndex = Theme.Z.WindowContent
    self.pages = pages
  
    local pageLayout = Instance.new("UIPageLayout")
    pageLayout.Parent = pages
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.EasingDirection = Enum.EasingDirection.Out
    pageLayout.EasingStyle = Enum.EasingStyle.Quint
    pageLayout.TweenTime = Theme.Motion.Open
    pageLayout.Circular = false
    self.pageLayout = pageLayout
  
    -- Status bar (will be resized to actual width in SetVisible)
    self._pendingStatusBarCb = function() end
    self._pendingStatusBarCb = function()
      self.statusBar, self._fpsLabel, self._pingLabel, self._activeLabel =
        createStatusBar(win, function() if self.onPanic then self.onPanic() end end, win.AbsoluteSize.X)
    end
  
    -- FAB (fixed top-right — NO drag)
    self.fab = createFab(sg, function() self:SetVisible(not self.open) end,
      settings.Accent or Theme.Color.Accent)
  
    -- ─── Visibility animation ─────────────────────────────────────────
    function self:SetVisible(visible)
      self.open = visible
      local viewport = getViewportSize()
      local winW = math.floor(viewport.X * Theme.Window.WidthPct)
      local winH = math.floor(viewport.Y * Theme.Window.HeightPct)
      local winX = math.floor((viewport.X - winW) / 2)
      local winY = math.floor((viewport.Y - winH) / 2)
  
      if visible then
        backdrop.Visible = true
        win.Visible = true
        win.Size = UDim2.fromOffset(winW, 0)
        win.Position = UDim2.fromOffset(winX, winY)
        TweenService:Create(backdrop,
          TweenInfo.new(Theme.Motion.Backdrop, Theme.Easing.Backdrop, Enum.EasingDirection.Out),
          { BackgroundTransparency = Theme.Alpha.Backdrop }
        ):Play()
        TweenService:Create(win,
          TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.Out),
          { Size = UDim2.fromOffset(winW, winH) }
        ):Play()
        -- Build status bar after window has size
        task.defer(function()
          if win.AbsoluteSize.X > 100 and not win:FindFirstChild("StatusBar") then
            self._pendingStatusBarCb()
            self._startStatusLoop()
          end
        end)
      else
        TweenService:Create(backdrop,
          TweenInfo.new(Theme.Motion.Backdrop, Theme.Easing.Backdrop, Enum.EasingDirection.In),
          { BackgroundTransparency = 1 }
        ):Play()
        TweenService:Create(win,
          TweenInfo.new(Theme.Motion.Open, Theme.Easing.Open, Enum.EasingDirection.In),
          { Size = UDim2.fromOffset(winW, 0) }
        ):Play()
        task.delay(Theme.Motion.Open + 0.02, function()
          if not self.open then
            win.Visible = false
            backdrop.Visible = false
            self._stopStatusLoop()
          end
        end)
      end
    end
  
    -- Status bar live update loop
    self._statusThread = nil
    function self._startStatusLoop()
      if self._statusThread then return end
      self._statusThread = task.spawn(function()
        while self.open do
          pcall(function()
            if self._fpsLabel then
              local fps = math.floor(1 / (RunService.RenderStepped:Wait() or 0.016))
              self._fpsLabel.Text = "FPS " .. fps
            end
            if self._pingLabel then
              local ping = math.floor(tonumber(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0)
              self._pingLabel.Text = "Ping " .. ping .. "ms"
            end
            if self._activeLabel then
              self._activeLabel.Text = self.activeCount .. "/14 ON"
            end
          end)
          task.wait(0.5)
        end
      end)
    end
    function self._stopStatusLoop()
      if self._statusThread then
        pcall(function() task.cancel(self._statusThread) end)
        self._statusThread = nil
      end
    end
  
    return self
  end
  
  -- ─── Tab ─────────────────────────────────────────────────────────────────────
  
  function Library:CreateTab(name, iconSpec)
    local tab = {}
    tab.sections = {}
  
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = self.pages
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Color.TextMuted
    page.ScrollBarImageTransparency = 0.5
    page.BorderSizePixel = 0
    page.ZIndex = Theme.Z.WindowContent
  
    local padding = Instance.new("UIPadding")
    padding.Parent = page
    padding.PaddingTop = UDim.new(0, Theme.Space.MD)
    padding.PaddingBottom = UDim.new(0, Theme.Space.LG)
    padding.PaddingLeft = UDim.new(0, Theme.Space.MD)
    padding.PaddingRight = UDim.new(0, Theme.Space.MD)
  
    local list = Instance.new("UIListLayout")
    list.Parent = page
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, Theme.Space.SM)
    list.ZIndex = Theme.Z.WindowContent
  
    -- Tab button
    local tabBar = self.window:FindFirstChild("TabBar")
    local btn = Instance.new("TextButton")
    btn.Name = name .. "TabBtn"
    btn.Parent = tabBar
    btn.Size = UDim2.fromOffset(Theme.Touch.TopTabWidth, Theme.Touch.TopTabHeight)
    btn.Position = UDim2.new(0, #self.tabs * Theme.Touch.TopTabWidth, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.ZIndex = Theme.Z.WindowContent + 1
    btn.LayoutOrder = #self.tabs + 1
  
    local icon = Instance.new("TextLabel")
    icon.Parent = btn
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, Theme.Size.Icon, 0, Theme.Size.Icon)
    icon.Position = UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.Icon/2)
    icon.Font = Theme.Font.Icon
    icon.TextSize = Theme.Size.Icon
    icon.Text = tostring(iconSpec or "◆")
    icon.TextColor3 = Theme.Color.TabInactive
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.TextYAlignment = Enum.TextYAlignment.Center
    icon.ZIndex = Theme.Z.WindowContent + 2
  
    local label = makeLabel(btn, name, {
      position = UDim2.new(0, Theme.Space.MD + Theme.Size.Icon + Theme.Space.SM, 0, 0),
      font = Theme.Font.Tab, textSize = Theme.Size.Tab,
      color = Theme.Color.TabInactive,
    })
    label.Size = UDim2.new(1, -Theme.Space.MD * 2 - Theme.Size.Icon - Theme.Space.SM, 1, 0)
  
    local indicator = Instance.new("Frame")
    indicator.Parent = btn
    indicator.Size = UDim2.new(0.7, 0, 0, 2)
    indicator.Position = UDim2.new(0.15, 0, 1, -2)
    indicator.BackgroundColor3 = Theme.Color.Accent
    indicator.Visible = (#self.tabs == 0)
    indicator.ZIndex = Theme.Z.WindowContent + 3
    indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator
  
    Input.onTap(btn, function()
      Input.haptic(0.2, 0.05)
      for _, t in ipairs(self.tabs) do
        Anim.tabSwitch(t, t == tab and tab or nil)
      end
      self.pageLayout:JumpTo(page)
    end)
  
    tab.page = page
    tab.button = btn
    tab.icon = icon
    tab.label = label
    tab.indicator = indicator
    tab.list = list
  
    if #self.tabs == 0 then
      self.pageLayout:JumpTo(page)
      -- Visual audit: was TabActive (emerald) for both icon and label — created
      -- triple-green noise. Now: icon ACCENT, label WHITE, indicator ACCENT.
      icon.TextColor3 = Theme.Color.TabActive
      label.TextColor3 = Theme.Color.TextPrimary
      indicator.Visible = true
    end
  
    table.insert(self.tabs, tab)
    function tab:CreateSection(name) return Library._createSection(self, name) end
    return tab
  end
  
  -- ─── Section ───────────────────────────────────────────────────────────────
  
  function Library._createSection(tab, name)
    local section = {}
    section.elements = {}
  
    -- Visual audit: section title was Accent (emerald) — competed with active tab
    -- indicator. Now: Gold (secondary) — reads as "section header" not "active state".
    local title = makeLabel(tab.page, name, {
      position = UDim2.new(0, Theme.Space.XS, 0, 0),
      font = Theme.Font.Heading, textSize = Theme.Size.Heading,
      color = Theme.Color.Gold,
    })
    title.Size = UDim2.new(1, -Theme.Space.XS * 2, 0, 24)
    title.LayoutOrder = #tab.sections * 1000
  
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Parent = tab.page
    container.BackgroundColor3 = Theme.Color.Surface
    container.BackgroundTransparency = Theme.Alpha.GlassCard
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.LayoutOrder = (#tab.sections * 1000) + 1
    container.ClipsDescendants = true
    container.BorderSizePixel = 0
    container.ZIndex = Theme.Z.WindowContent
    applyGlass(container, { radius = Theme.Radius.Card, transparency = Theme.Alpha.GlassCard })
  
    local cl = Instance.new("UIListLayout")
    cl.Parent = container
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 1)
    cl.ZIndex = Theme.Z.WindowContent
  
    section.container = container
    section.layout = cl
    table.insert(tab.sections, section)
  
    function section:CreateToggle(opts)   return Library._createToggle(self, opts) end
    function section:CreateSlider(opts)   return Library._createSlider(self, opts) end
    function section:CreateButton(opts)   return Library._createButton(self, opts) end
    function section:CreateKeybind(opts)  return Library._createKeybind(self, opts) end
    function section:CreateDropdown(opts) return Library._createDropdown(self, opts) end
    function section:CreateLabel(text)    return Library._createLabel(self, text) end
    return section
  end
  
  -- ─── Toggle ────────────────────────────────────────────────────────────────
  
  function Library._createToggle(section, opts)
    opts = opts or {}
    local row = Instance.new("TextButton")
    row.Name = opts.Name .. "Toggle"
    row.Parent = section.container
    row.BackgroundColor3 = Theme.Color.SurfaceRaised
    row.BackgroundTransparency = Theme.Alpha.GlassCard
    row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = #section.elements + 1
    row.BorderSizePixel = 0
    row.ZIndex = Theme.Z.WindowContent
  
    if opts.Icon then
      Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
        UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
    end
  
    local label = makeLabel(row, opts.Name or "Toggle", {
      position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                        or UDim2.new(0, Theme.Space.LG, 0, 0),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextPrimary,
    })
    label.Size = UDim2.new(1, -120, 1, 0)
  
    local track = Instance.new("Frame")
    track.Parent = row
    track.BackgroundColor3 = Theme.Color.SurfaceInset
    track.Size = UDim2.fromOffset(44, 24)
    track.Position = UDim2.new(1, -Theme.Space.LG - 44, 0.5, -12)
    track.BorderSizePixel = 0
    track.ZIndex = Theme.Z.WindowContent + 1
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
  
    local knob = Instance.new("Frame")
    knob.Parent = track
    knob.BackgroundColor3 = Theme.Color.TextMuted
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BorderSizePixel = 0
    knob.ZIndex = Theme.Z.WindowContent + 2
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
  
    local state = opts.CurrentValue or false
    local function render() Anim.toggle(track, knob, state) end
    -- iOS pattern: WHITE knob on ACCENT track
    knob.Position = UDim2.new(0, state and (44 - 18 - 3) or 3, 0.5, -9)
    if state then
      knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
      track.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    end
  
    local toggle = { state = state, row = row, knob = knob, track = track }
  
    function toggle:Set(value)
      state = value
      render()
      if opts.Callback then task.spawn(opts.Callback, value) end
    end
  
    Input.onTap(row, function()
      Input.haptic(0.3, 0.08)
      Anim.press(row)
      task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
      state = not state
      render()
      if opts.Callback then task.spawn(opts.Callback, state) end
    end)
  
    table.insert(section.elements, toggle)
    return toggle
  end
  
  -- ─── Slider ────────────────────────────────────────────────────────────────
  
  function Library._createSlider(section, opts)
    opts = opts or {}
    local range = opts.Range or {0, 100}
    local value = opts.CurrentValue or range[1]
    local increment = opts.Increment or 1
  
    local row = Instance.new("Frame")
    row.Name = opts.Name .. "Slider"
    row.Parent = section.container
    row.BackgroundColor3 = Theme.Color.SurfaceRaised
    row.BackgroundTransparency = Theme.Alpha.GlassCard
    row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight + 12)
    row.LayoutOrder = #section.elements + 1
    row.BorderSizePixel = 0
    row.ZIndex = Theme.Z.WindowContent
  
    if opts.Icon then
      Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
        UDim2.new(0, Theme.Space.MD, 0, Theme.Space.SM)
    end
  
    local label = makeLabel(row, opts.Name or "Slider", {
      position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, Theme.Space.SM)
                        or UDim2.new(0, Theme.Space.LG, 0, Theme.Space.SM),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextPrimary,
    })
    label.Size = UDim2.new(1, -120, 0, 20)
  
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = row
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -Theme.Space.LG - 60, 0, Theme.Space.SM)
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Font = Theme.Font.Mono
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.Color.Gold
    valueLabel.TextSize = Theme.Size.Value
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
  
    local track = Instance.new("Frame")
    track.Parent = row
    track.BackgroundColor3 = Theme.Color.SurfaceInset
    -- Visual audit: track was 6pt — felt flimsy. 8pt is more substantial,
    -- feels more premium, easier to tap-target.
    track.Size = UDim2.new(1, -Theme.Space.LG * 2, 0, 8)
    track.Position = UDim2.new(0, Theme.Space.LG, 0, 34)
    track.BorderSizePixel = 0
    track.ZIndex = Theme.Z.WindowContent
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
  
    local fill = Instance.new("Frame")
    fill.Parent = track
    fill.BackgroundColor3 = Theme.Color.Accent
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BorderSizePixel = 0
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
  
    local hitbox = Instance.new("TextButton")
    hitbox.Parent = track
    hitbox.BackgroundTransparency = 1
    hitbox.Size = UDim2.new(1, 0, 0, Theme.Touch.MinTarget)
    hitbox.Position = UDim2.new(0, 0, 0.5, -Theme.Touch.MinTarget/2)
    hitbox.Text = ""
    hitbox.BorderSizePixel = 0
    hitbox.ZIndex = 5
  
    local slider = { value = value, row = row, fill = fill, valueLabel = valueLabel }
  
    local function render()
      local ratio = (value - range[1]) / (range[2] - range[1])
      Anim.slider(fill, ratio)
      valueLabel.Text = tostring(math.floor(value * 100) / 100) .. (opts.Suffix or "")
    end
    render()
  
    function slider:Set(newVal)
      value = math.clamp(newVal, range[1], range[2])
      render()
      if opts.Callback then task.spawn(opts.Callback, value) end
    end
  
    local dragging = false
    hitbox.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        Input.haptic(0.15, 0.04)
      end
    end)
    hitbox.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
      end
    end)
    UserInputService.InputChanged:Connect(function(input)
      if not dragging then return end
      if input.UserInputType == Enum.UserInputType.MouseMovement
      or input.UserInputType == Enum.UserInputType.Touch then
        local absPos = track.AbsolutePosition
        local absSize = track.AbsoluteSize
        local ratio = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
        local stepped = math.floor((ratio * (range[2] - range[1]) + range[1]) / increment + 0.5) * increment
        if stepped ~= value then
          value = stepped
          render()
          if opts.Callback then task.spawn(opts.Callback, value) end
        end
      end
    end)
  
    table.insert(section.elements, slider)
    return slider
  end
  
  -- ─── Button ────────────────────────────────────────────────────────────────
  
  function Library._createButton(section, opts)
    opts = opts or {}
    local row = Instance.new("TextButton")
    row.Name = opts.Name .. "Button"
    row.Parent = section.container
    row.BackgroundColor3 = Theme.Color.SurfaceRaised
    row.BackgroundTransparency = Theme.Alpha.GlassCard
    row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = #section.elements + 1
    row.BorderSizePixel = 0
    row.ZIndex = Theme.Z.WindowContent
  
    if opts.Icon then
      Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
        UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
    end
  
    local label = makeLabel(row, opts.Name or "Button", {
      position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                        or UDim2.new(0, Theme.Space.LG, 0, 0),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextPrimary,
    })
    label.Size = UDim2.new(1, -Theme.Space.LG * 2, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Center
  
    local button = { row = row }
    function button:Set(newName) label.Text = newName end
  
    Input.onTap(row, function()
      Input.haptic(0.3, 0.08)
      Anim.press(row)
      task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
      if opts.Callback then
        local ok, err = pcall(opts.Callback)
        if not ok then
          Library:Notify({ Title = "⚠ Error", Content = tostring(err), Duration = 4 })
        end
      end
    end)
  
    table.insert(section.elements, button)
    return button
  end
  
  -- ─── Keybind ──────────────────────────────────────────────────────────────
  
  function Library._createKeybind(section, opts)
    opts = opts or {}
    local currentKey = opts.CurrentKeybind or "RightShift"
  
    local row = Instance.new("TextButton")
    row.Name = opts.Name .. "Keybind"
    row.Parent = section.container
    row.BackgroundColor3 = Theme.Color.SurfaceRaised
    row.BackgroundTransparency = Theme.Alpha.GlassCard
    row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = #section.elements + 1
    row.BorderSizePixel = 0
    row.ZIndex = Theme.Z.WindowContent
  
    if opts.Icon then
      Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
        UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
    end
  
    local label = makeLabel(row, opts.Name or "Keybind", {
      position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                        or UDim2.new(0, Theme.Space.LG, 0, 0),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextPrimary,
    })
    label.Size = UDim2.new(1, -120, 1, 0)
  
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Parent = row
    keyLabel.BackgroundTransparency = 1
    keyLabel.Position = UDim2.new(1, -Theme.Space.LG - 80, 0, 0)
    keyLabel.Size = UDim2.new(0, 80, 1, 0)
    keyLabel.Font = Theme.Font.Mono
    keyLabel.Text = currentKey
    keyLabel.TextColor3 = Theme.Color.Gold
    keyLabel.TextSize = Theme.Size.Value
    keyLabel.TextXAlignment = Enum.TextXAlignment.Right
    keyLabel.TextYAlignment = Enum.TextYAlignment.Center
  
    local keybind = { key = currentKey, row = row, keyLabel = keyLabel }
    function keybind:Set(newKey)
      currentKey = newKey
      keyLabel.Text = newKey
    end
  
    local listening = false
    Input.onTap(row, function()
      Input.haptic(0.2, 0.05)
      keyLabel.Text = "..."
      listening = true
    end)
  
    UserInputService.InputBegan:Connect(function(input, processed)
      if processed then return end
      if not listening then
        if input.KeyCode.Name == currentKey and opts.Callback then
          task.spawn(opts.Callback)
        end
        return
      end
      if input.KeyCode ~= Enum.KeyCode.Unknown then
        currentKey = input.KeyCode.Name
        keyLabel.Text = currentKey
        listening = false
      end
    end)
  
    table.insert(section.elements, keybind)
    return keybind
  end
  
  -- ─── Dropdown ─────────────────────────────────────────────────────────────
  
  function Library._createDropdown(section, opts)
    opts = opts or {}
    local options = opts.Options or {}
    local current = opts.CurrentOption or (options[1] or "")
  
    local row = Instance.new("TextButton")
    row.Name = opts.Name .. "Dropdown"
    row.Parent = section.container
    row.BackgroundColor3 = Theme.Color.SurfaceRaised
    row.BackgroundTransparency = Theme.Alpha.GlassCard
    row.Size = UDim2.new(1, 0, 0, Theme.Touch.RowHeight)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = #section.elements + 1
    row.BorderSizePixel = 0
    row.ZIndex = Theme.Z.WindowContent
  
    if opts.Icon then
      Icons.applyIcon(row, opts.Icon, Theme.Color.TextSecondary, Theme.Size.IconSmall).Position =
        UDim2.new(0, Theme.Space.MD, 0.5, -Theme.Size.IconSmall/2)
    end
  
    local label = makeLabel(row, opts.Name or "Dropdown", {
      position = opts.Icon and UDim2.new(0, Theme.Space.MD + Theme.Size.IconSmall + Theme.Space.SM, 0, 0)
                        or UDim2.new(0, Theme.Space.LG, 0, 0),
      font = Theme.Font.Body, textSize = Theme.Size.Body,
      color = Theme.Color.TextPrimary,
    })
    label.Size = UDim2.new(1, -100, 1, 0)
  
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = row
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -Theme.Space.LG - 80, 0, 0)
    valueLabel.Size = UDim2.new(0, 80, 1, 0)
    valueLabel.Font = Theme.Font.Mono
    valueLabel.Text = tostring(current)
    valueLabel.TextColor3 = Theme.Color.Gold
    valueLabel.TextSize = Theme.Size.Value
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
  
    local dropdown = { value = current, options = options, row = row, valueLabel = valueLabel }
    function dropdown:Set(val)
      current = val
      valueLabel.Text = tostring(val)
      if opts.Callback then task.spawn(opts.Callback, val) end
    end
    function dropdown:Refresh(newOptions)
      options = newOptions
      current = options[1] or ""
      valueLabel.Text = tostring(current)
    end
  
    Input.onTap(row, function()
      Input.haptic(0.2, 0.05)
      Anim.press(row)
      task.delay(Theme.Motion.Press + 0.02, function() Anim.release(row) end)
      local idx = table.find(options, current) or 0
      local nextOpt = options[(idx % #options) + 1]
      if nextOpt then dropdown:Set(nextOpt) end
    end)
  
    table.insert(section.elements, dropdown)
    return dropdown
  end
  
  -- ─── Label ─────────────────────────────────────────────────────────────────
  
  function Library._createLabel(section, text)
    local lbl = makeLabel(section.container, text, {
      position = UDim2.new(0, Theme.Space.LG, 0, 0),
      font = Theme.Font.Label, textSize = Theme.Size.Label,
      color = Theme.Color.TextSecondary,
    })
    lbl.Size = UDim2.new(1, -Theme.Space.LG * 2, 0, 24)
    lbl.LayoutOrder = #section.elements + 1
    return lbl
  end
  
  return Library
  
  end)()
  if _module then _BW.Library = _module end
end

-- ─── config.lua ───
do
  local _module = (function()
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
  
  end)()
  if _module then _BW.Config = _module end
end

-- ─── game/placeid.lua ───
do
  local _module = (function()
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
  
  end)()
  if _module then _BW.PlaceId = _module end
end

-- ─── game/services.lua ───
do
  local _module = (function()
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
  
  end)()
  if _module then _BW.Services = _module end
end

-- ─── game/remotes.lua ───
do
  local _module = (function()
  -- src/game/remotes.lua
  -- THE critical file. Bedwars is built on Knit + Flamework + Roblox-TS + @rbxts/net.
  -- Remotes are NOT static RemoteEvent instances in ReplicatedStorage. They are
  -- created dynamically by the Knit client and referenced by string name inside
  -- controller methods. We extract those names using the Luau `debug` library.
  --
  -- Technique (from VapeV4 research):
  --   1. Get Knit from `require(PlayerScripts.TS.knit).setup` via debug.getupvalue
  --   2. For each controller method, call debug.getconstants on it
  --   3. Find the string 'Client' in the constants, take the NEXT constant as the remote name
  --   4. Get the remote handle via `Client:Get(remoteName).instance`
  --
  -- This file is version-fragile — when Easy.gg updates Bedwars, controller paths
  -- may shift. The Spy feature (features/spy.lua) helps discover new remotes live.
  
  
  local Services = _BW.Services
  local Logger   = _BW.Logger
  
  local Remotes = {}
  
  -- The extracted Knit + Client + remote-name table.
  Remotes.Knit    = nil
  Remotes.Client  = nil
  Remotes.names   = {}    -- key -> remote name string
  Remotes.handles = {}    -- key -> remote handle (Instance)
  
  -- ─── Bootstrap: get Knit + Client ───────────────────────────────────────────
  -- Waits up to 30s for Knit to load (game might still be loading).
  function Remotes.bootstrap(timeout)
    timeout = timeout or 30
    local plr = Services.localPlayer()
    local replicatedStorage = Services.ReplicatedStorage()
    local deadline = tick() + timeout
  
    repeat
      local ok, result = pcall(function()
        -- Get Knit from the knit setup function's 9th upvalue
        local knitModule = plr:WaitForChild("PlayerScripts"):WaitForChild("TS"):WaitForChild("knit")
        local Knit = debug.getupvalue(require(knitModule).setup, 9)
        -- Get the @rbxts/net Client
        local Client = require(replicatedStorage.TS.remotes).default.Client
        return Knit, Client
      end)
      if ok and result then
        Remotes.Knit, Remotes.Client = result, result and result.Client or result
        -- Re-extract Client cleanly
        if result then
          local ok2, client = pcall(function()
            return require(replicatedStorage.TS.remotes).default.Client
          end)
          if ok2 then Remotes.Client = client end
        end
        Logger.info("Knit + Client acquired")
        return true
      end
      task.wait(0.2)
    until tick() > deadline
  
    Logger.error("Failed to bootstrap Knit within " .. timeout .. "s")
    return false
  end
  
  -- ─── Remote name extraction ─────────────────────────────────────────────────
  -- Given a Knit controller function, find the remote name string in its constants.
  -- The pattern: constants contain 'Client' followed immediately by the remote name.
  local function extractRemoteName(fn)
    if not fn then return nil end
    local ok, constants = pcall(debug.getconstants, fn)
    if not ok or not constants then return nil end
    for i, v in ipairs(constants) do
      if v == "Client" and constants[i + 1] and type(constants[i + 1]) == "string" then
        return constants[i + 1]
      end
    end
    return nil
  end
  
  -- ─── The remote name table ──────────────────────────────────────────────────
  -- Each entry is a function that returns the Knit controller method/proto from
  -- which we extract the remote name. Mirrors VapeV4's remoteNames table.
  -- These are the remotes we need for v1 features.
  RemoteSources = {
    -- Combat
    AttackEntity = function()
      return Remotes.Knit.Controllers.SwordController.sendServerRequest
    end,
    -- Inventory
    EquipItem = function()
      local InventoryEntity = require(Services.ReplicatedStorage().TS.entity.entities["inventory-entity"]).InventoryEntity
      return debug.getupvalue(InventoryEntity.equipItem, 4)
    end,
    -- World (generators, item drops)
    PickupItem = function()
      return Remotes.Knit.Controllers.ItemDropController.checkForPickup
    end,
    DropItem = function()
      return Remotes.Knit.Controllers.ItemDropController.dropItemInHand
    end,
    -- Bed break
    -- Block engine (for breaking blocks)
    -- Consume
    ConsumeItem = function()
      return debug.getproto(Remotes.Knit.Controllers.ConsumeController.onEnable, 1)
    end,
    -- Reset
    ResetCharacter = function()
      return debug.getproto(Remotes.Knit.Controllers.ResetController.createBindable, 1)
    end,
    -- AFK
    AfkStatus = function()
      return debug.getproto(Remotes.Knit.Controllers.AfkController.KnitStart, 1)
    end,
  }
  
  -- ─── Extract all remote names ───────────────────────────────────────────────
  -- Call this after bootstrap. Populates Remotes.names + Remotes.handles.
  function Remotes.extractAll()
    if not Remotes.Knit or not Remotes.Client then
      Logger.error("Cannot extract remotes — Knit/Client not bootstrapped")
      return false
    end
    local found, missed = 0, 0
    for key, sourceFn in pairs(RemoteSources) do
      local ok, fn = pcall(sourceFn)
      if ok and fn then
        local name = extractRemoteName(fn)
        if name then
          Remotes.names[key] = name
          -- Get the handle
          local okHandle, handle = pcall(function()
            return Remotes.Client:Get(name).instance
          end)
          if okHandle and handle then
            Remotes.handles[key] = handle
            found = found + 1
          else
            Logger.warn("Got name '" .. name .. "' for " .. key .. " but handle failed")
            missed = missed + 1
          end
        else
          Logger.warn("Could not extract remote name for " .. key)
          missed = missed + 1
        end
      else
        Logger.warn("Source function failed for " .. key .. ": " .. tostring(fn))
        missed = missed + 1
      end
    end
    Logger.info(string.format("Remotes extracted: %d found, %d missed", found, missed))
    return found > 0
  end
  
  -- ─── Fire a remote by key ───────────────────────────────────────────────────
  -- usage: Remotes.fire("AttackEntity", { weapon=..., chargedAttack=..., ... })
  function Remotes.fire(key, args)
    local handle = Remotes.handles[key]
    if not handle then
      Logger.warn("No handle for remote: " .. key)
      return false
    end
    local ok, err = pcall(function()
      handle:FireServer(args)
    end)
    if not ok then
      Logger.error("Fire " .. key .. " failed: " .. tostring(err))
      return false
    end
    return true
  end
  
  -- Call a remote async (returns a promise-like via CallServerAsync).
  -- usage: Remotes.call("PickupItem", { itemDrop = part }):andThen(cb)
  function Remotes.call(key, args)
    local name = Remotes.names[key]
    if not name then
      Logger.warn("No name for remote: " .. key)
      return nil
    end
    local ok, promise = pcall(function()
      return Remotes.Client:Get(name):CallServerAsync(args)
    end)
    if not ok then
      Logger.error("Call " .. key .. " failed: " .. tostring(promise))
      return nil
    end
    return promise
  end
  
  -- ─── Block damage remote (separate from Knit — uses block-engine) ───────────
  function Remotes.damageBlock(blockPosition, hitPosition, hitNormal)
    local rs = Services.ReplicatedStorage()
    local ok, BlockEngineRemotes = pcall(function()
      return require(rs["rbxts_include"]["node_modules"]["@easy-ggs"]["block-engine"].out.shared.remotes).BlockEngineRemotes.Client
    end)
    if not ok or not BlockEngineRemotes then
      Logger.warn("BlockEngineRemotes not available")
      return nil
    end
    return pcall(function()
      return BlockEngineRemotes:Get("DamageBlock"):CallServerAsync({
        blockRef = { blockPosition = blockPosition },
        hitPosition = hitPosition,
        hitNormal = hitNormal or Vector3.FromNormalId(Enum.NormalId.Top),
      })
    end)
  end
  
  return Remotes
  
  end)()
  if _module then _BW.Remotes = _module end
end

-- ─── game/workspace.lua ───
do
  local _module = (function()
  -- src/game/workspace.lua
  -- Entity library + workspace walkers for Bedwars.
  -- WHY: features (killaura, ESP, magnet) need a unified view of players, beds,
  -- generators, and item drops. We centralize the scanning + team check here.
  --
  -- Key Bedwars-specific findings from research:
  --   - Teams: Player:GetAttribute('Team') (numeric id), NOT Roblox Teams service
  --   - Health: Character:GetAttribute('Health'), NOT Humanoid.Health
  --   - Beds: CollectionService tag 'bed'
  --   - Item drops: CollectionService tag 'ItemDrop'
  --   - Item shops: CollectionService tag 'BedwarsItemShop'
  --   - Generators: spawn ItemDrop parts (so we scan ItemDrop, not "generators")
  
  
  local Services = _BW.Services
  local Logger   = _BW.Logger
  
  local Workspace = {}
  
  -- ─── Entity table ───────────────────────────────────────────────────────────
  -- Cached per-player data so features don't re-scan every frame.
  Workspace.entities = {}  -- Player -> entity table
  
  -- Entity table shape:
  -- {
  --   Player    = Player instance,
  --   Character = Character model,
  --   Humanoid  = Humanoid,
  --   RootPart  = HumanoidRootPart,
  --   Head      = Head part,
  --   Health    = number (from Character:GetAttribute('Health')),
  --   MaxHealth = number,
  --   HipHeight = number (for ESP box sizing),
  --   Team      = number (from Player:GetAttribute('Team')),
  --   IsAlive   = boolean,
  --   IsLocal   = boolean,
  --   IsEnemy   = boolean,
  -- }
  
  local CollectionService = Services.CollectionService()
  local Players           = Services.Players()
  
  -- ─── Team check ─────────────────────────────────────────────────────────────
  -- In Bedwars, teams are a numeric attribute, not the Roblox Teams service.
  local function getTeam(plr)
    if not plr then return nil end
    return plr:GetAttribute("Team")
  end
  
  function Workspace.isEnemy(plr)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not plr or plr == localPlayer then return false end
    local myTeam = getTeam(localPlayer)
    local theirTeam = getTeam(plr)
    if myTeam == nil or theirTeam == nil then return true end  -- no team = enemy
    return myTeam ~= theirTeam
  end
  
  -- ─── Build/update an entity from a character ────────────────────────────────
  local function buildEntity(plr, char)
    if not plr or not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not root then return nil end
  
    -- Bedwars stores Health on the Character as an attribute, not on Humanoid.
    -- Fall back to Humanoid.Health if attribute is missing.
    local health = char:GetAttribute("Health") or hum.Health
    local maxHealth = char:GetAttribute("MaxHealth") or hum.MaxHealth
  
    local hipHeight = hum.HipHeight + (root.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0)
  
    return {
      Player    = plr,
      Character = char,
      Humanoid  = hum,
      RootPart  = root,
      Head      = head,
      Health    = health,
      MaxHealth = maxHealth,
      HipHeight = hipHeight,
      Team      = getTeam(plr),
      IsAlive   = health > 0 and hum.Health > 0,
      IsLocal   = plr == Players.LocalPlayer,
      IsEnemy   = Workspace.isEnemy(plr),
    }
  end
  
  -- ─── Refresh all entities ───────────────────────────────────────────────────
  -- Call this on a heartbeat (10Hz is plenty for combat targeting).
  function Workspace.refresh()
    local fresh = {}
    for _, plr in ipairs(Players:GetPlayers()) do
      local char = plr.Character
      if char then
        local ent = buildEntity(plr, char)
        if ent then
          fresh[plr] = ent
        end
      end
    end
    Workspace.entities = fresh
  end
  
  -- ─── Get all alive enemy entities ───────────────────────────────────────────
  -- Optionally filter by range (in studs) from the local player's root.
  function Workspace.getEnemies(maxRange)
    local localRoot = Services.rootPart()
    if not localRoot then return {} end
    local out = {}
    for plr, ent in pairs(Workspace.entities) do
      if ent.IsEnemy and ent.IsAlive and ent.RootPart then
        if not maxRange or (ent.RootPart.Position - localRoot.Position).Magnitude <= maxRange then
          table.insert(out, ent)
        end
      end
    end
    -- Sort by distance (closest first)
    table.sort(out, function(a, b)
      return (a.RootPart.Position - localRoot.Position).Magnitude
           < (b.RootPart.Position - localRoot.Position).Magnitude
    end)
    return out
  end
  
  -- ─── Get the nearest enemy within range ─────────────────────────────────────
  function Workspace.getNearestEnemy(maxRange)
    local enemies = Workspace.getEnemies(maxRange)
    return enemies[1] or nil
  end
  
  -- ─── Get all alive entities (including teammates, for ESP) ──────────────────
  function Workspace.getAllEntities()
    local out = {}
    for _, ent in pairs(Workspace.entities) do
      if ent.IsAlive and ent.RootPart then
        table.insert(out, ent)
      end
    end
    return out
  end
  
  -- ─── Beds (CollectionService tag 'bed') ─────────────────────────────────────
  function Workspace.getBeds()
    local ok, beds = pcall(function()
      return CollectionService:GetTagged("bed")
    end)
    if not ok then return {} end
    return beds or {}
  end
  
  -- ─── Item drops (CollectionService tag 'ItemDrop') ──────────────────────────
  -- These are the spinning items spawned by generators + death drops.
  function Workspace.getItemDrops()
    local ok, drops = pcall(function()
      return CollectionService:GetTagged("ItemDrop")
    end)
    if not ok then return {} end
    return drops or {}
  end
  
  -- ─── Item shops (CollectionService tag 'BedwarsItemShop') ───────────────────
  function Workspace.getItemShops()
    local ok, shops = pcall(function()
      return CollectionService:GetTagged("BedwarsItemShop")
    end)
    if not ok then return {} end
    return shops or {}
  end
  
  -- ─── Initialize: wire player add/remove + character events ──────────────────
  function Workspace.init()
    -- Initial scan
    Workspace.refresh()
  
    -- Wire player add/remove
    Players.PlayerAdded:Connect(function(plr)
      plr.CharacterAdded:Connect(function()
        -- Will be picked up on next refresh
      end)
    end)
  
    -- Refresh on a steady cadence (10Hz — combat + ESP both need fresh data,
    -- but we don't need 60Hz which would burn mobile battery)
    task.spawn(function()
      while true do
        pcall(Workspace.refresh)
        task.wait(0.1)
      end
    end)
  
    Logger.info("Workspace entity library initialized")
  end
  
  return Workspace
  
  end)()
  if _module then _BW.GameWksp = _module end
end

-- ─── features/killaura.lua ───
do
  local _module = (function()
  -- src/features/killaura.lua
  -- Auto-attack nearby enemies with the best sword.
  -- Pattern from VapeV4 research:
  --   - Loop: repeat ... task.wait() ... until not enabled
  --   - Find targets via Workspace.getEnemies(range)
  --   - Switch to best sword via Store:dispatch
  --   - Fire AttackEntity remote with: { weapon, chargedAttack, entityInstance, validate }
  --   - Reach extension: selfPosition += lookVector * max(distance - 14.399, 0)
  --
  -- The 14.399 magic number is the legit attack reach. Extending selfPosition
  -- along the look vector by the surplus distance bypasses the server's reach check.
  
  
  local RunService  = game:GetService("RunService")
  local Workspace   = game:GetService("Workspace")
  
  local Services    = _BW.Services
  local GameWksp    = _BW.GameWksp
  local Remotes     = _BW.Remotes
  local Logger      = _BW.Logger
  local PlaceId     = _BW.PlaceId
  
  local Killaura = {
    enabled = false,
    range   = 18,
    speed   = 20,    -- attacks per second cap
    _thread = nil,
  }
  
  -- Get the local player's current sword tool.
  -- Bedwars stores the inventory in the Roact store, but we can also find the
  -- equipped tool by checking the character's children for a Tool with a sword meta.
  local function getCurrentSword()
    local char = Services.character()
    if not char then return nil end
    -- Find any Tool in the character (Bedwars swords are Tools)
    for _, child in ipairs(char:GetChildren()) do
      if child:IsA("Tool") then
        -- Best heuristic: assume the equipped tool is the sword. Bedwars auto-equips
        -- the sword when you switch to the combat hotbar slot.
        return child
      end
    end
    return nil
  end
  
  -- Switch hotbar to a sword slot. Bedwars uses Roact store dispatch:
  --   Store:dispatch({ type = "InventorySelectHotbarSlot", slot = N })
  -- We can't always access the store from outside, so as a fallback we use
  -- the Tool:Equip() pattern. For v1 we rely on the user having a sword equipped.
  local function ensureSwordEquipped()
    -- Try the Roact store dispatch (VapeV4 pattern)
    pcall(function()
      local plr = Services.localPlayer()
      local store = require(plr.PlayerScripts.TS.ui.store).ClientStore
      -- Find a sword in the inventory and select its hotbar slot
      -- This is complex; for v1 we just trust the user's current equip
    end)
  end
  
  -- The 14.399 magic number — legit attack reach in studs.
  local LEGIT_REACH = 14.399
  
  function Killaura.attack(target)
    if not target or not target.RootPart or not target.Character then return false end
    local sword = getCurrentSword()
    if not sword then return false end
  
    local localRoot = Services.rootPart()
    if not localRoot then return false end
  
    local selfpos = localRoot.Position
    local targetPos = target.RootPart.Position
    local delta = targetPos - selfpos
    local distance = delta.Magnitude
  
    -- Reach extension: move selfPosition toward target by the surplus over LEGIT_REACH
    local dir = CFrame.lookAt(selfpos, targetPos).LookVector
    local extendedPos = selfpos + dir * math.max(distance - LEGIT_REACH, 0)
  
    -- Fire the AttackEntity remote
    return Remotes.fire("AttackEntity", {
      weapon = sword,
      chargedAttack = { chargeRatio = 0 },
      entityInstance = target.Character,
      validate = {
        raycast = {
          cameraPosition = { value = extendedPos },
          cursorDirection = { value = dir },
        },
        targetPosition = { value = targetPos },
        selfPosition = { value = extendedPos },
      },
    })
  end
  
  -- The main killaura loop. Runs in a task.spawn'd thread.
  function Killaura._loop()
    local interval = 1 / Killaura.speed
    while Killaura.enabled do
      pcall(function()
        if not PlaceId.isMatch() then return end
        if not GameWksp.entities then return end
        local enemies = GameWksp.getEnemies(Killaura.range)
        for _, target in ipairs(enemies) do
          if target and target.IsAlive then
            Killaura.attack(target)
          end
        end
      end)
      task.wait(interval)
    end
  end
  
  function Killaura.setEnabled(state)
    Killaura.enabled = state
    if state and not Killaura._thread then
      Killaura._thread = task.spawn(Logger.guard(Killaura._loop, "killaura"))
    end
    Logger.info("Killaura " .. (state and "ON" or "OFF"))
  end
  
  function Killaura.setRange(value)
    Killaura.range = value
  end
  
  function Killaura.setSpeed(value)
    Killaura.speed = value
  end
  
  return Killaura
  
  end)()
  if _module then _BW.Killaura = _module end
end

-- ─── features/reach.lua ───
do
  local _module = (function()
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
  
  end)()
  if _module then _BW.Reach = _module end
end

-- ─── features/aimbot.lua ───
do
  local _module = (function()
  -- src/features/aimbot.lua
  -- Smooth camera lerp aimbot. From VapeV4 AimAssist pattern:
  --   - Runs on Heartbeat with dt
  --   - Uses entitylib.EntityPosition (nearest enemy in FOV)
  --   - Lerp: camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, targetPos), speed * dt)
  --   - FOV gate: angle between camera look and target < maxAngle/2
  --   - Only active when a sword is held
  
  
  local RunService = game:GetService("RunService")
  local Services   = _BW.Services
  local GameWksp   = _BW.GameWksp
  local Logger     = _BW.Logger
  local PlaceId    = _BW.PlaceId
  
  local Aimbot = {
    enabled     = false,
    smoothness  = 6,      -- lerp speed multiplier
    maxAngle    = 90,     -- FOV gate (degrees, full cone)
    _conn       = nil,
  }
  
  function Aimbot._onHeartbeat(dt)
    if not Aimbot.enabled then return end
    if not PlaceId.isMatch() then return end
  
    local camera = Services.camera()
    local localRoot = Services.rootPart()
    if not camera or not localRoot then return end
  
    -- Only aimbot when a tool is equipped (sword in hand)
    local char = Services.character()
    if not char then return end
    local hasTool = false
    for _, child in ipairs(char:GetChildren()) do
      if child:IsA("Tool") then hasTool = true; break end
    end
    if not hasTool then return end
  
    -- Find nearest enemy within a generous range (aimbot doesn't need the
    -- killaura range — we use 80 studs and rely on the FOV gate)
    local target = GameWksp.getNearestEnemy(80)
    if not target or not target.RootPart then return end
  
    -- FOV gate: angle between camera look (horizontal) and target direction
    local localFacing = localRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
    local delta = (target.RootPart.Position - localRoot.Position) * Vector3.new(1, 0, 1)
    if delta.Magnitude < 0.1 then return end
    local angle = math.acos(math.clamp(localFacing:Dot(delta.Unit), -1, 1))
  
    if angle > math.rad(Aimbot.maxAngle / 2) then return end
  
    -- Smooth lerp toward target
    local targetCF = CFrame.lookAt(camera.CFrame.Position, target.RootPart.Position)
    camera.CFrame = camera.CFrame:Lerp(targetCF, Aimbot.smoothness * dt)
  end
  
  function Aimbot.setEnabled(state)
    Aimbot.enabled = state
    if state and not Aimbot._conn then
      Aimbot._conn = RunService.Heartbeat:Connect(Logger.guard(Aimbot._onHeartbeat, "aimbot"))
    elseif not state and Aimbot._conn then
      Aimbot._conn:Disconnect()
      Aimbot._conn = nil
    end
    Logger.info("Aimbot " .. (state and "ON" or "OFF"))
  end
  
  function Aimbot.setSmoothness(value)
    Aimbot.smoothness = value
  end
  
  return Aimbot
  
  end)()
  if _module then _BW.Aimbot = _module end
end

-- ─── features/fly.lua ───
do
  local _module = (function()
  -- src/features/fly.lua
  -- Noclip + velocity lift. The classic Bedwars fly pattern:
  --   - Set Humanoid.PlatformStand = true (so gravity doesn't apply)
  --   - Each frame, set RootPart.Velocity based on camera look direction
  --   - Disable Collides on character parts (noclip through walls)
  --   - W/S to go forward/backward along camera look, A/D strafe, Space/Shift up/down
  --
  -- Mobile: we use on-screen joystick buttons (added to the UI) — but for v1
  -- we use the camera look direction + a single "ascend" toggle.
  
  
  local RunService = game:GetService("RunService")
  local Services   = _BW.Services
  local Logger     = _BW.Logger
  
  local Fly = {
    enabled  = false,
    speed    = 50,
    _conn    = nil,
    _originalCollisions = {},
  }
  
  function Fly._onHeartbeat(dt)
    local char = Services.character()
    local root = Services.rootPart()
    local hum  = Services.humanoid()
    local camera = Services.camera()
    if not char or not root or not hum or not camera then return end
  
    -- PlatformStand disables normal gravity + walk
    hum.PlatformStand = true
  
    -- Compute desired velocity from camera look + inputs
    local look = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector
    local up = Vector3.new(0, 1, 0)
  
    local UIS = game:GetService("UserInputService")
    local move = Vector3.new()
  
    -- Forward/back
    if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + look end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - look end
    -- Strafe
    if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
    -- Up/down
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
      move = move - up
    end
  
    if move.Magnitude > 0 then
      move = move.Unit * Fly.speed
    end
  
    -- Apply velocity (Roblox will integrate this for us)
    root.AssemblyLinearVelocity = move
  
    -- Disable collisions on all character parts (noclip while flying)
    for _, part in ipairs(char:GetDescendants()) do
      if part:IsA("BasePart") and part.CanCollide then
        part.CanCollide = false
      end
    end
  end
  
  function Fly.setEnabled(state)
    Fly.enabled = state
    if state and not Fly._conn then
      -- Save original collision state
      local char = Services.character()
      if char then
        Fly._originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
          if part:IsA("BasePart") then
            Fly._originalCollisions[part] = part.CanCollide
          end
        end
      end
      Fly._conn = RunService.Heartbeat:Connect(Logger.guard(Fly._onHeartbeat, "fly"))
    elseif not state then
      if Fly._conn then
        Fly._conn:Disconnect()
        Fly._conn = nil
      end
      -- Restore
      local hum = Services.humanoid()
      if hum then hum.PlatformStand = false end
      local char = Services.character()
      if char then
        for part, wasCollide in pairs(Fly._originalCollisions) do
          if part and part.Parent then
            part.CanCollide = wasCollide
          end
        end
      end
      Fly._originalCollisions = {}
    end
    Logger.info("Fly " .. (state and "ON" or "OFF"))
  end
  
  function Fly.setSpeed(value)
    Fly.speed = value
  end
  
  -- Re-apply on character respawn
  function Fly.onCharacterAdded()
    if Fly.enabled then
      -- Re-save original collisions for the new character
      local char = Services.character()
      if char then
        Fly._originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
          if part:IsA("BasePart") then
            Fly._originalCollisions[part] = part.CanCollide
          end
        end
      end
    end
  end
  
  return Fly
  
  end)()
  if _module then _BW.Fly = _module end
end

-- ─── features/speed.lua ───
do
  local _module = (function()
  -- src/features/speed.lua
  -- WalkSpeed modifier. Simple — set Humanoid.WalkSpeed each frame.
  -- WHY each frame: Bedwars may reset WalkSpeed on various events (kit abilities,
  -- slowdowns, etc.). Setting it every Heartbeat keeps it sticky.
  
  
  local RunService = game:GetService("RunService")
  local Services   = _BW.Services
  local Logger     = _BW.Logger
  
  local Speed = {
    enabled = false,
    value   = 32,
    _conn   = nil,
  }
  
  function Speed._onHeartbeat()
    if not Speed.enabled then return end
    local hum = Services.humanoid()
    if not hum then return end
    -- Only override if the game's current walkspeed is lower than our target
    -- (so we don't fight speed-boost kits that legitimately exceed our value)
    if hum.WalkSpeed < Speed.value then
      hum.WalkSpeed = Speed.value
    end
  end
  
  function Speed.setEnabled(state)
    Speed.enabled = state
    if state and not Speed._conn then
      Speed._conn = RunService.Heartbeat:Connect(Logger.guard(Speed._onHeartbeat, "speed"))
    elseif not state and Speed._conn then
      Speed._conn:Disconnect()
      Speed._conn = nil
      -- Restore default
      local hum = Services.humanoid()
      if hum then hum.WalkSpeed = 16 end
    end
    Logger.info("Speed " .. (state and "ON" or "OFF"))
  end
  
  function Speed.setValue(value)
    Speed.value = value
  end
  
  return Speed
  
  end)()
  if _module then _BW.Speed = _module end
end

-- ─── features/noclip.lua ───
do
  local _module = (function()
  -- src/features/noclip.lua
  -- Walk through walls. Disables CanCollide on all character parts each frame.
  -- Pairs with Fly (which also nocliips), but Noclip standalone keeps walking
  -- physics on (so you can walk through walls but still fall with gravity).
  
  
  local RunService = game:GetService("RunService")
  local Services   = _BW.Services
  local Logger     = _BW.Logger
  
  local Noclip = {
    enabled = false,
    _conn   = nil,
  }
  
  function Noclip._onHeartbeat()
    if not Noclip.enabled then return end
    local char = Services.character()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
      if part:IsA("BasePart") and part.CanCollide then
        part.CanCollide = false
      end
    end
  end
  
  function Noclip.setEnabled(state)
    Noclip.enabled = state
    if state and not Noclip._conn then
      Noclip._conn = RunService.Heartbeat:Connect(Logger.guard(Noclip._onHeartbeat, "noclip"))
    elseif not state and Noclip._conn then
      Noclip._conn:Disconnect()
      Noclip._conn = nil
      -- Restore collisions (Bedwars defaults)
      local char = Services.character()
      if char then
        for _, part in ipairs(char:GetDescendants()) do
          if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
          end
        end
      end
    end
    Logger.info("Noclip " .. (state and "ON" or "OFF"))
  end
  
  return Noclip
  
  end)()
  if _module then _BW.Noclip = _module end
end

-- ─── features/magnet.lua ───
do
  local _module = (function()
  -- src/features/magnet.lua
  -- Pulls ALL ItemDrop parts in the workspace to the player's feet instantly.
  -- User asked for "collect all diamonds across the whole map instantly like a
  -- magnet and the emeralds too". This is the implementation.
  --
  -- Two modes:
  --   1. CFrame TP: physically move each ItemDrop to the player (network-owner check)
  --   2. Remote fire: call PickupItem remote for each drop in radius
  --
  -- We do BOTH — TP first (so the drop is at our feet), then fire the pickup
  -- remote. This matches the VapeV4 PickupRange pattern but at a huge radius
  -- (default 9999 = whole map).
  --
  -- Loop rate: 5Hz (every 0.2s) to avoid spamming the server.
  
  local Services   = require(script.Parent.Parent.services)
  local GameWksp   = require(script.Parent.Parent.game.workspace)
  local Remotes     = require(script.Parent.Parent.game.remotes)
  local Logger      = require(script.Parent.Parent.util.logger)
  local PlaceId     = require(script.Parent.Parent.game.placeid)
  
  local Magnet = {
    enabled  = false,
    radius   = 9999,   -- whole map by default
    _thread  = nil,
  }
  
  -- Check if the local player is the network owner of a part.
  -- Vape uses `isnetworkowner` if available, else assumes true on non-AWP executors.
  local function isNetworkOwner(part)
    if isnetworkowner then
      return pcall(function() return isnetworkowner(part) end)
    end
    -- Fallback: try :GetNetworkOwner() on the part's assembly root
    local ok, owner = pcall(function()
      local root = part.AssemblyRootPart or part
      return root:GetNetworkOwner()
    end)
    if not ok then return false end
    return owner == Services.localPlayer()
  end
  
  function Magnet._loop()
    while Magnet.enabled do
      pcall(function()
        if not PlaceId.isMatch() then return end
        local localRoot = Services.rootPart()
        if not localRoot then return end
        local hum = Services.humanoid()
        if not hum or hum.Health <= 0 then return end
  
        local drops = GameWksp.getItemDrops()
        local localPos = localRoot.Position
        local targetPos = localPos - Vector3.new(0, 3, 0)  -- at our feet
  
        for _, drop in ipairs(drops) do
          -- Skip freshly-spawned drops (< 2s old) to be anti-cheat friendly
          local dropTime = drop:GetAttribute("ClientDropTime")
          if dropTime and (tick() - dropTime) < 2 then
            -- still collect, but only if very close
            if (drop.Position - localPos).Magnitude > 10 then
              -- skip this drop
            else
              if isNetworkOwner(drop) then
                drop.CFrame = CFrame.new(targetPos)
              end
              task.spawn(function()
                Remotes.call("PickupItem", { itemDrop = drop })
              end)
            end
          else
            if (drop.Position - localPos).Magnitude <= Magnet.radius then
              if isNetworkOwner(drop) then
                drop.CFrame = CFrame.new(targetPos)
              end
              task.spawn(function()
                Remotes.call("PickupItem", { itemDrop = drop })
              end)
            end
          end
        end
      end)
      task.wait(0.2)  -- 5Hz
    end
  end
  
  function Magnet.setEnabled(state)
    Magnet.enabled = state
    if state and not Magnet._thread then
      Magnet._thread = task.spawn(Logger.guard(Magnet._loop, "magnet"))
    end
    Logger.info("Magnet " .. (state and "ON" or "OFF"))
  end
  
  function Magnet.setRadius(value)
    Magnet.radius = value
  end
  
  return Magnet
  
  end)()
  if _module then _BW.Magnet = _module end
end

-- ─── features/generator.lua ───
do
  local _module = (function()
  -- src/features/generator.lua
  -- Auto-collect from generators. Same as Magnet but with a smaller radius
  -- (default 30 studs) + a 3-second spawn guard — so you walk near a
  -- generator and it auto-collects without being too aggressive.
  --
  -- Bedwars generators spawn ItemDrop parts tagged 'ItemDrop'. We reuse the
  -- VapeV4 PickupRange pattern at 10Hz.
  
  local Services   = require(script.Parent.Parent.services)
  local GameWksp   = require(script.Parent.Parent.game.workspace)
  local Remotes     = require(script.Parent.Parent.game.remotes)
  local Logger      = require(script.Parent.Parent.util.logger)
  local PlaceId     = require(script.Parent.Parent.game.placeid)
  
  local Generator = {
    enabled  = false,
    radius   = 30,
    _thread  = nil,
  }
  
  function Generator._loop()
    while Generator.enabled do
      pcall(function()
        if not PlaceId.isMatch() then return end
        local localRoot = Services.rootPart()
        if not localRoot then return end
        local hum = Services.humanoid()
        if not hum or hum.Health <= 0 then return end
  
        local drops = GameWksp.getItemDrops()
        local localPos = localRoot.Position
  
        for _, drop in ipairs(drops) do
          -- 3-second spawn guard (be anti-cheat friendly)
          local dropTime = drop:GetAttribute("ClientDropTime")
          if dropTime and (tick() - dropTime) < 3 then
            -- Skip this drop
          else
            local dist = (drop.Position - localPos).Magnitude
            if dist <= Generator.radius then
              task.spawn(function()
                Remotes.call("PickupItem", { itemDrop = drop })
              end)
            end
          end
        end
      end)
      task.wait(0.1)  -- 10Hz
    end
  end
  
  function Generator.setEnabled(state)
    Generator.enabled = state
    if state and not Generator._thread then
      Generator._thread = task.spawn(Logger.guard(Generator._loop, "generator"))
    end
    Logger.info("Generator auto-collect " .. (state and "ON" or "OFF"))
  end
  
  function Generator.setRadius(value)
    Generator.radius = value
  end
  
  return Generator
  
  end)()
  if _module then _BW.Generator = _module end
end

-- ─── features/bedaura.lua ───
do
  local _module = (function()
  -- src/features/bedaura.lua
  -- Auto-break nearby enemy beds. Walks CollectionService:GetTagged('bed'),
  -- filters to enemy team, fires the BedwarsBedBreak remote (or falls back to
  -- DamageBlock on the bed's parts).
  --
  -- Bedwars beds: a Model tagged 'bed' containing a Base Part. To destroy, we
  -- either call the BedwarsBedBreak remote (via Client:Get) or DamageBlock on
  -- each bed part's position. The remote is cleaner; DamageBlock is the fallback.
  
  local Services   = require(script.Parent.Parent.services)
  local GameWksp   = require(script.Parent.Parent.game.workspace)
  local Remotes     = require(script.Parent.Parent.game.remotes)
  local Logger      = require(script.Parent.Parent.util.logger)
  local PlaceId     = require(script.Parent.Parent.game.placeid)
  
  local BedAura = {
    enabled  = false,
    radius   = 30,
    _thread  = nil,
  }
  
  -- Determine if a bed belongs to an enemy team.
  local function isEnemyBed(bedModel)
    local localPlayer = Services.localPlayer()
    if not localPlayer then return false end
    local myTeam = localPlayer:GetAttribute("Team")
    local bedTeam = bedModel:GetAttribute("Team")
    if myTeam == nil or bedTeam == nil then return true end
    return myTeam ~= bedTeam
  end
  
  function BedAura._loop()
    while BedAura.enabled do
      pcall(function()
        if not PlaceId.isMatch() then return end
        local localRoot = Services.rootPart()
        if not localRoot then return end
  
        local beds = GameWksp.getBeds()
        for _, bed in ipairs(beds) do
          if isEnemyBed(bed) then
            local part = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
            if part then
              local dist = (part.Position - localRoot.Position).Magnitude
              if dist <= BedAura.radius then
                -- Try the bed break remote first
                local ok = pcall(function()
                  if Remotes.Client then
                    Remotes.Client:WaitFor("BedwarsBedBreak")
                    local remote = Remotes.Client:Get("BedwarsBedBreak")
                    if remote and remote.instance then
                      remote.instance:FireServer({ bed = bed })
                    end
                  end
                end)
                -- Fallback: damage each part via the block engine remote
                if not ok then
                  for _, p in ipairs(bed:GetDescendants()) do
                    if p:IsA("BasePart") then
                      Remotes.damageBlock(p.Position, p.Position, Vector3.FromNormalId(Enum.NormalId.Top))
                    end
                  end
                end
              end
            end
          end
        end
      end)
      task.wait(0.5)  -- 2Hz (bed breaking doesn't need to be fast)
    end
  end
  
  function BedAura.setEnabled(state)
    BedAura.enabled = state
    if state and not BedAura._thread then
      BedAura._thread = task.spawn(Logger.guard(BedAura._loop, "bedaura"))
    end
    Logger.info("BedAura " .. (state and "ON" or "OFF"))
  end
  
  function BedAura.setRadius(value)
    BedAura.radius = value
  end
  
  return BedAura
  
  end)()
  if _module then _BW.BedAura = _module end
end

-- ─── features/shop.lua ───
do
  local _module = (function()
  -- src/features/shop.lua
  -- Auto-buy from the Bedwars item shop. Uses the BedwarsPurchaseItem remote:
  --   Client:Get('BedwarsPurchaseItem'):CallServerAsync({ shopItem = ..., shopId = ... })
  --
  -- The user picks an item (e.g. "iron_sword") from a dropdown and we buy one
  -- every few seconds. ShopId is the nearest BedwarsItemShop (CollectionService tag).
  --
  -- Note: VapeV4 doesn't have a direct autobuy module — it relies on the game's
  -- shop UI. We implement autobuy by firing the purchase remote directly.
  
  
  local Services   = _BW.Services
  local GameWksp   = _BW.GameWksp
  local Remotes     = _BW.Remotes
  local Logger      = _BW.Logger
  local PlaceId     = _BW.PlaceId
  
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
  
  end)()
  if _module then _BW.Shop = _module end
end

-- ─── features/antiafk.lua ───
do
  local _module = (function()
  -- src/features/antiafk.lua
  -- Prevents the AFK kick. Bedwars has an AfkController that sets an AFK flag
  -- after ~20s of no input. We:
  --   1. Fire the AfkStatus remote every 10s to reset the flag
  --   2. Wiggle the camera by 0.01 radians every 30s as backup
  -- Web dev mental model: this is our "keep-alive ping".
  
  
  local RunService = game:GetService("RunService")
  local Services   = _BW.Services
  local Remotes     = _BW.Remotes
  local Logger      = _BW.Logger
  
  local AntiAFK = {
    enabled = false,
    _thread = nil,
  }
  
  function AntiAFK._loop()
    local lastWiggle = tick()
    while AntiAFK.enabled do
      pcall(function()
        -- Fire the AfkStatus remote to reset AFK flag
        Remotes.fire("AfkStatus", { isAfk = false })
  
        -- Backup: wiggle the camera every 30s
        if tick() - lastWiggle > 30 then
          local camera = Services.camera()
          if camera then
            local cf = camera.CFrame
            camera.CFrame = cf * CFrame.Angles(0, 0.01, 0)
            task.wait(0.05)
            camera.CFrame = cf
          end
          lastWiggle = tick()
        end
      end)
      task.wait(10)
    end
  end
  
  function AntiAFK.setEnabled(state)
    AntiAFK.enabled = state
    if state and not AntiAFK._thread then
      AntiAFK._thread = task.spawn(Logger.guard(AntiAFK._loop, "antiafk"))
    end
    Logger.info("Anti-AFK " .. (state and "ON" or "OFF"))
  end
  
  return AntiAFK
  
  end)()
  if _module then _BW.AntiAFK = _module end
end

-- ─── features/autorejoin.lua ───
do
  local _module = (function()
  -- src/features/autorejoin.lua
  -- Rejoins the same server on disconnect / kick.
  -- Uses TeleportService:TeleportToPlaceInstance with the current JobId.
  -- WHY: Bedwars kicks you on death (sometimes) or you might DC. Auto-rejoin
  -- keeps you in the same match.
  
  
  local TeleportService = game:GetService("TeleportService")
  local Services        = _BW.Services
  local Logger          = _BW.Logger
  
  local AutoRejoin = {
    enabled = false,
    _conn   = nil,
  }
  
  function AutoRejoin._onDisconnect()
    if not AutoRejoin.enabled then return end
    local plr = Services.localPlayer()
    local placeId = game.PlaceId
    local jobId = game.JobId
    pcall(function()
      TeleportService:TeleportToPlaceInstance(placeId, jobId, plr)
    end)
  end
  
  function AutoRejoin.setEnabled(state)
    AutoRejoin.enabled = state
    if state and not AutoRejoin._conn then
      -- Listen for the LocalPlayer's connection events.
      -- Roblox doesn't have a clean "disconnect" event, so we listen for
      -- CharacterRemoving with no CharacterAdded follow-up within 10s.
      local plr = Services.localPlayer()
      if plr then
        AutoRejoin._conn = plr.CharacterRemoving:Connect(function(char)
          task.delay(10, function()
            if not plr.Character and AutoRejoin.enabled then
              AutoRejoin._onDisconnect()
            end
          end)
        end)
      end
    elseif not state and AutoRejoin._conn then
      AutoRejoin._conn:Disconnect()
      AutoRejoin._conn = nil
    end
    Logger.info("AutoRejoin " .. (state and "ON" or "OFF"))
  end
  
  return AutoRejoin
  
  end)()
  if _module then _BW.AutoRejoin = _module end
end

-- ─── features/spy.lua ───
do
  local _module = (function()
  -- src/features/spy.lua
  -- Live RemoteEvent/Function spy. Hooks __namecall to log every FireServer /
  -- InvokeServer the client makes. Useful for discovering new remotes when
  -- Bedwars updates.
  --
  -- Pattern: hookmetamethod on __namecall. When the method is FireServer or
  -- InvokeServer, log the remote name + args. Filter by name to avoid spam.
  --
  -- Requires an executor with hookmetamethod (Delta + Codex both support it).
  
  
  local Services  = _BW.Services
  local Logger    = _BW.Logger
  
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
  
  end)()
  if _module then _BW.Spy = _module end
end

-- ─── features/esp.lua ───
do
  local _module = (function()
  -- src/features/esp.lua
  -- ESP for players, beds, generators, items. Uses the Drawing API
  -- (Drawing.new('Square'/'Line'/'Text')) which is UNC-standard and supported
  -- on Delta + Codex.
  --
  -- Pattern from VapeV4 research:
  --   - Runs on RenderStepped (every frame on desktop, throttled on mobile)
  --   - Box sized from HipHeight: top + bottom CFrame offsets projected to screen
  --   - Health bar = vertical Line on the left of the box
  --   - Tracers = Line from screen bottom center to target
  --   - Subscribe to entity add/remove events (we use Workspace.entities refresh)
  --
  -- Mobile throttle: 30Hz on touch devices to save battery. 60Hz on desktop.
  -- Rewritten to avoid `continue` for Lua 5.1+ compatibility (Luau supports it).
  
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
    _drawings    = {},
    _bedDrawings = {},
    _genDrawings = {},
    _itemDrawings= {},
    _lastFrame   = 0,
  }
  
  -- ─── Drawing factory ────────────────────────────────────────────────────────
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
    text.Font = 2
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
    if entity.Player and entity.Player.TeamColor then
      local tc = entity.Player.TeamColor.Color
      if tc then return tc end
    end
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
    if not Drawing then return end
  
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
          else
            local rootPos = ent.RootPart.Position
            local look = camera.CFrame.LookVector
            local topCF    = CFrame.lookAlong(rootPos, look) * CFrame.new(2, ent.HipHeight, 0)
            local botCF    = CFrame.lookAlong(rootPos, look) * CFrame.new(-2, -ent.HipHeight - 1, 0)
            local topScreen, topVis = camera:WorldToViewportPoint(topCF.Position)
            local botScreen, botVis = camera:WorldToViewportPoint(botCF.Position)
            local visible = topVis and botVis
  
            if not ESP._drawings[ent] then
              ESP._drawings[ent] = makePlayerDrawings()
            end
            local d = ESP._drawings[ent]
            if not d then
              -- skip silently
            elseif not visible then
              d.square.Visible = false
              d.health.Visible = false
              d.healthBg.Visible = false
              d.text.Visible = false
              d.tracer.Visible = false
            else
              local sizeX = topScreen.X - botScreen.X
              local sizeY = topScreen.Y - botScreen.Y
              local posX = topScreen.X - sizeX / 2
              local posY = topScreen.Y - sizeY / 2
  
              local color = teamColor(ent)
              d.square.Visible = true
              d.square.Size = Vector2.new(math.abs(sizeX), math.abs(sizeY))
              d.square.Position = Vector2.new(posX, posY)
              d.square.Color = color
              d.square.Transparency = 1
  
              local healthRatio = ent.MaxHealth > 0 and math.clamp(ent.Health / ent.MaxHealth, 0, 1) or 0
              d.healthBg.Visible = true
              d.healthBg.From = Vector2.new(posX - 6, posY)
              d.healthBg.To = Vector2.new(posX - 6, posY + math.abs(sizeY))
              d.health.Visible = true
              d.health.From = Vector2.new(posX - 6, posY + math.abs(sizeY) * (1 - healthRatio))
              d.health.To = Vector2.new(posX - 6, posY + math.abs(sizeY))
              d.health.Color = Color3.fromHSV(healthRatio / 2.5, 0.89, 0.75)
  
              d.text.Visible = true
              d.text.Text = string.format("%s [%dm]", ent.Player and ent.Player.Name or "?", math.floor(dist))
              d.text.Position = Vector2.new(posX, posY - 16)
              d.text.Color = color
              d.text.Transparency = 1
  
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
      end
    end
  
    -- ─── Beds ────────────────────────────────────────────────────────────
    if ESP.showBeds then
      local beds = GameWksp.getBeds()
      for _, bed in ipairs(beds) do
        local part = bed.PrimaryPart or bed:FindFirstChildWhichIsA("BasePart")
        if part then
          local dist = (part.Position - localRoot.Position).Magnitude
          if dist <= ESP.maxDistance then
            if not ESP._bedDrawings[bed] then
              ESP._bedDrawings[bed] = makeSimpleDrawings()
            end
            local d = ESP._bedDrawings[bed]
            if d then
              local screen, vis = camera:WorldToViewportPoint(part.Position)
              if vis then
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
              else
                d.text.Visible = false
              end
            end
          end
        end
      end
    end
  
    -- ─── Item drops (generators spawn these) ─────────────────────────────
    if ESP.showItems or ESP.showGens then
      local drops = GameWksp.getItemDrops()
      for _, drop in ipairs(drops) do
        local dist = (drop.Position - localRoot.Position).Magnitude
        if dist <= ESP.maxDistance then
          if not ESP._itemDrawings[drop] then
            ESP._itemDrawings[drop] = makeSimpleDrawings()
          end
          local d = ESP._itemDrawings[drop]
          if d then
            local screen, vis = camera:WorldToViewportPoint(drop.Position)
            if vis then
              local color = tierColor(drop.Name)
              d.text.Visible = true
              d.text.Text = string.format("%s [%dm]", drop.Name or "item", math.floor(dist))
              d.text.Position = Vector2.new(screen.X, screen.Y - 10)
              d.text.Color = color
              d.text.Transparency = 1
            else
              d.text.Visible = false
            end
          end
        end
      end
    end
  end
  
  -- ─── Mobile-throttled render loop ───────────────────────────────────────────
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
  
  end)()
  if _module then _BW.ESP = _module end
end


-- ═══ MAIN.LUA (inlined) ═══
local _ok, _err = pcall(function()
  -- main.lua
  -- Entry point. loadstring-compatible: loadstring(game:HttpGet(URL))()
  --
  -- Boots the script in this order:
  --   1. Load config
  --   2. Init the Workspace entity library (10Hz refresh loop)
  --   3. Bootstrap Knit + extract all remote names (asynchronously — Bedwars may
  --      still be loading when the script runs)
  --   4. Build the UI (window, tabs, sections, toggles/sliders per feature)
  --   5. Wire each toggle to its feature
  --   6. Show the FAB (floating action button) — user taps it to open the menu
  --
  -- All features are off by default. The user enables them via the UI.
  
  local Players         = game:GetService("Players")
  local UserInputService = game:GetService("UserInputService")
  
  
  local function setPkg(name, module)
    if getgenv then
      getgenv()._BW[name] = module
    else
      _G._BW[name] = module
    end
    return module
  end
  
  -- ─── Resolve local paths ────────────────────────────────────────────────────
  -- When loaded via loadstring, `script` is nil. We fetch each module from the
  -- GitHub raw URL, execute it, and register it in the package table.
  
  
  
  -- Features loaded inline above (no loadModule needed)
  
  -- ─── Boot sequence ──────────────────────────────────────────────────────────
  local function boot()
    -- 1. Config
    Config.load()
    Logger.info("Config loaded")
  
    -- 2. Workspace entity library
    GameWksp.init()
  
    -- 3. Knit bootstrap (async — Bedwars may still be loading)
    task.spawn(function()
      local ok = Remotes.bootstrap(60)
      if ok then
        Remotes.extractAll()
      end
    end)
  
    -- 4. Build UI
    local Window = Library:CreateWindow({
      Name = "Bedwars Script",
      Accent = Theme.Color.Accent,
    })
  
    -- Panic callback (called by status bar ⚠ PANIC button + RightCtrl)
    Window.onPanic = function()
      Killaura.setEnabled(false)
      Reach.setEnabled(false)
      Aimbot.setEnabled(false)
      Fly.setEnabled(false)
      Speed.setEnabled(false)
      Noclip.setEnabled(false)
      Magnet.setEnabled(false)
      Generator.setEnabled(false)
      BedAura.setEnabled(false)
      Shop.setEnabled(false)
      ESP.setEnabled(false)
      Library:Notify({ Title = "⚠ PANIC", Content = "All features disabled.", Duration = 3 })
    end
    Input.onKeyDown("RightControl", Window.onPanic)
  
    -- ─── Combat tab ──────────────────────────────────────────────────────
    local combatTab = Window:CreateTab("Combat", Icons.Unicode.Combat)
    local combatSec = combatTab:CreateSection("Offense")
  
    combatSec:CreateToggle({
      Name = "Killaura",
      Icon = "⚔",
      CurrentValue = Config.get("killaura_enabled"),
      Callback = function(v) Killaura.setEnabled(v) end,
    })
    combatSec:CreateSlider({
      Name = "Killaura Range",
      Range = {5, 40},
      CurrentValue = Config.get("killaura_range"),
      Suffix = " studs",
      Callback = function(v) Killaura.setRange(v) end,
    })
    combatSec:CreateSlider({
      Name = "Killaura Speed",
      Range = {5, 30},
      CurrentValue = Config.get("killaura_speed"),
      Suffix = " Hz",
      Callback = function(v) Killaura.setSpeed(v) end,
    })
    combatSec:CreateToggle({
      Name = "Reach Extension",
      Icon = "↔",
      CurrentValue = Config.get("reach_enabled"),
      Callback = function(v) Reach.setEnabled(v) end,
    })
    combatSec:CreateSlider({
      Name = "Reach Distance",
      Range = {15, 50},
      CurrentValue = Config.get("reach_distance"),
      Suffix = " studs",
      Callback = function(v) Reach.setDistance(v) end,
    })
    combatSec:CreateToggle({
      Name = "Aimbot (smooth)",
      Icon = "◎",
      CurrentValue = Config.get("aimbot_enabled"),
      Callback = function(v) Aimbot.setEnabled(v) end,
    })
    combatSec:CreateSlider({
      Name = "Aimbot Smoothness",
      Range = {1, 20},
      CurrentValue = Config.get("aimbot_smoothness"),
      Callback = function(v) Aimbot.setSmoothness(v) end,
    })
  
    -- ─── Visuals tab ─────────────────────────────────────────────────────
    local visTab = Window:CreateTab("Visuals", Icons.Unicode.Visuals)
    local visSec = visTab:CreateSection("ESP")
  
    visSec:CreateToggle({
      Name = "Player ESP",
      Icon = "◉",
      CurrentValue = Config.get("esp_players"),
      Callback = function(v)
        ESP.setShowPlayers(v)
        ESP.setEnabled(v or Config.get("esp_beds") or Config.get("esp_generators") or Config.get("esp_items"))
      end,
    })
    visSec:CreateToggle({
      Name = "Bed ESP",
      Icon = "▤",
      CurrentValue = Config.get("esp_beds"),
      Callback = function(v)
        ESP.setShowBeds(v)
        ESP.setEnabled(Config.get("esp_players") or v or Config.get("esp_generators") or Config.get("esp_items"))
      end,
    })
    visSec:CreateToggle({
      Name = "Generator / Item ESP",
      Icon = "◈",
      CurrentValue = Config.get("esp_generators"),
      Callback = function(v)
        ESP.setShowGens(v)
        ESP.setShowItems(v)
        ESP.setEnabled(Config.get("esp_players") or Config.get("esp_beds") or v)
      end,
    })
    visSec:CreateToggle({
      Name = "Tracers",
      Icon = "➤",
      CurrentValue = Config.get("esp_tracers"),
      Callback = function(v) ESP.setShowTracers(v) end,
    })
    visSec:CreateSlider({
      Name = "ESP Distance",
      Range = {50, 500},
      CurrentValue = Config.get("esp_distance"),
      Suffix = " studs",
      Callback = function(v) ESP.setMaxDistance(v) end,
    })
  
    -- ─── Movement tab ────────────────────────────────────────────────────
    local moveTab = Window:CreateTab("Move", Icons.Unicode.Move)
    local moveSec = moveTab:CreateSection("Movement")
  
    moveSec:CreateToggle({
      Name = "Fly (noclip + velocity)",
      Icon = "➤",
      CurrentValue = Config.get("fly_enabled"),
      Callback = function(v) Fly.setEnabled(v) end,
    })
    moveSec:CreateSlider({
      Name = "Fly Speed",
      Range = {10, 200},
      CurrentValue = Config.get("fly_speed"),
      Suffix = " studs/s",
      Callback = function(v) Fly.setSpeed(v) end,
    })
    moveSec:CreateToggle({
      Name = "Speed",
      Icon = "»",
      CurrentValue = Config.get("speed_enabled"),
      Callback = function(v) Speed.setEnabled(v) end,
    })
    moveSec:CreateSlider({
      Name = "WalkSpeed",
      Range = {16, 200},
      CurrentValue = Config.get("speed_value"),
      Callback = function(v) Speed.setValue(v) end,
    })
    moveSec:CreateToggle({
      Name = "Noclip",
      Icon = "▣",
      CurrentValue = Config.get("noclip_enabled"),
      Callback = function(v) Noclip.setEnabled(v) end,
    })
  
    -- ─── World tab ───────────────────────────────────────────────────────
    local worldTab = Window:CreateTab("World", Icons.Unicode.World)
    local worldSec = worldTab:CreateSection("Resources")
  
    worldSec:CreateToggle({
      Name = "Magnet (whole map)",
      Icon = "✦",
      CurrentValue = Config.get("magnet_enabled"),
      Callback = function(v) Magnet.setEnabled(v) end,
    })
    worldSec:CreateSlider({
      Name = "Magnet Radius",
      Range = {50, 9999},
      CurrentValue = Config.get("magnet_radius"),
      Suffix = " studs",
      Callback = function(v) Magnet.setRadius(v) end,
    })
    worldSec:CreateToggle({
      Name = "Generator Auto-Collect",
      Icon = "◈",
      CurrentValue = Config.get("generator_enabled"),
      Callback = function(v) Generator.setEnabled(v) end,
    })
    worldSec:CreateSlider({
      Name = "Generator Radius",
      Range = {10, 100},
      CurrentValue = 30,
      Suffix = " studs",
      Callback = function(v) Generator.setRadius(v) end,
    })
    worldSec:CreateToggle({
      Name = "Bed Aura (auto-break)",
      Icon = "▤",
      CurrentValue = Config.get("bedaura_enabled"),
      Callback = function(v) BedAura.setEnabled(v) end,
    })
    worldSec:CreateSlider({
      Name = "Bed Aura Radius",
      Range = {10, 100},
      CurrentValue = 30,
      Suffix = " studs",
      Callback = function(v) BedAura.setRadius(v) end,
    })
  
    local shopSec = worldTab:CreateSection("Shop")
    shopSec:CreateToggle({
      Name = "Auto-Buy",
      Icon = "$",
      CurrentValue = Config.get("shop_enabled"),
      Callback = function(v) Shop.setEnabled(v) end,
    })
    shopSec:CreateDropdown({
      Name = "Item",
      Options = {"iron_sword", "diamond_sword", "wool_white", "stone", "end_stone", "obsidian", "golden_apple"},
      CurrentOption = Config.get("shop_item"),
      Callback = function(v) Shop.setItem(v) end,
    })
  
    -- ─── Misc tab ────────────────────────────────────────────────────────
    local miscTab = Window:CreateTab("Misc", Icons.Unicode.Misc)
    local miscSec = miscTab:CreateSection("Quality of life")
  
    -- PANIC BUTTON — big, red, always-visible on touch devices.
    -- Disables every feature instantly. Also wired to RightCtrl on desktop.
    miscSec:CreateButton({
      Name = "⚠ PANIC — disable everything",
      Icon = "⚠",
      Callback = function()
        Killaura.setEnabled(false)
        Aimbot.setEnabled(false)
        Fly.setEnabled(false)
        Speed.setEnabled(false)
        Noclip.setEnabled(false)
        Magnet.setEnabled(false)
        Generator.setEnabled(false)
        BedAura.setEnabled(false)
        Shop.setEnabled(false)
        Library:Notify({ Title = "PANIC", Content = "All features disabled.", Duration = 3 })
      end,
    })
  
    miscSec:CreateToggle({
      Name = "Anti-AFK",
      Icon = "◐",
      CurrentValue = Config.get("antiafk_enabled"),
      Callback = function(v) AntiAFK.setEnabled(v) end,
    })
    miscSec:CreateToggle({
      Name = "Auto-Rejoin",
      Icon = "↻",
      CurrentValue = Config.get("autorejoin_enabled"),
      Callback = function(v) AutoRejoin.setEnabled(v) end,
    })
  
    local devSec = miscTab:CreateSection("Developer")
    devSec:CreateToggle({
      Name = "Remote Spy (log FireServer/InvokeServer)",
      Icon = "◬",
      CurrentValue = Config.get("spy_enabled"),
      Callback = function(v)
        if v then Spy.enable() else Spy.disable() end
      end,
    })
    devSec:CreateButton({
      Name = "Print Remote Log to Console",
      Icon = "◬",
      Callback = function()
        local recent = Spy.getRecent(50)
        print("=== Spy Log (last 50) ===")
        for _, e in ipairs(recent) do
          print(string.format("[%s] %s:%s", os.date("%H:%M:%S", e.time), e.name, e.method))
        end
      end,
    })
    devSec:CreateButton({
      Name = "Re-extract Remotes",
      Icon = "↻",
      Callback = function()
        task.spawn(function()
          Remotes.extractAll()
          Library:Notify({ Title = "Remotes", Content = "Re-extraction complete", Duration = 3 })
        end)
      end,
    })
    devSec:CreateButton({
      Name = "Save Config",
      Icon = "✦",
      Callback = function() Config.save() end,
    })
  
    -- (panic moved to Window.onPanic + status bar button)
  
    -- ─── Re-wire Fly on character respawn ────────────────────────────────
    Players.LocalPlayer.CharacterAdded:Connect(function()
      task.wait(1)
      Fly.onCharacterAdded()
    end)
  
    -- ─── Boot notification ───────────────────────────────────────────────
    Library:Notify({
      Title = "Bedwars Script",
      Content = "Loaded. Tap ⚡ to open. Use ⚠ PANIC to disable all.",
      Duration = 6,
    })
  
    Logger.info("Boot complete — UI ready")
    return Window
  end
  
  -- Run the boot
  local ok, err = pcall(boot)
  if not ok then
    warn("[bw-script] Boot failed: " .. tostring(err))
  end
  
end)
if not _ok then
  warn('[bw-script] Boot failed: ' .. tostring(_err))
end