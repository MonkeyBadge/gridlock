---
wave: 1
depends_on: []
files_modified:
  - res://scripts/resources/EnemyDefinition.gd
  - res://scripts/resources/WaveDefinition.gd
  - res://scripts/resources/SpawnGroupResource.gd
  - res://data/enemies/enemy_basic.tres
  - res://data/enemies/enemy_fast.tres
  - res://data/enemies/enemy_heavy.tres
  - res://data/waves/wave_01.tres
  - res://data/waves/wave_02.tres
  - res://data/waves/wave_03.tres
  - res://data/waves/wave_04.tres
  - res://data/waves/wave_05.tres
  - res://autoloads/EnemyManager.gd
  - res://autoloads/GameState.gd
  - res://scenes/enemies/EnemyMultiMesh.tscn
  - res://scripts/controllers/WaveController.gd
  - res://scenes/game/WaveController.tscn
  - res://project.godot
autonomous: true
---

# Plan 2: Enemies and Waves

**Phase:** 1 — The Maze Works
**Wave:** 1
**Requirements:** ENEMY-01, WAVE-01, WAVE-02

## Objective

This plan builds the enemy data layer, enemy rendering/movement system, wave data definitions, and wave controller. It runs in parallel with Plan 01 (no dependency on the grid system) because the enemy and wave systems are defined as data resources and manager logic that can be authored independently. The one integration point — enemies reading the flow field — is handled by a guard that skips movement until `FlowFieldManager` reports a valid field (version > 0). By end of this plan, the enemy pool, MultiMesh rendering, wave spawning loop, and both TIMED and PLAYER_TRIGGERED wave modes exist and are testable in isolation.

## Tasks

```xml
<task id="1-02-01" name="Create EnemyDefinition, WaveDefinition, and SpawnGroupResource Classes">
<objective>Define the three data resource classes that describe enemy properties and wave compositions. These are pure data containers — no logic — authored as .tres files in subsequent tasks.</objective>
<files>
  <create>res://scripts/resources/EnemyDefinition.gd</create>
  <create>res://scripts/resources/SpawnGroupResource.gd</create>
  <create>res://scripts/resources/WaveDefinition.gd</create>
</files>
<implementation>
1. Create `res://scripts/resources/EnemyDefinition.gd`:
   - `class_name EnemyDefinition extends Resource`.
   - `@export var enemy_id: String = ""` — unique string identifier (e.g., "basic", "fast", "heavy").
   - `@export var display_name: String = ""`.
   - `@export var speed: float = 3.0` — movement speed in cells per second.
   - `@export var scale: Vector3 = Vector3(1.0, 1.0, 1.0)` — visual scale applied to the MultiMesh instance transform.
   - `@export var mesh: Mesh = null` — reference to the 3D mesh used for this enemy type in MultiMeshInstance3D.
   - `@export var position_jitter: float = 0.3` — sub-tile position jitter factor (±30% of CELL_SIZE per RESEARCH.md Risk 8 mitigation). Applied at spawn time, held constant per enemy.

2. Create `res://scripts/resources/SpawnGroupResource.gd`:
   - `class_name SpawnGroupResource extends Resource`.
   - `@export var enemy_id: String = ""` — matches EnemyDefinition.enemy_id.
   - `@export var count: int = 1` — number of enemies in this group.
   - `@export var spawn_interval: float = 1.0` — seconds between successive enemy spawns within the group.
   - `@export var delay_from_wave_start: float = 0.0` — seconds after wave launch before this group begins spawning.

3. Create `res://scripts/resources/WaveDefinition.gd`:
   - `class_name WaveDefinition extends Resource`.
   - `@export var wave_number: int = 1`.
   - `@export var groups: Array[SpawnGroupResource] = []` — ordered list of spawn groups.
   - Computed property (not exported): `func get_total_enemy_count() -> int`: sum all `group.count` values across groups.
   - `@export var inter_wave_delay: float = 10.0` — seconds before this wave auto-launches (Timed mode) or the suggested countdown shown in the HUD (Player-Triggered mode).
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-02-02" name="Create Enemy Data Resources (Basic, Fast, Heavy)">
<objective>Save the three EnemyDefinition .tres files that define the distinct enemy types required by ENEMY-01. These must have visually distinct speed and scale values so a player can tell them apart without UI labels.</objective>
<files>
  <create>res://data/enemies/enemy_basic.tres</create>
  <create>res://data/enemies/enemy_fast.tres</create>
  <create>res://data/enemies/enemy_heavy.tres</create>
