---
phase: 01-the-maze-works
plan: 02
subsystem: enemies
tags: [gdscript, godot4, multimesh, wave-controller, resource, enemy-manager]

# Dependency graph
requires:
  - phase: 01-the-maze-works/01
    provides: GridManager (grid_to_world, exit_position, spawn_positions, CELL_SIZE), FlowFieldManager (get_direction, current_version)
provides:
  - EnemyDefinition, SpawnGroupResource, WaveDefinition resource classes
  - Three enemy .tres data files (basic/fast/heavy) with distinct speed and scale
  - Five wave .tres files with escalating difficulty (6/9/7/17/25 enemies)
  - GameState autoload (player_hp, deduct_life, wave_mode, gold stub)
  - EnemyManager autoload (data-pool enemies, MultiMeshInstance3D rendering, flow-field movement)
  - EnemyMultiMesh.tscn (three MultiMeshInstance3D nodes: MMI_Basic, MMI_Fast, MMI_Heavy)
  - WaveController node + WaveController.tscn (TIMED and PLAYER_TRIGGERED modes, coroutine spawning)
affects:
  - 01-the-maze-works/03+ (all future plans use GameState, EnemyManager, WaveController)
  - HUD plan (WaveController signals: wave_started, wave_completed, inter_wave_tick, all_waves_complete)
  - Game scene plan (must instantiate EnemyMultiMesh.tscn and call EnemyManager.initialize())

# Tech tracking
tech-stack:
  added: []
  patterns:
    - GDScript Resource subclasses for data containers (EnemyDefinition, WaveDefinition, SpawnGroupResource)
    - .tres text format for authoring resource instances outside the editor
    - MultiMeshInstance3D data-record pattern: enemies are Dictionaries, not nodes
    - Coroutine-based wave spawning with await get_tree().create_timer()

key-files:
  created:
    - scripts/resources/EnemyDefinition.gd
    - scripts/resources/SpawnGroupResource.gd
    - scripts/resources/WaveDefinition.gd
    - data/enemies/enemy_basic.tres
    - data/enemies/enemy_fast.tres
    - data/enemies/enemy_heavy.tres
    - data/waves/wave_01.tres
    - data/waves/wave_02.tres
    - data/waves/wave_03.tres
    - data/waves/wave_04.tres
    - data/waves/wave_05.tres
    - autoloads/GameState.gd
    - autoloads/EnemyManager.gd
    - scenes/enemies/EnemyMultiMesh.tscn
    - scripts/controllers/WaveController.gd
    - scenes/game/WaveController.tscn
  modified:
    - project.godot (added GameState and EnemyManager autoloads)

key-decisions:
  - "Enemies are Dictionary data records managed by EnemyManager — not scene nodes (ADR-05)"
  - "Four-directional movement only to prevent corner-cutting bugs (ADR-06)"
  - "is_mid_transition guard delays direction re-read until current cell step completes (Risk 3)"
  - "Position jitter ±position_jitter*CELL_SIZE assigned at spawn, held constant per enemy (Risk 8)"
  - "MultiMesh pre-sized to wave max; inactive enemies moved to Vector3(0,-1000,0) (Risk 4)"
  - "wave_mode flag on WaveController (not separate systems) — single bool controls TIMED vs PLAYER_TRIGGERED (ADR-07)"
  - "Send Wave bonus is a no-op stub with TODO comment — no currency system until Phase 2"
  - "EnemyManager._process() returns early when FlowFieldManager.current_version == 0"

patterns-established:
  - "Enemy pool pattern: pre-allocate Dictionary records at wave start, recycle via active flag"
  - "MultiMesh hide pattern: off-screen transform Vector3(0,-1000,0) for inactive instances"
  - "Wave completion: dual counter (spawns_dispatched + spawns_completed) ensures all enemies exit before wave ends"
  - "Resource subclass pattern: class_name + extends Resource + @export fields + .tres data files"

requirements-completed: [ENEMY-01, WAVE-01, WAVE-02]

# Metrics
duration: 25min
completed: 2026-03-09
---

