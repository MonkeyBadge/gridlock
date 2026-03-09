---
wave: 1
depends_on: []
files_modified:
  - res://project.godot
  - res://autoloads/GridManager.gd
  - res://scripts/resources/MapDefinition.gd
  - res://scripts/resources/GridCell.gd
  - res://scripts/pathfinding/FlowField.cs
  - res://scripts/pathfinding/PathValidator.cs
  - res://scripts/pathfinding/PathfindingBridge.gd
  - res://assets/maps/map_01/map_01.tres
  - res://scenes/maps/MapBase.tscn
  - res://scenes/maps/Map01.tscn
  - res://addons/gut/
  - res://tests/test_grid_manager.gd
  - res://tests/test_path_validation.gd
  - res://tests/test_flow_field.gd
  - res://tests/test_wave_controller.gd
  - res://tests/test_enemy_manager.gd
autonomous: true
---

# Plan 1: Foundation — Grid, Pathfinding, Map, and Test Infrastructure

**Phase:** 1 — The Maze Works
**Wave:** 1
**Requirements:** MAP-01, MAP-03, MAP-04, CORE-01, CORE-02

## Objective

This plan establishes the structural foundation that all other Phase 1 plans depend on. It creates the Godot 4 project structure, the logical grid system (GridManager autoload, GridCell, MapDefinition resource), the C# pathfinding layer (FlowField.cs, PathValidator.cs, PathfindingBridge.gd), the first hand-crafted map resource (Map01), and installs the GUT test framework with all five test stub files. Nothing in this plan runs enemies or waves — it proves only that the grid exists, that the pathfinding layer computes correct results, and that the test infrastructure is wired and ready.

## Tasks

```xml
<task id="1-01-01" name="Initialize Godot 4 Project Structure">
<objective>Create the canonical directory layout defined in RESEARCH.md so all subsequent tasks have stable paths to write into.</objective>
<files>
  <create>res://project.godot</create>
  <create>res://autoloads/.gitkeep</create>
  <create>res://assets/enemies/.gitkeep</create>
  <create>res://assets/towers/.gitkeep</create>
  <create>res://assets/maps/map_01/.gitkeep</create>
  <create>res://data/enemies/.gitkeep</create>
  <create>res://data/waves/.gitkeep</create>
  <create>res://scenes/game/.gitkeep</create>
  <create>res://scenes/enemies/.gitkeep</create>
  <create>res://scenes/towers/.gitkeep</create>
  <create>res://scenes/hud/.gitkeep</create>
  <create>res://scenes/camera/.gitkeep</create>
  <create>res://scenes/maps/.gitkeep</create>
  <create>res://scripts/pathfinding/.gitkeep</create>
  <create>res://scripts/controllers/.gitkeep</create>
  <create>res://scripts/resources/.gitkeep</create>
  <create>res://shaders/.gitkeep</create>
  <create>res://tests/.gitkeep</create>
</files>
<implementation>
1. Open Godot 4 and create a new project at the game-project root directory. Select "Forward+" renderer (supports 3D with good performance on GTX 1060-tier hardware per STEAM-04 target). Name the project "maze-td".
2. In the Godot FileSystem dock, create all directories listed under `files_modified` using right-click → New Folder. Exact paths match RESEARCH.md file structure section.
3. In Project Settings → General → Application → Run, set "Main Scene" to `res://scenes/game/Game.tscn` (this file will be created by Plan 05; leave the setting as-is for now — Godot will warn but not error on startup during development).
4. In Project Settings → General → Display → Window, set Width=1920, Height=1080 as the reference resolution.
5. Save the project (Ctrl+S). Verify the project.godot file exists at the repo root.
6. Create a `.gdignore` file (empty) inside `res://scripts/pathfinding/` — this prevents Godot from trying to parse the .cs files as GDScript. Remove it after the C# project is configured.
   Note: The C# project configuration (.csproj) will be initialized by Godot automatically when the first .cs file is created. Do not manually create the .csproj.
