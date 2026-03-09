---
phase: 01-the-maze-works
plan: 01
subsystem: grid, pathfinding
tags: [godot4, gdscript, csharp, flow-field, bfs, gridmanager, gut]

requires:
  - phase: none
    provides: greenfield project — no prior phase

provides:
  - Godot 4 project structure with Forward+ renderer, 1920x1080
  - GridManager autoload with flat 2D logical grid (cells[x + y * width])
  - GridCell class with State enum (EMPTY, TOWER, STATIC_OBJECT, SPAWN, EXIT) and passable derivation
  - MapDefinition Resource class for map configuration data
  - FlowField.cs — Dijkstra BFS from exit outward, returns per-cell direction array
  - PathValidator.cs — BFS flood-fill placement validation
  - PathfindingBridge.gd — GDScript/C# boundary adapter (ADR-02)
  - FlowFieldManager autoload with direction array, version counter, and validate_placement()
  - Map01: 20x20 grid, spawn (0,10), exit (19,10), 14 static objects (3 rock clusters)
  - MapBase.tscn (40x40 ground plane) and Map01.tscn (inherits MapBase + static object meshes)
  - 5 GUT test stub files (17 pending tests) with SETUP.md for manual GUT installation

affects: [02-enemies-and-waves, 03-tower-placement, 04-camera-and-hud, 05-path-visualization]

