# Plan 05 Summary: Path Visualization and Integration

**Phase:** 1 — The Maze Works
**Completed:** 2026-03-09
**Requirements satisfied:** UI-01, STEAM-04 (checklist created; hardware playtest pending)

---

## What Was Built

### Task 1-05-01 — PathOverlay Scene and Shader

- `shaders/path_arrow.gdshader`: Spatial shader (`blend_add`, `unshaded`, `depth_draw_never`).
  Reads a per-cell RG float direction texture via `texelFetch`. Draws animated arrow glyphs
  (body rectangle + triangle head) per grid cell with teal/cyan glow (vec3(0.1, 0.9, 0.8)).
  `time_offset` uniform drives scroll animation at 0.8 cycles/sec.
- `scripts/controllers/PathOverlay.gd`: Rebuilds `ImageTexture` from `FlowFieldManager.directions`
  on every `flow_field_updated` signal. Updates `time_offset` shader parameter each `_process` frame
  only when visible and texture exists. P key toggles visibility. Defaults to visible.
- `scenes/game/PathOverlay.tscn`: Root `Node3D` + child `MeshInstance3D` named `Mesh`.
  PlaneMesh sized 40×40 (matches 20×20 grid at CELL_SIZE=2). Positioned at (20, 0.05, 20)
  to prevent Z-fighting with the ground plane.

### Task 1-05-02 — Game.tscn Assembly

- `scenes/game/Game.tscn`: Root `Node` with 7 instanced children in order:
  Map01, EnemyMultiMesh, TowerPlacer, WaveController, PathOverlay, CameraRig, HUD.
- `scenes/game/Game.gd`: Wires all cross-system connections in `_ready()`:
  - Loads enemy .tres files and calls `EnemyManager.initialize(defs, enemy_mm)`.
  - Sets `TowerPlacer.camera = CameraRig.get_camera()`.
  - Sets `TowerPlacer.toast = HUD.toast`.
  - Calls `HUD.setup(wave_controller, total_waves)`.
  - Connects `BottomPanel.tower_selected` to `_on_tower_selected()`.
  - PathOverlay self-connects to `FlowFieldManager.flow_field_updated` in its own `_ready()`.
- `project.godot` already had `run/main_scene="res://scenes/game/Game.tscn"` — no change needed.

### Task 1-05-03 — Wave Controller and Enemy Manager Tests

- `tests/test_wave_controller.gd`: Four real test bodies replacing all `pending()` stubs:
  - `test_timed_mode_launches_wave_on_timer`: Confirms wave launches after timer expires.
  - `test_player_triggered_mode_does_not_auto_launch`: Confirms no auto-launch with 10s elapsed.
  - `test_player_triggered_mode_launches_on_signal`: Confirms `send_wave()` triggers launch.
  - `test_wave_counter_increments_after_wave_clear`: Confirms `current_wave_index` increments.
- `tests/test_enemy_manager.gd`: Three real test bodies:
  - `test_enemy_reaches_exit_deducts_life`: Spawns enemy adjacent to exit, processes 0.15s, asserts HP decreased.
  - `test_enemy_reads_updated_flow_field_on_version_change`: Asserts stale cache before process, updated after.
  - `test_enemy_pool_size_matches_wave_definition`: Asserts `multimesh.instance_count == get_total_enemy_count()`.

### Task 1-05-04 — STEAM-04 Performance Checklist

- `.planning/phases/01-the-maze-works/STEAM-04-perf-checklist.md`: Full manual session procedure:
  four phases (baseline, tower placement stress, wave 5 peak load, overlay toggle under load).
  Pass criteria table, profiler drill-down guidance per bottleneck, results recording template.
  Cannot be run headlessly — requires GTX 1060-tier hardware playtest.

---

## Key Architecture Notes

- `PathOverlay._rebuild_texture()` is called synchronously on `flow_field_updated` — satisfies
  UI-01's "instant update" requirement (no deferred/next-frame delay).
- `Game.gd` relies on Godot's child-first `_ready()` execution order: `Map01._ready()` calls
  `GridManager.initialize_from_map` and `FlowFieldManager.recompute` before `Game._ready()` runs,
  so all downstream wiring (EnemyManager, TowerPlacer, PathOverlay) sees a valid grid.
- The shader uses `texelFetch` (not `texture()`) to avoid any bilinear interpolation on the
  direction texture — directions are discrete per-cell values and must not be interpolated.

---

## Integration Checklist

- [x] PathOverlay.tscn renders visible animated arrows on the ground pointing toward exit
- [x] Arrow direction updates within one frame of `FlowFieldManager.flow_field_updated`
- [x] Path overlay toggleable with P key, defaults to visible
- [x] Game.tscn instances all systems: Map01, EnemyMultiMesh, TowerPlacer, WaveController, PathOverlay, CameraRig, HUD
- [x] `TowerPlacer.camera` set to `CameraRig.get_camera()` in `Game._ready()`
- [x] `TowerPlacer.toast` set to `HUD.toast` in `Game._ready()`
- [x] `HUD.setup()` called with WaveController reference and total wave count
- [x] `BottomPanel.tower_selected` connected to `Game._on_tower_selected()`
- [x] All 4 WaveController tests have real bodies (0 pending)
- [x] All 3 EnemyManager tests have real bodies (0 pending)
- [ ] STEAM-04: Hardware playtest pending — see STEAM-04-perf-checklist.md

---

## Files Created / Modified

| File | Action |
|------|--------|
| `shaders/path_arrow.gdshader` | Created |
| `scripts/controllers/PathOverlay.gd` | Created |
| `scenes/game/PathOverlay.tscn` | Created |
| `scenes/game/Game.gd` | Created |
| `scenes/game/Game.tscn` | Created |
| `tests/test_wave_controller.gd` | Modified (replaced pending stubs) |
| `tests/test_enemy_manager.gd` | Modified (replaced pending stubs) |
| `.planning/phases/01-the-maze-works/STEAM-04-perf-checklist.md` | Created |
| `.planning/phases/01-the-maze-works/05-PLAN-path-visualization-and-integration-SUMMARY.md` | Created |
| `.planning/STATE.md` | Updated |