</implementation>
<automated>godot --headless --path . --quit</automated>
</task>

<task id="1-01-02" name="Create GridCell and MapDefinition Resource Classes">
<objective>Define the data structures that represent the logical grid state and the map configuration. These are the authoritative source of truth for all pathfinding and placement logic (ADR-03).</objective>
<files>
  <create>res://scripts/resources/GridCell.gd</create>
  <create>res://scripts/resources/MapDefinition.gd</create>
</files>
<implementation>
1. Create `res://scripts/resources/GridCell.gd`:
   - Declare `class_name GridCell`.
   - Define enum `State { EMPTY, TOWER, STATIC_OBJECT, SPAWN, EXIT }` (ADR-07 of Risk 7: TOWER and STATIC_OBJECT are distinct).
   - Properties:
     - `var position: Vector2i`
     - `var state: State = State.EMPTY`
     - `var passable: bool = true`
   - Add a setter on `state` that automatically updates `passable`:
     - `passable = true` when state is EMPTY, SPAWN, or EXIT.
     - `passable = false` when state is TOWER or STATIC_OBJECT.
   - Do NOT extend Resource — GridCell is a plain GDScript object held in arrays, not saved as .tres.

2. Create `res://scripts/resources/MapDefinition.gd`:
   - Declare `class_name MapDefinition extends Resource`.
   - Add `@export var map_name: String = ""`.
   - Add `@export var grid_width: int = 20`.
   - Add `@export var grid_height: int = 20`.
   - Add `@export var spawn_positions: Array[Vector2i] = []` — at least one spawn cell per map.
   - Add `@export var exit_position: Vector2i = Vector2i(0, 0)`.
   - Add `@export var static_object_positions: Array[Vector2i] = []` — cells that are STATIC_OBJECT state at load time.
   - Add `@export var map_display_name: String = ""`.
   - No methods on this class — it is a pure data container.

3. Verify both scripts parse without error by opening them in the Godot editor Script tab. The Script tab will report syntax errors inline.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -v "^$"</automated>
</task>

<task id="1-01-03" name="Create GridManager Autoload">
<objective>Implement the GridManager singleton that owns the logical grid array, exposes coordinate conversion functions, handles passability queries, and provides the cell-state mutation API used by TowerPlacer (Plan 03) and the pathfinding layer.</objective>
<files>
  <create>res://autoloads/GridManager.gd</create>
  <modify>res://project.godot</modify>
</files>
<implementation>
1. Create `res://autoloads/GridManager.gd`:
   - Declare `extends Node`.
   - Constants: `const CELL_SIZE: float = 2.0` (ADR from RESEARCH.md — 2 Godot world units per cell).
   - Variables:
     - `var cells: Array = []` — flat Array of GridCell objects, indexed `x + y * grid_width`.
     - `var grid_width: int = 0`
     - `var grid_height: int = 0`
     - `var spawn_positions: Array[Vector2i] = []`
     - `var exit_position: Vector2i = Vector2i(-1, -1)`
   - Signal: `signal grid_changed` — emitted after any cell state mutation.

2. Implement `func initialize_from_map(map_def: MapDefinition) -> void`:
   - Set `grid_width = map_def.grid_width`, `grid_height = map_def.grid_height`.
   - Set `spawn_positions = map_def.spawn_positions`, `exit_position = map_def.exit_position`.
   - Clear `cells` array and fill with `grid_width * grid_height` new GridCell instances.
   - For each cell, set `position = Vector2i(x, y)` and `state = GridCell.State.EMPTY`.
   - For each position in `map_def.spawn_positions`: call `set_cell_state(pos, GridCell.State.SPAWN)`.
   - Set exit cell: `set_cell_state(map_def.exit_position, GridCell.State.EXIT)`.
   - For each position in `map_def.static_object_positions`: call `set_cell_state(pos, GridCell.State.STATIC_OBJECT)`.

