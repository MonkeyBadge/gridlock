# Plan 04 Summary: Camera and HUD

**Completed:** 2026-03-09
**Status:** DONE — all tasks committed atomically

---

## Tasks Completed

### Task 1-04-01: CameraRig Scene and Controller
- **`scenes/camera/CameraRig.tscn`** — Three-node hierarchy: `CameraRig (Node3D) → CameraPivot (Node3D) → Camera3D`. Default tilt -60° on CameraPivot X axis. Camera3D Z offset = 30.0 (Standard zoom). FOV 60°, near 0.1, far 500.
- **`scripts/controllers/CameraRig.gd`** — Full navigation implementation:
  - Three zoom levels `[50.0, 30.0, 12.0]` with 0.3s Tween transitions.
  - WASD + arrow keys + 40px edge-scroll pan.
  - Middle-click-drag with DRAG_SENSITIVITY = 0.015.
  - Hard map boundary clamping (`_clamp_to_map_bounds()`) on every pan update.
  - R / Home key triggers `_reset_camera()` — tweens position and tilt back to defaults, resets zoom to Standard.
  - Left-click raycast for click-to-follow (`_follow_target`); Escape clears.
  - `get_camera() -> Camera3D` for TowerPlacer ray projection.

### Task 1-04-02: HUD TopBar
- **`scenes/hud/TopBar.tscn`** — PanelContainer anchored top-full-rect, `offset_bottom=50`. Dark semi-transparent StyleBoxFlat. HBoxContainer with four 18px white Labels: LivesLabel, WaveLabel, GoldLabel, TimerLabel.
- **`scripts/hud/TopBar.gd`** — Connects to `GameState.lives_changed` in `_ready`. Exposes `update_wave(current, total)` and `update_timer(time, mode)`. Timer shows `"Next: Xs"` in TIMED mode and `"READY"` / `"Ready (Xs)"` in PLAYER_TRIGGERED mode.

### Task 1-04-03: BottomPanel, SendWaveButton, RangeOverlay Stub
- **`scenes/hud/BottomPanel.tscn`** — PanelContainer anchored bottom-full-rect. Single "Wall Tower [1]" Button. `[1]` hotkey also fires `tower_selected` signal.
- **`scripts/hud/BottomPanel.gd`** — Emits `tower_selected(tower_type_id: String)`.
- **`scenes/hud/SendWaveButton.tscn`** — Button anchored right-center, amber StyleBoxFlat, hidden by default. `setup(wave_controller, wave_mode)` controls visibility.
- **`scripts/hud/SendWaveButton.gd`** — Spacebar shortcut fires `send_wave()` when visible.
- **`scenes/game/TowerPlacer.tscn`** — Added `RangeOverlay` child: `MeshInstance3D` with `TorusMesh` (inner_radius=0, outer_radius=0.01), yellow semi-transparent material, `visible=false`.
- **`scripts/controllers/TowerPlacer.gd`** — Added `@onready var _range_overlay`, `_on_tower_type_selected()` that toggles visibility, and `_update_hover` now syncs `_range_overlay.global_position`.

### Task 1-04-04: HUD.tscn Root CanvasLayer
- **`scenes/hud/HUD.tscn`** — CanvasLayer (layer=1) with four instanced children: TopBar, BottomPanel, SendWaveButton, ToastNotification.
- **`scripts/hud/HUD.gd`** — `setup(wave_controller, total_waves)` wires `wave_started` and `inter_wave_tick` signals. `show_path_blocked_toast()` delegates to ToastNotification.

---

## Files Created / Modified

| File | Action |
|------|--------|
| `scenes/camera/CameraRig.tscn` | Created |
| `scripts/controllers/CameraRig.gd` | Created |
| `scenes/hud/TopBar.tscn` | Created |
| `scripts/hud/TopBar.gd` | Created |
| `scenes/hud/BottomPanel.tscn` | Created |
| `scripts/hud/BottomPanel.gd` | Created |
| `scenes/hud/SendWaveButton.tscn` | Created |
| `scripts/hud/SendWaveButton.gd` | Created |
| `scenes/hud/HUD.tscn` | Created |
| `scripts/hud/HUD.gd` | Created |
| `scenes/game/TowerPlacer.tscn` | Modified — added RangeOverlay child |
| `scripts/controllers/TowerPlacer.gd` | Modified — added _range_overlay, _on_tower_type_selected |

---

## Must-Have Verification

- [x] CameraRig.tscn has the three-node hierarchy
- [x] Default tilt is -60° on CameraPivot.rotation_degrees.x
- [x] Zoom transitions use Tween (0.3s duration)
- [x] Hard boundary: clamped to map bounds on every pan update
- [x] Quick reset (R or Home) tweens to map center, resets tilt and zoom
- [x] SendWaveButton hidden in TIMED mode, visible in PLAYER_TRIGGERED
- [x] SendWaveButton responds to Spacebar
- [x] TopBar LivesLabel updates on GameState.lives_changed
- [x] TopBar TimerLabel shows countdown / READY per wave mode
- [x] RangeOverlay MeshInstance3D in TowerPlacer.tscn, toggles on tower selection
- [x] ToastNotification is a child of HUD.tscn and accessible via show_path_blocked_toast()

---

## Integration Notes for Plan 05 (Game.tscn Assembly)

- Call `HUD.setup(wave_controller_node, wave_definitions.size())` after WaveController is ready.
- Connect `BottomPanel.tower_selected` signal to `TowerPlacer._on_tower_type_selected` in Game.tscn.
- Connect `TowerPlacer` rejection path to `HUD.show_path_blocked_toast()`.
- Add `CameraRig` to the scene and pass `camera_rig.get_camera()` to `TowerPlacer.camera` export.
