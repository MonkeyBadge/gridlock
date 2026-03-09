# Research Summary

*Synthesized from STACK.md, FEATURES.md, ARCHITECTURE.md, and PITFALLS.md — 2026-03-09*

---

## Recommended Stack

Use **Godot 4.3.x stable** (MIT license, zero royalties) as the engine. The primary language split is **GDScript for gameplay logic** (fast iteration, no compile step) and **C# (.NET 8 LTS) for performance-critical systems** — specifically the pathfinding layer and any tight loops that profile as bottlenecks. The pathfinding solution is **AStarGrid2D** (Godot 4.1+, C++-implemented, grid-native) for the primary flow-field computation, backed by **NavigationServer3D** only for local 3D avoidance and movement smoothing. 3D assets are authored in **Blender 4.2 LTS** and exported as `.glb` (GLTF 2.0); **Blockbench** serves stylized tower and enemy models. UI is designed in **Figma** (free tier) and implemented via Godot's Control/Theme system. Steam integration uses the **GodotSteam** plugin. Profiling stack: Godot's built-in Profiler/Monitor tabs, **RenderDoc** for GPU analysis, and **Tracy Profiler** for sub-millisecond C# hot-path analysis. Render enemies using **MultiMeshInstance3D** for a single draw call across all instances.

---

## Architecture Blueprint

- **Grid is source of truth.** A flat 2D logical array (`cell[x + y * width]`) drives all pathfinding, placement, and collision. The 3D scene is a rendering layer on top.
- **Flow field pathfinding (primary).** One Dijkstra pass from the exit produces a direction-per-cell array shared by all enemies — O(grid size) per tower placement, not O(enemy count × grid size). Version-stamp the field; enemies re-read on mismatch.
- **BFS reachability pre-check on every placement.** Before committing a tower, flood-fill from every spawn to every exit on a shadow grid copy. Reject and restore if any path is blocked. Runs once per player action, not per frame.
- **Per-enemy A* only for bosses** that target non-exit destinations (e.g., chasing a specific tower).
- **Multiple flow fields for multiple movement types.** At minimum two layers: ground and flying. Budget this from day one — retrofitting costs a mid-alpha rewrite.
- **Data-driven tower definitions.** All tower stats, damage types, synergy tags, and upgrade trees live in external JSON/resource files. One generic runtime `Tower` component reads its definition; no per-tower subclasses.
- **Tag-based synergy system.** Towers carry `synergyTags`; a `SynergyManager` singleton re-evaluates all rules on placement/removal events. New synergies = new data, no new code.
- **Status effects via a deferred tick queue (min-heap).** Per-frame cost scales with ticks due this frame, not total active effects. Frost slow is a cached passive multiplier, not a ticking event.
- **Strict RunState / MetaState separation.** `RunState` is ephemeral (discarded on run end; optionally serialized for crash recovery). `MetaState` is written to disk asynchronously after every meaningful milestone. Save format is versioned from day one with string IDs, not array indices.
- **EnemyManager singleton.** All enemies tick in a single C# loop; no per-enemy `_Process` virtual dispatch. Object pool pre-allocated at wave start from `WaveDefinition.totalEnemyCount`.
- **Status effect VFX budget per enemy: max 2 simultaneous visual indicators.** Priority-queue the most important ones; show the rest as small icons.
- **Spatial grid for range queries.** Divide the play area into cells sized to max tower range; towers query only their cell and neighbors — never iterate all enemies for every tower every frame.

---

## Must-Have at Launch