3. Implement `func get_cell(pos: Vector2i) -> GridCell`:
   - Return `null` if pos is out of bounds.
   - Return `cells[pos.x + pos.y * grid_width]`.

4. Implement `func set_cell_state(pos: Vector2i, state: GridCell.State) -> void`:
   - Get the cell, set `cell.state = state` (the setter on GridCell.gd auto-updates `passable`).
   - Emit `grid_changed`.

5. Implement `func is_passable(pos: Vector2i) -> bool`:
   - Return `false` if out of bounds.
   - Return `get_cell(pos).passable`.

6. Implement `func world_to_grid(world_pos: Vector3) -> Vector2i`:
   - Return `Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.z / CELL_SIZE))`.
   - Use `int()` truncation (floor behavior for positive coords). Add guard for negative coords if needed.

7. Implement `func grid_to_world(grid_pos: Vector2i) -> Vector3`:
   - Return `Vector3(grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5, 0.0, grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5)`.
   - This centers the returned world position at the middle of the cell.

8. Implement `func is_in_bounds(pos: Vector2i) -> bool`:
   - Return `pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height`.

9. Implement `func can_place_tower(pos: Vector2i) -> bool`:
   - Return `false` if `not is_in_bounds(pos)`.
   - Get cell. Return `false` if state is not EMPTY (cannot place on SPAWN, EXIT, STATIC_OBJECT, or existing TOWER).
   - Return `true` otherwise (BFS validation is done separately by TowerPlacer via PathfindingBridge).

10. Register the autoload: Open Project Settings → AutoLoad. Add `res://autoloads/GridManager.gd` with name `GridManager`. Place it first in the autoload order.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-01-04" name="Implement C# Pathfinding Layer (FlowField and PathValidator)">
<objective>Create the C# classes that compute the flow field (Dijkstra from exit outward) and validate tower placement (BFS flood-fill). These are the performance-critical pathfinding algorithms described in ADR-01, ADR-04, and the RESEARCH.md Implementation Approach sections.</objective>
<files>
  <create>res://scripts/pathfinding/FlowField.cs</create>
  <create>res://scripts/pathfinding/PathValidator.cs</create>
</files>
<implementation>
1. Remove the `.gdignore` file from `res://scripts/pathfinding/` if it was created in task 1-01-01. Creating the first .cs file in the project will prompt Godot to initialize the C# (.NET) project. Accept this when prompted, or run `dotnet new` if working outside the editor.

2. Create `res://scripts/pathfinding/FlowField.cs`:
   - Declare `using Godot;` at the top.
   - Declare `public partial class FlowField : GodotObject` — extends GodotObject so GDScript can instantiate it via `FlowField.new()`.
   - Public field: `public int Version { get; private set; } = 0;`
   - Public method signature:
     ```csharp
     public Godot.Collections.Array<Vector2I> Compute(
         int width, int height,
         Godot.Collections.Array<bool> passable,
         Vector2I exitCell)
     ```
   - Implementation:
     a. Allocate `int[] dist = new int[width * height]` filled with `int.MaxValue`.
     b. Allocate `Vector2I[] directions = new Vector2I[width * height]` filled with `Vector2I.Zero`.
     c. Set `dist[exitCell.X + exitCell.Y * width] = 0`.
     d. Create a `Queue<Vector2I>` and enqueue `exitCell`.
     e. Define four neighbor offsets: `(1,0), (-1,0), (0,1), (0,-1)` (four-cardinal directions, ADR-06).
     f. BFS loop: dequeue current cell. For each of the four neighbors:
        - Check bounds: `nx >= 0 && nx < width && ny >= 0 && ny < height`.
        - Check passable: `passable[nx + ny * width] == true`.
        - If `dist[nx + ny * width] > dist[current] + 1`: update dist, enqueue neighbor.
     g. After BFS: for each cell `(x, y)` where `dist[x + y * width] < int.MaxValue` and `Vector2I(x,y) != exitCell`:
        - Find which neighbor has the minimum distance value.
        - Set `directions[x + y * width]` to the Vector2I offset pointing toward that neighbor.
     h. Exit cell direction stays `Vector2I.Zero` (it IS the exit — per RESEARCH.md data structure spec).
     i. Unreachable cells (dist == int.MaxValue) keep direction `Vector2I.Zero`.
     j. Increment `Version`.
     k. Return `new Godot.Collections.Array<Vector2I>(directions)`.

