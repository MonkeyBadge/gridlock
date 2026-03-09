---
wave: 3
depends_on:
  - 03-PLAN-tower-placement.md
  - 04-PLAN-camera-and-hud.md
files_modified:
  - res://scenes/game/Game.tscn
  - res://scenes/game/PathOverlay.tscn
  - res://shaders/path_arrow.gdshader
  - res://scripts/controllers/PathOverlay.gd
  - res://tests/test_wave_controller.gd
  - res://tests/test_enemy_manager.gd
autonomous: true
---

# Plan 5: Path Visualization and Integration

**Phase:** 1 — The Maze Works
**Wave:** 3
**Requirements:** UI-01, STEAM-04

## Objective

This final plan wires every system built in Plans 01–04 into a single playable Game.tscn, implements the animated path visualization overlay (glowing directional arrows updating in real time as towers are placed — UI-01), completes the remaining test stubs for wave and enemy tests, and establishes the end-to-end performance baseline required by STEAM-04. After this plan completes, a player can launch the game, place towers on a 20×20 grid, watch enemies flow through the maze, manage waves in either Timed or Player-Triggered mode, and observe lives deducting as enemies reach the exit. No combat yet — this is the complete Phase 1 foundation.

## Tasks

```xml
<task id="1-05-01" name="Create PathOverlay Scene and Shader">
<objective>Build the path visualization overlay: a flat quad mesh covering the grid with a custom ShaderMaterial that reads a per-cell direction texture and renders animated glowing arrows pointing toward the exit. Satisfies UI-01.</objective>
<files>
  <create>res://scenes/game/PathOverlay.tscn</create>
  <create>res://shaders/path_arrow.gdshader</create>
  <create>res://scripts/controllers/PathOverlay.gd</create>
</files>
<implementation>
1. Create `res://shaders/path_arrow.gdshader`:
   Write the following shader code:
   ```glsl
   shader_type spatial;
   render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

   uniform sampler2D direction_texture : hint_default_black, filter_nearest;
   uniform int grid_width = 20;
   uniform int grid_height = 20;
   uniform float time_offset = 0.0;  // Passed from PathOverlay.gd each frame
   uniform float arrow_brightness = 0.6;

   // Draw an arrow shape in local cell UV [0,1]^2 pointing in direction dir_norm.
   // Returns alpha value for the arrow glyph.
   float arrow_alpha(vec2 cell_uv, vec2 dir_norm) {
       // Center the cell UV
       vec2 uv = cell_uv - vec2(0.5);
       // Project onto direction and perpendicular
       float fwd = dot(uv, dir_norm);
       float side = abs(dot(uv, vec2(-dir_norm.y, dir_norm.x)));
       // Animated scroll: shift the fwd coordinate over time
       float anim_fwd = fract(fwd + time_offset);
       // Arrow body: thin rectangle
       float body = step(side, 0.08) * step(0.05, anim_fwd) * step(anim_fwd, 0.55);
       // Arrow head: triangle
       float head = step(side, 0.22 * (0.72 - anim_fwd)) * step(0.55, anim_fwd) * step(anim_fwd, 0.75);
       return clamp(body + head, 0.0, 1.0);
   }

   void fragment() {
       // Determine which grid cell this fragment belongs to
       vec2 grid_uv = UV * vec2(float(grid_width), float(grid_height));
       ivec2 cell = ivec2(int(grid_uv.x), int(grid_uv.y));
       vec2 cell_local_uv = fract(grid_uv);

       // Sample direction texture (encoded as RG = direction.x, direction.y, remapped from [-1,1] to [0,1])
       vec4 dir_sample = texelFetch(direction_texture, cell, 0);
       vec2 dir = dir_sample.rg * 2.0 - vec2(1.0);  // Remap [0,1] -> [-1,1]

       // If direction is zero (exit cell or unreachable), no arrow
       float dir_len = length(dir);
       if (dir_len < 0.1) {
           ALBEDO = vec3(0.0);
           ALPHA = 0.0;
           return;
       }

       vec2 dir_norm = dir / dir_len;
       float alpha = arrow_alpha(cell_local_uv, dir_norm);

       // Glow color: teal/cyan (Claude's discretion — CONTEXT.md leaves this to implementation)
       ALBEDO = vec3(0.1, 0.9, 0.8) * arrow_brightness;
       ALPHA = alpha * 0.85;
   }
   ```

