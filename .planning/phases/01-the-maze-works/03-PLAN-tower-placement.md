---
wave: 2
depends_on:
  - 01-PLAN-foundation.md
files_modified:
  - res://scripts/controllers/TowerPlacer.gd
  - res://scenes/game/TowerPlacer.tscn
  - res://scenes/towers/TowerWall.tscn
  - res://scenes/towers/TowerGhost.tscn
  - res://scenes/hud/ToastNotification.tscn
  - res://tests/test_grid_manager.gd
  - res://tests/test_path_validation.gd
  - res://tests/test_flow_field.gd
autonomous: true
---

# Plan 3: Tower Placement

**Phase:** 1 — The Maze Works
**Wave:** 2
**Requirements:** CORE-01, CORE-02, CORE-03

## Objective

This plan builds the tower placement system: the TowerPlacer controller that raycasts cursor position onto the grid, a ghost preview mesh that turns green or red based on live BFS validation, single-click placement that commits the tower to the grid, and the "Path blocked" toast notification for invalid placements. It also completes the test stubs for CORE-01, CORE-02, and CORE-03 — replacing the `pending()` bodies with real assertions. CORE-03 (enemies re-route mid-wave) is verified by confirming that a successful tower placement triggers a FlowField version increment and that all enemy caches are invalidated; the visual re-routing is confirmed via manual playtest. This plan depends on Plan 01 (GridManager, FlowFieldManager, and the Map01 scene must exist).

## Tasks

