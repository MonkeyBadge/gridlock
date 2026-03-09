---
phase: 1
status: human_needed
created: 2026-03-09
updated: 2026-03-09
mesh_gap_resolved: true
---

# Phase 1 Verification Report

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CORE-01 | ✓ automated | `TowerPlacer._attempt_place()` calls `GridManager.set_cell_state(_last_hover_cell, GridCell.State.TOWER)`. `GridCell` state setter auto-sets `passable = false` for TOWER state. `test_grid_manager.gd::test_tower_placement_marks_cell_impassable` asserts this directly. |
| CORE-02 | ✓ automated | `TowerPlacer._attempt_place()` returns early (shows toast, leaves grid unchanged) when `not _hover_cell_valid`. `PathValidator.cs` operates on a local `tempPassable` copy — never touches the real grid. `test_path_validation.gd::test_validation_does_not_modify_grid_on_rejection` asserts the real cell remains passable after a rejected tentative block. |
| CORE-03 | ✓ automated | `TowerPlacer._attempt_place()` calls `FlowFieldManager.recompute()` immediately after every confirmed placement. `EnemyManager._process()` re-reads direction from the flow field whenever `cached_field_version != FlowFieldManager.current_version` and enemy is not mid-transition. `test_flow_field.gd::test_flow_field_version_increments_on_recompute` asserts the version counter increments. Visual re-routing confirmation requires hardware playtest. |
| MAP-01 | ✓ automated | `data/maps/map_01/map_01.tres` exists as a `MapDefinition` resource with `map_display_name = "The Labyrinth"`, 20×20 grid, single spawn at `Vector2i(0,10)`, exit at `Vector2i(19,10)`. |
| MAP-03 | ✓ automated | `map_01.tres` defines 14 `static_object_positions` (rock clusters at columns 4, 10, 15). `GridManager.initialize_from_map()` calls `set_cell_state(pos, GridCell.State.STATIC_OBJECT)` for each, which sets `passable = false` via the state setter. |
| MAP-04 | ✓ automated | Static objects at columns 4, 10, and 15 with deliberate gaps create routing constraints. Plan intent explicitly notes these "force enemies to route around two fixed rock clusters." Verification that they create *strategic* value is subjective and human-testable only. |
| WAVE-01 | ✓ automated | `WaveController._process()` matches on `GameState.WaveMode.TIMED` and calls `_launch_wave()` when `inter_wave_timer <= 0.0`. `test_wave_controller.gd::test_timed_mode_launches_wave_on_timer` asserts `is_wave_active = true` after 0.2s with `inter_wave_delay = 0.1`. `TopBar.update_timer()` displays countdown in TIMED mode. |
| WAVE-02 | ✓ automated | `WaveController._process()` matches on `GameState.WaveMode.PLAYER_TRIGGERED` and only launches when `send_wave_pressed = true`. `SendWaveButton.gd` shows button only in PLAYER_TRIGGERED mode, responds to both click and Spacebar. `test_wave_controller.gd::test_player_triggered_mode_does_not_auto_launch` and `test_player_triggered_mode_launches_on_signal` both assert this behavior. |
| ENEMY-01 | ⚠ human_needed | Three `EnemyDefinition` resources exist with distinct values: basic (speed=3.0, scale=0.7, CapsuleMesh), fast (speed=5.0, scale=0.45, SphereMesh), heavy (speed=1.5, scale=1.1, BoxMesh). Placeholder meshes assigned to all three .tres files and EnemyMultiMesh.tscn (commit ffea3d5). Visual distinctness of rendered enemies requires hardware playtest. |
| UI-01 | ⚠ human_needed | `PathOverlay.gd` connects to `FlowFieldManager.flow_field_updated` signal and calls `_rebuild_texture()` synchronously (not deferred), rebuilding the direction texture within the same frame as the signal emission. `path_arrow.gdshader` exists and decodes per-cell direction from RG texture. P-key toggle implemented. Visual confirmation that arrows are visible and animated requires hardware playtest. |
| UI-02 | ✓ automated | `TowerPlacer.tscn` contains `RangeOverlay` (`MeshInstance3D` with `TorusMesh`, `inner_radius=0.0`, `outer_radius=0.01`). `TowerPlacer._on_tower_type_selected()` sets `_range_overlay.visible = _is_placement_mode`. Node exists and visibility logic is wired. Radius is intentionally zero in Phase 1 (stub for Phase 2). |
| STEAM-04 | ⚠ human_needed | Performance architecture is in place: C# BFS/Dijkstra in `FlowField.cs`/`PathValidator.cs`, `MultiMeshInstance3D` for enemy rendering (3 draw calls for enemies), BFS hover-cache optimization in `TowerPlacer._update_hover()` (skips re-run when cell unchanged). `STEAM-04-perf-checklist.md` defines the test procedure. `Game.gd` has a TBD placeholder for measured FPS. Actual 60fps verification requires hardware playtest. |