2. Create `res://scripts/controllers/PathOverlay.gd`:
   ```gdscript
   extends Node3D

   @onready var _mesh: MeshInstance3D = $Mesh
   var _direction_texture: ImageTexture = null
   var _elapsed: float = 0.0

   func _ready() -> void:
       FlowFieldManager.flow_field_updated.connect(_on_flow_field_updated)
       # If flow field already computed, build texture immediately
       if FlowFieldManager.current_version > 0:
           _rebuild_texture()

   func _process(delta: float) -> void:
       if not visible or _direction_texture == null:
           return
       _elapsed += delta
       # Pass animated time offset to shader — creates flowing arrow effect
       var mat: ShaderMaterial = _mesh.material_override
       if mat:
           mat.set_shader_parameter("time_offset", fmod(_elapsed * 0.8, 1.0))

   func _on_flow_field_updated(_version: int) -> void:
       _rebuild_texture()

   func _rebuild_texture() -> void:
       var w = GridManager.grid_width
       var h = GridManager.grid_height
       var img = Image.create(w, h, false, Image.FORMAT_RGF)
       for y in range(h):
           for x in range(w):
               var dir: Vector2i = FlowFieldManager.get_direction(Vector2i(x, y))
               # Encode direction.x and direction.y in RG channels, remapped [−1,1] -> [0,1]
               var r = (float(dir.x) + 1.0) * 0.5
               var g = (float(dir.y) + 1.0) * 0.5
               img.set_pixel(x, y, Color(r, g, 0.0, 1.0))
       if _direction_texture == null:
           _direction_texture = ImageTexture.create_from_image(img)
       else:
           _direction_texture.update(img)
       var mat: ShaderMaterial = _mesh.material_override
       if mat:
           mat.set_shader_parameter("direction_texture", _direction_texture)
           mat.set_shader_parameter("grid_width", w)
           mat.set_shader_parameter("grid_height", h)

   func set_visible_overlay(is_visible: bool) -> void:
       visible = is_visible
   ```

3. Create `res://scenes/game/PathOverlay.tscn`:
   - Root node: `Node3D` named `PathOverlay`. Attach `res://scripts/controllers/PathOverlay.gd`.
   - Child node: `MeshInstance3D` named `Mesh`.
   - Set mesh to `PlaneMesh`. Set `size = Vector2(40.0, 40.0)` (matches 20×20 grid at CELL_SIZE=2).
   - Position `Mesh` at `Vector3(20.0, 0.05, 20.0)` — 0.05 units above the ground plane to prevent z-fighting.
   - Create a `ShaderMaterial` on the Mesh:
     - `shader = res://shaders/path_arrow.gdshader`.
     - Leave shader parameters at defaults (they are set at runtime in PathOverlay.gd).
   - Assign the ShaderMaterial as `material_override` on the Mesh node.
   - Save as PathOverlay.tscn.

4. Add a toggle input in PathOverlay.gd:
   ```gdscript
   func _input(event: InputEvent) -> void:
       if event is InputEventKey and event.pressed and not event.echo:
           if event.keycode == KEY_P:  # Toggle path overlay with P key
               set_visible_overlay(not visible)
               get_viewport().set_input_as_handled()
   ```
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse\|shader"</automated>
</task>

<task id="1-05-02" name="Assemble Game.tscn — Wire All Systems Together">
<objective>Create the root game scene that instances every system built across all five plans and wires their cross-system connections: GridManager initialization, FlowFieldManager, EnemyManager, WaveController, TowerPlacer (with camera ref and toast ref), CameraRig, HUD (with WaveController signals), PathOverlay, and Map01. After this task the game is playable end-to-end.</objective>
<files>
  <create>res://scenes/game/Game.tscn</create>
