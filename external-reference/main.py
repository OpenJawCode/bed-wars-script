"""
main.py — entry point.

Wires together:
    Memory (process attach + read/write)
    Bedwars (game-aware snapshot)
    Overlay (PyQt5 transparent, click-through ESP)
    UI     (PyQt5 control panel with toggles)

Hotkeys (rebindable in UI):
    INSERT  show/hide the control panel
    END     clean exit (also closes the overlay)
    X       toggle triggerbot hold
    F       toggle fly (only effective if 'fly_enabled' is on in UI)

Run:
    python main.py
"""
from __future__ import annotations

import sys
import threading
import time

import keyboard
import mouse
import pyautogui
from PyQt5.QtCore import Qt, QTimer, pyqtSignal
from PyQt5.QtGui import QColor, QFont, QPainter, QPen, QBrush
from PyQt5.QtWidgets import (
    QApplication,
    QCheckBox,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QSlider,
    QVBoxLayout,
    QWidget,
)

from bedwars import Bedwars, project_snapshot
from classes import Mat4, Vec2, Vec3
from memory import Memory


# ----- color palette (team-coded ESP) -----
TEAM_RGB = {
    "Red":    (220,  60,  60),
    "Blue":   ( 60, 120, 230),
    "Green":  ( 60, 200,  90),
    "Yellow": (240, 220,  60),
    "None":   (200, 200, 200),
}
GEN_RGB = {
    "iron":    (180, 180, 200),
    "gold":    (240, 200,  60),
    "diamond": (140, 220, 255),
    "emerald": ( 60, 220, 130),
}
ITEM_RGB = {
    "weapon": (255, 120,  60),
    "block":  (180, 140, 255),
    "other":  (200, 200, 200),
}