</files>
<implementation>
1. In the Godot editor FileSystem dock, right-click `res://data/enemies/` → New Resource → EnemyDefinition. Create three resources:

2. `res://data/enemies/enemy_basic.tres`:
   - `enemy_id = "basic"`
   - `display_name = "Grunt"`
   - `speed = 3.0` (3 cells per second — baseline)
   - `scale = Vector3(0.7, 0.7, 0.7)` (standard size — fits comfortably within a 2-unit cell)
   - `mesh = null` (placeholder — assign a CapsuleMesh or BoxMesh as a stand-in until assets/enemies/enemy_basic.glb is imported)
   - `position_jitter = 0.3`

3. `res://data/enemies/enemy_fast.tres`:
   - `enemy_id = "fast"`
   - `display_name = "Skitter"`
   - `speed = 5.0` (5 cells per second — visibly faster)
   - `scale = Vector3(0.45, 0.45, 0.45)` (visibly smaller — half the cross-section of basic)
   - `mesh = null` (placeholder — assign a SphereMesh as stand-in)
   - `position_jitter = 0.4` (more jitter to emphasize frantic movement)

4. `res://data/enemies/enemy_heavy.tres`:
   - `enemy_id = "heavy"`
   - `display_name = "Brute"`
   - `speed = 1.5` (1.5 cells per second — visibly slower)
   - `scale = Vector3(1.1, 1.1, 1.1)` (larger than basic — more than double the volume)
   - `mesh = null` (placeholder — assign a BoxMesh as stand-in)
   - `position_jitter = 0.15` (minimal jitter — heavy enemies move deliberately)

5. For the placeholder meshes: create the primitive meshes directly in the resource inspector (click the mesh field → New CapsuleMesh / SphereMesh / BoxMesh). These will be replaced by actual .glb assets in a later polish pass. The important values for Phase 1 are speed and scale — the meshes just need to be non-null so MultiMeshInstance3D renders something.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-02-03" name="Create Five Wave Definition Resources">
<objective>Save five WaveDefinition .tres files that provide increasing difficulty and exercise all three enemy types. These satisfy the "at least 5 waves" requirement from RESEARCH.md and give WAVE-01 and WAVE-02 a meaningful test case.</objective>
<files>
  <create>res://data/waves/wave_01.tres</create>
  <create>res://data/waves/wave_02.tres</create>
  <create>res://data/waves/wave_03.tres</create>
  <create>res://data/waves/wave_04.tres</create>
  <create>res://data/waves/wave_05.tres</create>
</files>
<implementation>
Create each WaveDefinition resource via right-click → New Resource → WaveDefinition in the Godot editor. For each, create SpawnGroupResource instances inline as the `groups` array elements.

1. `res://data/waves/wave_01.tres`:
   - `wave_number = 1`
   - `inter_wave_delay = 15.0`
   - groups:
     - SpawnGroupResource: `enemy_id="basic"`, `count=6`, `spawn_interval=1.5`, `delay_from_wave_start=0.0`

2. `res://data/waves/wave_02.tres`:
   - `wave_number = 2`
   - `inter_wave_delay = 12.0`
   - groups:
     - SpawnGroupResource: `enemy_id="basic"`, `count=6`, `spawn_interval=1.2`, `delay_from_wave_start=0.0`
     - SpawnGroupResource: `enemy_id="fast"`, `count=3`, `spawn_interval=0.8`, `delay_from_wave_start=3.0`

3. `res://data/waves/wave_03.tres`:
   - `wave_number = 3`
   - `inter_wave_delay = 12.0`
   - groups:
     - SpawnGroupResource: `enemy_id="fast"`, `count=5`, `spawn_interval=0.6`, `delay_from_wave_start=0.0`
     - SpawnGroupResource: `enemy_id="heavy"`, `count=2`, `spawn_interval=3.0`, `delay_from_wave_start=2.0`