</files>
<implementation>
1. Create `res://scenes/game/Game.tscn`:
   - Root node: `Node` named `Game`. Attach a new script `Game.gd` (inline script on root node).
   - Instance all the following as children (use Scene → Instance Child Scene for .tscn files):
     a. `Map01` (from `res://scenes/maps/Map01.tscn`) — named `Map01`.
     b. `EnemyMultiMesh` (from `res://scenes/enemies/EnemyMultiMesh.tscn`) — named `EnemyMultiMesh`.
     c. `TowerPlacer` (from `res://scenes/game/TowerPlacer.tscn`) — named `TowerPlacer`.
     d. `WaveController` (from `res://scenes/game/WaveController.tscn`) — named `WaveController`.
     e. `PathOverlay` (from `res://scenes/game/PathOverlay.tscn`) — named `PathOverlay`.
     f. `CameraRig` (from `res://scenes/camera/CameraRig.tscn`) — named `CameraRig`.
     g. `HUD` (from `res://scenes/hud/HUD.tscn`) — named `HUD`.
     h. `ToastNotification` reference — ToastNotification is already a child of HUD; use `$HUD/ToastNotification`.

2. Create `Game.gd` script attached to the root `Game` node:
   ```gdscript
   extends Node

   @onready var _map: Node3D = $Map01
   @onready var _enemy_mm: Node3D = $EnemyMultiMesh
   @onready var _tower_placer: Node3D = $TowerPlacer
   @onready var _wave_controller: Node = $WaveController
   @onready var _path_overlay: Node3D = $PathOverlay
   @onready var _camera_rig: Node3D = $CameraRig
   @onready var _hud: CanvasLayer = $HUD

   func _ready() -> void:
       # Step 1: Map01._ready() calls GridManager.initialize_from_map and FlowFieldManager.recompute
       # These happen automatically as Map01 is a child and its _ready() runs before ours.

       # Step 2: Initialize EnemyManager with the enemy definitions and MultiMesh nodes
       var enemy_defs: Array[EnemyDefinition] = []
       for tres_path in [
           "res://data/enemies/enemy_basic.tres",
           "res://data/enemies/enemy_fast.tres",
           "res://data/enemies/enemy_heavy.tres"
       ]:
           enemy_defs.append(load(tres_path) as EnemyDefinition)
       EnemyManager.initialize(enemy_defs, _enemy_mm)

       # Step 3: Wire TowerPlacer references
       _tower_placer.camera = _camera_rig.get_camera()
       _tower_placer.toast = _hud.toast  # Expose toast via HUD property

       # Step 4: Wire HUD
       _hud.setup(_wave_controller, _wave_controller.wave_definitions.size())

       # Step 5: Wire BottomPanel tower selection to TowerPlacer
       _hud.get_node("BottomPanel").tower_selected.connect(_on_tower_selected)

       # Step 6: Wire TowerPlacer's invalid placement notification to HUD toast
       # (TowerPlacer calls toast.show_message() directly via the toast reference set in step 3)

       # Step 7: Set wave mode (can be changed here for testing; default = TIMED)
       # GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED  # Uncomment to test PT mode

   func _on_tower_selected(tower_type_id: String) -> void:
       # In Phase 1, only "wall" exists
       if tower_type_id == "wall":
           _tower_placer.activate_placement_mode()
   ```

3. Wire HUD.gd: add `var toast` property to expose the toast node:
   In `HUD.gd`, add:
   ```gdscript
   @onready var toast = $ToastNotification
   ```
   (This property is already referenced by Game.gd step 3.)

4. Set `res://scenes/game/Game.tscn` as the main scene in Project Settings → General → Application → Run → Main Scene.

5. Verify the scene tree structure in the editor. Expected hierarchy:
   ```
   Game (Node)
   ├── Map01 (Node3D — inherits MapBase)
   │   └── StaticObjects (Node3D)
   ├── EnemyMultiMesh (Node3D)
   │   ├── MMI_Basic (MultiMeshInstance3D)
   │   ├── MMI_Fast (MultiMeshInstance3D)
   │   └── MMI_Heavy (MultiMeshInstance3D)
   ├── TowerPlacer (Node3D)
   │   ├── [ghost instance added at runtime]
   │   └── RangeOverlay (MeshInstance3D)
   ├── WaveController (Node)
   ├── PathOverlay (Node3D)
   │   └── Mesh (MeshInstance3D)
   ├── CameraRig (Node3D)
   │   └── CameraPivot (Node3D)
   │       └── Camera3D
   └── HUD (CanvasLayer)
       ├── TopBar (PanelContainer)
       ├── BottomPanel (PanelContainer)
       ├── SendWaveButton (Button)
       └── ToastNotification (CanvasLayer)
   ```