# ============================================================
#  Overlay (transparent, click-through, fullscreen)
# ============================================================
class Overlay(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.FramelessWindowHint
            | Qt.WindowStaysOnTopHint
            | Qt.Tool
            | Qt.WindowTransparentForInput
        )
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_ShowWithoutActivating)
        screen = QApplication.primaryScreen().geometry()
        self.width_, self.height_ = screen.width(), screen.height()
        self.setGeometry(0, 0, self.width_, self.height_)

        self.payload: dict = {
            "players": [], "beds": [], "gens": [], "items": [],
        }
        self.local_pos: Vec3 | None = None

        # visual toggles
        self.show_player_box = True
        self.show_player_name = True
        self.show_player_health = True
        self.show_player_distance = True
        self.show_snaplines = True
        self.show_beds = True
        self.show_generators = True
        self.show_items = True

    def update_payload(self, payload: dict, local_pos: Vec3 | None):
        self.payload = payload
        self.local_pos = local_pos
        self.update()  # schedule repaint

    # ---- drawing ----
    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        try:
            self._draw(p)
        finally:
            p.end()

    def _draw(self, p: QPainter):
        # Players
        for pl in self.payload.get("players", []):
            team = pl["team"]
            rgb = TEAM_RGB.get(team, TEAM_RGB["None"])
            # Skeleton/box style differs for local vs enemy
            x, y = pl["screen"].x, pl["screen"].y
            dist = pl.get("distance", 0.0)
            scale = max(0.35, min(1.4, 80.0 / max(dist, 8.0)))  # shrink with distance
            w = int(36 * scale)
            h = int(72 * scale)

            if pl["is_local"]:
                self._draw_box(p, x, y, w, h, (255, 255, 255), alpha=120, width=1)
            else:
                self._draw_box(p, x, y, w, h, rgb, alpha=235, width=2)
                if self.show_player_health:
                    self._draw_health_bar(p, x, y, w, h, pl["health"], pl["max"], rgb)
                if self.show_player_name:
                    self._draw_text_centered(p, x, y - h // 2 - 18, pl["name"], (255, 255, 255), 10)
                if self.show_player_distance:
                    self._draw_text_centered(p, x, y + h // 2 + 4, f"{int(dist)}m", (220, 220, 220), 9)
                if self.show_snaplines:
                    self._draw_snapline(p, x, y, rgb, alpha=140)

        # Beds
        if self.show_beds:
            for b in self.payload.get("beds", []):
                rgb = TEAM_RGB.get(b["team"], (255, 255, 255))
                x, y = b["screen"].x, b["screen"].y
                if b["alive"]:
                    self._draw_text(p, x + 12, y - 18, f"{b['team']} BED", rgb, 11, bold=True)
                    self._draw_circle(p, x, y, 8, rgb, alpha=230)
                else:
                    self._draw_text(p, x + 12, y - 18, f"{b['team']} BED (dead)", (200, 80, 80), 11, bold=True)
                    self._draw_cross(p, x, y, 8, (200, 80, 80))

        # Generators
        if self.show_generators:
            for g in self.payload.get("gens", []):
                rgb = GEN_RGB.get(g["tier"], (200, 200, 200))
                x, y = g["screen"].x, g["screen"].y
                self._draw_diamond(p, x, y, 7, rgb, alpha=220)
                self._draw_text(p, x + 10, y - 4, g["tier"].upper(), rgb, 9, bold=True)

        # Items
        if self.show_items:
            for it in self.payload.get("items", []):
                rgb = ITEM_RGB.get(it["cat"], (200, 200, 200))
                x, y = it["screen"].x, it["screen"].y
                self._draw_square(p, x, y, 5, rgb, alpha=200)
                self._draw_text(p, x + 8, y + 4, it["name"], rgb, 9)

    # ---- primitives ----
    @staticmethod
    def _qcolor(rgb, alpha=255):
        r, g, b = rgb
        return QColor(r, g, b, max(0, min(255, alpha)))

    def _draw_box(self, p, cx, cy, w, h, rgb, alpha=255, width=2):
        c = self._qcolor(rgb, alpha)
        p.setPen(QPen(c, width))
        p.setBrush(Qt.NoBrush)
        p.drawRect(int(cx - w / 2), int(cy - h / 2), int(w), int(h))

    def _draw_health_bar(self, p, cx, cy, w, h, hp, max_hp, rgb):
        if max_hp <= 0:
            return
        ratio = max(0.0, min(1.0, hp / max_hp))
        bx = int(cx - w / 2 - 6)
        by_top = int(cy - h / 2)
        bh = int(h)
        p.setPen(Qt.NoPen)
        p.setBrush(QBrush(self._qcolor((20, 20, 20), 200)))
        p.drawRect(bx, by_top, 4, bh)
        fill = max(1, int(bh * ratio))
        hp_color = (
            (60 + int(195 * (1 - abs(ratio - 0.5) * 2)),
             200 if ratio > 0.5 else 80,
             60)
        )
        p.setBrush(QBrush(self._qcolor(hp_color, 240)))
        p.drawRect(bx, by_top + (bh - fill), 4, fill)

    def _draw_text(self, p, x, y, text, rgb, size=10, bold=False):
        p.setPen(self._qcolor(rgb, 255))
        f = QFont("Segoe UI", size)
        f.setBold(bold)
        p.setFont(f)
        p.drawText(int(x), int(y), text)

    def _draw_text_centered(self, p, x, y, text, rgb, size=10, bold=False):
        f = QFont("Segoe UI", size)
        f.setBold(bold)
        p.setFont(f)
        p.setPen(self._qcolor(rgb, 255))
        rect = p.fontMetrics().boundingRect(text)
        p.drawText(int(x - rect.width() / 2), int(y), text)

    def _draw_snapline(self, p, x, y, rgb, alpha=120):
        p.setPen(QPen(self._qcolor(rgb, alpha), 1))
        p.drawLine(0, int(self.height_), int(x), int(y))

    def _draw_circle(self, p, cx, cy, r, rgb, alpha=220):
        p.setPen(QPen(self._qcolor(rgb, alpha), 2))
        p.setBrush(Qt.NoBrush)
        p.drawEllipse(int(cx - r), int(cy - r), int(r * 2), int(r * 2))

    def _draw_cross(self, p, cx, cy, r, rgb):
        c = self._qcolor(rgb, 255)
        p.setPen(QPen(c, 2))
        p.drawLine(int(cx - r), int(cy - r), int(cx + r), int(cy + r))
        p.drawLine(int(cx - r), int(cy + r), int(cx + r), int(cy - r))

    def _draw_diamond(self, p, cx, cy, r, rgb, alpha=220):
        c = self._qcolor(rgb, alpha)
        p.setPen(QPen(c, 2))
        p.setBrush(Qt.NoBrush)
        p.drawPolygon([
            p.begin_npos() if False else __import__("PyQt5.QtCore", fromlist=["QPoint"]).QPoint(int(cx), int(cy - r)),
            __import__("PyQt5.QtCore", fromlist=["QPoint"]).QPoint(int(cx + r), int(cy)),
            __import__("PyQt5.QtCore", fromlist=["QPoint"]).QPoint(int(cx), int(cy + r)),
            __import__("PyQt5.QtCore", fromlist=["QPoint"]).QPoint(int(cx - r), int(cy)),
        ])

    def _draw_square(self, p, cx, cy, r, rgb, alpha=200):
        c = self._qcolor(rgb, alpha)
        p.setPen(QPen(c, 2))
        p.setBrush(Qt.NoBrush)
        p.drawRect(int(cx - r), int(cy - r), int(r * 2), int(r * 2))


# ============================================================
#  Control panel
# ============================================================
class ControlPanel(QWidget):
    toggled_visibility = pyqtSignal()

    def __init__(self, overlay: Overlay, state: dict):
        super().__init__()
        self.overlay = overlay
        self.state = state
        self.setWindowTitle("bw-external  //  control panel")
        self.setFixedSize(360, 560)
        self.setWindowFlags(Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.Tool)
        self._dragging = False
        self._pos = None
        self._build_ui()

    def _build_ui(self):
        outer = QVBoxLayout()
        outer.setContentsMargins(16, 16, 16, 16)
        outer.setSpacing(8)
        self.setStyleSheet(self._stylesheet())

        title = QLabel("Bedwars External  ::  build 0.1")
        title.setStyleSheet("color:#fff; font-weight:700; font-size:14pt;")
        outer.addWidget(title)

        self.status = QLabel("Status: idle (waiting for Roblox)")
        self.status.setStyleSheet("color:#ffa500;")
        outer.addWidget(self.status)

        # ----- ESP section -----
        outer.addWidget(self._section("ESP"))

        self.cb_esp = QCheckBox("ESP master")
        self.cb_esp.setChecked(True)
        self.cb_esp.stateChanged.connect(self._sync_state)
        outer.addWidget(self.cb_esp)

        for label, attr in [
            ("Player box",        "show_player_box"),
            ("Player name",       "show_player_name"),
            ("Player health bar", "show_player_health"),
            ("Player distance",   "show_player_distance"),
            ("Snaplines",         "show_snaplines"),
            ("Beds",              "show_beds"),
            ("Generators",        "show_generators"),
            ("Items",             "show_items"),
        ]:
            cb = QCheckBox(label)
            cb.setChecked(getattr(self.overlay, attr))
            cb.stateChanged.connect(lambda _s, a=attr: setattr(self.overlay, a, bool(_s)))
            outer.addWidget(cb)

        # ----- Combat -----
        outer.addWidget(self._section("Combat"))
        self.cb_trigger = QCheckBox("Triggerbot (auto-fire on enemy)")
        self.cb_trigger.setChecked(False)
        outer.addWidget(self.cb_trigger)

        self.cb_aimbot = QCheckBox("Aimbot (colorbot ROI)")
        self.cb_aimbot.setChecked(False)
        outer.addWidget(self.cb_aimbot)

        # ----- Movement -----
        outer.addWidget(self._section("Movement"))
        speed_row = QHBoxLayout()
        self.lbl_speed = QLabel(f"Walk speed: {self.state['walkspeed']:.0f}")
        speed_row.addWidget(self.lbl_speed)
        self.slider_speed = QSlider(Qt.Horizontal)
        self.slider_speed.setMinimum(16)
        self.slider_speed.setMaximum(200)
        self.slider_speed.setValue(int(self.state["walkspeed"]))
        self.slider_speed.valueChanged.connect(self._on_speed_change)
        speed_row.addWidget(self.slider_speed, 1)
        outer.addLayout(speed_row)

        self.cb_fly = QCheckBox("Fly hack (loop JumpPower / CanCollide)")
        self.cb_fly.setChecked(False)
        outer.addWidget(self.cb_fly)

        self.cb_antiafk = QCheckBox("Anti-AFK")
        self.cb_antiafk.setChecked(False)
        outer.addWidget(self.cb_antiafk)

        # ----- Hotkey info -----
        outer.addWidget(self._section("Hotkeys"))
        outer.addWidget(QLabel("INSERT  show/hide panel"))
        outer.addWidget(QLabel("END      clean exit"))
        outer.addWidget(QLabel("X        toggle triggerbot hold"))

        # Exit
        self.btn_exit = QPushButton("Exit (END)")
        self.btn_exit.setStyleSheet("background:#d13438; color:white; font-weight:700; padding:8px;")
        self.btn_exit.clicked.connect(self.close)
        outer.addWidget(self.btn_exit)

        self.setLayout(outer)

    def _section(self, text: str) -> QLabel:
        lbl = QLabel(f"— {text} —")
        lbl.setStyleSheet("color:#7aa2ff; font-weight:700; margin-top:8px;")
        lbl.setAlignment(Qt.AlignCenter)
        return lbl

    def _on_speed_change(self, value: int):
        self.state["walkspeed"] = float(value)
        self.lbl_speed.setText(f"Walk speed: {value}")

    def _sync_state(self):
        # Master toggle: zero out payload when off.
        if not self.cb_esp.isChecked():
            self.overlay.update_payload(
                {"players": [], "beds": [], "gens": [], "items": []}, None
            )

    def _stylesheet(self):
        return """
        QWidget {
            background:#15171c;
            color:#e6e6e6;
            font-family:'Segoe UI','SF Pro Display','Helvetica Neue',Arial,sans-serif;
            font-size:10pt;
        }
        QCheckBox { spacing:8px; padding:2px; }
        QCheckBox::indicator {
            width:16px; height:16px; border-radius:3px;
            border:2px solid #3a3f4b; background:#1f222a;
        }
        QCheckBox::indicator:checked { background:#3a86ff; border-color:#3a86ff; }
        QSlider::groove:horizontal { height:4px; background:#2a2e36; border-radius:2px; }
        QSlider::handle:horizontal {
            background:#3a86ff; width:14px; height:14px; margin:-6px 0; border-radius:7px;
        }
        QLabel { padding:2px; }
        """

    # drag to move
    def mousePressEvent(self, e):
        if e.button() == Qt.LeftButton:
            self._dragging = True
            self._pos = e.globalPos() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, e):
        if self._dragging:
            self.move(e.globalPos() - self._pos)

    def mouseReleaseEvent(self, e):
        if e.button() == Qt.LeftButton:
            self._dragging = False

    def keyPressEvent(self, e):
        if e.key() == Qt.Key_Insert:
            self.toggled_visibility.emit()


# ============================================================
#  App
# ============================================================
class App:
    def __init__(self):
        self.memory = Memory()
        self.bedwars = Bedwars(self.memory)
        self.state = {
            "walkspeed": 16.0,
            "triggerbot": False,
            "aimbot": False,
            "fly": False,
            "antiafk": False,
        }

        self.app = QApplication.instance() or QApplication(sys.argv)
        self.overlay = Overlay()
        self.overlay.show()
        self.panel = ControlPanel(self.overlay, self.state)
        self.panel.toggled_visibility.connect(self.toggle_panel)
        self.panel.show()

        self._register_hotkeys()

        self.timer = QTimer()
        self.timer.timeout.connect(self._tick)
        self.timer.start(60)  # ~16 Hz

        self._last_afk = 0.0
        self._fly_loop_running = False

    # ----- hotkeys -----
    def _register_hotkeys(self):
        try:
            keyboard.add_hotkey("insert", lambda: self.panel.toggled_visibility.emit())
        except Exception:
            pass
        try:
            keyboard.add_hotkey("end", self._quit)
        except Exception:
            pass
        try:
            keyboard.add_hotkey("x", lambda: self.panel.cb_trigger.toggle())
        except Exception:
            pass
        try:
            keyboard.add_hotkey("f", lambda: self.panel.cb_fly.toggle())
        except Exception:
            pass

    def toggle_panel(self):
        if self.panel.isVisible():
            self.panel.hide()
        else:
            self.panel.show()
            self.panel.raise_()
            self.panel.activateWindow()

    # ----- main loop tick -----
    def _tick(self):
        # Try (re)attach to Roblox.
        if not self.memory.is_open():
            ok = self.memory.attach()
            if ok:
                self.panel.status.setText("Status: attached")
                self.panel.status.setStyleSheet("color:#7CFF7C;")
            else:
                self.panel.status.setText("Status: waiting for RobloxPlayerBeta.exe …")
                self.panel.status.setStyleSheet("color:#ffa500;")
                return

        dm = self.memory.get_dm()
        ve = self.memory.get_visual()
        if not dm or not ve:
            return

        snap = self.bedwars.snapshot(dm)

        # Movement: walkspeed (only if not flying — flying overwrites it)
        if not self.state["fly"] and snap.local_player and snap.local_player.humanoid.address:
            try:
                snap.local_player.humanoid.set_walkspeed(self.state["walkspeed"])
            except Exception:
                pass

        # Fly: simple version — keep walk fast and toggle CanCollide false each frame
        if self.state["fly"] and snap.local_player and snap.local_player.root.address:
            try:
                snap.local_player.humanoid.set_walkspeed(120.0)
                # bounce jump so the player ascends; this is the cheap "fly"
                jp = snap.local_player.humanoid.get_jumppower()
                if jp < 0:
                    snap.local_player.humanoid.set_jumppower(50.0)
            except Exception:
                pass

        # Anti-AFK: tiny mouse nudge every 60s
        if self.state["antiafk"] and time.time() - self._last_afk > 60:
            try:
                pyautogui.moveRel(1, 0)
                pyautogui.moveRel(-1, 0)
            except Exception:
                pass
            self._last_afk = time.time()

        # Project to screen
        matrix = self.memory.utils.get_matrix(ve)
        dims = self.memory.utils.get_dims(ve)
        local_pos = snap.local_player.position if snap.local_player else None
        payload = project_snapshot(snap, self.memory.utils, matrix, dims, local_pos)

        # Triggerbot
        if self.state["triggerbot"] and payload["players"]:
            self._do_triggerbot(payload)

        # Aimbot (colorbot) — only if enabled, runs in background thread
        if self.state["aimbot"] and payload["players"]:
            self._do_aimbot(payload)

        # Push to overlay
        self.overlay.update_payload(payload, local_pos)

    def _do_triggerbot(self, payload: dict):
        # Fire if any ENEMY player's screen position is within radius of crosshair.
        cx, cy = self.width_ / 2.0, self.height_ / 2.0
        for pl in payload["players"]:
            if pl["is_local"] or not pl["alive"]:
                continue
            sx, sy = pl["screen"].x, pl["screen"].y
            d = ((sx - cx) ** 2 + (sy - cy) ** 2) ** 0.5
            if d < 60:
                try:
                    mouse.click("left")
                except Exception:
                    pass
                return

    def _do_aimbot(self, payload: dict):
        # Colorbot: scan a small ROI around the screen center for an enemy
        # color and move the mouse toward the closest match. Cheap, external,
        # pixel-only. Not pixel-perfect — but matches the "AI colorbot" pattern.
        try:
            import numpy as np
            from mss import mss
        except Exception:
            return  # numpy/mss not installed
        roi = 90
        cx, cy = self.width_ / 2.0, self.height_ / 2.0
        with mss() as sct:
            img = np.array(sct.grab({
                "left": int(max(0, cx - roi)),
                "top":  int(max(0, cy - roi)),
                "width": roi * 2, "height": roi * 2,
            }))
        bgr = img[:, :, :3]
        # target color: bright red (enemy hit)
        target = np.array([60, 60, 220])
        diff = np.linalg.norm(bgr.astype(int) - target, axis=2)
        ys, xs = np.where(diff < 35)
        if len(xs) == 0:
            return
        # closest to center
        d2 = (xs - roi) ** 2 + (ys - roi) ** 2
        i = int(d2.argmin())
        dx, dy = int(xs[i] - roi), int(ys[i] - roi)
        # smooth: only nudge a fraction per tick
        try:
            mouse.move(int(cx + dx * 0.4), int(cy + dy * 0.4), absolute=True)
        except Exception:
            pass

    def _quit(self):
        try:
            keyboard.unhook_all_hotkeys()
        except Exception:
            pass
        self.app.quit()


# ============================================================
#  Entry
# ============================================================
if __name__ == "__main__":
    app = App()
    sys.exit(app.app.exec_())
