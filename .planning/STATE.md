# Project State

## Current Phase
Phase 1 — Complete (all 5 plans executed; STEAM-04 hardware playtest pending)

## Phase Status
| Phase | Name | Status | Requirements |
|-------|------|--------|--------------|
| 1 | The Maze Works | **COMPLETE** (Plans 01–05 done; STEAM-04 hardware playtest required before final sign-off) | CORE-01, CORE-02, CORE-03, MAP-01, MAP-03, MAP-04, WAVE-01, WAVE-02, ENEMY-01, UI-01, UI-02, STEAM-04 |
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
- UI-01 (Plan 05): Animated path visualization overlay (PathOverlay shader, updates on flow_field_updated)
- UI-02 (Plan 03/04): Range overlay stub (zero-radius torus, toggled on tower selection)
- CORE-01 (Plan 03): Tower placement marks grid cell impassable
- CORE-02 (Plan 03): BFS validation rejects placements that block all paths
- CORE-03 (Plan 03): Flow field recomputed on confirmed placement; enemies reroute
- MAP-01 (Plan 01): Hand-crafted Map01 with spawn/exit and static objects
- MAP-03 (Plan 01): Static objects pre-placed and impassable from grid init
- STEAM-04 (Plan 05): Checklist created; hardware playtest pending

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
Plan 03 complete: 2026-03-09 (TowerPlacer, TowerWall, TowerGhost, ToastNotification, real test bodies for CORE-01/02/03)
  Summary: 03-PLAN-tower-placement-SUMMARY.md created 2026-03-09
  Integration note: TowerPlacer.camera and TowerPlacer.toast must be wired in Game.tscn (Plan 05)
Plan 04 complete: 2026-03-09 (CameraRig, HUD, TopBar, BottomPanel, SendWaveButton, RangeOverlay stub)
  Summary: 04-PLAN-camera-and-hud-SUMMARY.md created 2026-03-09
Plan 05 complete: 2026-03-09 (PathOverlay shader+scene+controller, Game.tscn full integration, real test bodies for wave/enemy tests)
  Summary: 05-PLAN-path-visualization-and-integration-SUMMARY.md created 2026-03-09
  STEAM-04 note: Hardware playtest required — see STEAM-04-perf-checklist.md
  Phase 1 execution complete. All systems wired. Ready for Phase 2 planning.