| Category | Feature |
|---|---|
| Core loop | Wave counter (current / total), next-wave preview |
| Core loop | Tower placement with live range/damage radius overlay |
| Core loop | Enemy health bars (floating); boss health bar as dedicated UI element |
| Core loop | Path visualization overlay on the map at all times |
| Core loop | Minimum 4 tower archetypes (slow, single-target DPS, AoE, support/buff) |
| Core loop | Tower upgrade system (linear minimum; branching preferred) |
| Core loop | Clear gold income loop; visually distinct run vs. meta currencies |
| Core loop | Lives/base HP readout |
| Core loop | Pause + 1×/2× speed; 3×–4× fast-forward (mandatory for roguelite replayability) |
| Core loop | Mid-wave tower selling (50–75% refund) |
| Core loop | Run-end screen with stats (waves, kills, damage); prompt to restart |
| Maze-specific | Valid-path enforcement: placement turns red instantly if it would block all paths |
| Maze-specific | Dynamic enemy rerouting on mid-wave tower placement |
| Maze-specific | Live path-length delta indicator on placement hover |
| Maze-specific | Camera rotate/zoom during placement; transparency/cutaway for tall structures |
| Maze-specific | At least one flying enemy type |
| Maze-specific | 3–4 distinct maps at EA launch |
| Roguelite | Run structure visible (wave ladder with mini-boss and boss milestones) |
| Roguelite | At least one decision point per wave (3-pick offer, shop, or event card) |
| Roguelite | Meaningful meta-progression unlock every 2–3 runs |
| Roguelite | Endless escalation mode with a visible leaderboard (local minimum) |
| Roguelite | Run history log (last 10 runs) with per-tower damage breakdown |
| Roguelite | Run-suspend crash-recovery save |
| Steam platform | Steam Achievements (20–30 minimum) |
| Steam platform | Steam Cloud Saves (implement early; retrofitting is painful) |
| Steam platform | Controller support functional at launch |
| Steam platform | UI legible and functional at 1280×800 (Steam Deck) |
| Steam platform | Accurate system requirements tested on GTX 1060 / RX 580 hardware |
| Steam platform | Volume controls (master / music / SFX) and display settings |
| Steam platform | Colorblind mode for status effect color-coding (deuteranopia/protanopia minimum) |
| Polish | Stable 60 fps on GTX 1060-tier hardware during peak waves |
| Polish | Death-to-new-run time under 15 seconds |
| Polish | All damage numbers and status effect interactions visible and labeled in-game |

---

## Genuine Differentiators

- **Towers-as-maze-walls in 3D.** True 3D environments where the tower IS the wall segment — with camera, lighting, and spatial puzzle implications — is not well-represented in the current market. Requires committed art direction (parapet aesthetics, wall-tower duality) to read correctly.
- **Class/race gating of tower pools.** Hard class-gating with intra-class synergies designed together is closer to Slay the Spire's character-specific card sets than to the universal random pool used by Brotato or Deep Rock: Survivor. Runs feel fundamentally different rather than "same pool, different luck."
- **Damage matrix (attack type vs. armor type).** A structured matrix with counter-picking meta is uncommon in TD games. Creates a "read the enemy composition and respond" loop that adds genuine strategic depth — but only if surfaced clearly in the UI and kept to 3×3 or 4×4 interactions maximum.
- **Potential differentiators not yet in the plan (high opportunity):** (1) Maze efficiency scoring — live feedback on travel-time efficiency vs. optimal, (2) Asymmetric multi-spawn routing that turns maze design into a constraint-satisfaction puzzle, (3) Ghost-run overlay showing a previous run's maze layout.

---

## Top Risks to Watch

| Risk | One-Line Prevention |
|---|---|
| **Pathfinding + status effects + rendering hit frame budget simultaneously** | Establish a shared per-frame performance budget across all three systems and profile them together under load, not in isolation. |
| **Boss encounters invalidate the maze** (highest design tension in this project) | Resolve boss-vs-maze philosophy in writing before alpha: bosses should stress-test the maze, not negate it; communicate boss properties one wave in advance. |
| **Single optimal maze layout discovered on run 2** | Vary spawn/exit positions per run; add enemy types that punish long paths; use class-specific synergies that incentivize different spatial patterns. |
| **Scope exceeds team capacity** (this is a 3–4 person, 2-year project as designed) | Lock a feature freeze 4 months before EA; maintain an explicit cut list; defer roguelite meta-progression to post-EA if needed for a solo developer. |
| **Class balance — one class dominates** | Each class must offer a different *type* of power, not a different amount; design enemies that specifically threaten each class's win condition; target <40% win-rate dominance in internal testing. |
| **RNG upgrade offers feel like no choice** | Weight offers toward the player's current class and already-built towers; guarantee one build-synergy offer every 5 waves. |
| **EA launch timing / review score death spiral** | Do a Steam Next Fest demo before EA launch; target 5,000+ wishlists; fix all known negative-review triggers before going live; soft-launch on itch.io or Discord closed beta first. |

---

## Key Design Decisions Needed Before Alpha

These must be resolved in writing before any implementation begins. Flagged explicitly by research.

