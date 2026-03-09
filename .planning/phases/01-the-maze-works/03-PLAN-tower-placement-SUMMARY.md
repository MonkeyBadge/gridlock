# Plan 03: Tower Placement — Summary

**Completed:** 2026-03-09
**Status:** COMPLETE

## What Was Built

### Task 1-03-01: TowerWall and TowerGhost Scenes
- `scenes/towers/TowerWall.tscn` — permanent placed tower: Node3D + MeshInstance3D with BoxMesh (1.8×2.0×1.8), blue-grey StandardMaterial3D (albedo 0.3/0.3/0.45, roughness 0.9), Mesh positioned at Y=1.0 so the base sits on the ground plane.
- `scenes/towers/TowerGhost.tscn` — cursor-following preview: same mesh dimensions, two semi-transparent materials (green alpha=0.5 valid, red alpha=0.5 invalid), hidden by default. Attached `TowerGhost.gd` with `set_valid(bool)` that swaps `material_override`.

### Task 1-03-02: ToastNotification Scene
- `scenes/hud/ToastNotification.tscn` — CanvasLayer (layer=10), PanelContainer anchored top-center, Label with default text "Path blocked — enemies must have a route". Hidden by default.
- `ToastNotification.gd` — `show_message(text)` makes node visible, waits `display_duration` seconds (default 2.0) via tween, then hides. No player input required to dismiss.

### Task 1-03-03: TowerPlacer Controller and Scene
- `scripts/controllers/TowerPlacer.gd` — full implementation:
  - `_update_hover()`: raycasts cursor onto Y=0 plane via manual plane intersection, converts to grid cell, caches last hovered cell to skip BFS on redundant mouse events (Risk 1 mitigation), moves ghost, validates via `GridManager.can_place_tower()` + `FlowFieldManager.validate_placement()`, updates ghost color.
  - `_attempt_place()`: on valid cell commits `GridCell.State.TOWER` to GridManager (CORE-01), calls `FlowFieldManager.recompute()` (CORE-03), spawns TowerWall mesh. On invalid cell shows toast without touching grid state (CORE-02).
  - `activate_placement_mode()` / `deactivate_placement_mode()` for external control.
- `scenes/game/TowerPlacer.tscn` — Node3D with TowerPlacer.gd, ghost_scene and tower_wall_scene pre-assigned. `camera` and `toast` must be wired in Plan 05 when Game.tscn is assembled.

### Task 1-03-04: Real Test Bodies
Replaced all `pending()` stubs with real assertions:
- `tests/test_grid_manager.gd` (5 tests): cell passability, tower placement marks impassable, static object impassable, spawn/exit reject placement.
- `tests/test_path_validation.gd` (5 tests): open grid valid, full column block rejected, partial block leaves route, corner block leaves route, rejection does not mutate grid.
- `tests/test_flow_field.gd` (4 tests): exit cell zero direction, adjacent cell points at exit, version increments on recompute, isolated cell has zero direction.

## Key Architecture Notes
- TowerPlacer uses manual plane intersection (`-from.y / dir.y`) instead of physics raycast — no collision shapes needed on the grid ground.
- BFS cell-change cache: `_last_hover_cell` prevents re-running `FlowFieldManager.validate_placement()` on every `InputEventMouseMotion` event.
- `_attempt_place()` resets `_last_hover_cell` to `(-1,-1)` after placement so the ghost immediately re-validates the next hover position.
- Tests call `_bridge.is_path_valid(w, h, GridManager.cells, spawns, exit, tentative)` — passing the real GridCell array, consistent with PathfindingBridge's actual API.

## Commits
- `feat(1-03-01)`: TowerWall and TowerGhost scenes
- `feat(1-03-02)`: ToastNotification scene
- `feat(1-03-03)`: TowerPlacer controller and scene
- `test(1-03-04)`: CORE-01/02/03 unit and integration tests

## Integration Notes for Plan 05
- `TowerPlacer.camera` must be assigned to the Camera3D in Game.tscn.
- `TowerPlacer.toast` must be assigned to the ToastNotification node in the HUD.
- `activate_placement_mode()` should be called from the HUD tower selection button.
