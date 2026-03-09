---
wave: 2
depends_on:
  - 01-PLAN-foundation.md
  - 02-PLAN-enemies-and-waves.md
files_modified:
  - res://scenes/camera/CameraRig.tscn
  - res://scripts/controllers/CameraRig.gd
  - res://scenes/hud/HUD.tscn
  - res://scenes/hud/TopBar.tscn
  - res://scenes/hud/BottomPanel.tscn
  - res://scenes/hud/SendWaveButton.tscn
autonomous: true
---

# Plan 4: Camera and HUD

**Phase:** 1 — The Maze Works
**Wave:** 2
**Requirements:** UI-02, WAVE-01, WAVE-02

## Objective

This plan builds the camera rig and the full HUD. The CameraRig implements all navigation behaviors specified in CONTEXT.md and RESEARCH.md: 60° default tilt, three smooth-animated zoom levels, WASD and click-drag pan with hard map-edge boundaries, a quick-reset key, and click-to-follow targeting for enemies and towers. The HUD implements the top bar (lives, wave counter, timer), the bottom panel (single tower selection button for Phase 1), and the Send Wave button that connects to WaveController and supports Spacebar. The tower range overlay stub (UI-02) is implemented as a zero-radius ring MeshInstance3D that toggles on tower selection. This plan depends on Plans 01 and 02 for the map size constants (grid dimensions from MapDefinition) and WaveController signals.

## Tasks

```xml
<task id="1-04-01" name="Create CameraRig Scene and Controller">
<objective>Build the three-node camera hierarchy (CameraRig → CameraPivot → Camera3D) and implement all navigation behaviors: 60° default tilt, three zoom levels with Tween transitions, WASD/edge-scroll/click-drag pan, hard map-edge clamping, quick reset, and click-to-follow target lock.</objective>
<files>
  <create>res://scenes/camera/CameraRig.tscn</create>
  <create>res://scripts/controllers/CameraRig.gd</create>
</files>
<implementation>
1. Create `res://scenes/camera/CameraRig.tscn`:
   - Root node: `Node3D` named `CameraRig`. Attach `res://scripts/controllers/CameraRig.gd`.
   - Child node: `Node3D` named `CameraPivot`.
   - Child of CameraPivot: `Camera3D` named `Camera3D`.
   - Set Camera3D `fov = 60.0`.
   - Set Camera3D `near = 0.1`, `far = 500.0`.
   - Initial position of CameraRig: `Vector3(20.0, 0.0, 20.0)` — center of the 20×20 grid (40×40 world units).
   - Initial rotation of CameraPivot: `rotation_degrees = Vector3(-60.0, 0.0, 0.0)` — 60° from vertical per CONTEXT.md and RESEARCH.md.
   - Initial position of Camera3D: `Vector3(0.0, 0.0, 30.0)` — 30 units back along the pivot's local Z axis (Standard zoom level).
   - Save as CameraRig.tscn.

2. Create `res://scripts/controllers/CameraRig.gd`:
   - `extends Node3D`.
   - Constants:
     ```gdscript
     const ZOOM_DISTANCES = [50.0, 30.0, 12.0]  # Overview, Standard, Detail (Claude's discretion per RESEARCH.md)
     const ZOOM_TWEEN_DURATION = 0.3
     const TILT_DEFAULT_DEGREES = -60.0
     const TILT_MIN_DEGREES = -80.0   # Near top-down
     const TILT_MAX_DEGREES = -45.0   # Maximum 3D tilt (always reads as 3D)
     const PAN_SPEED_KEYBOARD = 15.0  # World units per second
     const PAN_SPEED_EDGE = 12.0
     const EDGE_SCROLL_MARGIN = 40.0  # Pixels from screen edge
     const DRAG_SENSITIVITY = 0.015   # World units per pixel
     ```
   - `@export var map_width_units: float = 40.0` — set to grid_width × CELL_SIZE (20 × 2.0). Assign in Inspector or compute from GridManager in _ready.
   - `@export var map_height_units: float = 40.0`.

3. Variables:
   ```gdscript
   @onready var _pivot: Node3D = $CameraPivot
   @onready var _camera: Camera3D = $CameraPivot/Camera3D
   var _zoom_level: int = 1       # 0=Overview, 1=Standard, 2=Detail
   var _is_dragging: bool = false
   var _drag_start_mouse: Vector2
   var _drag_start_rig_pos: Vector3
   var _follow_target: Node3D = null  # click-to-follow target
   var _active_zoom_tween: Tween = null
   ```