3. Create `res://scripts/pathfinding/PathValidator.cs`:
   - Declare `using Godot;`.
   - Declare `public partial class PathValidator : GodotObject`.
   - Public method signature:
     ```csharp
     public bool IsPathValid(
         int width, int height,
         Godot.Collections.Array<bool> passable,
         Godot.Collections.Array<Vector2I> spawnPositions,
         Vector2I exitCell,
         Vector2I tentativeBlockCell)
     ```
   - Implementation (ADR-04 — BFS flood-fill from exit, check all spawns are reachable):
     a. Create a local `bool[] tempPassable = passable.ToArray()` copy.
     b. Set `tempPassable[tentativeBlockCell.X + tentativeBlockCell.Y * width] = false` (the tentative tower cell is treated as blocked without modifying the real grid).
     c. BFS from `exitCell` outward through `tempPassable` (same BFS logic as FlowField.Compute, but only tracking reachability, not distances).
     d. For each spawn position in `spawnPositions`: check if it was visited by the BFS. If any spawn is NOT visited, return `false`.
     e. If all spawns are visited (reachable from exit), return `true`.
   - Edge cases (per RESEARCH.md):
     - If `tentativeBlockCell` equals any spawn position: return `false` immediately (spawns cannot be blocked).
     - If `tentativeBlockCell` equals `exitCell`: return `false` immediately.

4. Build the C# project: in the Godot editor, select Build → Build Project (or run `dotnet build` in the project root). Verify zero errors in the build output panel.
</implementation>
<automated>dotnet build --no-restore 2>&1 | tail -5</automated>
</task>

<task id="1-01-05" name="Create PathfindingBridge GDScript Wrapper">
<objective>Implement the GDScript adapter that instantiates the C# FlowField and PathValidator objects and exposes their API to the rest of the GDScript codebase. This is the clean GDScript/C# boundary defined in ADR-02.</objective>
<files>
  <create>res://scripts/pathfinding/PathfindingBridge.gd</create>
  <create>res://autoloads/FlowFieldManager.gd</create>
  <modify>res://project.godot</modify>
</files>
<implementation>
1. Create `res://scripts/pathfinding/PathfindingBridge.gd`:
   - `extends RefCounted` (not a node — it is a utility object).
   - In `_init()`:
     - Instantiate the C# classes: `var _flow_field = FlowField.new()` and `var _path_validator = PathValidator.new()`.
     - Store as member variables.
   - Implement `func compute_flow_field(width: int, height: int, passable: Array, exit_cell: Vector2i) -> Array`:
     - Build a `Array[bool]` passable map from the GridManager cell array.
     - Call `_flow_field.Compute(width, height, passable_array, exit_cell)`.
     - Return the resulting direction array.
   - Implement `func is_path_valid(width: int, height: int, passable: Array, spawn_positions: Array, exit_cell: Vector2i, tentative_block: Vector2i) -> bool`:
     - Call `_path_validator.IsPathValid(width, height, passable_array, spawn_array, exit_cell, tentative_block)`.
     - Return the bool result.
   - Implement `func get_flow_field_version() -> int`:
     - Return `_flow_field.Version`.
   - Helper: `func _build_passable_array() -> Array[bool]`:
     - Iterate all GridManager.cells, return Array[bool] of `cell.passable` values in order.

