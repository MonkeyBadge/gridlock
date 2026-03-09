# Phase 1: The Maze Works — Research

**Date:** 2026-03-09
**Status:** RESEARCH COMPLETE

---

## Architecture Decision Record

### ADR-01: Flow Field over Per-Enemy A* (User Decision — Final)

The user has committed to a flow field (Dijkstra from exit outward) rather than per-enemy A*. This decision is recorded in CONTEXT.md as an established pattern and supersedes the alternative considered in STACK.md. The flow field approach computes one shared direction map per grid state; all enemies read from it rather than each running independent path queries. This is the correct architecture when all enemies share the same goal (the exit), as it reduces the recalculation cost from O(enemy_count × grid_size) to O(grid_size) per tower placement.

**Implication for Phase 1:** The C# pathfinding layer must implement Dijkstra from the exit outward, not AStarGrid2D per-enemy. The `AStarGrid2D` class can still be used internally to drive the BFS/Dijkstra computation if convenient, but the output is a direction-per-cell map, not a per-enemy path sequence.

### ADR-02: GDScript + C# Split

GDScript handles all gameplay logic (tower placement UI, wave controller, HUD, enemy state). C# handles the pathfinding layer (flow field computation, BFS validation). The boundary is clean: the C# layer exposes a simple API that GDScript calls — `ComputeFlowField(grid)`, `IsPathValid(grid, targetCell)` — and returns direction arrays that GDScript-driven enemies consume. Do not let the split grow beyond this boundary in Phase 1.

### ADR-03: Flat 2D Logical Grid with 3D Visual Representation

The grid is the single source of truth. The 3D scene is purely a rendering layer. All pathfinding, placement validation, and collision logic operates on the flat 2D array. This prevents the common mistake of treating the 3D `GridMap` node as authoritative and having to synchronize state between the visual and logical layers.

### ADR-04: BFS Flood-Fill for Placement Validation (not A*)

The pre-check that runs before committing a tower placement uses BFS, not the flow field. BFS flood-fill is O(grid_size), runs only on player action, and requires no heuristic setup. It simply asks: "From every spawn point, can we reach the exit?" If yes, placement is legal and the flow field is then recomputed. If no, the placement is rejected with no state change.

### ADR-05: MultiMeshInstance3D for Enemy Rendering

All enemies of the same type are rendered as a single draw call using `MultiMeshInstance3D`. Per-instance data (transform, optionally color for future status effect tinting) is updated via the `multimesh.transform_array` each frame. This is the established Godot 4 pattern for rendering many instances efficiently. Phase 1 has no status effect coloring, but the MultiMesh infrastructure must be set up correctly now since retrofitting it later is disruptive.

### ADR-06: Four-Directional Movement Only

Enemies move in four cardinal directions only (no diagonals). This eliminates corner-cutting bugs where enemies slide through the gap between two diagonally-adjacent towers. The flow field stores one of four direction vectors per cell (UP, DOWN, LEFT, RIGHT) plus a special BLOCKED value. This is the correct default for a maze-TD and is simpler than the alternative.

### ADR-07: Wave Mode as a Single Flag on WaveController

Timed Waves mode and Player-Triggered mode are not separate systems. A single `wave_mode` enum flag on the `WaveController` node controls whether the inter-wave gap is driven by a countdown timer or by a player input event. All other wave logic (spawning, enemy management, lives deduction) is identical between modes.

---

## Implementation Approach

### Grid System

**Do not use Godot's built-in `GridMap` node as the authoritative data structure.** `GridMap` is a visual tool for painting 3D tiles; it does not expose a clean API for pathfinding queries, and reading cell states from it every frame is inefficient. Instead:

