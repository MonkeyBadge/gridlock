# Architecture Research

*Last updated: 2026-03-09*

---

## Grid & Pathfinding

### Grid Structure

Use a **flat 2D logical grid with 3D visual representation**. The grid is the source of truth for all game logic — pathfinding, tower placement, trap placement, and collision. The 3D scene is a rendering layer on top of the logical grid.

Each cell in the grid carries:

```
GridCell {
  position: Vector2Int          // logical grid coordinates
  state: enum (Empty, Tower, Trap, Spawn, Exit)
  occupant: EntityId | null     // which tower/trap occupies this cell
  passable: bool                // derived: is this cell walkable by enemies
  trapId: EntityId | null       // floor trap if any (can coexist with passable=true)
}
```

The grid lives as a flat array (`cell[x + y * width]`) for cache efficiency. All pathfinding and placement queries operate on this array.

**Floor traps are not blockers.** They occupy a cell but leave `passable = true`. This means the same cell data structure supports both tower-walls and trap-floors without ambiguity.

### Tower Placement Validation (Always-Valid-Path Enforcement)

Before committing a tower placement, run a **reachability check**:

1. Tentatively mark the target cell as impassable.
2. Run a BFS/flood-fill from every active spawn point.
3. If every exit is reachable from every spawn, the placement is legal — commit it and trigger pathfinding recalculation.
4. If any spawn cannot reach any exit, reject the placement and restore the cell.

Use BFS (not A*) for this check — it is faster for pure reachability, visits each cell at most once, and has no heuristic overhead. For a 30×30 grid this is trivially fast. For larger grids (50×50+) still negligible at ~2500 cell visits max.

This check runs **only on tower placement events**, not every frame — cost is paid once per player decision.

### Pathfinding Strategy: Flow Fields (Primary Recommendation)

For this game's access pattern — many enemies sharing the same goal (the exit) — **flow fields are dramatically more efficient than per-enemy A***.

A flow field is computed once per grid state from the exit outward (Dijkstra/BFS in reverse), producing a direction vector for every passable cell. Each enemy then simply reads its current cell's direction and moves. No per-enemy search.

```
FlowField {
  directions: Vector2[gridWidth * gridHeight]  // best direction from each cell
  costs: float[gridWidth * gridHeight]         // optional: distance-to-exit per cell
  version: int                                 // incremented on each recalculation
}
```

**When a tower is placed:**
1. Validate path (BFS reachability check — see above).
2. Mark cell as impassable in the grid.
3. Recompute the flow field from scratch (Dijkstra from exit, ~milliseconds for typical grid sizes).
4. Broadcast the new `version` number to all enemies.

**Enemy response to field version change:**
- Each enemy caches the `version` it is navigating against.
- On each movement tick, if `enemy.fieldVersion != currentField.version`, the enemy re-reads its direction from the new field. No special re-routing code needed — the field handles it automatically.
- Enemies in mid-step finish their current cell transition, then follow the new field. This prevents visual snapping.

**Why not hierarchical A*:** Hierarchical A* (HPA*) shines when you have many agents with *different* goals. Here, all enemies share the same goal (the exit). Flow fields are strictly better for this access pattern and simpler to implement correctly.

**When to fall back to per-enemy A*:** If boss enemies need to navigate to a *different* target (e.g., chasing the player, attacking a specific tower), use A* only for that enemy. Standard enemies always use the flow field.

### Handling Multiple Spawn Points

Compute one flow field per exit. If there is a single exit (standard case), one flow field covers all enemies. If future maps have multiple exits, compute one field per exit and assign enemies to their target exit at spawn.

### Handling Enemies Mid-Path When Route Changes

The flow field approach handles this elegantly — enemies have no stored path to invalidate. They read their next direction from the field on every movement step. When the field updates, their next read naturally follows the new route. No explicit "re-route this enemy" logic is required.

For enemies mid-cell-transition: let them complete the step (prevents visual jitter), then follow the new field from the destination cell.

---

## Tower System

### Data-Driven Tower Definitions

Define all tower archetypes in external data (JSON or ScriptableObjects in Unity, or equivalent resource files). No hardcoded tower stats in code.