</implementation>
<manual>Play the scene (F5). Verify:
1. The 20×20 grid ground plane is visible with static objects placed at the correct positions.
2. The camera starts at map center with 60° tilt and Standard zoom.
3. The path overlay arrows are visible on the ground, pointing from spawn toward exit.
4. In TIMED mode: the wave auto-launches after inter_wave_delay seconds. Enemies appear at the spawn cell and move toward the exit following the arrows.
5. An enemy reaching the exit decrements the lives counter in the top bar.
6. Selecting the Wall Tower button (or pressing 1) activates placement mode. The ghost mesh appears at the cursor.
7. Hovering over a valid cell: ghost is green. Hovering over an impassable cell or a path-blocking position: ghost turns red.
8. Left-clicking a valid cell places a permanent tower wall. The path overlay updates immediately (arrows reroute).
9. Placing a tower mid-wave: enemies change direction on their next cell step (not a visual snap).
10. Clicking an invalid cell: toast "Path blocked" message appears for ~2 seconds.</manual>
</task>

<task id="1-05-03" name="Implement Wave Controller and Enemy Manager Tests">
<objective>Replace the pending() stubs in test_wave_controller.gd and test_enemy_manager.gd with real assertions. These tests verify TIMED vs PLAYER_TRIGGERED wave launch behavior (WAVE-01, WAVE-02), wave counter increment, life deduction on exit, flow field version cache invalidation, and pool sizing.</objective>
<files>
  <modify>res://tests/test_wave_controller.gd</modify>
  <modify>res://tests/test_enemy_manager.gd</modify>
</files>
<implementation>
1. Replace `res://tests/test_wave_controller.gd` with:
```gdscript
extends GutTest

var _wave_ctrl: Node
var _wave_defs: Array[WaveDefinition]

func before_each():
    # Build a minimal 2-wave setup for testing
    var group1 = SpawnGroupResource.new()
    group1.enemy_id = "basic"
    group1.count = 2
    group1.spawn_interval = 0.1
    group1.delay_from_wave_start = 0.0

    var def1 = WaveDefinition.new()
    def1.wave_number = 1
    def1.inter_wave_delay = 0.1  # Very short for test
    def1.groups = [group1]

    var def2 = WaveDefinition.new()
    def2.wave_number = 2
    def2.inter_wave_delay = 0.1
    def2.groups = [group1]

    _wave_defs = [def1, def2]

    _wave_ctrl = load("res://scripts/controllers/WaveController.gd").new()
    _wave_ctrl.wave_definitions = _wave_defs
    add_child_autofree(_wave_ctrl)

    # Also set up a minimal grid so GridManager.spawn_positions[0] works
    var map_def = MapDefinition.new()
    map_def.grid_width = 5
    map_def.grid_height = 5
    map_def.spawn_positions = [Vector2i(0, 2)]
    map_def.exit_position = Vector2i(4, 2)
    GridManager.initialize_from_map(map_def)
    FlowFieldManager.recompute()

func test_timed_mode_launches_wave_on_timer():
    GameState.wave_mode = GameState.WaveMode.TIMED
    _wave_ctrl._ready()
    assert_false(_wave_ctrl.is_wave_active, "Wave should not be active before timer expires")
    # Simulate enough time passing to exhaust the inter_wave_delay
    _wave_ctrl._process(0.2)  # 0.2 > 0.1 inter_wave_delay
    assert_true(_wave_ctrl.is_wave_active, "Wave should launch after timer expires in TIMED mode")

func test_player_triggered_mode_does_not_auto_launch():
    GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED
    _wave_ctrl._ready()
    _wave_ctrl._process(10.0)  # Simulate a lot of time passing
    assert_false(_wave_ctrl.is_wave_active,
        "Wave must not auto-launch in PLAYER_TRIGGERED mode regardless of time elapsed")

func test_player_triggered_mode_launches_on_signal():
    GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED
    _wave_ctrl._ready()
    _wave_ctrl._process(0.05)  # Some time, but not enough to trigger timed launch
    assert_false(_wave_ctrl.is_wave_active)
    _wave_ctrl.send_wave()
    _wave_ctrl._process(0.0)  # One more tick to process send_wave_pressed
    assert_true(_wave_ctrl.is_wave_active,
        "Wave should launch immediately after send_wave() is called")

func test_wave_counter_increments_after_wave_clear():
    GameState.wave_mode = GameState.WaveMode.TIMED
    _wave_ctrl._ready()
    var initial_index = _wave_ctrl.current_wave_index
    # Force wave to end
    _wave_ctrl._launch_wave()
    _wave_ctrl._active_spawn_count = 0
    _wave_ctrl._spawns_dispatched = _wave_defs[0].get_total_enemy_count()
    _wave_ctrl._end_wave()
    assert_eq(_wave_ctrl.current_wave_index, initial_index + 1,
        "current_wave_index should increment after wave ends")
```

