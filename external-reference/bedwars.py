"""
bedwars.py — game-aware helpers for Roblox Bedwars (Easybb Studios).

What this module does (purely READ + a couple of benign writes for speed/fly):
- detect if we're in Bedwars (canonical PlaceId + workspace shape)
- walk the Workspace tree and classify objects:
    * teams, players, beds, generators, dropped items
- expose queries the overlay can use:
    * enemy players (filter by team)
    * alive status
    * bed alive/destroyed per team
    * generator tier + position
    * dropped weapons / blocks

Writes (only when user toggles):
- set_walkspeed on the local Humanoid
- set_jumppower on the local Humanoid
- cancollide / anchored toggles for fly

Nothing here injects Lua. Everything is memory-level. Offsets live in offsets.json.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Iterable

from classes import Instance, Vec3, Mat4, Vec2


# Canonical Roblox Bedwars place id (Easybb Studios / "Bedwars").
BEDWARS_PLACE_ID = 6872265039

# Canonical team color names Bedwars uses for team entities (case-insensitive match).
TEAM_COLORS = ("Red", "Blue", "Green", "Yellow")

# Generator tier (ordered by power).
GENERATOR_TIERS = ("iron", "gold", "diamond", "emerald")

# Tool names worth tracking as "items".
WEAPON_HINTS = ("sword", "pickaxe", "axe", "shears")
BLOCK_HINTS = ("wool", "plank", "stone", "clay", "end_stone", "obsidian", "ladder")


# ------------------------- data classes -------------------------

@dataclass
class BedwarsPlayer:
    instance: Instance                 # Player class instance
    name: str
    team: str                          # "Red" | "Blue" | "Green" | "Yellow" | "None"
    is_local: bool
    character: Instance = field(default_factory=lambda: Instance())
    head: Instance = field(default_factory=lambda: Instance())
    humanoid: Instance = field(default_factory=lambda: Instance())
    root: Instance = field(default_factory=lambda: Instance())
    position: Vec3 = field(default_factory=Vec3)
    health: float = 0.0
    max_health: float = 0.0
    alive: bool = False


@dataclass
class BedInfo:
    team: str                          # e.g. "Red"
    model: Instance                    # the bed model in Workspace
    position: Vec3
    alive: bool                        # True if any Base part inside has a child "Block" / "Sheet"


@dataclass
class Generator:
    tier: str                          # "iron" | "gold" | "diamond" | "emerald"
    name: str                          # raw name from the model
    model: Instance
    position: Vec3


@dataclass
class DroppedItem:
    name: str
    category: str                      # "weapon" | "block" | "other"
    instance: Instance
    position: Vec3


@dataclass
class BedwarsSnapshot:
    place_id: int
    in_bedwars: bool
    local_player: BedwarsPlayer | None
    players: list[BedwarsPlayer] = field(default_factory=list)
    enemy_players: list[BedwarsPlayer] = field(default_factory=list)
    beds: list[BedInfo] = field(default_factory=list)
    generators: list[Generator] = field(default_factory=list)
    items: list[DroppedItem] = field(default_factory=list)


# ------------------------- main helper -------------------------

class Bedwars:
    def __init__(self, memory):
        self.memory = memory

    # ---------- top-level snapshot ----------

    def snapshot(self, dm_addr: int) -> BedwarsSnapshot:
        snap = BedwarsSnapshot(place_id=0, in_bedwars=False, local_player=None)
        if not dm_addr:
            return snap

        # Place ID (cached on the DataModel).
        try:
            raw = self.memory.read_ptr(dm_addr + self.memory.get_offset("PlaceId"))
            snap.place_id = raw
        except Exception:
            pass
        snap.in_bedwars = snap.place_id == BEDWARS_PLACE_ID

        # Even if PlaceId mismatches, still useful for ESP in any Roblox game,
        # but only run Bedwars-specific logic (bed/generator/item search) when in_bedwars.
        players = self.memory.utils.get_all_players(dm_addr)
        local_player_instance = self.memory.utils.get_local_player(dm_addr)

        for p in players:
            bw_player = self._build_player(p, is_local=(p.address == local_player_instance.address))
            snap.players.append(bw_player)
            if bw_player.is_local:
                snap.local_player = bw_player

        if snap.local_player and snap.local_player.team and snap.local_player.team != "None":
            snap.enemy_players = [p for p in snap.players
                                  if not p.is_local and p.team != snap.local_player.team]
        else:
            snap.enemy_players = [p for p in snap.players if not p.is_local]

        if snap.in_bedwars:
            workspace = self.memory.utils.get_workspace(dm_addr)
            if workspace.address:
                snap.beds = self._find_beds(workspace)
                snap.generators = self._find_generators(workspace)
                snap.items = self._find_items(workspace)

        return snap

    # ---------- player / team ----------

    def _build_player(self, player_inst: Instance, is_local: bool) -> BedwarsPlayer:
        name = player_inst.get_name()
        team = self._player_team_name(player_inst)
        char_inst = player_inst.get_model()
        head = char_inst.find_first_class("Part") if char_inst.address else Instance(0, self.memory)
        # Refine: actual head is a Part named "Head"
        head = char_inst.find_child("Head") if char_inst.address else Instance(0, self.memory)
        root = char_inst.find_child("HumanoidRootPart") if char_inst.address else Instance(0, self.memory)
        humanoid = char_inst.find_first_class("Humanoid") if char_inst.address else Instance(0, self.memory)
        position = root.get_pos() if root.address else Vec3()
        health = humanoid.get_health() if humanoid.address else 0.0
        max_health = humanoid.get_max_health() if humanoid.address else 0.0
        return BedwarsPlayer(
            instance=player_inst,
            name=name,
            team=team,
            is_local=is_local,
            character=char_inst,
            head=head,
            humanoid=humanoid,
            root=root,
            position=position,
            health=health,
            max_health=max_health,
            alive=(health > 0.0) and bool(humanoid.address),
        )

    def _player_team_name(self, player_inst: Instance) -> str:
        """Try to read the player's TeamColor (BrickColor name) -> team string.
        Falls back to Team object name; else 'None'."""
        try:
            # Read TeamColor (IntValue-style enum) at offset 0xD8
            tc_addr = player_inst.address + self.memory.get_offset("TeamColor")
            # Some versions store it as a u16; the rest is metadata we ignore.
            raw = self.memory.read_int(tc_addr) & 0xFFFF
            # BrickColor enum id -> name (only the canonical Bedwars team colors).
            # Roblox BrickColor ids (subset):
            #   1=White, 21=Bright red, 23=Bright blue, 24=Bright yellow, 37=Bright green
            mapping = {21: "Red", 23: "Blue", 24: "Yellow", 37: "Green"}
            if raw in mapping:
                return mapping[raw]
        except Exception:
            pass
        # Fallback: Team instance under player
        try:
            team = Instance(self.memory.read_ptr(
                player_inst.address + self.memory.get_offset("Team")), self.memory)
            tname = team.get_name()
            for c in TEAM_COLORS:
                if c.lower() in tname.lower():
                    return c
        except Exception:
            pass
        return "None"

    # ---------- beds ----------

    def _find_beds(self, workspace: Instance) -> list[BedInfo]:
        out: list[BedInfo] = []
        for child in workspace.get_children():
            if child.get_class() != "Model":
                continue
            name = child.get_name()
            team = self._match_team(name)
            if not team:
                continue
            # Heuristic: a Bed model in Bedwars contains a Part named "Base".
            base = child.find_child("Base")
            if not base.address:
                # Some maps name it differently; accept any Part child as a fallback.
                base = child.find_first_class("Part")
            if not base.address:
                continue
            alive = self._bed_alive(child)
            out.append(BedInfo(
                team=team,
                model=child,
                position=base.get_pos(),
                alive=alive,
            ))
        return out

    def _bed_alive(self, bed_model: Instance) -> bool:
        """A bed is alive if it has visible block children (a destroyed bed is a
        small 'destroyed' mesh). Cheap check: any child is a Part with size > 1.
        """
        try:
            for c in bed_model.get_children():
                if c.get_class() != "Part":
                    continue
                s = c.get_size()
                # Destroyed beds in Bedwars have very small (~0,0,0) extent.
                if max(s.x, s.y, s.z) > 1.0:
                    return True
            return False
        except Exception:
            return True  # assume alive if we can't tell

    # ---------- generators ----------

    def _find_generators(self, workspace: Instance) -> list[Generator]:
        out: list[Generator] = []
        for child in workspace.get_children():
            if child.get_class() != "Model":
                continue
            raw = child.get_name()
            tier = self._match_tier(raw)
            if not tier:
                continue
            # Generators expose a "Generator" instance part for world->screen anchor.
            base = child.find_first_class("Part")
            pos = base.get_pos() if base.address else Vec3()
            out.append(Generator(tier=tier, name=raw, model=child, position=pos))
        return out

    # ---------- dropped items ----------

    def _find_items(self, workspace: Instance) -> list[DroppedItem]:
        out: list[DroppedItem] = []
        for child in workspace.get_children():
            if child.get_class() != "Tool":
                continue
            name = child.get_name()
            cat = self._item_category(name)
            handle = child.find_first_class("Part")
            pos = handle.get_pos() if handle.address else Vec3()
            out.append(DroppedItem(name=name, category=cat, instance=child, position=pos))
        return out

    # ---------- matchers ----------

    @staticmethod
    def _match_team(name: str) -> str | None:
        n = name.lower()
        if "bed" not in n:
            return None
        for c in TEAM_COLORS:
            if c.lower() in n:
                return c
        return None

    @staticmethod
    def _match_tier(name: str) -> str | None:
        n = name.lower()
        if "generator" not in n:
            return None
        for t in GENERATOR_TIERS:
            if t in n:
                return t
        return None

    @staticmethod
    def _item_category(name: str) -> str:
        n = name.lower()
        if any(w in n for w in WEAPON_HINTS):
            return "weapon"
        if any(b in n for b in BLOCK_HINTS):
            return "block"
        return "other"


# ------------------------- screen-projection helpers -------------------------

def project_snapshot(
    snap: BedwarsSnapshot,
    utils,
    matrix: Mat4,
    dims: Vec2,
    local_pos: Vec3 | None,
) -> dict:
    """Returns a flat dict of overlay-ready entries (positions in screen space)."""
    out = {
        "players": [],   # list[dict]: name, pos, health, max_h, alive, team
        "beds": [],      # list[dict]: team, pos, alive
        "gens": [],      # list[dict]: tier, pos
        "items": [],     # list[dict]: name, cat, pos
    }

    def w2s(p: Vec3) -> Vec2:
        return utils.world_to_screen(p, matrix, dims)

    for p in snap.players:
        if not p.position.x and not p.position.y and not p.position.z:
            continue
        s = w2s(p.position)
        if s.x < 0 or s.y < 0:
            continue
        dist = 0.0
        if local_pos is not None:
            dx = p.position.x - local_pos.x
            dy = p.position.y - local_pos.y
            dz = p.position.z - local_pos.z
            dist = (dx * dx + dy * dy + dz * dz) ** 0.5
        out["players"].append({
            "name": p.name,
            "screen": s,
            "pos": p.position,
            "health": p.health,
            "max": p.max_health,
            "alive": p.alive,
            "team": p.team,
            "is_local": p.is_local,
            "distance": dist,
        })

    for b in snap.beds:
        s = w2s(b.position)
        if s.x < 0 or s.y < 0:
            continue
        out["beds"].append({"team": b.team, "screen": s, "alive": b.alive, "pos": b.position})

    for g in snap.generators:
        s = w2s(g.position)
        if s.x < 0 or s.y < 0:
            continue
        out["gens"].append({"tier": g.tier, "screen": s, "pos": g.position, "name": g.name})

    for it in snap.items:
        s = w2s(it.position)
        if s.x < 0 or s.y < 0:
            continue
        out["items"].append({"name": it.name, "cat": it.category, "screen": s, "pos": it.position})

    return out
