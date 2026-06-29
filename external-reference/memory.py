"""
memory.py — process attach + memory I/O for RobloxPlayerBeta.exe

Adapted from RajkoRSL/python-external-roblox (MIT-style educational reference).
Bedwars-specific tweaks: leaner API, expose setters we need for speed/fly.
"""
import json
import psutil
import pymem
import pymem.process


class Memory:
    def __init__(self, target: str = "RobloxPlayerBeta.exe"):
        self.target = target
        self.process: pymem.Pymem | None = None
        self.base: int = 0
        self.offsets: dict = {}
        self.utils = None
        self.scheduler = None
        self._load_offsets()

    def _load_offsets(self, path: str = "offsets.json"):
        try:
            with open(path, "r", encoding="utf-8") as f:
                self.offsets = json.load(f)
        except FileNotFoundError:
            raise RuntimeError(
                "offsets.json not found. Place it next to main.py."
            )

    def get_offset(self, name: str) -> int:
        s = self.offsets.get(name, "0x0")
        return int(s, 16)

    # ---------- process ----------
    def find_pid(self, name: str | None = None) -> int | None:
        name = name or self.target
        for proc in psutil.process_iter(["pid", "name"]):
            if proc.info["name"] == name:
                return proc.info["pid"]
        return None

    def attach(self, name: str | None = None) -> bool:
        name = name or self.target
        try:
            self.process = pymem.Pymem(name)
            mod = pymem.process.module_from_name(self.process.process_handle, name)
            self.base = mod.lpBaseOfDll
            from classes import Utils, Scheduler
            self.utils = Utils(self)
            self.scheduler = Scheduler(self)
            return True
        except Exception:
            return False

    def is_open(self) -> bool:
        try:
            return (
                self.process is not None
                and self.process.process_handle is not None
            )
        except Exception:
            return False

    # ---------- raw reads/writes ----------
    def read_ptr(self, addr: int) -> int:
        try:
            return self.process.read_longlong(addr)
        except Exception:
            return 0

    def read_int(self, addr: int) -> int:
        try:
            return self.process.read_int(addr)
        except Exception:
            return 0

    def write_int(self, addr: int, value: int) -> bool:
        try:
            self.process.write_int(addr, value)
            return True
        except Exception:
            return False

    def read_float(self, addr: int) -> float:
        try:
            return self.process.read_float(addr)
        except Exception:
            return 0.0

    def write_float(self, addr: int, value: float) -> bool:
        try:
            self.process.write_float(addr, value)
            return True
        except Exception:
            return False

    def read_bytes(self, addr: int, size: int) -> bytes:
        try:
            return self.process.read_bytes(addr, size)
        except Exception:
            return b"\x00" * size

    # ---------- high-level getters ----------
    def get_dm(self) -> int:
        if not self.base or not self.scheduler:
            return 0
        try:
            return self.scheduler.get_dm()
        except Exception:
            return 0

    def get_visual(self) -> int:
        if not self.base or not self.scheduler:
            return 0
        try:
            return self.scheduler.get_visual()
        except Exception:
            return 0