```
TowerDefinition {
  id: string                    // "frost_cannon", "poison_spire"
  classId: string               // which class pool this belongs to
  displayName: string
  description: string
  cost: int
  attackDamage: float
  attackRange: float            // in grid units
  attackSpeed: float            // attacks per second
  damageType: DamageType        // enum: Physical, Magic, Fire, Ice, Poison, Lightning
  statusEffect: StatusEffectDef | null
  upgradeTree: UpgradeNode[]
  synergyTags: string[]         // e.g. ["frost_class", "aoe", "slow"]
  targeting: TargetingMode      // First, Last, Strongest, Closest, LowestHP
  projectileId: string | null   // null = instant/hitscan
}

UpgradeNode {
  id: string
  cost: int
  statDeltas: Map<string, float>  // e.g. {"attackDamage": 10, "attackRange": 0.5}
  newSynergyTags: string[]
  description: string
}
```

Towers are defined entirely by data. The runtime `Tower` component reads its `TowerDefinition` and operates generically. No subclasses per tower type.

### Tower Attack Logic

```
Tower (runtime component) {
  definition: TowerDefinition   // reference to static data
  upgrades: UpgradeNode[]       // applied upgrades, modifying effective stats
  effectiveStats: TowerStats    // computed = base + upgrade deltas + synergy bonuses
  currentTarget: EntityId | null
  attackCooldown: float
}
```

**Attack loop (per tower, per tick):**
1. If cooldown > 0, decrement and skip.
2. Find enemies within `effectiveStats.attackRange` (use spatial partitioning — see Performance section).
3. Select target by `targetingMode`.
4. Apply damage via the damage matrix (see Enemy System).
5. If `statusEffect` defined, apply to target enemy.
6. Reset cooldown to `1 / effectiveStats.attackSpeed`.

Targeting queries are the hot path. Do not iterate all enemies for every tower every frame — use a spatial grid or quadtree (see Performance).

### Class and Synergy System

The synergy system uses a **tag-based component model** rather than hardcoded class checks.

Each tower has `synergyTags` (defined in data). A `SynergyManager` singleton holds a registry of active synergy rules, also defined in data:

```
SynergyRule {
  id: string
  requiredTags: string[]        // all must be present on the map
  minCount: int                 // how many towers with matching tags needed
  effect: SynergyEffect         // stat bonus applied to matching towers
  description: string
}

SynergyEffect {
  targetTags: string[]          // which towers receive the bonus
  statBonus: Map<string, float> // {"attackDamage": 0.15} = +15%
  bonusType: Flat | Percent
}
```

**When a tower is placed or removed**, the `SynergyManager` re-evaluates all rules. For towers that match updated rules, their `effectiveStats` are recomputed. This is a low-frequency event (player action), so full re-evaluation is acceptable.

This approach means new synergies require only new data entries, no new code.

---

## Status Effect System

### Effect Representation

Each enemy maintains a list of active `StatusEffectInstance` objects:

```
StatusEffectInstance {
  type: StatusEffectType        // Frost, Poison, Burn
  sourceId: EntityId            // which tower applied it (for stacking rules)
  intensity: float              // e.g., slow percentage or DoT damage per tick
  duration: float               // remaining seconds
  tickInterval: float           // seconds between DoT ticks (0 = continuous/modifier)
  tickAccumulator: float        // time since last tick
  stackIndex: int               // which stack number this is (for capped stacking)
}
```

### Stacking Rules

Define per effect type (in data, not code):

```
StatusEffectConfig {
  type: StatusEffectType
  maxStacks: int                // -1 = unlimited (Poison), 1 = no stacking (Frost)
  stackBehavior: Refresh | Add | Extend
    // Refresh: resets duration on re-application (Burn)
    // Add: new instance added up to maxStacks (Poison)
    // Extend: adds duration to existing instance (alternative Frost behavior)
  tickInterval: float
  dispatchesEvent: bool         // whether to fire an event on application (for future combos)
}
```

**Frost** (slow): max 1 stack, Refresh behavior. Slows move speed by `intensity`%. Re-application resets duration and may increase intensity if new application is stronger.

**Poison** (DoT): up to N stacks (e.g., 5), Add behavior. Each stack ticks independently. Total DPS scales with stacks.

**Burn** (DoT + spread): max 1 stack per enemy, Refresh behavior. On tick, check nearby enemies within radius; apply Burn to them at reduced intensity. Spread logic runs in the Burn tick handler.