4. `res://data/waves/wave_04.tres`:
   - `wave_number = 4`
   - `inter_wave_delay = 10.0`
   - groups:
     - SpawnGroupResource: `enemy_id="basic"`, `count=8`, `spawn_interval=1.0`, `delay_from_wave_start=0.0`
     - SpawnGroupResource: `enemy_id="fast"`, `count=6`, `spawn_interval=0.5`, `delay_from_wave_start=2.0`
     - SpawnGroupResource: `enemy_id="heavy"`, `count=3`, `spawn_interval=2.5`, `delay_from_wave_start=4.0`

5. `res://data/waves/wave_05.tres`:
   - `wave_number = 5`
   - `inter_wave_delay = 10.0`
   - groups:
     - SpawnGroupResource: `enemy_id="fast"`, `count=10`, `spawn_interval=0.4`, `delay_from_wave_start=0.0`
     - SpawnGroupResource: `enemy_id="heavy"`, `count=5`, `spawn_interval=2.0`, `delay_from_wave_start=1.0`
     - SpawnGroupResource: `enemy_id="basic"`, `count=10`, `spawn_interval=0.8`, `delay_from_wave_start=3.0`

Total enemies per wave: 6, 9, 7, 17, 25. Peak simultaneous enemies (given ~6-second transit time and 1/s spawn): approximately 6, 9, 7, 17, 25 (since no combat, enemies accumulate). At wave 5, peak on-screen count ~25 — well within the MultiMeshInstance3D budget per RESEARCH.md performance section.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-02-04" name="Create GameState Autoload">
<objective>Implement the GameState singleton that holds the run-level state (lives, current wave index, wave mode). This is the shared state container referenced by WaveController, HUD, and EnemyManager.</objective>
<files>
  <create>res://autoloads/GameState.gd</create>
  <modify>res://project.godot</modify>
</files>
<implementation>
1. Create `res://autoloads/GameState.gd`:
   - `extends Node`.
   - Enum: `enum WaveMode { TIMED, PLAYER_TRIGGERED }`.
   - Variables:
     - `var player_hp: int = 20` — starting lives.
     - `var current_wave_index: int = 0` — zero-based index into the wave definition array.
     - `var wave_mode: WaveMode = WaveMode.TIMED` — default mode; can be changed before game start.
     - `var gold: int = 0` — currency stub (always 0 in Phase 1; Phase 2 will populate).
   - Signals:
     - `signal lives_changed(new_lives: int)`
     - `signal wave_mode_changed(new_mode: WaveMode)`
   - Implement `func deduct_life() -> void`:
     - Decrement `player_hp` by 1.
     - Emit `lives_changed(player_hp)`.
     - If `player_hp <= 0`: emit a `signal game_over` (wire to game-end logic in Plan 05).
   - Implement `func reset() -> void`:
     - Reset all variables to defaults. Used at run start.
   - Add `signal game_over`.

2. Register as autoload in Project Settings → AutoLoad: `res://autoloads/GameState.gd` named `GameState`. Place it third in autoload order (after GridManager, FlowFieldManager).
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-02-05" name="Create EnemyManager Autoload and EnemyMultiMesh Scene">
<objective>Implement the EnemyManager singleton that owns the enemy data pool, drives per-frame movement via the flow field, manages MultiMeshInstance3D rendering for all three enemy types, and handles life deduction on exit reach. This implements ADR-05 (MultiMeshInstance3D), ADR-06 (four-directional movement), and the mid-transition direction-snap mitigation from RESEARCH.md Risk 3.</objective>
<files>
  <create>res://autoloads/EnemyManager.gd</create>
  <create>res://scenes/enemies/EnemyMultiMesh.tscn</create>
  <modify>res://project.godot</modify>
</files>
<implementation>
1. Create `res://scenes/enemies/EnemyMultiMesh.tscn`:
   - Root node: `Node3D` named `EnemyMultiMesh`.
   - Add three `MultiMeshInstance3D` child nodes: `MMI_Basic`, `MMI_Fast`, `MMI_Heavy`.
   - For each MultiMeshInstance3D:
     - Create a new `MultiMesh` resource on the `multimesh` property.
     - Set `MultiMesh.transform_format = MultiMesh.TRANSFORM_3D`.
     - Set `MultiMesh.use_colors = false` (Phase 1 has no status effect tinting).
     - Set `MultiMesh.instance_count = 0` (will be set dynamically per wave).
     - Leave `MultiMesh.mesh` as null for now (EnemyManager sets it from EnemyDefinition.mesh).
   - Save scene.

