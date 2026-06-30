#!/usr/bin/env python3
"""Build a single-file version of the Bedwars script."""
import os, re

BASE = '/home/ubuntu/projects/clients/roblox-scripts/bed-wars-script'

module_files = [
    'util/logger.lua',
    'ui/theme.lua',
    'util/tween.lua',
    'util/dragger.lua',
    'util/input.lua',
    'util/projection.lua',
    'ui/animations.lua',
    'ui/icons.lua',
    'ui/library.lua',
    'config.lua',
    'game/placeid.lua',
    'game/services.lua',
    'game/remotes.lua',
    'game/workspace.lua',
    'features/killaura.lua',
    'features/reach.lua',
    'features/aimbot.lua',
    'features/fly.lua',
    'features/speed.lua',
    'features/noclip.lua',
    'features/magnet.lua',
    'features/generator.lua',
    'features/bedaura.lua',
    'features/shop.lua',
    'features/antiafk.lua',
    'features/autorejoin.lua',
    'features/spy.lua',
    'features/esp.lua',
]

name_map = {
    'logger': 'Logger', 'theme': 'Theme', 'tween': 'Tween',
    'dragger': 'Dragger', 'input': 'Input', 'projection': 'Projection',
    'animations': 'Anim', 'icons': 'Icons', 'library': 'Library',
    'config': 'Config', 'placeid': 'PlaceId', 'services': 'Services',
    'remotes': 'Remotes', 'workspace': 'GameWksp',
    'killaura': 'Killaura', 'reach': 'Reach', 'aimbot': 'Aimbot',
    'fly': 'Fly', 'speed': 'Speed', 'noclip': 'Noclip',
    'magnet': 'Magnet', 'generator': 'Generator', 'bedaura': 'BedAura',
    'shop': 'Shop', 'antiafk': 'AntiAFK', 'autorejoin': 'AutoRejoin',
    'spy': 'Spy', 'esp': 'ESP',
}

out = []
out.append("-- docs/bw-singlefile.lua")
out.append("-- Bedwars Script — SINGLE FILE version. No HttpGet required.")
out.append("-- Paste this entire string into your executor (Delta/Codex/etc).")
out.append("--")
out.append("-- Generated from the multi-file project by scripts/build_singlefile.py")
out.append("-- Total: " + str(len(module_files)) + " modules inlined.")
out.append("")
out.append("-- ═══ SETUP: package registry ═══")
out.append("local _BW = (getgenv and getgenv()) or _G")
out.append("_BW._BW = _BW")
out.append("")

# Inline each module
for path in module_files:
    full = os.path.join(BASE, 'src', path)
    with open(full) as f:
        src = f.read()
    # Remove the `local _BW = ...` line since we already have _BW defined
    src = re.sub(
        r"^local _BW = \(getgenv and getgenv\(\)\._BW\) or _G\._BW\s*\n",
        '',
        src,
        flags=re.MULTILINE
    )
    # Use the path basename to derive the module name
    name = os.path.basename(path).replace('.lua', '')
    var_name = name_map.get(name.lower(), name.capitalize())

    out.append(f"-- ─── {path} ───")
    out.append("do")
    out.append("  local _module = (function()")
    for line in src.split('\n'):
        out.append('  ' + line)
    out.append("  end)()")
    out.append(f"  if _module then _BW.{var_name} = _module end")
    out.append("end")
    out.append("")

# Inline main.lua
with open(os.path.join(BASE, 'main.lua')) as f:
    main_src = f.read()

# Strip the loadModule / registry setup
main_src = re.sub(
    r"^-- ─── Package registry.*?^end\n",
    '',
    main_src,
    flags=re.DOTALL | re.MULTILINE
)
main_src = re.sub(
    r"^-- Generic loader:.*?^end\n",
    '',
    main_src,
    flags=re.DOTALL | re.MULTILINE
)
main_src = re.sub(
    r"^local function loadModule\(name, path\).*?^end\n",
    '',
    main_src,
    flags=re.DOTALL | re.MULTILINE
)
# Remove `local X = loadModule(...)` lines
main_src = re.sub(
    r'local \w+\s*=\s*loadModule\("[^"]+",\s*"[^"]+"\)\n',
    '',
    main_src
)
# Remove the "─── Load order" comment + Features comment
main_src = re.sub(
    r"^-- ─── Load order.*?-- Features\n",
    '-- Features loaded inline above (no loadModule needed)\n',
    main_src,
    flags=re.DOTALL | re.MULTILINE
)
# Remove SOURCE_BASE line
main_src = re.sub(
    r'^local SOURCE_BASE = "[^"]*"\n',
    '',
    main_src,
    flags=re.MULTILINE
)

out.append("")
out.append("-- ═══ MAIN.LUA (inlined) ═══")
out.append("local _ok, _err = pcall(function()")
for line in main_src.split('\n'):
    out.append('  ' + line)
out.append("end)")
out.append("if not _ok then")
out.append("  warn('[bw-script] Boot failed: ' .. tostring(_err))")
out.append("end")

# Write
out_path = os.path.join(BASE, 'docs', 'bw-singlefile.lua')
with open(out_path, 'w') as f:
    f.write('\n'.join(out))

size_kb = os.path.getsize(out_path) / 1024
line_count = sum(1 for _ in open(out_path))
print(f"Single-file generated: {out_path}")
print(f"  Size: {size_kb:.1f} KB, Lines: {line_count}, Modules: {len(module_files)}")
