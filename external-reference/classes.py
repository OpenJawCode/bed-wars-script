"""
classes.py — math types, instance wrapper, world->screen, scheduler traversal.

Adapted from RajkoRSL/python-external-roblox. Bedwars-cleanup pass:
- typed hints
- removed getclass() (not needed when we filter by name)
- kept instance traversal + children/parent lookups
- world->screen reads viewmatrix directly from VisualEngine
"""
from __future__ import annotations
import struct
from typing import Iterator


class Vec2:
    __slots__ = ("x", "y")
    def __init__(self, x: float = 0.0, y: float = 0.0):
        self.x, self.y = x, y


class Vec3:
    __slots__ = ("x", "y", "z")
    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        self.x, self.y, self.z = x, y, z

    def __sub__(self, o: "Vec3") -> "Vec3":
        return Vec3(self.x - o.x, self.y - o.y, self.z - o.z)


class Mat4:
    """4x4 row-major view matrix; .data[0..15] floats."""
    __slots__ = ("data",)
    def __init__(self, data: list[float] | None = None):
        self.data = data if data else [0.0] * 16


# ------------------------- string / instance -------------------------

class Instance:
    """Wraps a Roblox instance address. Address 0 == null instance."""
    __slots__ = ("address", "memory")

    def __init__(self, address: int = 0, memory: "Memory | None" = None):
        self.address = address
        self.memory = memory

    def _valid(self) -> bool:
        return bool(self.address) and self.memory is not None

    def _read_cstr(self, addr: int, limit: int = 200) -> str:
        if not self._valid() or not addr:
            return ""
        out = []
        for off in range(limit):
            try:
                b = self.memory.process.read_bytes(addr + off, 1)[0]
            except Exception:
                break
            if b == 0:
                break
            out.append(chr(b))
        return "".join(out)

    def _read_roblox_string(self, addr: int) -> str:
        """Roblox std::string layout: short <=15 chars inlined, else pointer."""
        if not self._valid() or not addr:
            return ""
        try:
            length = self.memory.read_int(addr + 0x18)
            if length >= 16:
                return self._read_cstr(self.memory.read_ptr(addr))
            return self._read_cstr(addr)
        except Exception:
            return ""

    # -------- name --------
    def get_name(self) -> str:
        if not self._valid():
            return ""
        try:
            ptr = self.memory.read_ptr(self.address + self.memory.get_offset("Name"))
            return self._read_roblox_string(ptr)
        except Exception:
            return ""

    # -------- class name (uses ClassDescriptor) --------
    def get_class(self) -> str:
        if not self._valid():
            return "unknown"
        try:
            desc = self.memory.read_ptr(
                self.address + self.memory.get_offset("ClassDescriptor")
            )
            name_ptr = self.memory.read_ptr(desc + 0x8)
            return self._read_roblox_string(name_ptr) or "unknown"
        except Exception:
            return "unknown"

    # -------- children --------
    def get_children(self) -> list["Instance"]:
        if not self._valid():
            return []
        try:
            list_addr = self.memory.read_ptr(
                self.address + self.memory.get_offset("Children")
            )
            start = self.memory.read_ptr(list_addr)
            end = self.memory.read_ptr(list_addr + self.memory.get_offset("ChildrenEnd"))
            out: list[Instance] = []
            i = start
            while i < end:
                child_addr = self.memory.read_ptr(i)
                if child_addr:
                    out.append(Instance(child_addr, self.memory))
                i += 0x10
            return out
        except Exception:
            return []

    def iter_children(self) -> Iterator["Instance"]:
        return iter(self.get_children())

    def find_child(self, name: str) -> "Instance":
        for c in self.get_children():
            if c.get_name() == name:
                return c
        return Instance(0, self.memory)

    def find_first_class(self, classname: str) -> "Instance":
        for c in self.get_children():
            if c.get_class() == classname:
                return c
        return Instance(0, self.memory)

    def find_descendant(self, name: str) -> "Instance":
        for c in self.get_children():
            if c.get_name() == name:
                return c
            sub = c.find_descendant(name)
            if sub.address:
                return sub
        return Instance(0, self.memory)

    # -------- position / size (via Primitive) --------
    def get_pos(self) -> Vec3:
        if not self._valid():
            return Vec3()
        try:
            prim = self.memory.read_ptr(
                self.address + self.memory.get_offset("Primitive")
            )
            if not prim:
                return Vec3()
            data = self.memory.read_bytes(prim + self.memory.get_offset("Position"), 12)
            return Vec3(*struct.unpack("fff", data))
        except Exception:
            return Vec3()

    def get_size(self) -> Vec3:
        if not self._valid():
            return Vec3()
        try:
            prim = self.memory.read_ptr(
                self.address + self.memory.get_offset("Primitive")
            )
            if not prim:
                return Vec3()
            data = self.memory.read_bytes(prim + self.memory.get_offset("PartSize"), 12)
            return Vec3(*struct.unpack("fff", data))
        except Exception:
            return Vec3()

    # -------- model (for Player) --------
    def get_model(self) -> "Instance":
        if not self._valid():
            return Instance(0, self.memory)
        try:
            addr = self.memory.read_ptr(
                self.address + self.memory.get_offset("ModelInstance")
            )
            return Instance(addr, self.memory) if addr else Instance(0, self.memory)
        except Exception:
            return Instance(0, self.memory)

    # -------- health (Humanoid, XOR-obfuscated) --------
    def get_health(self) -> float:
        if not self._valid():
            return 0.0
        try:
            off = self.memory.get_offset("Health")
            a = self.memory.read_ptr(self.address + off)
            b = self.memory.read_ptr(self.memory.read_ptr(self.address + off))
            return struct.unpack("f", struct.pack("Q", a ^ b))[0]
        except Exception:
            return 0.0

    def get_max_health(self) -> float:
        if not self._valid():
            return 0.0
        try:
            off = self.memory.get_offset("MaxHealth")
            a = self.memory.read_ptr(self.address + off)
            b = self.memory.read_ptr(self.memory.read_ptr(self.address + off))
            return struct.unpack("f", struct.pack("Q", a ^ b))[0]
        except Exception:
            return 0.0

    # -------- walkspeed (Humanoid) — read/write for speed hack --------
    def get_walkspeed(self) -> float:
        return self.memory.read_float(
            self.address + self.memory.get_offset("WalkSpeed")
        )

    def set_walkspeed(self, value: float) -> bool:
        return self.memory.write_float(
            self.address + self.memory.get_offset("WalkSpeed"), value
        )

    def get_jumppower(self) -> float:
        return self.memory.read_float(
            self.address + self.memory.get_offset("JumpPower")
        )

    def set_jumppower(self, value: float) -> bool:
        return self.memory.write_float(
            self.address + self.memory.get_offset("JumpPower"), value
        )