2. Create `res://autoloads/EnemyManager.gd`:
   - `extends Node`.

3. Define the enemy data structure as an inner Dictionary schema (GDScript has no struct — use Dictionary):
   ```gdscript
   # Enemy record keys:
   # "id": int           — pool index
   # "type_id": String   — matches EnemyDefinition.enemy_id
   # "world_pos": Vector3
   # "grid_pos": Vector2i
   # "direction": Vector2i   — current movement direction
   # "progress": float       — 0.0–1.0 fraction through current cell transition
   # "is_mid_transition": bool  — true while moving between cells (Risk 3 mitigation)
   # "jitter": Vector2      — assigned at spawn, constant per enemy (Risk 8 mitigation)
   # "cached_field_version": int
   # "active": bool
   ```

4. Variables on EnemyManager:
   - `var _enemy_defs: Dictionary = {}` — keyed by enemy_id, value is EnemyDefinition.
   - `var _pools: Dictionary = {}` — keyed by enemy_id, value is Array of enemy record Dictionaries.
   - `var _active_enemies: Array = []` — flat array of active enemy records across all types.
   - `var _multi_mesh_nodes: Dictionary = {}` — keyed by enemy_id, value is MultiMeshInstance3D node ref.
   - Signal: `signal enemy_reached_exit(enemy_record: Dictionary)`.

5. Implement `func initialize(enemy_definitions: Array[EnemyDefinition], multi_mesh_parent: Node) -> void`:
   - For each EnemyDefinition: store in `_enemy_defs[def.enemy_id] = def`.
   - For each enemy_id: locate the corresponding `MMI_*` node under `multi_mesh_parent` by name. Store in `_multi_mesh_nodes`.
   - Set `MultiMesh.mesh` for each MMI from the EnemyDefinition.mesh.

6. Implement `func prepare_wave(wave_def: WaveDefinition) -> void`:
   - Calculate total count per enemy type from wave_def groups.
   - For each type, pre-size the MultiMesh: `mmi.multimesh.instance_count = count_for_type`.
   - Pre-hide all instances: set their transform to `Transform3D(Basis.IDENTITY, Vector3(0, -1000, 0))` (per RESEARCH.md Risk 4 mitigation).
   - Initialize pool records for the wave.

7. Implement `func spawn_enemy(type_id: String, spawn_position: Vector2i) -> void`:
   - Get an inactive record from the pool for this type.
   - Set `active = true`, `world_pos = GridManager.grid_to_world(spawn_position)`.
   - Apply jitter: `jitter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * GridManager.CELL_SIZE * def.position_jitter`.
   - Set `grid_pos = spawn_position`, `direction = FlowFieldManager.get_direction(spawn_position)`.
   - Set `cached_field_version = FlowFieldManager.current_version`.
   - Set `progress = 0.0`, `is_mid_transition = false`.
   - Add to `_active_enemies`.