```xml
<task id="1-03-01" name="Create TowerWall and TowerGhost Scenes">
<objective>Build the two mesh scenes used in tower placement: TowerWall (the permanent placed tower) and TowerGhost (the translucent cursor-following preview). The ghost uses a green/red material swap to communicate placement validity.</objective>
<files>
  <create>res://scenes/towers/TowerWall.tscn</create>
  <create>res://scenes/towers/TowerGhost.tscn</create>
</files>
<implementation>
1. Create `res://scenes/towers/TowerWall.tscn`:
   - Root node: `Node3D` named `TowerWall`.
   - Add child `MeshInstance3D` named `Mesh`.
   - Set mesh to `BoxMesh`. Set size `Vector3(1.8, 2.0, 1.8)` (slightly narrower than the 2-unit cell to leave visible gaps between adjacent towers; 2.0 tall).
   - Position `Mesh` at `Vector3(0, 1.0, 0)` so the box base sits on the ground plane (Y=0).
   - Create a `StandardMaterial3D` named `TowerMaterial`:
     - `albedo_color = Color(0.3, 0.3, 0.45)` (blue-grey stone, Claude's discretion).
     - `roughness = 0.9`, `metallic = 0.0`.
   - Assign TowerMaterial to the Mesh node.
   - Save as TowerWall.tscn.

2. Create `res://scenes/towers/TowerGhost.tscn`:
   - Root node: `Node3D` named `TowerGhost`.
   - Add child `MeshInstance3D` named `Mesh`.
   - Set mesh to `BoxMesh`, same size `Vector3(1.8, 2.0, 1.8)`.
   - Position `Mesh` at `Vector3(0, 1.0, 0)`.
   - Create TWO `StandardMaterial3D` resources:
     a. `GhostValid`: `albedo_color = Color(0.1, 0.9, 0.1, 0.5)`, `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, `albedo_color.a = 0.5`.
     b. `GhostInvalid`: `albedo_color = Color(0.9, 0.1, 0.1, 0.5)`, `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, `albedo_color.a = 0.5`.
   - Assign `GhostValid` as the default material.
   - Attach a small script `TowerGhost.gd` to the root node:
     ```gdscript
     extends Node3D
     @onready var _mesh: MeshInstance3D = $Mesh
     @export var material_valid: StandardMaterial3D
     @export var material_invalid: StandardMaterial3D

     func set_valid(is_valid: bool) -> void:
         _mesh.material_override = material_valid if is_valid else material_invalid
     ```
   - Assign the two materials to the exported properties in the Inspector.
   - Set `TowerGhost.visible = false` by default (TowerPlacer shows it on tower mode activation).
   - Save as TowerGhost.tscn.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-03-02" name="Create ToastNotification Scene">
<objective>Build the toast notification UI element that shows "Path blocked — enemies must have a route" when an invalid placement is attempted. This is the invalid placement feedback specified in CONTEXT.md.</objective>
<files>
  <create>res://scenes/hud/ToastNotification.tscn</create>
</files>
<implementation>
1. Create `res://scenes/hud/ToastNotification.tscn`:
   - Root node: `CanvasLayer` named `ToastNotification`. Set `layer = 10` (above other HUD elements).
   - Add child `PanelContainer` named `Panel`. Position it at the top-center of the screen: set anchors to top-center, set `offset_top = 80`, `offset_left = -200`, `offset_right = 200`, `offset_bottom = 120` (approximately).
   - Add child `Label` named `Message` inside Panel.
     - `text = "Path blocked — enemies must have a route"`.
     - `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER`.
   - Set `ToastNotification.visible = false` by default.
   - Attach script `ToastNotification.gd`:
     ```gdscript
     extends CanvasLayer

     @export var display_duration: float = 2.0

     func show_message(message: String = "") -> void:
         if message != "":
             $Panel/Message.text = message
         visible = true
         var tween = create_tween()
         tween.tween_interval(display_duration)
         tween.tween_callback(func(): visible = false)
     ```
   - The animation style (Claude's discretion per CONTEXT.md): the tween simply waits then hides (no fade for now — clean and correct).
   - Save as ToastNotification.tscn.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-03-03" name="Create TowerPlacer Controller">
<objective>Implement the TowerPlacer node that handles cursor-to-grid raycasting, hover ghost positioning with live BFS validation (green/red), click-to-place commit, flow field recompute after placement, and toast notification on rejection. This is the primary implementation of CORE-01, CORE-02, and CORE-03.</objective>
<files>
  <create>res://scripts/controllers/TowerPlacer.gd</create>
  <create>res://scenes/game/TowerPlacer.tscn</create>
</files>
<implementation>
1. Create `res://scripts/controllers/TowerPlacer.gd`:
   - `extends Node3D`.
   - Exported references:
     - `@export var ghost_scene: PackedScene` — assign TowerGhost.tscn.
     - `@export var tower_wall_scene: PackedScene` — assign TowerWall.tscn.
     - `@export var toast: Node` — assign ToastNotification node (set up in Game.tscn in Plan 05; use @onready or exported reference).
     - `@export var camera: Camera3D` — reference to the Camera3D in the scene.
   - Variables:
     - `var _ghost: Node3D = null`
     - `var _is_placement_mode: bool = false`
     - `var _last_hover_cell: Vector2i = Vector2i(-1, -1)` — cache for BFS optimization (Risk 1 mitigation from RESEARCH.md).
     - `var _hover_cell_valid: bool = false`
     - `var _placed_towers: Array[Node3D] = []` — track placed tower nodes.

2. Implement `func _ready() -> void`:
   - Instantiate ghost: `_ghost = ghost_scene.instantiate()`. Add to scene: `add_child(_ghost)`. Set `_ghost.visible = false`.

3. Implement `func activate_placement_mode() -> void`:
   - `_is_placement_mode = true`
   - `_ghost.visible = true`

4. Implement `func deactivate_placement_mode() -> void`:
   - `_is_placement_mode = false`
   - `_ghost.visible = false`
   - `_last_hover_cell = Vector2i(-1, -1)`

5. Implement `func _input(event: InputEvent) -> void`:
   - If `not _is_placement_mode`: return.
   - If event is `InputEventMouseMotion`: `_update_hover(event.position)`.
   - If event is `InputEventMouseButton` and `event.button_index == MOUSE_BUTTON_LEFT` and `event.pressed`:
     - `_attempt_place()`.

6. Implement `func _update_hover(screen_pos: Vector2) -> void`:
   - Raycast from camera onto Y=0 plane (the grid ground):
     ```gdscript
     var from = camera.project_ray_origin(screen_pos)
     var dir = camera.project_ray_normal(screen_pos)
     if abs(dir.y) < 0.001:
         return  # Ray is parallel to ground plane — no intersection
     var t = -from.y / dir.y
     var hit_pos = from + dir * t
     ```
   - Convert to grid cell: `var cell = GridManager.world_to_grid(hit_pos)`.
   - Optimization: if `cell == _last_hover_cell`: return (no BFS re-run, per RESEARCH.md Risk 1).
   - `_last_hover_cell = cell`.
   - Move ghost: `_ghost.global_position = GridManager.grid_to_world(cell)`.
   - Validate placement:
     - If not `GridManager.is_in_bounds(cell)`: `_hover_cell_valid = false`.
     - Else if not `GridManager.can_place_tower(cell)`: `_hover_cell_valid = false` (spawn, exit, occupied, or out-of-bounds).
     - Else: `_hover_cell_valid = FlowFieldManager.validate_placement(cell)` (BFS path check, only runs when cell changes).
   - Update ghost material: `_ghost.set_valid(_hover_cell_valid)`.

7. Implement `func _attempt_place() -> void`:
   - If not `GridManager.is_in_bounds(_last_hover_cell)`: return.
   - If not `_hover_cell_valid`:
     - Show toast: `toast.show_message()` (uses default message "Path blocked — enemies must have a route").
     - Return.
   - Commit placement:
     a. `GridManager.set_cell_state(_last_hover_cell, GridCell.State.TOWER)`.
     b. `FlowFieldManager.recompute()` — this triggers all enemies to re-read directions on their next movement tick (CORE-03).
     c. Spawn permanent tower mesh:
        ```gdscript
        var tower = tower_wall_scene.instantiate()
        get_tree().current_scene.add_child(tower)
        tower.global_position = GridManager.grid_to_world(_last_hover_cell)
        _placed_towers.append(tower)
        ```
     d. Invalidate hover cache so the ghost re-validates on next mouse move: `_last_hover_cell = Vector2i(-1, -1)`.

8. Create `res://scenes/game/TowerPlacer.tscn`:
   - Root node: `Node3D` named `TowerPlacer`.
   - Attach `res://scripts/controllers/TowerPlacer.gd`.
   - Assign ghost_scene and tower_wall_scene in the Inspector.
   - Note: `camera` and `toast` references must be assigned after Game.tscn is assembled in Plan 05.
   - Save scene.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-03-04" name="Implement CORE-01, CORE-02, CORE-03 Unit and Integration Tests">
<objective>Replace the pending() stubs in test_grid_manager.gd, test_path_validation.gd, and test_flow_field.gd with real assertions. These tests verify tower placement marks cells impassable (CORE-01), invalid placements are rejected without grid mutation (CORE-02), and flow field version increments on successful placement (CORE-03).</objective>
<files>
  <modify>res://tests/test_grid_manager.gd</modify>
  <modify>res://tests/test_path_validation.gd</modify>
  <modify>res://tests/test_flow_field.gd</modify>
</files>
<implementation>
1. Replace `res://tests/test_grid_manager.gd` with:
```gdscript
extends GutTest

var _map_def: MapDefinition

func before_each():
    _map_def = MapDefinition.new()
    _map_def.grid_width = 5
    _map_def.grid_height = 5
    _map_def.spawn_positions = [Vector2i(0, 2)]
    _map_def.exit_position = Vector2i(4, 2)
    _map_def.static_object_positions = [Vector2i(2, 0)]
    GridManager.initialize_from_map(_map_def)

func test_cell_initialized_passable():
    var cell = GridManager.get_cell(Vector2i(1, 1))
    assert_not_null(cell, "Cell should not be null")
    assert_true(cell.passable, "Empty cell should be passable after initialization")

func test_tower_placement_marks_cell_impassable():
    GridManager.set_cell_state(Vector2i(1, 1), GridCell.State.TOWER)
    var cell = GridManager.get_cell(Vector2i(1, 1))
    assert_false(cell.passable, "Cell should be impassable after tower placement")
    assert_eq(cell.state, GridCell.State.TOWER)

func test_static_object_cell_is_impassable():
    var cell = GridManager.get_cell(Vector2i(2, 0))
    assert_false(cell.passable, "Static object cell should be impassable at initialization")
    assert_eq(cell.state, GridCell.State.STATIC_OBJECT)

func test_spawn_cell_cannot_receive_tower():
    var can_place = GridManager.can_place_tower(Vector2i(0, 2))
    assert_false(can_place, "Spawn cell should not accept tower placement")

func test_exit_cell_cannot_receive_tower():
    var can_place = GridManager.can_place_tower(Vector2i(4, 2))
    assert_false(can_place, "Exit cell should not accept tower placement")
```

2. Replace `res://tests/test_path_validation.gd` with:
```gdscript
extends GutTest

var _bridge: PathfindingBridge
var _map_def: MapDefinition

func before_each():
    _bridge = PathfindingBridge.new()
    _map_def = MapDefinition.new()
    _map_def.grid_width = 5
    _map_def.grid_height = 5
    _map_def.spawn_positions = [Vector2i(0, 2)]
    _map_def.exit_position = Vector2i(4, 2)
    _map_def.static_object_positions = []
    GridManager.initialize_from_map(_map_def)

func _get_passable_array() -> Array:
    var arr = []
    for cell in GridManager.cells:
        arr.append(cell.passable)
    return arr

func test_open_grid_path_is_valid():
    var passable = _get_passable_array()
    var valid = _bridge.is_path_valid(5, 5, passable,
        [Vector2i(0,2)], Vector2i(4,2), Vector2i(-1,-1))
    assert_true(valid, "Open grid should have a valid path")

func test_full_block_is_rejected():
    # Block the entire middle column
    GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 2), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
    var passable = _get_passable_array()
    var valid = _bridge.is_path_valid(5, 5, passable,
        [Vector2i(0,2)], Vector2i(4,2), Vector2i(-1,-1))
    assert_false(valid, "Fully blocked column should be rejected")

func test_partial_block_leaves_route_valid():
    # Block all but one cell in middle column
    GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
    # Cell (2,2) remains passable — one-cell gap in the column
    var passable = _get_passable_array()
    var valid = _bridge.is_path_valid(5, 5, passable,
        [Vector2i(0,2)], Vector2i(4,2), Vector2i(-1,-1))
    assert_true(valid, "Single gap in column should leave path valid")

func test_corner_block_leaves_route_valid():
    # Block two cells that form an L — route still available around the outside
    GridManager.set_cell_state(Vector2i(1, 2), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(1, 3), GridCell.State.TOWER)
    var passable = _get_passable_array()
    var valid = _bridge.is_path_valid(5, 5, passable,
        [Vector2i(0,2)], Vector2i(4,2), Vector2i(-1,-1))
    assert_true(valid, "Corner block should leave valid route around the outside")

func test_validation_does_not_modify_grid_on_rejection():
    # Confirm cell state is unchanged after a rejected placement
    GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
    # Tentatively block cell (2,2) — this would disconnect the path
    var passable = _get_passable_array()
    var valid = _bridge.is_path_valid(5, 5, passable,
        [Vector2i(0,2)], Vector2i(4,2), Vector2i(2,2))
    assert_false(valid, "Blocking last gap should be rejected")
    # Verify the real grid cell is still passable (validation must not modify grid)
    var cell = GridManager.get_cell(Vector2i(2, 2))
    assert_true(cell.passable, "Rejected placement must not modify the real grid")
```

3. Replace `res://tests/test_flow_field.gd` with:
```gdscript
extends GutTest

var _map_def: MapDefinition

func before_each():
    _map_def = MapDefinition.new()
    _map_def.grid_width = 5
    _map_def.grid_height = 5
    _map_def.spawn_positions = [Vector2i(0, 2)]
    _map_def.exit_position = Vector2i(4, 2)
    _map_def.static_object_positions = []
    GridManager.initialize_from_map(_map_def)
    FlowFieldManager.recompute()

func test_exit_cell_direction_is_zero_vector():
    var dir = FlowFieldManager.get_direction(Vector2i(4, 2))
    assert_eq(dir, Vector2i.ZERO, "Exit cell direction should be zero vector")

func test_adjacent_to_exit_points_at_exit():
    # Cell directly left of exit (3,2) should point right toward exit (4,2)
    var dir = FlowFieldManager.get_direction(Vector2i(3, 2))
    assert_eq(dir, Vector2i(1, 0), "Cell adjacent to exit should point toward exit")

func test_flow_field_version_increments_on_recompute():
    var version_before = FlowFieldManager.current_version
    GridManager.set_cell_state(Vector2i(1, 1), GridCell.State.TOWER)
    FlowFieldManager.recompute()
    assert_gt(FlowFieldManager.current_version, version_before,
        "Flow field version should increment after recompute")

func test_unreachable_cell_has_zero_direction():
    # Block all four neighbors of cell (1,1) to isolate it
    GridManager.set_cell_state(Vector2i(1, 0), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(0, 1), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
    GridManager.set_cell_state(Vector2i(1, 2), GridCell.State.TOWER)
    FlowFieldManager.recompute()
    var dir = FlowFieldManager.get_direction(Vector2i(1, 1))
    assert_eq(dir, Vector2i.ZERO, "Isolated cell should have zero direction (unreachable)")
```
</implementation>
<automated>godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit 2>&1 | tail -15</automated>
</task>
```

## must_haves

- [ ] TowerWall.tscn renders as a box mesh with non-transparent material at Y=1.0 (sitting on ground)
- [ ] TowerGhost.tscn has two distinct materials (green semi-transparent valid, red semi-transparent invalid) and set_valid() switches between them
- [ ] ToastNotification shows for ~2 seconds and auto-hides without requiring player input
- [ ] TowerPlacer._update_hover() only runs BFS when the hovered grid cell changes (not every mouse motion event)
- [ ] TowerPlacer._attempt_place() calls FlowFieldManager.recompute() after committing a valid tower to the grid
- [ ] TowerPlacer does NOT modify the grid on an invalid placement attempt (cell state unchanged after rejection)
- [ ] test_grid_manager.gd: all 5 tests pass (not pending)
- [ ] test_path_validation.gd: all 5 tests pass (not pending)
- [ ] test_flow_field.gd: all 4 tests pass (not pending)
- [ ] Full GUT suite: 14 formerly-pending tests now pass; remaining 8 tests still pending (wave and enemy tests — those are implemented in Plan 05)

## verification

Run the full test suite:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Expected: 14 passing, 8 pending, 0 failed. Exit code 0.

Manual integration check (requires Game.tscn from Plan 05, or temporarily add TowerPlacer and Map01 to a test scene):
1. Open a scene containing Map01.tscn and TowerPlacer.tscn as children.
2. Assign the camera reference to TowerPlacer.
3. Play the scene. Move the cursor over the grid. Confirm the ghost follows the cursor and turns green on valid cells.
4. Hover over a spawn or exit cell. Confirm ghost turns red.
5. Left-click a valid green cell. Confirm a TowerWall mesh appears at that grid position.
6. After placement, run the scene in debug mode and check Output panel: FlowFieldManager.current_version should have incremented.
7. Try to place a tower that would fully block the path. Confirm ghost is red and clicking shows the toast.