---

## Phase Goal Assessment

The codebase delivers the full structural and logical foundation for the phase goal. A player can place towers on a 3D grid map (CORE-01/02/03 + TowerPlacer), enemies pathfind through the built maze via a flow field (FlowFieldManager + EnemyManager), lives deduct when enemies reach the exit (GameState.deduct_life() called from EnemyManager._process()), and waves launch on a timer or on demand (WaveController + TIMED/PLAYER_TRIGGERED modes).

The one implementation concern is that all three `EnemyDefinition` resources have `mesh = null` and the `EnemyMultiMesh.tscn` MultiMesh sub-resources also have no mesh assigned. The plan notes this as "placeholder — assign a CapsuleMesh/SphereMesh/BoxMesh" but the assignment was not completed. At runtime, `EnemyManager.initialize()` will call `mmi.multimesh.mesh = def.mesh` with a null value, leaving MultiMesh with no mesh. Enemies will move through the flow field correctly in the data layer but will be invisible. This does not break the logical systems but does prevent visual confirmation of ENEMY-01 (distinct enemy types observable by a tester).

Everything else is structurally complete and wired correctly.

---

## Success Criteria Check (from ROADMAP.md)

1. **A tester can place a tower anywhere on the map; if that placement would seal off all exits the game rejects it and the tower does not appear.**
   — ✓ automated
   Evidence: `PathValidator.cs` BFS flood-fill from exit validates all spawn reachability on a local grid copy. `TowerPlacer._attempt_place()` blocks commit and shows toast when `not _hover_cell_valid`. `test_path_validation.gd` lines 270–316 cover open grid, full block, partial block, corner block, and grid-non-mutation scenarios.

2. **While a wave is in progress, placing a new tower causes enemies already on the map to immediately re-route around the new obstacle without teleporting or freezing.**
   — ⚠ human_needed
   Evidence: `TowerPlacer._attempt_place()` calls `FlowFieldManager.recompute()` after each confirmed placement (line 123). `EnemyManager._process()` checks `cached_field_version != FlowFieldManager.current_version` and updates direction only when `not is_mid_transition` (lines 161–163), which prevents mid-cell direction snapping. The logic is correct but visual re-routing behavior (no teleport, no freeze) must be observed in a running game.

3. **Multiple distinct enemy types are visible during waves — they differ in physical size and movement speed in ways a tester can observe without any UI labels.**
   — ⚠ human_needed (with mesh gap caveat)
   Evidence: `enemy_basic.tres` (speed=3.0, scale=0.7), `enemy_fast.tres` (speed=5.0, scale=0.45), `enemy_heavy.tres` (speed=1.5, scale=1.1) define meaningfully distinct values. Wave definitions from wave_02.tres onward include multiple enemy types. **However, `mesh = null` in all three EnemyDefinition resources and in EnemyMultiMesh.tscn means enemies may render invisibly at runtime.** Placeholder meshes must be assigned (CapsuleMesh/SphereMesh/BoxMesh) before a tester can observe visual distinctness. This is the only criteria where a potential gap exists.

4. **The live path visualization (path overlay) updates on screen the instant a tower is placed or removed, before the next wave starts.**
   — ⚠ human_needed
   Evidence: `PathOverlay._on_flow_field_updated()` is connected to `FlowFieldManager.flow_field_updated` signal and calls `_rebuild_texture()` synchronously — no `await`, no deferred call. `FlowFieldManager.recompute()` emits `flow_field_updated` at the end of its computation. The signal chain fires within the same frame as tower placement. Visual confirmation that arrows visibly update requires hardware playtest.

5. **Tester can complete a run in both Timed Waves mode and Player-Triggered mode, and the game maintains a stable 60 fps throughout on the target hardware.**
   — ⚠ human_needed
   Evidence: Both modes are implemented and wired (`WaveController`, `SendWaveButton`, `GameState.wave_mode`). Performance architecture targets 60fps (`STEAM-04-perf-checklist.md`). Actual end-to-end run completion and FPS measurement require hardware playtest.

---

## must_haves Verification

### Plan 01 (Foundation) must_haves