8. Implement `func _process(delta: float) -> void`:
   - If `FlowFieldManager.current_version == 0`: return early (field not yet computed, per Plan 01 integration).
   - For each active enemy record:
     a. If `not is_mid_transition` and `cached_field_version != FlowFieldManager.current_version`:
        - Update `direction = FlowFieldManager.get_direction(enemy.grid_pos)`.
        - Update `cached_field_version = FlowFieldManager.current_version`.
     b. Advance movement:
        - `var def = _enemy_defs[enemy.type_id]`
        - `enemy.progress += def.speed * delta` (progress in cells per second; progress >= 1.0 means cell completed).
        - While `enemy.progress >= 1.0`:
          - `enemy.progress -= 1.0`
          - Advance `enemy.grid_pos` by `enemy.direction`.
          - Check exit: if `enemy.grid_pos == GridManager.exit_position`:
            - Call `GameState.deduct_life()`.
            - Emit `enemy_reached_exit(enemy)`.
            - Deactivate: `enemy.active = false`. Remove from `_active_enemies`. Hide MultiMesh instance.
            - Break.
          - Set `is_mid_transition = false`.
          - Update direction for next cell: `enemy.direction = FlowFieldManager.get_direction(enemy.grid_pos)`.
        - Compute world position for rendering:
          - Lerp between the previous cell center and next cell center using `enemy.progress`.
          - `var base_pos = GridManager.grid_to_world(enemy.grid_pos)`
          - `var next_pos = base_pos + Vector3(enemy.direction.x, 0, enemy.direction.y) * GridManager.CELL_SIZE`
          - `var render_pos = base_pos.lerp(next_pos, enemy.progress) + Vector3(enemy.jitter.x, 0.5, enemy.jitter.y)`
          - Note: `0.5` Y offset places enemy center above the ground plane.
     c. Update MultiMesh transform for this enemy's instance index:
        - `var t = Transform3D(Basis.IDENTITY.scaled(def.scale), render_pos)`
        - `_multi_mesh_nodes[enemy.type_id].multimesh.set_instance_transform(enemy.id, t)`
   - After processing all enemies, remaining inactive slots already have off-screen transforms from prepare_wave().

9. Register EnemyManager as autoload in Project Settings → AutoLoad: `res://autoloads/EnemyManager.gd` named `EnemyManager`. Place it fourth in autoload order.

Note: EnemyManager._process() movement is intentionally simple in Phase 1 — enemies move in a straight interpolation between cells. The `is_mid_transition` flag for Risk 3 is managed via the while loop: an enemy only reads a new direction after completing a full cell step.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>

<task id="1-02-06" name="Create WaveController">
<objective>Implement the WaveController node (not an autoload — it lives in the game scene) that drives the wave lifecycle: inter-wave countdown or player trigger, spawn scheduling via coroutines, wave completion detection, and mode switching between TIMED and PLAYER_TRIGGERED per ADR-07.</objective>
<files>
  <create>res://scripts/controllers/WaveController.gd</create>
  <create>res://scenes/game/WaveController.tscn</create>
</files>
<implementation>
1. Create `res://scripts/controllers/WaveController.gd`:
   - `extends Node`.
   - Variables:
     - `@export var wave_definitions: Array[WaveDefinition] = []` — assign all 5 wave .tres files in the Inspector.
     - `var current_wave_index: int = 0`
     - `var is_wave_active: bool = false`
     - `var inter_wave_timer: float = 0.0` — countdown value shown in HUD.
     - `var send_wave_pressed: bool = false` — set by UI button or Spacebar input.
     - `var _active_spawn_count: int = 0` — tracks enemies spawned but not yet at exit.
   - Signals:
     - `signal wave_started(wave_number: int)`
     - `signal wave_completed(wave_number: int)`
     - `signal inter_wave_tick(time_remaining: float)`
     - `signal all_waves_complete`

2. Implement `func _ready() -> void`:
   - Connect to `EnemyManager.enemy_reached_exit` signal: call `_on_enemy_reached_exit`.
   - Start the first inter-wave phase: `_begin_inter_wave_phase()`.

3. Implement `func _begin_inter_wave_phase() -> void`:
   - If `current_wave_index >= wave_definitions.size()`:
     - Emit `all_waves_complete`. Return.
   - `var wave_def = wave_definitions[current_wave_index]`
   - `inter_wave_timer = wave_def.inter_wave_delay`
   - `send_wave_pressed = false`
   - `is_wave_active = false`
   - In TIMED mode: `inter_wave_timer` will count down in `_process`.
   - In PLAYER_TRIGGERED mode: timer still counts down for HUD display, but the wave only launches on `send_wave_pressed`.

4. Implement `func _process(delta: float) -> void`:
   - If `is_wave_active`: return (do not countdown during an active wave).
   - `inter_wave_timer = max(0.0, inter_wave_timer - delta)`
   - Emit `inter_wave_tick(inter_wave_timer)`.
   - Launch condition:
     - TIMED mode: `if inter_wave_timer <= 0.0: _launch_wave()`
     - PLAYER_TRIGGERED mode: `if send_wave_pressed: _launch_wave()`