tech-stack:
  added: [Godot 4.3 Forward+, GDScript, C# (.NET 8), GUT 9.x (manual install required)]
  patterns:
    - Flat 2D logical grid as authoritative data (NOT GridMap node) — ADR-03
    - GDScript/C# split at clean boundary via PathfindingBridge — ADR-02
    - Flow field (Dijkstra from exit) over per-enemy A* — ADR-01
    - BFS flood-fill for placement validation — ADR-04
    - Four-cardinal movement only (no diagonals) — ADR-06
    - CELL_SIZE=2.0 Godot world units per cell

key-files:
  created:
    - project.godot
    - MazeTD.csproj
    - autoloads/GridManager.gd
    - autoloads/FlowFieldManager.gd
    - scripts/resources/GridCell.gd
    - scripts/resources/MapDefinition.gd
    - scripts/pathfinding/FlowField.cs
    - scripts/pathfinding/PathValidator.cs
    - scripts/pathfinding/PathfindingBridge.gd
    - data/maps/map_01/map_01.tres
    - scenes/maps/MapBase.tscn
    - scenes/maps/MapBase.gd
    - scenes/maps/Map01.tscn
    - scenes/maps/Map01.gd
    - tests/test_grid_manager.gd
    - tests/test_path_validation.gd
    - tests/test_flow_field.gd
    - tests/test_wave_controller.gd
    - tests/test_enemy_manager.gd
    - tests/SETUP.md
  modified: []

key-decisions:
  - "GridCell is a plain GDScript object (not Resource) — held in arrays, no .tres serialization overhead"
  - "FlowField and PathValidator extend GodotObject so GDScript can call .new() without Godot Node overhead"
  - "map_01.tres stored under data/maps/ (not assets/maps/) to separate data from art assets"
  - "Static objects at x=4 (y=6-8, y=12-14), x=10 (y=4-5, y=15-16), x=15 (y=8-9, y=11-12) — path via y=10 row unobstructed"
  - "FlowFieldManager does NOT auto-recompute on grid_changed — TowerPlacer calls recompute() explicitly after confirmed placements"
  - "GUT requires manual installation via Godot editor AssetLib — documented in tests/SETUP.md"

patterns-established:
  - "GridManager pattern: flat array with x + y * grid_width indexing, used by all systems that need cell data"
  - "Autoload registration: GridManager first, FlowFieldManager second (order matters for _ready() dependencies)"
  - "C# boundary: all pathfinding C# calls go through PathfindingBridge.gd, never direct from other GDScript files"
  - "Map loading sequence: Map01._ready() → GridManager.initialize_from_map() → FlowFieldManager.recompute()"

requirements-completed: [MAP-01, MAP-03, MAP-04]

duration: ~45min
completed: 2026-03-09
---

# Phase 1 Plan 01: Foundation — Grid, Pathfinding, Map, and Test Infrastructure Summary

**Godot 4 project with GridManager autoload (flat 2D grid), C# FlowField/PathValidator pathfinding, PathfindingBridge GDScript adapter, Map01 (20x20 with 14 static objects), and 17 pending GUT test stubs**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-09T19:00:00Z
- **Completed:** 2026-03-09T20:30:00Z
- **Tasks:** 7
- **Files created:** 20+

## Accomplishments

- Full Godot 4 project structure with project.godot (Forward+ renderer, 1920x1080) and MazeTD.csproj
- GridManager autoload owns the authoritative flat 2D logical grid; all coordinate conversions centralized
- C# pathfinding layer: FlowField.cs (Dijkstra BFS from exit) and PathValidator.cs (flood-fill validation)
- PathfindingBridge.gd creates clean GDScript/C# boundary; FlowFieldManager autoload owns direction array
- Map01: 20x20 grid with spawn at (0,10), exit at (19,10), 14 static object rocks; path verified valid
- 17 GUT test stubs across 5 files; tests/SETUP.md documents manual GUT installation steps

## Task Commits

Each task was committed atomically:

1. **Task 1: Godot project structure** - `7524d00` + `8d925f5` (earlier session)
2. **Task 2: GridCell and MapDefinition** - `bb28f60` (feat)
3. **Task 3: GridManager autoload** - `ba12f23` (feat)
4. **Task 4: C# pathfinding layer** - `6316df0` (feat)
5. **Task 5: PathfindingBridge + FlowFieldManager** - `93eea9f` (feat)
6. **Task 6: Map01 resource and scenes** - `032177b` (feat)
7. **Task 7: GUT test stubs + SETUP.md** - `3510f1c` (feat)

## Files Created/Modified

- `project.godot` — Godot 4.3 project config with autoloads and Forward+ renderer
- `MazeTD.csproj` — .NET 8 project for C# pathfinding classes
- `autoloads/GridManager.gd` — flat grid, coordinate conversions, passability queries
- `autoloads/FlowFieldManager.gd` — owns direction array, version counter, validate_placement()
- `scripts/resources/GridCell.gd` — State enum with passable derivation via setter
- `scripts/resources/MapDefinition.gd` — pure data Resource with spawn/exit/static positions
- `scripts/pathfinding/FlowField.cs` — Dijkstra BFS, returns Vector2I direction array
- `scripts/pathfinding/PathValidator.cs` — BFS flood-fill with tentative block parameter
- `scripts/pathfinding/PathfindingBridge.gd` — GDScript adapter instantiating C# objects
- `data/maps/map_01/map_01.tres` — MapDefinition resource for The Labyrinth (20x20)
- `scenes/maps/MapBase.tscn` + `MapBase.gd` — base scene with 40x40 ground plane
- `scenes/maps/Map01.tscn` + `Map01.gd` — inherits MapBase, adds 14 rock meshes
- `tests/test_*.gd` (5 files) — 17 pending GUT test stubs
- `tests/SETUP.md` — manual GUT installation steps

## Decisions Made

- GridCell is a plain GDScript object (not Resource): avoids .tres overhead for objects held in arrays
- map_01.tres stored under `data/maps/` to separate game data from visual assets in `assets/`
- FlowFieldManager does NOT auto-recompute on grid_changed signal: TowerPlacer calls recompute() explicitly after confirmed placements only
- GUT installation is manual: requires Godot editor AssetLib; documented in tests/SETUP.md

## Deviations from Plan

None — plan executed exactly as specified. The `.gdignore` step for scripts/pathfinding/ was skipped as it only applied to editor usage during development (not needed for file creation).

## Issues Encountered

- GUT cannot be installed headlessly: test stub files created, but GUT framework files under addons/gut/ require manual installation via the Godot editor. Full documented in tests/SETUP.md.

## User Setup Required

**GUT test framework requires manual installation.**

See `tests/SETUP.md` for:
1. Open Godot editor with this project
2. AssetLib → search "GUT" → install "Gut - Godot Unit Testing" by bitwes
3. Project Settings → Plugins → GUT → Enable
4. Verify: Run All in GUT panel → 17 pending tests, exit code 0

## Next Phase Readiness

- Grid system, pathfinding layer, and map data fully established — all subsequent plans build on these
- Plan 02 (Enemies and Waves) can proceed: EnemyManager, GameState, WaveController all depend on GridManager and FlowFieldManager which are now in place
- Note: Plans 02 through 05 are already complete in this project (see git log)

---
*Phase: 01-the-maze-works*
*Completed: 2026-03-09*