2. Replace `res://tests/test_enemy_manager.gd` with:
```gdscript
extends GutTest

func before_each():
    var map_def = MapDefinition.new()
    map_def.grid_width = 10
    map_def.grid_height = 5
    map_def.spawn_positions = [Vector2i(0, 2)]
    map_def.exit_position = Vector2i(9, 2)
    map_def.static_object_positions = []
    GridManager.initialize_from_map(map_def)
    FlowFieldManager.recompute()

    # Initialize EnemyManager with a basic enemy def
    var def = EnemyDefinition.new()
    def.enemy_id = "basic"
    def.speed = 10.0  # Fast for test purposes
    def.scale = Vector3.ONE
    def.position_jitter = 0.0

    # Create a minimal MultiMeshInstance3D parent for the test
    var mm_parent = Node3D.new()
    var mmi = MultiMeshInstance3D.new()
    mmi.name = "MMI_Basic"
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = BoxMesh.new()
    mm.instance_count = 0
    mmi.multimesh = mm
    mm_parent.add_child(mmi)
    add_child_autofree(mm_parent)
    EnemyManager.initialize([def], mm_parent)

func test_enemy_reaches_exit_deducts_life():
    var initial_hp = GameState.player_hp
    # Place enemy directly adjacent to the exit
    EnemyManager.spawn_enemy("basic", Vector2i(8, 2))
    # Simulate enough time for the enemy to cross one cell at speed=10.0
    EnemyManager._process(0.15)  # 0.15s * 10 cells/s = 1.5 cells > 1 cell step
    assert_lt(GameState.player_hp, initial_hp,
        "Player HP should decrease when enemy reaches exit")

func test_enemy_reads_updated_flow_field_on_version_change():
    EnemyManager.spawn_enemy("basic", Vector2i(0, 2))
    var enemy = EnemyManager._active_enemies[0]
    var old_version = FlowFieldManager.current_version
    # Trigger a recompute to increment version
    FlowFieldManager.recompute()
    assert_gt(FlowFieldManager.current_version, old_version,
        "Flow field version should have incremented")
    # Before _process runs, cached_field_version is stale
    assert_ne(enemy["cached_field_version"], FlowFieldManager.current_version,
        "Enemy cache should be stale before next process tick")
    # After _process, cache should be updated
    EnemyManager._process(0.0)
    assert_eq(enemy["cached_field_version"], FlowFieldManager.current_version,
        "Enemy should update cached_field_version on next process tick")

func test_enemy_pool_size_matches_wave_definition():
    var group = SpawnGroupResource.new()
    group.enemy_id = "basic"
    group.count = 5
    group.spawn_interval = 0.0
    group.delay_from_wave_start = 0.0

    var wave_def = WaveDefinition.new()
    wave_def.wave_number = 1
    wave_def.groups = [group]

    EnemyManager.prepare_wave(wave_def)
    assert_eq(EnemyManager._multi_mesh_nodes["basic"].multimesh.instance_count,
        wave_def.get_total_enemy_count(),
        "MultiMesh instance_count should equal total enemy count from wave definition")
```
</implementation>
<automated>godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit 2>&1 | tail -20</automated>
</task>

<task id="1-05-04" name="Performance Baseline Check (STEAM-04)">
<objective>Verify stable 60fps throughout Phase 1 gameplay conditions by running the Godot built-in profiler during a full 5-wave session with the path overlay active and towers being placed mid-wave. Identify and fix any frame budget violations before Phase 1 is declared done.</objective>
<files>
</files>
<implementation>
This task is a manual profiling session. No code changes unless a performance issue is found.

1. Open the project in the Godot editor. Open the Debugger panel (F8 or bottom toolbar → Debugger).

2. Navigate to the Profiler tab. Enable "Show FPS" in the Monitors tab.

3. Play the game scene (F5). In the Monitors tab, pin the following metrics:
   - FPS
   - Process Time (ms)
   - Render Draw Calls