4. Implement `func _ready() -> void`:
   - If GridManager is available: `map_width_units = GridManager.grid_width * GridManager.CELL_SIZE`, same for height.
   - Set initial position to map center: `global_position = Vector3(map_width_units * 0.5, 0.0, map_height_units * 0.5)`.
   - Set initial camera zoom distance: `_camera.position.z = ZOOM_DISTANCES[_zoom_level]`.
   - Set initial tilt: `_pivot.rotation_degrees.x = TILT_DEFAULT_DEGREES`.

5. Implement `func _process(delta: float) -> void`:
   - Follow target lock (click-to-follow):
     ```gdscript
     if _follow_target != null and is_instance_valid(_follow_target):
         var target_xz = Vector3(_follow_target.global_position.x, 0, _follow_target.global_position.z)
         global_position = target_xz
         _clamp_to_map_bounds()
         return  # Skip pan input while following
     ```
   - WASD pan:
     ```gdscript
     var pan_dir = Vector3.ZERO
     if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    pan_dir.z -= 1.0
     if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  pan_dir.z += 1.0
     if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  pan_dir.x -= 1.0
     if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): pan_dir.x += 1.0
     ```
   - Edge-scroll pan (check mouse position vs viewport edges):
     ```gdscript
     var mouse_pos = get_viewport().get_mouse_position()
     var vp_size = get_viewport().get_visible_rect().size
     if mouse_pos.x < EDGE_SCROLL_MARGIN:     pan_dir.x -= 1.0
     if mouse_pos.x > vp_size.x - EDGE_SCROLL_MARGIN: pan_dir.x += 1.0
     if mouse_pos.y < EDGE_SCROLL_MARGIN:     pan_dir.z -= 1.0
     if mouse_pos.y > vp_size.y - EDGE_SCROLL_MARGIN: pan_dir.z += 1.0
     ```
   - Apply pan:
     ```gdscript
     if pan_dir != Vector3.ZERO:
         global_position += pan_dir.normalized() * PAN_SPEED_KEYBOARD * delta
         _clamp_to_map_bounds()
     ```

6. Implement `func _input(event: InputEvent) -> void`:
   - Mouse wheel zoom:
     ```gdscript
     if event is InputEventMouseButton:
         if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
             _set_zoom(_zoom_level - 1)
         elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
             _set_zoom(_zoom_level + 1)
         elif event.button_index == MOUSE_BUTTON_MIDDLE:
             _is_dragging = event.pressed
             if _is_dragging:
                 _drag_start_mouse = event.position
                 _drag_start_rig_pos = global_position
         elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
             _handle_left_click(event.position)
     ```
   - Drag pan:
     ```gdscript
     if event is InputEventMouseMotion and _is_dragging:
         var delta_mouse = event.position - _drag_start_mouse
         var pan_offset = Vector3(-delta_mouse.x, 0, -delta_mouse.y) * DRAG_SENSITIVITY * ZOOM_DISTANCES[_zoom_level]
         global_position = _drag_start_rig_pos + pan_offset
         _clamp_to_map_bounds()
     ```
   - Quick reset (R key or Home key):
     ```gdscript
     if event is InputEventKey and event.pressed:
         if event.keycode == KEY_R or event.keycode == KEY_HOME:
             _reset_camera()
         if event.keycode == KEY_ESCAPE:
             _follow_target = null  # Clear follow lock on Escape
     ```

7. Implement `func _set_zoom(level: int) -> void`:
   - Clamp: `level = clamp(level, 0, ZOOM_DISTANCES.size() - 1)`.
   - If `level == _zoom_level`: return.
   - `_zoom_level = level`.
   - If `_active_zoom_tween` is valid, kill it.
   - `_active_zoom_tween = create_tween()`.
   - `_active_zoom_tween.tween_property(_camera, "position:z", ZOOM_DISTANCES[level], ZOOM_TWEEN_DURATION)`.

8. Implement `func _clamp_to_map_bounds() -> void`:
   - `global_position.x = clamp(global_position.x, 0.0, map_width_units)`.
   - `global_position.z = clamp(global_position.z, 0.0, map_height_units)`.
   - `global_position.y = 0.0` — rig stays on XZ plane.

