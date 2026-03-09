# Project State

## Current Phase
Phase 1 — In Progress

## Phase Status
| Phase | Name | Status | Requirements |
|-------|------|--------|--------------|
| 1 | The Maze Works | In Progress (Plan 01 complete, Plan 02 complete) | CORE-01, CORE-02, CORE-03, MAP-01, MAP-03, MAP-04, WAVE-01, WAVE-02, ENEMY-01, UI-01, UI-02, STEAM-04 |
| 2 | Towers Kill Things | Not Started | DMG-01, DMG-02, DMG-03, ENEMY-02, CORE-04, CORE-05, UI-03, UI-04 |
| 3 | Status Effects & Traps | Not Started | DMG-04, DMG-05, DMG-06, DMG-07, CORE-06, UI-05 |
| 4 | Classes & Synergies | Not Started | CLASS-01, CLASS-02, CLASS-03, CLASS-04, CORE-07, CORE-08 |
| 5 | Bosses & Escalation | Not Started | ENEMY-03, ENEMY-04, ENEMY-05, WAVE-03, WAVE-04, MAP-02 |
| 6 | Roguelite Loop | Not Started | PROG-01, PROG-02, PROG-03, UI-06 |
| 7 | Steam & Polish | Not Started | STEAM-01, STEAM-02, STEAM-03 |

## Completed Requirements
- ENEMY-01 (Plan 02): Three enemy types with distinct speeds (1.5/3.0/5.0) and scales
- WAVE-01 (Plan 02): Timed wave mode implemented in WaveController
- WAVE-02 (Plan 02): Player-triggered mode implemented in WaveController with send_wave() stub

## Plan 02 Complete — Key Outputs
- `autoloads/GameState.gd` — lives=20, wave_mode enum, deduct_life(), game_over signal
- `autoloads/EnemyManager.gd` — data-record enemy pool, MultiMesh rendering, flow-field movement
- `scenes/enemies/EnemyMultiMesh.tscn` — MMI_Basic, MMI_Fast, MMI_Heavy (TRANSFORM_3D)
- `scripts/controllers/WaveController.gd` — TIMED/PLAYER_TRIGGERED, coroutine spawning
- `data/enemies/` — 3 EnemyDefinition .tres files
- `data/waves/` — 5 WaveDefinition .tres files (6/9/7/17/25 enemies)

## Integration Notes
- EnemyManager.initialize() must be called from game scene with enemy defs + EnemyMultiMesh parent
- EnemyManager guards _process() on FlowFieldManager.current_version == 0
- WaveController reads GameState.wave_mode to determine TIMED vs PLAYER_TRIGGERED behavior

## Notes
Initialized: 2026-03-09
Plan 01 complete: 2026-03-09 (GridManager, FlowFieldManager, C# pathfinding, map + GridCell resources)
  Summary: 01-PLAN-foundation-SUMMARY.md created 2026-03-09
  GUT manual setup required: see tests/SETUP.md
Plan 02 complete: 2026-03-09 (EnemyManager, GameState, WaveController, enemy/wave data resources)