1. **Boss-vs-maze philosophy.** Do bosses use the maze path, bypass it, or partially interact with it? This determines boss state machine design, map design constraints, and player expectation-setting. *The single highest-risk unresolved question in this project.*

2. **Movement type layers.** How many distinct passability layers exist at launch (ground, flying, burrowing)? Each adds a flow field and a separate pathfinding budget. Define the full list and architecture contract before writing any enemy movement code.

3. **Multi-spawn-point strategy.** Are multiple simultaneous spawn points a launch feature? This directly determines whether the flow-field-per-exit architecture (one field per exit) is needed from day one or can be deferred.

4. **Damage matrix dimensions.** Lock the attack-type × armor-type matrix to 3×3 or 4×4 maximum at launch. More than 16 interactions cannot be learned without a wiki. Decide which types ship at EA.

5. **Status effect interaction depth.** Define the maximum interaction chain length (recommend: no more than 2-level chains — A+B triggers AB; never A+B+C). Document all planned combo triggers before implementing any of them.

6. **Selling / repositioning rules.** Can towers be sold mid-wave? Can they be repositioned between waves for free? This is load-bearing for the maze-as-investment feel. Decide and communicate this to players from wave 1.

7. **Run length target.** Lock the target run duration (recommend: 20–40 minutes). This drives wave count, wave pacing, and boss frequency. Cannot be tuned retroactively without touching every other balance number.

8. **Meta-progression power budget.** Define the maximum power delta between a zero-unlock and a fully-unlocked profile (recommend: 15–25%, with most unlock value being variety, not raw stats). Set this ceiling before implementing any permanent upgrades.

9. **EA pricing and roadmap communication style.** Price at 70–80% of 1.0 intent. Use content-category roadmap language ("new class + towers") with seasonal horizons, not specific dates or feature lists.

---

## Build Order

Dependencies flow top to bottom. Do not start a phase before its prerequisites produce a working, testable result.

1. **Grid system** — Flat array, `GridCell` struct, passable/impassable logic. Everything depends on this.
2. **BFS reachability pre-check** — Path-blocking guard before any pathfinding. Prevents bad states during all subsequent testing.
3. **Flow field computation** — Dijkstra from exit, direction vectors per cell. Validate with placeholder move-toward-exit cubes before any enemy logic.
4. **Basic enemy movement on flow field** — Entity reads field, moves, reaches exit. No combat. Validates the core "towers are maze walls" loop concept.
5. **Tower placement system** — Place/remove towers, triggers reachability check + flow field recalculation. First playable prototype moment.
6. **Wave spawn system** — `WaveDefinition` data, `WaveController`, timed and player-triggered modes as a single flag.
7. **Damage matrix + enemy HP** — Load 6×6 (or chosen size) matrix from data; enemies can die.
8. **Tower attack logic** — Range queries via spatial grid, targeting modes, attack cooldown. First complete gameplay loop.
9. **Status effect system** — Tick queue (min-heap), Frost/Poison/Burn, stacking rules, pooled instances.
10. **Enemy state machine** — Pathing / Staggered / Dead states formalized. Required before boss states.
11. **Data-driven tower definitions** — Move all hardcoded stats to external files. Required before class system.
12. **Class system + SynergyManager** — Class pools, tag-based synergy rules, re-evaluation on placement events.
13. **Tower upgrade system** — `UpgradeNode` data, `effectiveStats` recomputation.
14. **Boss system** — Boss `WaveDefinition` entries, per-boss state machine configurations, A* override for boss targeting.
15. **Floor trap system** — Trap definitions, placement on passable cells, trigger logic. Lower priority than combat; insert here or after step 8.
16. **MetaState + versioned save/load** — Disk serialization with string IDs and `saveVersion`. Async writes; crash-recovery RunState temp file.
17. **Run flow** — Start / mid-run / end-run transitions, reward calculation, meta currency.
18. **Roguelite meta-progression UI and unlocks** — Class unlocks, permanent upgrades, endless high scores display.
19. **Steam integration pass** — Achievements, Cloud Saves, controller bindings, Steam Deck UI audit.
20. **Performance and content audit** — Profile all three hot systems together (pathfinding + status effects + rendering) on GTX 1060-tier hardware. Colorblind modes. Death-to-new-run timing. Minimum spec finalized.