9. Implement `func _reset_camera() -> void`:
   - Tween rig position back to map center:
     ```gdscript
     var t = create_tween().set_parallel(true)
     t.tween_property(self, "global_position",
         Vector3(map_width_units * 0.5, 0.0, map_height_units * 0.5), 0.4)
     t.tween_property(_pivot, "rotation_degrees:x", TILT_DEFAULT_DEGREES, 0.4)
     ```
   - Reset zoom to Standard: `_set_zoom(1)`.
   - Clear follow target: `_follow_target = null`.

10. Implement `func _handle_left_click(screen_pos: Vector2) -> void`:
    - Perform a physics raycast from camera at screen_pos:
      ```gdscript
      var space_state = get_world_3d().direct_space_state
      var from = _camera.project_ray_origin(screen_pos)
      var to = from + _camera.project_ray_normal(screen_pos) * 1000.0
      var query = PhysicsRayQueryParameters3D.create(from, to)
      var result = space_state.intersect_ray(query)
      if result and result.collider is Node3D:
          _follow_target = result.collider
      else:
          _follow_target = null
      ```
    - Note: Enemies in Phase 1 use MultiMeshInstance3D which does not have per-instance colliders. Follow-targeting enemies will be limited to clicking the MultiMeshInstance3D parent node (which follows the rig to the average enemy position — this is an acceptable Phase 1 limitation). Tower nodes (Node3D with MeshInstance3D) can be clicked since they are individual scene nodes. Full per-enemy follow requires per-enemy Area3D nodes (Phase 2 enhancement).

11. Implement `func get_camera() -> Camera3D`: return `_camera`. (Used by TowerPlacer to project rays.)
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-04-02" name="Create HUD TopBar Scene">
<objective>Build the top-bar HUD element showing lives remaining, current wave / total waves, a gold display (showing "—" in Phase 1), and the wave timer countdown (TIMED mode) or "READY" indicator (PLAYER_TRIGGERED mode). This HUD element connects to GameState and WaveController signals.</objective>
<files>
  <create>res://scenes/hud/TopBar.tscn</create>
</files>
<implementation>
1. Create `res://scenes/hud/TopBar.tscn`:
   - Root node: `PanelContainer` named `TopBar`.
   - Set anchors to top-full-rect: `anchor_left=0, anchor_right=1, anchor_top=0, anchor_bottom=0`.
   - Set `offset_bottom = 50`.
   - Style: Add a `StyleBoxFlat` on the panel: `bg_color = Color(0.05, 0.05, 0.1, 0.85)` (dark near-black with slight blue, semi-transparent).
   - Add child `HBoxContainer` named `Bar`. Set `alignment = BoxContainer.ALIGNMENT_CENTER`. Set `separation = 40`.
   - Inside Bar, add the following `Label` nodes (all with same font size ~18px, white color):
     a. `Label` named `LivesLabel`: default text `"❤ 20"`.
     b. `Label` named `WaveLabel`: default text `"Wave 1 / 5"`.
     c. `Label` named `GoldLabel`: default text `"Gold: —"`.
     d. `Label` named `TimerLabel`: default text `"Next: 15s"`.
   - Attach script `TopBar.gd`:
     ```gdscript
     extends PanelContainer

     @onready var _lives_label: Label = $Bar/LivesLabel
     @onready var _wave_label: Label = $Bar/WaveLabel
     @onready var _gold_label: Label = $Bar/GoldLabel
     @onready var _timer_label: Label = $Bar/TimerLabel

     func _ready() -> void:
         GameState.lives_changed.connect(_on_lives_changed)
         # WaveController signals are connected by Game.tscn after assembly

     func update_wave(current: int, total: int) -> void:
         _wave_label.text = "Wave %d / %d" % [current, total]

     func update_timer(time_remaining: float, wave_mode: GameState.WaveMode) -> void:
         if wave_mode == GameState.WaveMode.TIMED:
             _timer_label.text = "Next: %ds" % int(ceil(time_remaining))
         else:
             if time_remaining > 0:
                 _timer_label.text = "Ready (%ds)" % int(ceil(time_remaining))
             else:
                 _timer_label.text = "READY"

     func _on_lives_changed(new_lives: int) -> void:
         _lives_label.text = "❤ %d" % new_lives
     ```
   - Save as TopBar.tscn.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-04-03" name="Create HUD BottomPanel, SendWaveButton, and Range Overlay Stub">