### Effect Processing Loop

Do not tick all effects on all enemies every frame. Use a **deferred tick queue**:

1. On application, schedule the effect's first tick at `now + tickInterval`.
2. Maintain a priority queue (min-heap by next-tick-time) of pending ticks.
3. Each frame, pop all ticks whose scheduled time <= current time and process them.
4. After processing, re-schedule at `now + tickInterval` if duration remains.

This means the per-frame cost scales with **ticks due this frame**, not **all effects on all enemies**. At reasonable tick intervals (0.25–1.0s), this is very low even with hundreds of enemies affected.

**Continuous modifiers** (Frost slow) are not ticks — they are passive multipliers read by the movement system. No per-frame processing needed; the movement system reads `enemy.moveSpeedMultiplier` which is recomputed when effects are applied/removed.

### Combo Reactions (Future Extension Point)

The `dispatchesEvent: bool` flag on `StatusEffectConfig` exists for this. When a new effect is applied to an enemy that already has a specific effect:

1. The effect application fires an `EffectAppliedEvent { enemyId, newType, existingTypes }`.
2. A `ComboReactionSystem` listens and checks if any combo rule matches.
3. If matched: trigger the combo effect (e.g., Shatter, Toxic Explosion) and optionally remove the source effects.

This extension requires no changes to the core status effect system — it plugs in via the event bus.

---

## Enemy System

### Damage Type / Armor Type Matrix

Store the 6×6 matrix as a static lookup table, not a switch/case chain:

```
DamageMatrix {
  // [damageType][armorType] = damage multiplier
  multipliers: float[6][6]
}

// Example entries:
// Physical vs Light Armor    = 1.5x
// Physical vs Heavy Armor    = 0.6x
// Magic vs Heavy Armor       = 1.4x
// Magic vs MagicResistant    = 0.4x
// Poison vs Boss             = 0.7x
// (all others default to 1.0x)
```

Define multipliers in a data file (JSON/CSV). At startup, load into a flat `float[36]` array indexed by `damageTypeIndex * 6 + armorTypeIndex`.

**Applying damage:**
```
effectiveDamage = rawDamage * matrix[attackType][targetArmorType] * targetDefenseMultiplier
```

This is a single array lookup — negligible cost per attack.

### Enemy State Machine

Use a **hierarchical state machine** (HSM) per enemy, with states as objects/classes rather than enums+switch statements. States own their transition logic.

```
EnemyState (base) {
  onEnter(enemy)
  onUpdate(enemy, dt): EnemyState | null  // null = no transition
  onExit(enemy)
}
```

**Standard enemy states:**

- `Pathing`: Read flow field, move toward exit. Default state.
- `Staggered`: Briefly halted (e.g., freeze effect or hit stun). Returns to Pathing.
- `Dead`: Trigger death sequence, queue removal.

**Boss-specific states extend the same base:**

- `Pathing` (overridden: bosses may ignore flow field for A* targeting)
- `Shielded`: Absorbs damage, spawns adds
- `Splitting`: Boss splits into multiple sub-enemies
- `Teleporting`: Boss relocates to a new cell
- `Enraged`: Increased speed/damage after HP threshold

Boss states are defined per-boss-type as a state configuration asset — behavior changes require no new code, only new state graphs.

**Reacting to status effects:**
Effects do not directly modify state. Instead, the `Pathing` state reads `enemy.moveSpeedMultiplier` (set by Frost) and applies it to movement. Stagger/freeze thresholds can trigger a `Staggered` state transition from within `Pathing.onUpdate`. This keeps state and effect systems decoupled.

### Wave and Spawn System

```
WaveDefinition {
  waveNumber: int
  groups: SpawnGroup[]
  interGroupDelay: float
  isBossWave: bool
  bossId: string | null
}

SpawnGroup {
  enemyId: string
  count: int
  spawnInterval: float          // seconds between each spawn in group
  spawnPoint: Vector2Int | null // null = use default/random spawn point
  delayFromWaveStart: float
}
```

The `WaveController` reads `WaveDefinition` data and drives a coroutine/timer that spawns enemies per the schedule. Between waves, it waits for the preparation phase timer (Timed mode) or for the player trigger (Player-Triggered mode) — this distinction is a single flag on the `WaveController`, not separate systems.