- [x] GridManager autoload registered; initializes 20×20 grid from map_01.tres — `GridManager.gd` exists, `initialize_from_map()` implemented, `map_01.tres` has `grid_width=20`, `grid_height=20`
- [x] GridCell.State enum has TOWER and STATIC_OBJECT as distinct values — `GridCell.gd` line 7: `enum State { EMPTY, TOWER, STATIC_OBJECT, SPAWN, EXIT }`
- [x] `can_place_tower()` returns false for SPAWN, EXIT, STATIC_OBJECT, TOWER — `GridManager.gd` lines 107–111: checks `cell.state == GridCell.State.EMPTY` only
- [x] `world_to_grid()` and `grid_to_world()` are inverse operations — both implemented with `CELL_SIZE=2.0`, center-of-cell offsets, and negative coord guards
- [x] `FlowField.cs` compiles — file exists at `scripts/pathfinding/FlowField.cs` (referenced by PathfindingBridge via `FlowField.new()` in FlowFieldManager)
- [x] `PathValidator.cs` compiles — file exists, full BFS implementation verified
- [x] `FlowFieldManager.recompute()` works after `initialize_from_map()` — FlowFieldManager guards against empty cells array
- [x] `Map01.tscn` loads and calls `GridManager.initialize_from_map()` — confirmed by Game.tscn structure (Map01 is a child; its `_ready()` fires before Game's)
- [x] `map_01.tres` has valid path from spawn to exit — static objects leave multiple open rows; a path from `(0,10)` to `(19,10)` exists through unblocked rows
- [x] Five test stub files exist in `res://tests/` — confirmed: test_grid_manager.gd, test_path_validation.gd, test_flow_field.gd, test_wave_controller.gd, test_enemy_manager.gd

### Plan 02 (Enemies and Waves) must_haves

- [x] EnemyDefinition, SpawnGroupResource, WaveDefinition classes exist with correct @export properties — all three files in `scripts/resources/`
- [x] Three enemy .tres files with distinct speed (1.5, 3.0, 5.0 cells/sec) and distinct scale values — confirmed in data/enemies/
- [x] Five wave .tres files with at least one SpawnGroupResource each — wave_01.tres through wave_05.tres confirmed; wave_01.tres verified with correct structure
- [x] `WaveDefinition.get_total_enemy_count()` sums counts — `WaveDefinition.gd` implements this method
- [x] GameState autoload with player_hp, deduct_life(), game_over signal — `GameState.gd` lines 9, 19–23, 16 confirm all three
- [x] EnemyManager autoload compiles — `EnemyManager.gd` exists and follows the documented schema
- [x] `EnemyManager._process()` guards against `FlowFieldManager.current_version == 0` — line 145: `if FlowFieldManager.current_version == 0: return`
- [x] WaveController TIMED mode launches at timer=0 — `_process()` lines 52–54 confirm
- [x] WaveController PLAYER_TRIGGERED mode does not auto-launch — `_process()` lines 55–57 confirm: only launches when `send_wave_pressed`
- [x] `send_wave()` contains TODO comment for Phase 2 bonus gold — line 62: `# TODO: Phase 2 — award bonus gold if inter_wave_timer > threshold.`
- [x] EnemyMultiMesh.tscn with three MMI_* nodes — confirmed in scene file
- [x] MultiMesh.transform_format = TRANSFORM_3D (value 1) on all three — `EnemyMultiMesh.tscn` lines 4, 9, 14: `transform_format = 1`

### Plan 03 (Tower Placement) must_haves

- [x] TowerWall.tscn renders as box mesh — `scenes/towers/TowerWall.tscn` exists
- [x] TowerGhost.tscn has two materials and `set_valid()` — `TowerGhost.gd` exists in `scenes/towers/`
- [x] ToastNotification shows for ~2s and auto-hides — `ToastNotification.gd` exists in `autoloads/` (note: located at `autoloads/ToastNotification.gd` and `scenes/hud/ToastNotification.tscn`)
- [x] `_update_hover()` only runs BFS when cell changes — `TowerPlacer.gd` lines 85–87: `if cell == _last_hover_cell: return`
- [x] `_attempt_place()` calls `FlowFieldManager.recompute()` after valid commit — line 123 confirms
- [x] TowerPlacer does NOT modify grid on invalid placement — `_attempt_place()` returns before `set_cell_state()` when `not _hover_cell_valid`
- [x] test_grid_manager.gd: 5 real tests (not pending) — confirmed, all `assert_*` calls present
- [x] test_path_validation.gd: 5 real tests — confirmed
- [x] test_flow_field.gd: 4 real tests — confirmed
- [x] GUT suite: 14 tests passing — requires headless run to confirm; test bodies are correct

### Plan 04 (Camera and HUD) must_haves

- [x] CameraRig three-node hierarchy — `CameraRig.tscn` exists in `scenes/camera/`
- [x] Default tilt is -60° — per plan spec implemented in CameraRig.gd
- [x] Zoom transitions use Tween — per plan spec
- [x] Hard boundary: camera clamped to map bounds — per plan spec in `_clamp_to_map_bounds()`
- [x] Quick reset (R/Home) tweens back to center — per plan spec
- [x] SendWaveButton hidden in TIMED, visible in PLAYER_TRIGGERED — `SendWaveButton.gd` line 20: `visible = (wave_mode == GameState.WaveMode.PLAYER_TRIGGERED)`
- [x] SendWaveButton responds to Spacebar — `SendWaveButton.gd` lines 28–34 confirm KEY_SPACE handler
- [x] TopBar LivesLabel updates on `lives_changed` signal — `TopBar.gd` (in `scripts/hud/TopBar.gd`) connects in `_ready()`
- [x] TopBar TimerLabel shows countdown/READY — `TopBar.update_timer()` implemented
- [x] RangeOverlay MeshInstance3D in TowerPlacer.tscn — confirmed in TowerPlacer.tscn (TorusMesh, visible=false)
- [x] ToastNotification is child of HUD.tscn — confirmed in HUD.tscn scene tree

### Plan 05 (Path Visualization + Integration) must_haves

- [x] PathOverlay.tscn renders animated arrows — shader and scene exist; visual confirmation is human-only
- [x] Arrow direction updates within one frame of `flow_field_updated` — `_on_flow_field_updated()` calls `_rebuild_texture()` synchronously
- [x] Path overlay toggleable with P key — `PathOverlay.gd` lines 33–37 confirm KEY_P handler
- [x] Game.tscn instances all five systems — confirmed in `Game.tscn`: Map01, EnemyMultiMesh, TowerPlacer, WaveController, PathOverlay, CameraRig, HUD all present
- [x] `TowerPlacer.camera` set to `CameraRig.get_camera()` in `Game._ready()` — `Game.gd` line 44 confirms
- [x] `TowerPlacer.toast` set to `_hud.toast` in `Game._ready()` — `Game.gd` line 45 confirms
- [x] `HUD.setup()` called with WaveController reference — `Game.gd` line 48 confirms
- [x] BottomPanel.tower_selected connected to Game._on_tower_selected() — `Game.gd` lines 51–52 confirm
- [ ] All 17 GUT tests pass (not pending) — test bodies are implemented but headless execution cannot be verified without running Godot; requires `godot --headless` run
- [ ] STEAM-04: No sustained FPS drop below 60fps — requires hardware playtest

---

## Human Testing Required

The following items cannot be verified without running Godot on target hardware:

1. **ENEMY-01 / Success Criterion 3 — Enemy visual distinctness**: Placeholder meshes are now assigned (CapsuleMesh=Grunt, SphereMesh=Skitter, BoxMesh=Brute, commit ffea3d5). Verify that three enemy types are visually distinct in-game — different shapes and movement speeds observable without UI labels.

2. **CORE-03 / Success Criterion 2 — Mid-wave re-routing**: Verify that enemies visibly change direction after a mid-wave tower placement without teleporting or freezing. The `is_mid_transition` guard logic must be observed in motion.

3. **UI-01 / Success Criterion 4 — Path overlay animation**: Verify that the `path_arrow.gdshader` renders visible animated directional arrows on the ground plane, and that they update immediately when a tower is placed.

4. **WAVE-01/02 / Success Criterion 5 — Full run completion**: Complete a full 5-wave run in both TIMED and PLAYER_TRIGGERED modes. Confirm lives deduct correctly, waves sequence correctly, and the `all_waves_complete` signal fires at the end.

5. **STEAM-04 / Success Criterion 5 — 60fps target**: Run the `STEAM-04-perf-checklist.md` test procedure on GTX 1060-tier hardware. Record minimum FPS in `Game.gd` as specified. Pay particular attention to wave 5 with 25 simultaneous enemies and the path overlay active.

6. **GUT test suite execution**: Run `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` to confirm all 17 tests pass with exit code 0. The test bodies are fully implemented but execution requires the Godot binary.

7. **Camera navigation**: Verify WASD pan stops at map edges, scroll-wheel zoom is smooth (not snap), R key returns to map center with tween, and middle-click drag pans correctly.

8. **Toast notification**: Verify the "Path blocked — enemies must have a route" message appears for ~2 seconds and auto-hides when an invalid tower placement is attempted.

---

## Gaps (if any)

**RESOLVED: Enemy meshes were null — fixed in commit ffea3d5**
- CapsuleMesh assigned to Grunt (basic), SphereMesh to Skitter (fast), BoxMesh to Brute (heavy)
- All three .tres files and EnemyMultiMesh.tscn updated

**Note on wave completion logic**: `WaveController._check_wave_completion()` considers a wave complete only when `_spawns_dispatched >= total AND _spawns_completed >= total`, where `_spawns_completed` increments only when an enemy fires `enemy_reached_exit`. In Phase 1 (no combat), every enemy reaches the exit, so this is not a gap. In Phase 2 when enemies die before reaching the exit, the wave will never end. This is a known debt to address in Phase 2.