# ------------------------- world -> screen -------------------------

class Utils:
    def __init__(self, memory: "Memory"):
        self.memory = memory

    def get_matrix(self, visual_engine_addr: int) -> Mat4:
        try:
            data = self.memory.read_bytes(
                visual_engine_addr + self.memory.get_offset("viewmatrix"), 64
            )
            return Mat4(list(struct.unpack("16f", data)))
        except Exception:
            return Mat4()

    def get_dims(self, visual_engine_addr: int) -> Vec2:
        try:
            data = self.memory.read_bytes(
                visual_engine_addr + self.memory.get_offset("Dimensions"), 8
            )
            return Vec2(*struct.unpack("ff", data))
        except Exception:
            return Vec2(800, 600)

    def world_to_screen(self, pos: Vec3, m: Mat4, dims: Vec2) -> Vec2:
        try:
            d = m.data
            cx = pos.x * d[0] + pos.y * d[1] + pos.z * d[2] + d[3]
            cy = pos.x * d[4] + pos.y * d[5] + pos.z * d[6] + d[7]
            cz = pos.x * d[8] + pos.y * d[9] + pos.z * d[10] + d[11]
            cw = pos.x * d[12] + pos.y * d[13] + pos.z * d[14] + d[15]
            if cw < 0.1:
                return Vec2(-1, -1)
            ndc_x = cx / cw
            ndc_y = cy / cw
            x = (dims.x / 2.0) * (1.0 + ndc_x)
            y = (dims.y / 2.0) * (1.0 - ndc_y)
            return Vec2(x, y)
        except Exception:
            return Vec2(-1, -1)

    # ---------- service helpers ----------
    def get_workspace(self, dm_addr: int) -> Instance:
        return Instance(dm_addr, self.memory).find_child("Workspace")

    def get_players_service(self, dm_addr: int) -> Instance:
        return Instance(dm_addr, self.memory).find_child("Players")

    def get_local_player(self, dm_addr: int) -> Instance:
        players = self.get_players_service(dm_addr)
        if not players.address:
            return Instance(0, self.memory)
        return Instance(
            self.memory.read_ptr(players.address + self.memory.get_offset("LocalPlayer")),
            self.memory,
        )

    def get_all_players(self, dm_addr: int) -> list[Instance]:
        players = self.get_players_service(dm_addr)
        if not players.address:
            return []
        out = []
        for child in players.get_children():
            if child.get_class() == "Player":
                out.append(child)
        return out


# ------------------------- scheduler (entry into Roblox) -------------------------

class Scheduler:
    RENDER_JOB = "RenderJob"

    def __init__(self, memory: "Memory"):
        self.memory = memory

    def _jobs_base(self) -> int:
        return self.memory.read_ptr(
            self.memory.base + self.memory.get_offset("task_scheduler_offset")
        )

    def _jobs_end(self) -> int:
        return self.memory.read_ptr(
            self.memory.base + self.memory.get_offset("task_scheduler_offset") + 0x8
        )

    def _job_name(self, addr: int) -> str:
        try:
            ptr = addr + self.memory.get_offset("job_name")
            length = self.memory.read_int(ptr + 0x18)
            if length >= 16:
                ptr = self.memory.read_ptr(ptr)
            raw = self.memory.read_bytes(ptr, min(length, 100))
            return raw.decode("utf-8", errors="ignore").rstrip("\x00")
        except Exception:
            return ""

    def _iter_jobs(self) -> Iterator[int]:
        try:
            base = self._jobs_base()
            end = self._jobs_end()
            i = 0
            while (base + i) < end:
                job = self.memory.read_ptr(base + i)
                if job:
                    yield job
                i += 0x10
        except Exception:
            return

    def _find_job(self, contains: str) -> int:
        for job in self._iter_jobs():
            if contains in self._job_name(job):
                return job
        return 0

    def get_visual(self) -> int:
        job = self._find_job(self.RENDER_JOB)
        if not job:
            return 0
        rv_off = self.memory.get_offset("renderview_ptr")
        ve_off = self.memory.get_offset("visualengine_ptr")
        rv = self.memory.read_ptr(job + rv_off)
        return self.memory.read_ptr(rv + ve_off)

    def get_dm(self) -> int:
        job = self._find_job(self.RENDER_JOB)
        if not job:
            return 0
        dm_off = self.memory.get_offset("datamodel_ptr")
        dmoff_off = self.memory.get_offset("datamodel_offset")
        dm = self.memory.read_ptr(job + dm_off)
        return dm + dmoff_off