**Boss waves** are a `WaveDefinition` with `isBossWave: true`. The `WaveController` spawns the boss entity via the same spawn pipeline. The boss's unique mechanics are implemented in its state machine — the spawn system does not need to know about boss mechanics.

---

## Roguelite Architecture

### State Separation

The most critical architectural decision: **run state and meta state must never be stored in the same place**.

```
RunState (ephemeral, lives in memory, discarded on run end)
{
  currentWave: int
  playerHP: int
  playerResources: int
  placedTowers: Tower[]
  activeEnemies: Enemy[]
  currentClass: ClassId
  runUpgrades: UpgradeId[]      // upgrades chosen during this run
  mapSeed: int
}

MetaState (persistent, written to disk on change)
{
  unlockedClasses: ClassId[]
  unlockedTowers: Map<ClassId, TowerId[]>
  permanentUpgrades: UpgradeId[]
  completedRuns: RunSummary[]
  endlessHighScores: Map<ClassId, int>
  currency: int                 // meta currency for permanent upgrades
}
```

`RunState` is never serialized to disk during normal play (only for crash recovery, optionally). `MetaState` is written to disk whenever it changes (after each wave clear, boss kill, run end).

**Run end flow:**
1. Compute `RunSummary` from `RunState` (wave reached, enemies killed, time, class used).
2. Compute `MetaRewards` from summary (currency earned, unlocks triggered).
3. Apply `MetaRewards` to `MetaState`.
4. Write `MetaState` to disk.
5. Discard `RunState`.

This means a crash mid-run at worst loses run progress — meta progress (the part players care about long-term) is durable.

### Save/Load Structure

Use a **versioned save format** from day one. Schema migrations are painful to retrofit.

```json
{
  "saveVersion": 1,
  "metaState": {
    "unlockedClasses": ["frost_class"],
    "permanentUpgrades": ["upgrade_001"],
    "currency": 450,
    "endlessHighScores": { "frost_class": 42 },
    "completedRuns": [
      { "waveReached": 15, "class": "frost_class", "timestamp": 1741478400 }
    ]
  }
}
```

**Upgrade/unlock references use string IDs, not indices.** If you use array indices and later reorder or add items, saves break. String IDs are stable across content additions.

Include `saveVersion` at the top level. On load, run migration functions if `saveVersion < currentVersion`. Even if you never need to migrate, the infrastructure costs nothing and saves a painful retrofit.

**Crash recovery (optional, recommended):** Serialize `RunState` to a temp file at the start of each wave. On launch, detect and offer to resume. Discard temp file on clean run completion.

### Endless Mode Integration

Endless mode uses the same `RunState`/`MetaState` separation. The only difference: `RunState.waveNumber` never triggers a "run end" condition — it escalates indefinitely. Score (wave reached) is written to `MetaState.endlessHighScores` on game over. No separate endless system needed.

---

## Suggested Build Order

Build in this order. Each phase's systems are dependencies for the next.

1. **Grid system** — Cell data structure, flat array layout, passable/impassable logic. Everything depends on this.

2. **Path validation (BFS reachability)** — Before pathfinding, implement the placement guard. Prevents building yourself into bad states while testing.

3. **Flow field pathfinding** — Dijkstra from exit, direction vectors per cell. Test with placeholder enemies (move-toward-exit cubes) before any other enemy logic.

4. **Enemy movement on flow field** — Basic enemy entity: reads flow field, moves, reaches exit. No combat yet. Validates the core loop concept.

5. **Tower placement system** — Place/remove towers on grid, triggers reachability check + flow field recalculation. Now the core "towers are maze walls" loop is playable.

6. **Wave spawn system** — `WaveDefinition` data, `WaveController`, spawn scheduling. Combine with steps 4–5 for a minimal playable loop.

7. **Damage matrix + enemy HP** — Load 6×6 matrix from data, apply damage to enemies on contact/attack range. Enemies can now die.

8. **Tower attack logic** — Range queries, targeting modes, attack cooldown loop. Towers can now kill enemies. First truly playable game loop.

9. **Status effect system** — Effect instances, tick queue, Frost/Poison/Burn implementations. Layer on top of working combat.