- Maintain a flat GDScript Array (or C# `GridCell[]`) as the logical grid: `cells[x + y * width]`.
- `GridMap` (or a custom `MeshInstance3D` grid) is used only for rendering the ground tiles.
- Each logical `GridCell` tracks: `position: Vector2i`, `state: enum {Empty, Tower, StaticObject, Spawn, Exit}`, `passable: bool`.
- `passable` is derived: `true` when state is Empty or Spawn or Exit, `false` when Tower or StaticObject.
- The grid is initialized from a map definition resource (a custom `Resource` class with a cell-state array, spawn positions, and exit position).

**Cell size:** Use 2 units (Godot world units) per grid cell as a starting value. This gives enough 3D visual clearance for tower models and enemy models without the grid feeling too large. This is marked as Claude's discretion in CONTEXT.md and can be tuned.

**Coordinate system:** Grid origin at `(0, 0)` maps to world position at the corner of the map. Cell `(x, y)` maps to world position `Vector3(x * cell_size + half_cell, 0, y * cell_size + half_cell)`. All grid-to-world and world-to-grid conversions are centralized in a `GridManager` autoload singleton.

### Flow Field Pathfinding

**Data structure:**

```
FlowField:
  directions: Array[Vector2i]  # indexed as x + y*width; value is one of (1,0),(-1,0),(0,1),(0,-1),(0,0)
  # (0,0) means this cell IS the exit or is unreachable
  version: int                 # incremented on each recomputation
```

**Computation (C# layer, called from GDScript):**

1. Initialize a distance array of size `width * height` to `INT_MAX`.
2. Set exit cell distance to 0, add to a `Queue<Vector2i>`.
3. Standard BFS from exit outward. For each cell popped, iterate its four passable neighbors. If `neighbor_distance > current_distance + 1`, update and enqueue.
4. After BFS completes, write directions: for each passable cell, its direction is the vector toward its neighbor with the lowest distance value.
5. Increment `version`.
6. The C# method returns the direction array (or exposes it via a Godot-compatible `Array` or `PackedVector2Array`).

**Enemy reads the field:**

Each enemy stores `cached_field_version: int`. On each movement tick:
- If `cached_field_version != FlowFieldManager.current_version`, re-read direction from the field at current cell and update `cached_field_version`.
- Move in the stored direction at the enemy's movement speed.
- Mid-cell transitions: if an enemy is already moving between cells, allow it to complete the current step before reading the new direction. This prevents visual snapping on mid-wave tower placement.

**Update trigger:** The flow field is recomputed exactly once per successful tower placement and once per tower removal. It is never recomputed per-frame. On a 30×30 grid, BFS visits at most 900 cells — sub-millisecond even in GDScript, and negligible in C#.

**Multiple spawn points:** Phase 1 uses a single exit. The single flow field covers all spawn points. The architecture handles this correctly: enemies at any passable cell will read the direction toward the exit.

### Path Validation (BFS Flood-Fill)

**When it runs:** Only on a tower placement attempt, before the placement is committed to the grid.

**Algorithm:**

1. Tentatively mark the target cell as impassable (do not modify the actual grid yet).
2. BFS from the exit cell (or equivalently flood-fill from every spawn point — choose spawn-to-exit for simplicity).
3. If the exit is reachable from every active spawn point: placement is legal. Commit the cell state change, recompute the flow field, proceed.
4. If any spawn point cannot reach the exit: reject the placement. Restore the cell. Show "Path blocked" feedback.

**Implementation detail:** Use a temporary `passable` override during the check — do not copy the entire grid. Pass the tentative blocked cell as an exclusion parameter to the BFS function.

**Edge cases:**
- Spawn point is adjacent to the cell being placed: handled correctly, BFS will fail to find a route.
- Tower placed on a spawn cell: reject immediately without BFS (spawn cells are always off-limits for placement).
- Tower placed on the exit cell: reject immediately.
- Static objects (MAP-03): these are initialized as impassable in the grid at map load time. The BFS sees them as normal impassable cells — no special handling needed.
- Multiple spawn points: BFS must succeed for ALL spawn points, not just one. Run one BFS, flood-fill from the exit outward; all spawn points must be reached.

**What counts as valid:** Any cell that is not Tower, StaticObject, Spawn, or Exit can receive a tower, provided the placement does not disconnect any spawn from the exit.

### Enemy System

**Phase 1 enemy types (ENEMY-01 — distinct speeds and sizes, no combat):**

Define two or three enemy types in data to satisfy ENEMY-01's requirement for "multiple distinct types with different speeds and sizes observable without UI labels." Suggested minimal set:
- `EnemyBasic`: standard size, standard speed (e.g., 3 cells/second).
- `EnemyFast`: visually smaller model, higher speed (e.g., 5 cells/second).
- `EnemyHeavy`: visually larger model, slower speed (e.g., 1.5 cells/second).

No HP, no armor types, no damage in Phase 1 — enemies simply walk to the exit and deduct lives on arrival. Enemy "death" does not occur in Phase 1 (no combat), so the only removal trigger is reaching the exit.

**Enemy movement:**

Each enemy is not a full scene node — enemies are data records managed by an `EnemyManager` autoload. The `EnemyManager` holds:
- An array of active enemy structs (GDScript Dictionary or C# struct).
- A `MultiMesh` per enemy type (separate `MultiMeshInstance3D` nodes in the scene).
- Each frame, `EnemyManager._process(delta)` iterates all active enemies, reads their flow field direction, advances their world position, and updates the `MultiMesh` transform array.

This avoids per-enemy `_process()` virtual dispatch overhead and keeps all enemy logic centralized.

**Movement interpolation:** Enemies move smoothly through world space, not snapping cell-to-cell. They use their current world position to determine which grid cell they are in (`grid_pos = floor(world_pos / cell_size)`), then read the flow field direction for that cell and apply it as a velocity direction.

**Reaching the exit:** When an enemy's grid position equals the exit cell position, deduct one life from `RunState.playerHP`, emit a signal (`enemy_reached_exit`), and remove the enemy from the active list (returning it to the pool).

**Object pooling:** Pre-allocate a pool of enemy data records at the start of each wave based on `WaveDefinition.total_enemy_count`. Avoid allocation mid-wave.

### Wave System

**WaveDefinition resource (GDScript `Resource` class):**

```
wave_number: int
groups: Array[SpawnGroupResource]
  # SpawnGroupResource: enemy_id, count, spawn_interval, delay_from_wave_start
```

For Phase 1, wave definitions are defined directly as `Resource` assets in the Godot editor (`.tres` files). No JSON pipeline yet — keep it simple.

**WaveController (Node, not autoload — lives in the game scene):**

```
wave_mode: enum { TIMED, PLAYER_TRIGGERED }
current_wave: int
inter_wave_timer: float        # countdown between waves (Timed mode)
is_wave_active: bool
send_wave_pressed: bool        # set true by UI button or Spacebar
```

**Wave flow:**

1. At game start, load the first `WaveDefinition`.
2. Start inter-wave phase: in TIMED mode, count down `inter_wave_timer`; in PLAYER_TRIGGERED mode, wait for `send_wave_pressed`.
3. When the wave launches, iterate the SpawnGroups, spawning enemies per `spawn_interval` and `delay_from_wave_start` using `await get_tree().create_timer(delay).timeout` chains (coroutine pattern in GDScript).
4. Track active enemy count. When it reaches 0 and all spawns are complete, the wave is over.
5. Load the next `WaveDefinition`. Repeat.
6. When all waves complete (or `playerHP <= 0`), end the run.

**Phase 1 wave count:** Define at minimum 5 waves to make the Timed vs Player-Triggered modes meaningfully testable. Wave composition can be simple: increasing enemy count and mix of the three enemy types. No scaling logic yet (WAVE-04 is Phase 5).

**Send Wave bonus (WAVE-02):** Player-Triggered mode awards a bonus for early sends in later phases. In Phase 1, the "bonus rewards" component is not implemented (no currency system yet). The button and the early-send mechanic must exist and be functional, but the reward effect is a no-op stub with a `TODO: Phase 2 — award bonus gold` comment.

### Camera System

**Node setup:** `Camera3D` as a child of a `CameraRig` node. The rig handles pan and zoom; the camera itself handles the tilt angle.

```
CameraRig (Node3D)
  └─ CameraPivot (Node3D)  # handles tilt rotation
       └─ Camera3D
```

**Default angle:** 60° from vertical (30° from horizontal). This is the "always reads as 3D" feel specified in CONTEXT.md. In Godot terms, rotate `CameraPivot` by `-60` degrees on the X axis.

**Tilt range:** Player can adjust tilt from 60° from vertical to ~80° from vertical (nearly top-down). Hard stops at both ends. Do not allow orbit (no Y-axis rotation of the rig).

**Zoom levels (3 defined):**

| Level | Name | Camera Z distance from pivot |
|-------|------|------------------------------|
| 1 | Overview | Far (full map visible) |
| 2 | Standard | Medium (default) |
| 3 | Detail | Close |

Exact distance values are Claude's discretion — tune during implementation to fit the map size. Transitions use `Tween` for smooth animation (not instant).

**Pan:**
- WASD and edge-scrolling: move the `CameraRig` position in XZ plane.
- Click-and-drag: on `InputEventMouseButton` press + `InputEventMouseMotion`, project the mouse delta onto the XZ plane and offset the rig position.
- Hard boundary: clamp `CameraRig.position` to the map bounds on every pan update.

**Quick reset:** One key (e.g., R or Home) calls a function that tweens the rig back to the map center and resets tilt and zoom to Standard defaults.

**Click-to-follow (Phase 1 scope):** The CONTEXT.md mentions "player can click an enemy or tower to follow it" during combat. This belongs in Phase 1 since the camera system is being built here. Implementation: on left-click, raycast from camera into the world; if an entity is hit, set a `follow_target` reference and lock the rig to track that entity's world position each frame. A second click (or Escape) clears the follow target.

### Tower Placement

**Tower types in Phase 1:** Only one tower type is needed — a generic "wall tower" (a block that occupies a cell). No combat stats, no range, no attack. The tower's only function is to occupy a grid cell and block movement. This satisfies CORE-01, CORE-02, CORE-03 cleanly. (Phase 2 introduces towers that actually attack.)

**Ghost preview:**
- On `InputEventMouseMotion`, raycast from the camera onto the XZ grid plane using `PhysicsRayQueryParameters3D` or a manual plane intersection.
- Determine which grid cell the cursor is over: `grid_cell = floor(ray_hit_pos / cell_size)`.
- Move a pre-instantiated "ghost" `MeshInstance3D` to that cell's world position.
- Each frame, run the BFS placement validation against the hovered cell (not the full flow field — just the reachability check). Set ghost material to green `StandardMaterial3D` (valid) or red (invalid).
- This BFS runs every frame while hovering. On a 30×30 grid in GDScript this is acceptable; if profiling shows it is a bottleneck, cache the last hovered cell and only re-run when the cell changes.

**Placement:** On left-click over a valid cell:
1. Confirm placement (commit cell state to grid, mark impassable).
2. Recompute flow field (C# call).
3. Spawn a permanent tower mesh at the cell.
4. Hide ghost (or move it to the new hover position).

**Invalid placement feedback:**
- Ghost is red (already visible from the hover state).
- Show a toast notification: a `Label` node with "Path blocked — enemies must have a route" that animates in and auto-dismisses after ~2 seconds. The animation style is Claude's discretion.

**Mid-wave placement:** Tower placement is always allowed (no wave-state gate). When placed mid-wave, the flow field recalculates immediately. Enemies respond on their next movement tick (which reads the new field version). No special mid-wave logic is needed.

**Tower removal:** Not in scope for Phase 1 (selling is CORE-04, Phase 2). Towers placed in Phase 1 are permanent for the wave set.

### Path Visualization

**What it shows:** Glowing directional arrows along the current shortest valid route from every spawn to the exit. This satisfies UI-01.

**Implementation approach — custom shader on a quad mesh:**

The simplest performant approach in Godot 4 is a flat `MeshInstance3D` quad (or `PlaneMesh`) covering the grid, with a custom `ShaderMaterial` that draws the arrows procedurally.

- Pass the flow field direction array to the shader as a `Texture2D` (encode direction as 2-channel float texture, one texel per grid cell).
- In the fragment shader, sample the direction texture at the grid cell corresponding to the current UV, and draw an arrow glyph pointing in that direction.
- Animate the arrows by passing a `TIME` uniform and scrolling a pattern along the arrow direction to create the "flowing toward exit" feel specified in CONTEXT.md.

**Alternative (simpler, less efficient):** Place pre-made arrow `MeshInstance3D` nodes at each cell, update their rotation when the flow field changes. Simpler to implement but generates many draw calls. Only use this approach for prototyping; ship with the shader approach.

**Update trigger:** Regenerate the direction texture whenever the flow field version increments. This is a one-time CPU upload per tower placement, not a per-frame cost.

**Toggle:** A boolean `path_overlay_visible` flag on the `GridManager` autoload. Toggling updates the `MeshInstance3D.visible` property. Default: visible.

**Scope note:** UI-01 says arrows show "the current shortest valid route." This means the visualization always reflects the live flow field — it is not a preview of a potential route.

### HUD

**Layout (from CONTEXT.md):**
- Top bar: lives remaining, wave counter (current / total), gold/resources (no currency system in Phase 1 — show "—" or hide), countdown timer (Timed mode) or "READY" indicator (Player-Triggered mode).
- Bottom panel: tower selection buttons. In Phase 1, only one tower type exists, so the panel has one button (or is minimal).
- Send Wave button: only visible in Player-Triggered mode. Prominent position. Spacebar also triggers it.

**Godot 4 implementation:**
- All HUD lives in a `CanvasLayer` node (z-index above the 3D world).
- Top bar: `HBoxContainer` with `Label` nodes for each value.
- Bottom panel: `HBoxContainer` or `GridContainer` with tower buttons.
- Countdown timer: updated each frame from `WaveController.inter_wave_timer` in `_process`.
- Send Wave button: `Button` node wired to `WaveController.send_wave()`. Visibility toggled based on `WaveController.wave_mode`.

**Gold/resources in Phase 1:** Currency is a Phase 2 concern. The HUD must include the gold display element (for Phase 2 expansion), but it shows "—" or 0 in Phase 1. Do not implement the currency system yet.

**Pause controls (UI-03):** These are Phase 2. Do not implement pause/speed controls in Phase 1. The HUD in Phase 1 has no speed buttons.

**Tower range overlay (UI-02):** In Phase 1, towers have no range (they are pure walls). The range overlay should still be stubbed as a `MeshInstance3D` circle mesh that is toggled visible/invisible on tower selection. In Phase 1, it shows nothing meaningful (range = 0 = invisible circle). The infrastructure must exist for Phase 2 to populate.

### Performance (STEAM-04)

**Target:** Stable 60fps on GTX 1060-tier hardware throughout Phase 1.

**Enemy rendering budget:** `MultiMeshInstance3D` with one `MultiMesh` per enemy type. Update `multimesh.transform_array` each frame from the `EnemyManager` loop. For Phase 1's expected enemy count (50–150 enemies across the three types), this is one to three draw calls total for all enemies.

**Enemy count estimate for Phase 1:** No damage means enemies accumulate on the map across a wave until they reach the exit. With 3–5 second transit times across a 30×30 grid and a spawn rate of 1 enemy per second, peak simultaneous on-screen enemies could reach 30–50 per wave. This is well within the `MultiMeshInstance3D` budget.

**Flow field recalculation cost:** BFS on a 30×30 grid (900 cells) in C# takes under 0.1ms. Even at 30×50 (1500 cells), sub-0.5ms. Not a frame budget concern at Phase 1 scale.

**BFS validation cost (hover):** Running BFS every frame on cursor movement is the riskiest Phase 1 performance cost. Mitigation: cache the last hovered grid cell and skip the BFS if the cell has not changed. Only re-run when the cursor crosses a cell boundary.

**Draw call budget:** With `MultiMeshInstance3D` for enemies, static tower meshes (Godot can merge static meshes), and a single quad for the path visualization, total draw calls in Phase 1 should be under 20 per frame. Well within budget.

**Godot profiling workflow:** Use the Debugger → Profiler tab during play-in-editor. Pin "FPS", "Process time", and "Navigation Map Updates" monitors. After first enemy wave implementation, profile specifically during tower placement (the highest-cost event) to confirm sub-frame BFS + flow field update.

---

## Validation Architecture

### Test Framework

**Recommendation: GUT (Godot Unit Testing) with manual scene testing for visual/behavioral requirements.**

**GUT** is the de facto standard Godot testing framework. It supports:
- Unit tests for pure logic (GDScript or C# via the GUT C# companion).
- Integration tests that run full Godot scenes headlessly.
- Assertion library familiar to developers who have used GTest, pytest, or RSpec.
- Active maintenance and Godot 4 compatibility (GUT 9.x targets Godot 4.x).

**Why not gdUnit4:** gdUnit4 is also a solid choice for Godot 4, with a stronger IDE integration story (JetBrains plugin). However, GUT has a larger existing community, more shipped game examples, and its headless CLI support is better documented. For a solo project, GUT is the lower-friction starting point. gdUnit4 is a valid alternative if IDE integration is a priority.

**Why not manual testing only:** Pathfinding correctness (CORE-02, CORE-03) is not reliably verified by human observation alone. A tower that appears to block the path might actually be rejected for a subtly wrong reason. Unit tests on the BFS validation and flow field computation prevent silent regressions as the grid system evolves across phases.

**Installation:**
1. Download GUT from the Godot Asset Library (search "GUT") or from `github.com/bitwes/Gut`.
2. Enable the plugin in Godot Project Settings → Plugins.
3. Test files live in `res://tests/` by convention, named `test_*.gd`.

### Running Tests

**Headless CLI command (Godot 4):**

```bash
godot --headless --path /path/to/project -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**Breakdown of flags:**
- `--headless`: runs without display (required for CI / automated runs).
- `--path`: absolute path to the Godot project root.
- `-s addons/gut/gut_cmdln.gd`: runs the GUT command-line runner script.
- `-gdir=res://tests`: directory GUT scans for `test_*.gd` files.
- `-gexit`: exits the process when tests complete (returns non-zero exit code on failure).

**CI integration:** Add this command to a GitHub Actions workflow (or equivalent) triggered on push. Use `setup-godot-action` (community action) or download the Godot headless binary directly in the CI script.

**Estimated total automated test suite execution time for Phase 1:** Under 30 seconds headless. BFS and flow field unit tests are pure computation — sub-millisecond each. Integration tests that spin up a minimal scene take 1–3 seconds each. With ~15–20 tests total, the suite completes well under one minute.

### Per-Requirement Testability

| Requirement | Test Type | Approach | Estimated Time |
|-------------|-----------|----------|----------------|
| CORE-01 | unit + manual | Unit: assert that placing a tower marks the grid cell impassable (`cell.passable == false`). Manual: visually verify enemies cannot walk through tower cells during a live wave. | Unit: <1s. Manual: 2 min |
| CORE-02 | unit | Unit: attempt to place a tower that would seal the only exit; assert the placement is rejected and grid state is unchanged. Test multiple blocking configurations (corner block, full-row block). | <1s per test case |
| CORE-03 | integration | Integration test: place a tower mid-simulated-wave, assert that `FlowField.version` increments and that all enemy direction caches are stale (triggering a re-read on next tick). Full visual verification is manual. | Integration: 3–5s. Manual: 3 min |
| MAP-01 | manual | Load each hand-crafted map in the editor; verify spawn and exit positions are correctly placed and the map loads without errors. Structural test: assert map resource loads and has valid spawn/exit cells. | Resource load test: <1s. Manual review: 5 min per map |
| MAP-03 | unit | Unit: initialize a grid with static object cells pre-set; assert those cells have `passable == false` and that `IsPathValid` correctly routes around them. | <1s |
| MAP-04 | manual | Playtest with a tester: verify that static objects create meaningful routing constraints (enemies cannot pass through them, placement near them is strategically interesting). No automated test for "strategic interest." | 15–30 min playtest |
| WAVE-01 | integration | Integration test: set `WaveController.wave_mode = TIMED`, simulate time passage, assert that the next wave launches automatically when `inter_wave_timer` reaches 0. Assert wave counter increments. | 3–5s (must simulate timer) |
| WAVE-02 | integration | Integration test: set `wave_mode = PLAYER_TRIGGERED`, assert wave does not auto-launch, then fire `send_wave_pressed = true`, assert wave launches. Assert Send Wave button visible in this mode. | 3–5s |
| ENEMY-01 | manual | Manual: observe a wave containing all three enemy types; confirm size and speed differences are visually obvious without UI labels. Automated: assert that at minimum 2 enemy type definitions exist in the enemy data, each with distinct `speed` and `scale` values. | Data assert: <1s. Manual: 5 min |
| UI-01 | integration | Integration: place a tower, assert that `PathOverlay.direction_texture` is regenerated (or that `FlowField.version` is updated and a `path_updated` signal is emitted). Manual: visually confirm arrows update immediately on screen. | Signal test: <1s. Manual: 2 min |
| UI-02 | manual | Manual: select a tower type, confirm a range overlay circle appears at the placement cursor location. (In Phase 1, range = 0 so the circle is invisible or zero-radius; test that the node exists and visibility is toggled correctly.) Automated: assert overlay `MeshInstance3D` exists in scene and toggles visible on tower selection signal. | <1s automated. Manual: 2 min |
| STEAM-04 | manual | Manual: run a full 5-wave session on target hardware (GTX 1060-tier or equivalent), observe frame counter does not drop below 60fps. Use Godot Debugger Monitor tab with FPS graph pinned. Test specifically during: peak enemy count, tower placement mid-wave, path overlay visible. | 20–30 min manual performance session |

### Wave 0 Test Stubs Needed

Create these test files before implementation begins. Each file contains the test structure (class, `before_each`, test method skeletons) with `pending("not implemented")` bodies. This forces the test architecture to be designed upfront and makes it obvious what must be proven before Phase 1 is declared done.

```
res://tests/
  test_grid_manager.gd
    - test_cell_initialized_passable()
    - test_tower_placement_marks_cell_impassable()
    - test_static_object_cell_is_impassable()
    - test_spawn_cell_cannot_receive_tower()
    - test_exit_cell_cannot_receive_tower()

  test_path_validation.gd
    - test_open_grid_path_is_valid()
    - test_full_block_is_rejected()
    - test_partial_block_leaves_route_valid()
    - test_corner_block_leaves_route_valid()
    - test_validation_does_not_modify_grid_on_rejection()

  test_flow_field.gd
    - test_exit_cell_direction_is_zero_vector()
    - test_adjacent_to_exit_points_at_exit()
    - test_flow_field_version_increments_on_recompute()
    - test_unreachable_cell_has_zero_direction()

  test_wave_controller.gd
    - test_timed_mode_launches_wave_on_timer()
    - test_player_triggered_mode_does_not_auto_launch()
    - test_player_triggered_mode_launches_on_signal()
    - test_wave_counter_increments_after_wave_clear()

  test_enemy_manager.gd
    - test_enemy_reaches_exit_deducts_life()
    - test_enemy_reads_updated_flow_field_on_version_change()
    - test_enemy_pool_size_matches_wave_definition()
```

---

## Pitfalls & Risks

### Risk 1: BFS hover validation runs every frame (high probability)

**Problem:** Running BFS on every `InputEventMouseMotion` event will trigger multiple BFS calls per frame on fast mouse movement. On a larger grid or slower hardware this can accumulate.

**Mitigation:** Cache the last hovered grid cell. Only run BFS when `current_hover_cell != last_hover_cell`. This reduces BFS calls from "every mouse event" to "every cell boundary crossing" — typically 0–1 times per frame during normal play.

### Risk 2: Flow field direction encoding across the GDScript/C# boundary

**Problem:** Passing a `Vector2i[]` direction array from C# to GDScript has overhead if done naively (boxing, conversion). If this is called every frame it could become a bottleneck.

**Mitigation:** The flow field is only recomputed on tower placement events, not per-frame. The direction array is passed once at recompute time and stored in a GDScript-accessible buffer. Enemies read from this buffer per-frame without crossing the language boundary again.

### Risk 3: Enemies "teleporting" at flow field boundaries

**Problem:** If an enemy is mid-transition between two cells when the flow field updates, reading the new direction immediately can cause a visual direction snap.

**Mitigation:** Enemies track `is_mid_transition: bool`. When `is_mid_transition == true`, delay the direction re-read until the current cell step completes. This is documented in ARCHITECTURE.md and must be implemented from the start, not retrofitted.

### Risk 4: MultiMesh transform array size mismatch

**Problem:** `MultiMeshInstance3D` requires the `MultiMesh.instance_count` to be set before writing `transform_array`. If enemy count fluctuates mid-wave (which it will, as enemies reach the exit), either the count must be updated dynamically (expensive) or the array must be pre-sized and inactive enemies must be hidden by moving them off-screen.

**Mitigation:** Pre-size the `MultiMesh.instance_count` to the maximum possible enemy count for the wave (from `WaveDefinition.total_enemy_count`) at wave start. For inactive pool slots, set their transform to a position outside the camera frustum (e.g., `Vector3(0, -1000, 0)`). This avoids dynamic resizing and keeps the GPU from rendering off-screen instances (they are still submitted but not visible — acceptable tradeoff for Phase 1 enemy counts).

### Risk 5: Path visualization shader complexity

**Problem:** Writing a custom fragment shader to render animated directional arrows is the highest-skill-floor task in Phase 1. If the shader is incorrect or has UV mapping issues, the arrow visualization will look wrong or have undefined behavior on different GPU vendors.

**Mitigation:** Build the placeholder visualization first using `MeshInstance3D` arrow meshes (one per cell), which is straightforward and correct. Replace with the shader approach only once the game loop is playable. The shader is a visual polish item, not a functional blocker. Mark the shader as "Phase 1 polish task, not Phase 1 blocker."

### Risk 6: No combat means no natural wave end condition

**Problem:** In Phase 2+, a wave ends when all enemies are dead. In Phase 1, enemies never die (no combat) — they only exit. If enemies take a very long path, the wave could last much longer than intended, making the game feel slow.

**Mitigation:** Enemies that reach the exit are removed from the active list (lives are deducted). This is the only removal mechanism in Phase 1. Ensure wave definitions are designed so the maximum transit time across the longest possible maze path keeps waves at a reasonable length (target: under 60 seconds per wave at standard speed). Add a `max_wave_duration` timer as a safety net: if a wave exceeds it, force-complete the wave and deduct lives for any still-living enemies.

### Risk 7: Static objects must be distinguishable from towers in grid state

**Problem:** MAP-03 requires pre-placed static objects. If these are treated identically to player-placed towers in the grid state, removing them (if that ever becomes relevant) or querying "how many static objects" is ambiguous.

**Mitigation:** Use distinct enum values: `GridCell.State.Tower` vs `GridCell.State.StaticObject`. Both have `passable = false`. This costs nothing and prevents state confusion in later phases.

### Risk 8: Convoy behavior (all enemies follow identical path)

**Problem:** With a shared flow field, all enemies of the same type follow the exact same route. This looks unnatural and makes splash attacks trivially effective.

**Mitigation (minimal for Phase 1):** Add sub-tile position jitter to each enemy's world position (a small random `Vector2` offset, e.g., ±20% of cell size, assigned at spawn and held constant). This spreads enemies visually without changing their logical grid position for pathfinding purposes. Full multi-path spreading is a future enhancement.

---

## File Structure Recommendation

```
res://
  addons/
    gut/                          # GUT test framework plugin
  assets/
    enemies/
      enemy_basic.glb
      enemy_fast.glb
      enemy_heavy.glb
    towers/
      tower_wall.glb
    ui/
      icons/
    maps/
      map_01/
        map_01.tres               # MapDefinition resource
        map_01_thumbnail.png
  autoloads/
    GridManager.gd                # Grid state, coordinate conversion, passable queries
    FlowFieldManager.gd           # Owns flow field data, calls C# layer, broadcasts version
    EnemyManager.gd               # Enemy pool, per-frame movement, MultiMesh updates
    GameState.gd                  # RunState (lives, current wave, wave mode)
  data/
    enemies/
      enemy_basic.tres            # EnemyDefinition resource (speed, scale, mesh ref)
      enemy_fast.tres
      enemy_heavy.tres
    waves/
      wave_01.tres                # WaveDefinition resource
      wave_02.tres
      wave_03.tres
      wave_04.tres
      wave_05.tres
  scenes/
    game/
      Game.tscn                   # Root game scene (GridManager, EnemyManager, WaveController)
      GridVisual.tscn             # 3D grid rendering (ground plane, cell lines)
      TowerGhost.tscn             # Ghost preview mesh
      PathOverlay.tscn            # Path visualization quad/mesh with shader
    enemies/
      EnemyMultiMesh.tscn         # One scene per enemy type (wraps MultiMeshInstance3D)
    towers/
      TowerWall.tscn              # Placed tower visual
    hud/
      HUD.tscn                    # CanvasLayer root
      TopBar.tscn                 # Lives, wave counter, timer
      BottomPanel.tscn            # Tower selection buttons
      SendWaveButton.tscn         # Player-Triggered mode button
      ToastNotification.tscn      # Invalid placement toast
    camera/
      CameraRig.tscn              # CameraRig + CameraPivot + Camera3D
    maps/
      MapBase.tscn                # Base scene extended by map instances
      Map01.tscn                  # Extends MapBase, places static objects
  scripts/
    pathfinding/                  # C# project folder
      FlowField.cs                # Dijkstra from exit, returns direction array
      PathValidator.cs            # BFS flood-fill validation
      PathfindingBridge.gd        # GDScript wrapper calling C# via GodotObject
    controllers/
      WaveController.gd           # Wave mode, timer, spawn scheduling
      TowerPlacer.gd              # Raycast, hover, click handling
    resources/
      MapDefinition.gd            # Resource class: cell states, spawn/exit positions
      WaveDefinition.gd           # Resource class: wave groups
      EnemyDefinition.gd          # Resource class: speed, scale, mesh
  shaders/
    path_arrow.gdshader           # Flow field arrow visualization shader
  tests/
    test_grid_manager.gd
    test_path_validation.gd
    test_flow_field.gd
    test_wave_controller.gd
    test_enemy_manager.gd
```

**Notes:**
- Autoloads are registered in Project Settings → Autoload. `GridManager`, `FlowFieldManager`, `EnemyManager`, and `GameState` are all singletons.
- The C# pathfinding code lives in `scripts/pathfinding/` as a separate `.csproj` alongside the Godot project's `.csproj`. GDScript calls into C# via `PathfindingBridge.gd`, which instantiates the C# `FlowField` and `PathValidator` classes.
- `MapDefinition.tres` files are the authoritative source for MAP-01 hand-crafted maps. They define which cells are static objects, where spawn points are, and where the exit is.

---

## Phase Scope Boundary

### Explicitly IN Scope for Phase 1

- 3D grid rendering with visible cell lines/ground
- Logical grid data structure (flat array, `GridCell` states)
- One tower type (wall block) with placement, ghost preview, and validation
- BFS flood-fill placement validation (path must remain valid)
- Flow field pathfinding (Dijkstra from exit, C# implementation)
- Path visualization (directional arrows on grid, toggleable)
- Three enemy types with distinct visual sizes and movement speeds
- Enemy movement along flow field (no combat, no HP)
- Life deduction when enemy reaches exit
- Enemy rendering via `MultiMeshInstance3D`
- Wave Controller with TIMED and PLAYER_TRIGGERED modes
- At least 5 wave definitions
- HUD: top bar (lives, wave counter, timer) + bottom panel (tower selection stub) + Send Wave button
- Tower range overlay stub (infrastructure for Phase 2, shows nothing in Phase 1)
- Camera: 60° default tilt, three zoom levels, WASD/edge-scroll/click-drag pan, hard map-edge stops, quick reset
- Click-to-follow camera (enemy or tower)
- One hand-crafted map with pre-placed static objects (MAP-01, MAP-03, MAP-04)
- GUT test framework installed and configured
- All five test stub files created with `pending()` bodies

### Explicitly OUT of Scope for Phase 1

- Tower combat, damage, projectiles (Phase 2)
- Enemy HP and death (Phase 2)
- Currency/gold system (Phase 2)
- Tower selling or removal (Phase 2 — CORE-04)
- Tower upgrades (Phase 2 — CORE-05)
- Pause, 1x, 2x speed controls (Phase 2 — UI-03)
- Enemy health bars (Phase 2 — UI-04)
- Armor types, damage matrix (Phase 2)
- Status effects: Frost, Poison, Burn (Phase 3)
- Floor traps (Phase 3)
- Classes and synergies (Phase 4)
- Multiple spawn/exit configurations per map (Phase 5 — MAP-02)
- Boss enemies and mini-bosses (Phase 5)
- Endless Escalation mode (Phase 5 — WAVE-03)
- Wave difficulty scaling logic (Phase 5 — WAVE-04)
- Meta progression and roguelite loop (Phase 6)
- Run stats screen (Phase 6)
- Steam integration (Phase 7)
- More than one map (Phase 1 ships with exactly one map)
- Tutorial or onboarding flow
- Audio (sound effects, music) — deferred until gameplay is stable
- Settings menu — deferred until Phase 2+
- Boss auto-pan camera toggle (Phase 5 — noted in CONTEXT.md)
- Send Wave bonus rewards (infrastructure stub exists; no currency to award until Phase 2)

---

## RESEARCH COMPLETE
