# STEAM-04 Performance Baseline Checklist

**Requirement:** Stable 60fps throughout Phase 1 gameplay on GTX 1060-tier hardware.
**Status:** Pending manual execution

---

## Setup

1. Open the project in the Godot 4 editor.
2. Open **Debugger** panel (bottom toolbar or F8).
3. Navigate to the **Monitors** tab. Pin the following metrics:
   - FPS
   - Process Time (ms)
   - Render Draw Calls
4. Ensure `GameState.wave_mode = GameState.WaveMode.TIMED` (default) for auto-launch.

---

## Test Session Procedure

### Phase A — Baseline (wave 1, no towers)

1. Press **F5** to play `res://scenes/game/Game.tscn`.
2. Wait for wave 1 to auto-launch (~inter_wave_delay seconds).
3. Watch the Monitors tab as 6 enemies traverse the grid.
4. Record: **FPS at peak wave 1 simultaneous enemy count**.
5. Press **P** to toggle the path overlay off; record FPS delta.
6. Press **P** again to re-enable the overlay.

### Phase B — Tower Placement Stress (mid-wave 1)

1. While wave 1 is active, press **1** to activate Wall Tower placement mode.
2. Place **5 towers in rapid succession** (one click per second).
3. After each placement, observe the FPS spike in the Monitors panel.
4. Record: **Minimum FPS during the placement frame** (single-frame spike is acceptable).
5. Attempt one **path-blocking placement** (place a tower that seals the route).
   - Verify the ghost turns red and the "Path blocked" toast appears.
   - Confirm FPS does not drop on rejected placements.

### Phase C — Wave 5 Peak Load

1. Allow all 5 waves to run (or press **Space** / **Send Wave** button to advance faster).
2. Wave 5 has 25 enemies. At peak, all 25 may be simultaneously on screen.
3. Record: **Minimum FPS at peak wave 5 simultaneous count**.
4. Record: **Render Draw Calls** in the Monitors tab at peak.

### Phase D — PathOverlay Toggle Under Load

1. During wave 5 peak load, press **P** to toggle the path overlay off.
2. Note the FPS change (expected: marginal, shader is a single draw call).
3. Toggle back on. Note the direction texture rebuild cost (should be sub-frame).

---

## Pass Criteria (STEAM-04)

| Condition | Pass threshold | Acceptable exception |
|-----------|---------------|----------------------|
| Idle (no wave) | >= 60 fps | — |
| Wave 1, 6 enemies, overlay on | >= 60 fps | — |
| Tower placement frame (confirmed) | >= 55 fps | Single-frame spike only; must recover immediately |
| Tower placement frame (rejected) | >= 60 fps | — |
| Wave 5, 25 enemies, overlay on | >= 60 fps | — |
| Path overlay toggle frame | >= 60 fps | Single-frame spike to 55fps acceptable |

---

## Profiler Drill-Down (if FPS drops are found)

Open **Debugger → Profiler** tab, click **Start**, reproduce the drop, click **Stop**.
Look at the following function names and their self-time:

| Symptom | Function to check | Mitigation |
|---------|------------------|------------|
| Drop during hover (cursor moving) | `TowerPlacer._update_hover` | Confirm `_last_hover_cell` cache prevents BFS re-runs when cursor stays in the same cell |
| Drop each frame with 25 enemies | `EnemyManager._process` | Consider batching transform writes into a `PackedFloat32Array` before passing to multimesh |
| Drop during PathOverlay rebuild | `PathOverlay._rebuild_texture` | Expected < 1ms; if higher, check `Image.create` and `ImageTexture.update` call overhead |
| Drop during tower placement | `FlowFieldManager.recompute` | Confirm BFS executes in C# layer (FlowField.cs), not pure GDScript |
| Sustained GPU cost | Render Draw Calls > 30 | Check MultiMeshInstance3D is one draw call per enemy type (should be 3 total for enemies) |

---

## Recording Results

After the session, record results in a comment at the top of `scenes/game/Game.gd`:

```gdscript
## STEAM-04 baseline (date, hardware):
##   Minimum FPS: ___
##   FPS during tower placement: ___
##   Draw calls at peak wave 5: ___
##   Target hardware: ___
```

---

*Phase 1 — Plan 05 — Task 1-05-04*