<objective>Build the bottom panel tower selection HUD (single tower button for Phase 1), the Send Wave button (visible in PLAYER_TRIGGERED mode, triggers WaveController.send_wave() or Spacebar), and the tower range overlay stub MeshInstance3D (UI-02 infrastructure for Phase 2).</objective>
<files>
  <create>res://scenes/hud/BottomPanel.tscn</create>
  <create>res://scenes/hud/SendWaveButton.tscn</create>
</files>
<implementation>
1. Create `res://scenes/hud/BottomPanel.tscn`:
   - Root node: `PanelContainer` named `BottomPanel`.
   - Anchors: bottom-full-rect. `offset_top = -80`.
   - Style: `StyleBoxFlat`, `bg_color = Color(0.05, 0.05, 0.1, 0.85)`.
   - Child `HBoxContainer` named `TowerButtons`. `alignment = BoxContainer.ALIGNMENT_CENTER`.
   - Inside TowerButtons, add one `Button` named `WallTowerButton`:
     - `text = "Wall Tower [1]"`.
     - `tooltip_text = "Place a wall to block enemy movement"`.
   - Attach script `BottomPanel.gd`:
     ```gdscript
     extends PanelContainer

     signal tower_selected(tower_type_id: String)

     @onready var _wall_btn: Button = $TowerButtons/WallTowerButton

     func _ready() -> void:
         _wall_btn.pressed.connect(func(): emit_signal("tower_selected", "wall"))

     func _input(event: InputEvent) -> void:
         if event is InputEventKey and event.pressed and not event.echo:
             if event.keycode == KEY_1:
                 emit_signal("tower_selected", "wall")
     ```
   - Save as BottomPanel.tscn.

2. Create `res://scenes/hud/SendWaveButton.tscn`:
   - Root node: `Button` named `SendWaveButton`.
   - `text = "Send Wave\n[SPACE]"`.
   - Position: right side of screen, vertically centered. Anchors: right-center. Set `offset_left = -180`, `offset_top = -40`, `offset_right = -20`, `offset_bottom = 40`.
   - Style: Add a `StyleBoxFlat` for normal state: `bg_color = Color(0.8, 0.5, 0.05)` (amber/orange — prominent per CONTEXT.md).
   - `custom_minimum_size = Vector2(160, 80)`.
   - Attach script `SendWaveButton.gd`:
     ```gdscript
     extends Button

     # Assigned by Game.tscn after assembly
     var _wave_controller: Node = null

     func _ready() -> void:
         pressed.connect(_on_pressed)
         visible = false  # Hidden by default; shown only in PLAYER_TRIGGERED mode

     func setup(wave_controller: Node, wave_mode: GameState.WaveMode) -> void:
         _wave_controller = wave_controller
         visible = (wave_mode == GameState.WaveMode.PLAYER_TRIGGERED)

     func _on_pressed() -> void:
         if _wave_controller != null:
             _wave_controller.send_wave()

     func _input(event: InputEvent) -> void:
         if not visible: return
         if event is InputEventKey and event.pressed and not event.echo:
             if event.keycode == KEY_SPACE:
                 _on_pressed()
                 get_viewport().set_input_as_handled()
     ```
   - Save as SendWaveButton.tscn.

3. Tower Range Overlay stub (UI-02 — add to TowerPlacer.tscn, not a separate scene):
   - Open `res://scenes/game/TowerPlacer.tscn`.
   - Add a child `MeshInstance3D` named `RangeOverlay` to the root node.
   - Set mesh: `TorusMesh` with `inner_radius = 0.0`, `outer_radius = 0.01` (effectively invisible — range = 0 in Phase 1).
   - Create `StandardMaterial3D`: `albedo_color = Color(1.0, 1.0, 0.0, 0.3)`, `transparency = TRANSPARENCY_ALPHA`.
   - Set `RangeOverlay.visible = false`.
   - In TowerPlacer.gd, add:
     ```gdscript
     @onready var _range_overlay: MeshInstance3D = $RangeOverlay

     func _on_tower_type_selected(_tower_type_id: String) -> void:
         # Show range overlay at ghost position during placement mode
         _range_overlay.visible = _is_placement_mode
         _range_overlay.global_position = _ghost.global_position
     ```
   - Also update `_update_hover` to move `_range_overlay.global_position = _ghost.global_position` while in placement mode.
   - Connect BottomPanel's `tower_selected` signal to `_on_tower_type_selected` in Game.tscn (Plan 05).
   - Save TowerPlacer.tscn.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-04-04" name="Assemble HUD.tscn Root CanvasLayer">