2. Create `res://autoloads/FlowFieldManager.gd`:
   - `extends Node`.
   - Variables:
     - `var _bridge: PathfindingBridge`
     - `var current_directions: Array = []` — stores the last computed direction array.
     - `var current_version: int = 0`
   - Signal: `signal flow_field_updated(version: int)`.
   - In `_ready()`: instantiate `_bridge = PathfindingBridge.new()`.
   - Implement `func recompute() -> void`:
     - Call `_bridge.compute_flow_field(GridManager.grid_width, GridManager.grid_height, GridManager.cells, GridManager.exit_position)`.
     - Store result in `current_directions`.
     - Set `current_version = _bridge.get_flow_field_version()`.
     - Emit `flow_field_updated(current_version)`.
   - Implement `func get_direction(grid_pos: Vector2i) -> Vector2i`:
     - If `current_directions` is empty, return `Vector2i.ZERO`.
     - Return `current_directions[grid_pos.x + grid_pos.y * GridManager.grid_width]`.
   - Implement `func validate_placement(tentative_cell: Vector2i) -> bool`:
     - Call `_bridge.is_path_valid(...)` passing current GridManager state and `tentative_cell`.
     - Return the bool.
   - Connect to `GridManager.grid_changed` signal in `_ready()` — but do NOT auto-recompute on every grid_changed (only TowerPlacer explicitly calls recompute after confirmed placement).

3. Register FlowFieldManager as an autoload in Project Settings → AutoLoad: `res://autoloads/FlowFieldManager.gd` named `FlowFieldManager`. Place it second in autoload order (after GridManager).
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|failed"</automated>
</task>

<task id="1-01-06" name="Create Hand-Crafted Map01 Resource and Scene">
<objective>Define and save the first playable map as a MapDefinition .tres resource and a Map01.tscn scene that loads it. This satisfies MAP-01 (at least one hand-crafted map), MAP-03 (static objects present), and MAP-04 (static objects create strategic routing constraints).</objective>
<files>
  <create>res://assets/maps/map_01/map_01.tres</create>
  <create>res://scenes/maps/MapBase.tscn</create>
  <create>res://scenes/maps/Map01.tscn</create>
</files>
<implementation>
1. Create `res://assets/maps/map_01/map_01.tres` as a MapDefinition resource in the Godot editor:
   - In the FileSystem dock, right-click `res://assets/maps/map_01/` → New Resource → MapDefinition.
   - Set `map_name = "map_01"`.
   - Set `map_display_name = "The Labyrinth"`.
   - Set `grid_width = 20`, `grid_height = 20` (20×20 grid, 40×40 world units at CELL_SIZE=2).
   - Set `spawn_positions = [Vector2i(0, 10)]` — single spawn on the left edge, middle row.
   - Set `exit_position = Vector2i(19, 10)` — exit on the right edge, middle row.
   - Set `static_object_positions` to create meaningful routing constraints per MAP-04. Use this layout:
     - `Vector2i(4, 6)`, `Vector2i(4, 7)`, `Vector2i(4, 8)` — rock cluster top-center
     - `Vector2i(4, 12)`, `Vector2i(4, 13)`, `Vector2i(4, 14)` — rock cluster bottom-center
     - `Vector2i(10, 4)`, `Vector2i(10, 5)` — ruins mid-left
     - `Vector2i(10, 15)`, `Vector2i(10, 16)` — ruins mid-right
     - `Vector2i(15, 8)`, `Vector2i(15, 9)`, `Vector2i(15, 11)`, `Vector2i(15, 12)` — late-game chokepoint rocks
   - These positions force enemies to route around two fixed rock clusters in the middle thirds of the map, creating natural funnel opportunities for tower placement. Verify via manual inspection that a path from Vector2i(0,10) to Vector2i(19,10) still exists with all static objects present.
   - Save the resource.