# Phase 1, Plan 02: Enemies and Waves Summary

**EnemyManager autoload with MultiMeshInstance3D data-record pool, three enemy types (basic/fast/heavy), five wave definitions, GameState autoload, and WaveController with TIMED/PLAYER_TRIGGERED modes**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-09
- **Completed:** 2026-03-09
- **Tasks:** 6
- **Files modified:** 17

## Accomplishments
- Full enemy data layer: EnemyDefinition/SpawnGroupResource/WaveDefinition resource classes plus 3 enemy and 5 wave .tres files
- EnemyManager autoload implements data-record pool, per-frame flow-field movement with is_mid_transition guard, position jitter, and MultiMeshInstance3D rendering
- WaveController supports both TIMED (auto-launch on countdown) and PLAYER_TRIGGERED (send_wave() / Spacebar) modes via coroutine spawn scheduling

## Task Commits

Each task was committed atomically:

1. **Task 1-02-01: Resource Classes** - `7524d00` (feat)
2. **Task 1-02-02: Enemy .tres Files** - `8d925f5` (feat)
3. **Task 1-02-03: Wave .tres Files** - `1ce922c` (feat)
4. **Task 1-02-04: GameState Autoload** - `ce41b0a` (feat)
5. **Task 1-02-05: EnemyManager + EnemyMultiMesh.tscn** - `02e42b8` (feat)
6. **Task 1-02-06: WaveController** - `7acdc85` (feat)

## Files Created/Modified
- `scripts/resources/EnemyDefinition.gd` — enemy_id, display_name, speed, scale, mesh, position_jitter
- `scripts/resources/SpawnGroupResource.gd` — enemy_id, count, spawn_interval, delay_from_wave_start
- `scripts/resources/WaveDefinition.gd` — wave_number, groups, inter_wave_delay, get_total_enemy_count()
- `data/enemies/enemy_basic.tres` — Grunt: speed=3.0, scale=0.7
- `data/enemies/enemy_fast.tres` — Skitter: speed=5.0, scale=0.45
- `data/enemies/enemy_heavy.tres` — Brute: speed=1.5, scale=1.1
- `data/waves/wave_01.tres` — 6 basic enemies
- `data/waves/wave_02.tres` — 6 basic + 3 fast (9 total)
- `data/waves/wave_03.tres` — 5 fast + 2 heavy (7 total)
- `data/waves/wave_04.tres` — 8 basic + 6 fast + 3 heavy (17 total)
- `data/waves/wave_05.tres` — 10 fast + 5 heavy + 10 basic (25 total)
- `autoloads/GameState.gd` — player_hp=20, wave_mode, gold stub, deduct_life(), reset(), game_over signal
- `autoloads/EnemyManager.gd` — full enemy pool, flow-field movement, MultiMesh rendering
- `scenes/enemies/EnemyMultiMesh.tscn` — Node3D with MMI_Basic, MMI_Fast, MMI_Heavy (TRANSFORM_3D)
- `scripts/controllers/WaveController.gd` — TIMED/PLAYER_TRIGGERED, coroutine spawning, wave lifecycle
- `scenes/game/WaveController.tscn` — WaveController node with all 5 wave definitions pre-assigned
- `project.godot` — added GameState and EnemyManager to autoload order

## Decisions Made
- Followed plan architecture exactly: enemies as Dictionary records, not scene nodes
- Used `_spawns_dispatched` + `_spawns_completed` dual counters for reliable wave completion detection (plan Note in task 1-02-06 step 8)
- EnemyManager reads `GridManager.CELL_SIZE` with fallback to 2.0 to stay independent of Plan 01 during parallel execution

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- EnemyManager.initialize() must be called from the game scene with an EnemyDefinition array and the EnemyMultiMesh parent node
- WaveController.tscn must be added to the game scene as a child node
- Plan 03+ can connect to WaveController signals (wave_started, wave_completed, inter_wave_tick, all_waves_complete)
- GameState.reset() should be called at game start / restart

---
*Phase: 01-the-maze-works*
*Completed: 2026-03-09*