4. Let the first wave auto-launch (TIMED mode). Observe FPS during peak simultaneous enemy movement (~6 enemies for wave 1).

5. While the first wave is active, place 5–10 wall towers in rapid succession. Observe FPS during each placement (this is the highest-cost event: BFS validation + flow field recompute).

6. Advance to wave 5 (25 total enemies). Observe peak simultaneous enemy count and FPS.

7. Toggle the path overlay off (P key) and on during wave 5. Observe FPS change.

8. Record the following in the Output or a comment in Game.gd:
   - Minimum FPS observed
   - FPS during tower placement
   - Draw call count at peak enemy count

9. Pass criteria (STEAM-04): No sustained FPS drop below 60 on GTX 1060-tier hardware or equivalent. Single-frame spikes to 55fps on tower placement are acceptable (single frame, not sustained).

10. If FPS drops are found, apply the following mitigations in priority order:
    a. BFS hover validation running too often: verify the cell-change cache in TowerPlacer._update_hover() is correctly preventing BFS re-runs when the cursor stays on the same cell. If not cached, fix the cache logic.
    b. EnemyManager._process() GDScript overhead: if 25+ enemies show high process time, profile the per-enemy loop. Consider batching transform updates into a PackedFloat32Array before writing to multimesh (avoids per-instance method call overhead).
    c. PathOverlay shader: if the shader causes draw call or GPU overhead, reduce animation speed (time_offset change rate) or disable the overlay by default.
    d. Flow field C# computation: if FlowFieldManager.recompute() shows in profiler, it is likely GDScript call overhead wrapping the C# result. Consider caching the direction array as a PackedVector2Array instead of a generic Array to reduce per-element boxing.
</implementation>
<manual>Run the 5-wave playtest session as described in the implementation steps. Confirm minimum FPS stays at or above 60fps on the target hardware. Check the Godot Debugger Monitors tab during: (a) peak wave 5 enemy count with path overlay visible, (b) rapid tower placement mid-wave, (c) tower placement that triggers the path-blocked toast. Record the minimum FPS observed in a comment in Game.gd.</manual>
</task>
```

## must_haves

- [ ] PathOverlay.tscn renders visible animated arrows on the ground that point toward the exit cell
- [ ] Arrow direction updates within one frame of FlowFieldManager emitting flow_field_updated (UI-01: instant update, not deferred)
- [ ] Path overlay is toggleable with the P key and defaults to visible
- [ ] Game.tscn instances all five systems: Map01, EnemyMultiMesh, TowerPlacer, WaveController, PathOverlay, CameraRig, HUD
- [ ] TowerPlacer.camera is set to CameraRig.get_camera() in Game._ready()
- [ ] TowerPlacer.toast is set to the HUD's ToastNotification in Game._ready()
- [ ] HUD.setup() is called in Game._ready() with the WaveController reference and correct total wave count
- [ ] BottomPanel.tower_selected signal is connected to Game._on_tower_selected()
- [ ] All 17 GUT tests pass (not pending): 5 in test_grid_manager, 5 in test_path_validation, 4 in test_flow_field, 4 in test_wave_controller, 3 in test_enemy_manager — no failures
- [ ] STEAM-04: No sustained FPS drop below 60fps observed during the 5-wave manual session on target hardware

## verification

Run the complete automated test suite:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Expected: 17 tests passing, 0 pending, 0 failed. Exit code 0.

End-to-end manual verification (the full Phase 1 playtest):
1. Launch the game (`godot --path . res://scenes/game/Game.tscn` or F5 in editor).
2. Verify all Phase 1 must_haves listed below are observable:
   - Grid is visible in 3D with static obstacle meshes.
   - Camera starts at default 60° tilt, Standard zoom.
   - Wave 1 launches automatically (TIMED mode) after ~15 seconds.
   - Basic, Fast, and Heavy enemies are visually distinct in size and movement speed.
   - Enemies follow the path overlay arrows and deduct lives on reaching the exit.
   - Tower placement ghost turns green/red correctly.
   - Placing a tower updates the flow field and the path overlay arrows instantly.
   - Enemies change direction after a mid-wave tower placement (on next cell step).
   - Invalid placements show the toast notification.
   - 5 waves complete without crashes.
   - FPS stays at or above 60 throughout.