2. Create `res://scenes/maps/MapBase.tscn`:
   - Root node: `Node3D` named `MapBase`.
   - Add a child `MeshInstance3D` named `GroundPlane`.
   - Set the mesh to a `PlaneMesh`. Set `size = Vector2(40.0, 40.0)` (matches 20×20 grid at CELL_SIZE=2).
   - Position the ground plane at `Vector3(20.0, 0.0, 20.0)` so it aligns with grid origin at corner (grid cell 0,0 starts at world 0,0).
   - Create a default `StandardMaterial3D` for the ground: color `#3d5a3e` (dark green/grey, Claude's discretion per CONTEXT.md).
   - Add a child `MeshInstance3D` named `GridLines`. Set mesh to a custom `ArrayMesh` (leave empty for now — grid line rendering is a visual polish detail). Mark this node for future population.
   - Save as MapBase.tscn.

3. Create `res://scenes/maps/Map01.tscn`:
   - Create a new scene that inherits from MapBase.tscn (Scene → New Inherited Scene → select MapBase.tscn).
   - Root node is now named `Map01`.
   - Add a child `Node3D` named `StaticObjects`.
   - For each static_object_position defined in map_01.tres, add a `MeshInstance3D` child under StaticObjects:
     - Mesh: `BoxMesh`, size `Vector3(1.8, 1.5, 1.8)` (slightly smaller than cell to leave visual gaps).
     - Position: `GridManager.grid_to_world(pos)` shifted up by `Vector3(0, 0.75, 0)` so the box sits on the ground plane. Since GridManager is not available at scene-edit time, manually calculate: `Vector3(pos.x * 2.0 + 1.0, 0.75, pos.y * 2.0 + 1.0)`.
     - Material: `StandardMaterial3D`, color `#7d6b5a` (stone grey, Claude's discretion).
     - Name each node descriptively: `Rock_4_6`, `Rock_4_7`, etc.
   - Add an exported variable `@export var map_definition: MapDefinition` to the scene's root script (create `Map01.gd` attached to the root node).
   - In `Map01.gd._ready()`: call `GridManager.initialize_from_map(map_definition)`, then call `FlowFieldManager.recompute()`.
   - Assign `map_definition = res://assets/maps/map_01/map_01.tres` in the Inspector.
   - Save as Map01.tscn.
</implementation>
<manual>Open Map01.tscn in the editor. Verify: (1) Ground plane is visible and sized correctly for a 20×20 grid. (2) All static object boxes are positioned on the ground at the correct grid cells. (3) Running the scene calls GridManager.initialize_from_map without errors (check Godot Output panel). (4) After initialization, verify static object cells have passable=false by adding a temporary debug print in Map01.gd._ready().</manual>
</task>

<task id="1-01-07" name="Install GUT Test Framework and Create Test Stub Files">
<objective>Install GUT 9.x (the Godot Unit Testing framework selected in RESEARCH.md) and create all five test stub files with pending() bodies. This establishes the test contract that must be green before Phase 1 is declared done.</objective>
<files>
  <create>res://addons/gut/</create>
  <create>res://tests/test_grid_manager.gd</create>
  <create>res://tests/test_path_validation.gd</create>
  <create>res://tests/test_flow_field.gd</create>
  <create>res://tests/test_wave_controller.gd</create>
  <create>res://tests/test_enemy_manager.gd</create>
</files>
<implementation>
1. Install GUT:
   - In the Godot editor, open the AssetLib tab. Search for "GUT". Install "Gut - Godot Unit Testing" (by bitwes). This places files under `res://addons/gut/`.
   - Alternatively, download `gut_9.x.zip` from `https://github.com/bitwes/Gut/releases` and extract into `res://addons/gut/`.
   - Enable the plugin: Project Settings → Plugins → GUT → Enable.
   - Verify: A "GUT" panel appears in the editor bottom dock.

2. Create `res://tests/test_grid_manager.gd`:
```gdscript
extends GutTest

func before_each():
    pass

func test_cell_initialized_passable():
    pending("not implemented")

func test_tower_placement_marks_cell_impassable():
    pending("not implemented")

func test_static_object_cell_is_impassable():
    pending("not implemented")

func test_spawn_cell_cannot_receive_tower():
    pending("not implemented")

func test_exit_cell_cannot_receive_tower():
    pending("not implemented")
```

3. Create `res://tests/test_path_validation.gd`:
```gdscript
extends GutTest

func before_each():
    pass

func test_open_grid_path_is_valid():
    pending("not implemented")

func test_full_block_is_rejected():
    pending("not implemented")

func test_partial_block_leaves_route_valid():
    pending("not implemented")

func test_corner_block_leaves_route_valid():
    pending("not implemented")

func test_validation_does_not_modify_grid_on_rejection():
    pending("not implemented")
```

4. Create `res://tests/test_flow_field.gd`:
```gdscript
extends GutTest

func before_each():
    pass

func test_exit_cell_direction_is_zero_vector():
    pending("not implemented")

func test_adjacent_to_exit_points_at_exit():
    pending("not implemented")

func test_flow_field_version_increments_on_recompute():
    pending("not implemented")

func test_unreachable_cell_has_zero_direction():
    pending("not implemented")
```

5. Create `res://tests/test_wave_controller.gd`:
```gdscript
extends GutTest

func before_each():
    pass

func test_timed_mode_launches_wave_on_timer():
    pending("not implemented")

func test_player_triggered_mode_does_not_auto_launch():
    pending("not implemented")

func test_player_triggered_mode_launches_on_signal():
    pending("not implemented")

func test_wave_counter_increments_after_wave_clear():
    pending("not implemented")
```

6. Create `res://tests/test_enemy_manager.gd`:
```gdscript
extends GutTest

func before_each():
    pass

func test_enemy_reaches_exit_deducts_life():
    pending("not implemented")

func test_enemy_reads_updated_flow_field_on_version_change():
    pending("not implemented")

func test_enemy_pool_size_matches_wave_definition():
    pending("not implemented")
```

7. Verify the GUT runner can discover and run the stubs:
   - In the GUT panel, click "Run All". All 17 tests should show as "pending" (not failed, not errored).
   - A pending test is a passing test for structural purposes — the suite should exit with code 0.
</implementation>
<automated>godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit 2>&1 | tail -10</automated>
</task>
```

## must_haves

- [ ] GridManager autoload is registered and initializes a 20×20 logical grid from map_01.tres without errors
- [ ] GridCell.State enum has TOWER and STATIC_OBJECT as distinct values (not merged)
- [ ] GridManager.can_place_tower() returns false for SPAWN, EXIT, STATIC_OBJECT, and TOWER cells
- [ ] GridManager.world_to_grid() and grid_to_world() are inverse operations (round-trip test: grid_to_world then world_to_grid returns the original cell)
- [ ] FlowField.cs compiles with zero errors via dotnet build
- [ ] PathValidator.cs compiles with zero errors via dotnet build
- [ ] FlowFieldManager.recompute() completes without crashing after GridManager.initialize_from_map()
- [ ] Map01.tscn loads and calls GridManager.initialize_from_map(map_01.tres) in _ready()
- [ ] map_01.tres has a valid path from spawn Vector2i(0,10) to exit Vector2i(19,10) with all static objects present
- [ ] All five test stub files exist in res://tests/ and GUT discovers them as 17 pending tests
- [ ] GUT headless CLI run exits with code 0 (pending tests do not count as failures)

## verification

Run the full test suite headlessly:
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Expected: 17 tests, all pending. Exit code 0.

Verify C# build:
```
dotnet build
```
Expected: Build succeeded, 0 errors.

Manual checks:
1. Open the Godot editor. Verify no parse errors in the Script tab for GridManager.gd, GridCell.gd, MapDefinition.gd, PathfindingBridge.gd, FlowFieldManager.gd.
2. Open Map01.tscn. Run the scene in the editor (F5 with Map01.tscn as active scene, or set as main scene temporarily). Check the Output panel for no errors.
3. Add a temporary debug print in Map01.gd after initialize_from_map: print the passable state of one static object cell (e.g., Vector2i(4,6)) and one empty cell. Confirm static = false, empty = true.