10. **Enemy state machine** — Formalize Pathing/Staggered/Dead states. Required before boss states can be added.

11. **Tower definitions (data-driven)** — Move hardcoded tower stats into data files. Required before class system makes sense.

12. **Class system + synergy manager** — Class pools, synergy rules, `SynergyManager` tag evaluation. Requires tower data to be external.

13. **Tower upgrade system** — `UpgradeNode` data, upgrade application to `effectiveStats`. Builds on data-driven tower definitions.

14. **Boss system** — Boss `WaveDefinition` entries, boss-specific state machine states. Requires wave system, state machine, and damage system.

15. **Floor trap system** — Trap definitions, placement on passable cells, trigger logic on enemy step. Can be built any time after step 5; listed here because it's lower priority than combat.

16. **Meta state + save/load** — `MetaState` structure, disk serialization, versioned save format. Must exist before roguelite loop is complete.

17. **Run flow** — Start-run, mid-run, end-run transitions. Reward calculation, meta currency. Depends on meta state.

18. **Roguelite meta progression UI and unlocks** — Class unlocks, permanent upgrades, endless high scores. Depends on meta state + run flow.

---

## Performance Considerations

### Grid & Pathfinding

- **Flow field over per-enemy A***: O(GridSize) to compute once vs O(EnemyCount × GridSize) per recalculation. For 200 enemies on a 40×40 grid, this is roughly 200× fewer operations per tower placement.
- **Flat array for grid**: `cell[x + y * width]` is cache-friendly. Avoid dictionary/hashmap keyed on coordinates for hot-path queries.
- **Flow field recalculation is async-safe**: The flow field can be computed on a background thread (it reads only the immutable grid snapshot, produces a new array). Swap the reference atomically when done. Enemies read the old field until the new one is ready — produces a one-frame lag at most, invisible to players.
- **BFS for reachability check**: Runs only on tower placement (player event). No optimization needed beyond using the flat array.

### Tower Attack System

- **Spatial partitioning for range queries**: Do not iterate all enemies for every tower every frame. Use a spatial grid (divide the play area into cells of size = max tower range). Each tower queries only its cell + neighbors. Updates the grid as enemies move.
- **Targeting cache**: Cache the current target. Only re-evaluate targeting when the target dies, leaves range, or a new enemy enters range. Do not re-sort all candidates every frame.
- **Stagger attack tick processing**: Use a tower update queue — towers update on a round-robin spread across frames rather than all towers every frame. For 50 towers updating at 10/frame, cost is distributed evenly.

### Status Effect System

- **Deferred tick queue (min-heap)**: Scales with ticks-due-this-frame, not active effects. At 0.5s tick intervals, 200 enemies with 2 effects each = 400 scheduled ticks, but only ~800/s ticks across all of them. At 60fps that is ~13 ticks per frame — negligible.
- **Avoid per-effect Update() calls**: Never register an `Update()` coroutine per effect instance. The heap-based queue avoids this entirely.
- **Effect pooling**: Pool `StatusEffectInstance` objects. DoT effects are created and destroyed frequently; pooling eliminates allocation pressure and GC stalls.
- **Move speed multiplier as a derived value**: Compute `enemy.moveSpeedMultiplier` once when effects are applied/removed, not every frame. The movement system reads the cached value.

### Enemy System

- **Enemy pooling**: Pre-allocate an enemy pool at wave start based on `WaveDefinition.totalEnemyCount`. Avoids mid-wave allocations.
- **Dead enemy cleanup**: Mark enemies dead, move to inactive pool, batch-remove from spatial partitioning at end of frame. Do not remove mid-frame while iterating.
- **Boss enemy budget**: Boss enemies may use per-entity A* and run expensive state logic. Limit concurrent bosses (design constraint: 1 at a time) to cap this cost.
- **LOD for effects**: At high enemy counts, reduce visual effect fidelity for enemies far from the camera. Status effect particle systems are the most likely performance bottleneck on the rendering side.

### Roguelite / Save System

- **Write meta state asynchronously**: Never block the main thread on disk I/O. Fire-and-forget async write after run milestones. Keep a dirty flag — only write when state actually changed.
- **Run state is never large**: `RunState` contains references (IDs), not deep copies of enemy arrays. Serialization for crash recovery should be fast.