5. Implement `func send_wave() -> void` (called by UI button or Spacebar):
   - `send_wave_pressed = true`
   - # TODO: Phase 2 — award bonus gold if inter_wave_timer > threshold.

6. Implement `func _launch_wave() -> void`:
   - `is_wave_active = true`
   - `var wave_def = wave_definitions[current_wave_index]`
   - `_active_spawn_count = wave_def.get_total_enemy_count()`
   - `GameState.current_wave_index = current_wave_index`
   - `EnemyManager.prepare_wave(wave_def)`
   - Emit `wave_started(wave_def.wave_number)`.
   - Schedule all spawn groups using coroutines:
     ```gdscript
     for group in wave_def.groups:
         _schedule_spawn_group(group)
     ```

7. Implement `func _schedule_spawn_group(group: SpawnGroupResource) -> void`:
   - This is an async function using `await`:
     ```gdscript
     func _schedule_spawn_group(group: SpawnGroupResource) -> void:
         await get_tree().create_timer(group.delay_from_wave_start).timeout
         for i in range(group.count):
             var spawn_pos = GridManager.spawn_positions[0]  # Phase 1: single spawn point
             EnemyManager.spawn_enemy(group.enemy_id, spawn_pos)
             if i < group.count - 1:
                 await get_tree().create_timer(group.spawn_interval).timeout
     ```

8. Implement `func _on_enemy_reached_exit(_enemy_record) -> void`:
   - Decrement `_active_spawn_count`.
   - If `_active_spawn_count <= 0` and all spawns are complete: `_end_wave()`.
   - Note: Use a separate `_spawns_dispatched` counter to track whether all spawn coroutines have finished dispatching. Only call `_end_wave()` when both spawns are fully dispatched AND active_spawn_count is 0.

9. Implement `func _end_wave() -> void`:
   - `is_wave_active = false`
   - `var wave_number = wave_definitions[current_wave_index].wave_number`
   - `current_wave_index += 1`
   - Emit `wave_completed(wave_number)`.
   - `_begin_inter_wave_phase()`

10. Create `res://scenes/game/WaveController.tscn`:
    - Root node: `Node` named `WaveController`.
    - Attach `res://scripts/controllers/WaveController.gd` as the script.
    - In the Inspector, assign all 5 wave definition resources to the `wave_definitions` array.
    - Save scene.
</implementation>
<automated>godot --headless --path . --quit 2>&1 | grep -i "error\|parse"</automated>
</task>
```

## must_haves

- [ ] EnemyDefinition, SpawnGroupResource, and WaveDefinition resource classes exist with correct @export properties
- [ ] Three enemy .tres files exist with distinct speed values (1.5, 3.0, 5.0 cells/sec) and visually distinct scale values
- [ ] Five wave .tres files exist, each with at least one SpawnGroupResource
- [ ] WaveDefinition.get_total_enemy_count() correctly sums counts across all groups
- [ ] GameState autoload exists with player_hp, deduct_life(), and game_over signal
- [ ] EnemyManager autoload exists and compiles without errors
- [ ] EnemyManager._process() guards against running when FlowFieldManager.current_version == 0
- [ ] WaveController in TIMED mode: inter_wave_timer counts down in _process and launches the wave at 0
- [ ] WaveController in PLAYER_TRIGGERED mode: does NOT auto-launch; only launches when send_wave_pressed = true
- [ ] WaveController.send_wave() contains a TODO comment for Phase 2 bonus gold
- [ ] EnemyMultiMesh.tscn exists with three MultiMeshInstance3D child nodes named MMI_Basic, MMI_Fast, MMI_Heavy
- [ ] MultiMesh.transform_format is set to TRANSFORM_3D on all three MultiMeshInstance3D nodes

## verification

Run the full test suite headlessly (stubs only at this stage — should still pass as pending):
```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Manual checks:
1. Open each .tres file in the Godot inspector. Verify the exported fields are populated with correct values.
2. Open WaveController.tscn. Verify all 5 wave_definitions slots in the Inspector are assigned.
3. In the Script tab, open WaveController.gd. Confirm `send_wave()` has the `# TODO: Phase 2` comment.
4. Open EnemyManager.gd. Confirm the `if FlowFieldManager.current_version == 0: return` guard is present in `_process`.