<objective>Combine TopBar, BottomPanel, SendWaveButton, and ToastNotification into the HUD.tscn root CanvasLayer. Wire WaveController signal connections so the timer display and Send Wave button visibility are driven by live game state.</objective>
<files>
  <create>res://scenes/hud/HUD.tscn</create>
</files>
<implementation>
1. Create `res://scenes/hud/HUD.tscn`:
   - Root node: `CanvasLayer` named `HUD`. Set `layer = 1`.
   - Instantiate and add as children (using "Instance Child Scene"):
     - `TopBar` (from TopBar.tscn)
     - `BottomPanel` (from BottomPanel.tscn)
     - `SendWaveButton` (from SendWaveButton.tscn)
     - `ToastNotification` (from ToastNotification.tscn)
   - Attach script `HUD.gd`:
     ```gdscript
     extends CanvasLayer

     @onready var top_bar = $TopBar
     @onready var send_wave_btn = $SendWaveButton
     @onready var toast = $ToastNotification

     # Called by Game.tscn after WaveController is available
     func setup(wave_controller: Node, total_waves: int) -> void:
         send_wave_btn.setup(wave_controller, GameState.wave_mode)
         top_bar.update_wave(1, total_waves)
         wave_controller.wave_started.connect(func(wn): top_bar.update_wave(wn, total_waves))
         wave_controller.inter_wave_tick.connect(
             func(t): top_bar.update_timer(t, GameState.wave_mode))

     func show_path_blocked_toast() -> void:
         toast.show_message()
     ```
   - Save as HUD.tscn.

2. Connect GameState.lives_changed in TopBar (already done in TopBar.gd._ready via autoload signal — no additional wiring needed here).

3. Verify Send Wave button visibility logic:
   - TIMED mode: `SendWaveButton.visible = false` (hidden — wave launches automatically).
   - PLAYER_TRIGGERED mode: `SendWaveButton.visible = true`.
   - The `setup()` call in HUD.gd passes the current `GameState.wave_mode` to `SendWaveButton.setup()`.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>
```

## must_haves

- [ ] CameraRig.tscn has the three-node hierarchy: CameraRig (Node3D) → CameraPivot (Node3D) → Camera3D
- [ ] Default tilt is -60° on CameraPivot.rotation_degrees.x (reads as 3D as specified in CONTEXT.md)
- [ ] Zoom transitions use a Tween (smooth animation, not instant snap) — verified by examining the _set_zoom() function
- [ ] Hard boundary: CameraRig position is clamped to map bounds on every pan update
- [ ] Quick reset (R or Home key) tweens back to map center and resets tilt and zoom level to Standard
- [ ] SendWaveButton is hidden when GameState.wave_mode == TIMED and visible when PLAYER_TRIGGERED
- [ ] SendWaveButton responds to Spacebar (InputEventKey KEY_SPACE) in addition to mouse click
- [ ] TopBar LivesLabel updates when GameState.lives_changed signal fires
- [ ] TopBar TimerLabel shows countdown seconds in TIMED mode and "READY" in PLAYER_TRIGGERED mode when timer reaches 0
- [ ] RangeOverlay MeshInstance3D exists in TowerPlacer.tscn and toggles visible on tower type selection
- [ ] ToastNotification is a child of HUD.tscn and is accessible via HUD.show_path_blocked_toast()

## verification

Run the full test suite (no new automated tests in this plan — camera and HUD are validated manually):
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Expected: same result as after Plan 03 — 14 passing, 8 pending, 0 failed.

Manual checks (run after Game.tscn is assembled in Plan 05):
1. Play the game scene. Move the camera with WASD. Confirm movement stops at map edges.
2. Scroll the mouse wheel. Confirm smooth zoom transition (not snap).
3. Press R. Confirm camera smoothly returns to map center at Standard zoom.
4. Middle-click-drag. Confirm the view pans smoothly.
5. Set GameState.wave_mode = PLAYER_TRIGGERED in the script before running. Confirm Send Wave button is visible. Press Spacebar — confirm WaveController.send_wave() is called (add a temporary debug print).
6. Set wave_mode = TIMED. Confirm Send Wave button is invisible. Confirm timer countdown appears in the top bar.
7. Select the Wall Tower button. Confirm RangeOverlay becomes visible (even though it's tiny/invisible due to radius=0).
