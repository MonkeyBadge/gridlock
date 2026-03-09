# Project: [Title TBD]

## Vision

A 3D maze-builder tower defense game where **towers are the maze**. Players place towers that physically block enemy movement, forcing enemies to pathfind through whatever maze the player builds. The strategic depth comes from designing efficient killing corridors, chaining elemental effects, and leveraging class-specific tower synergies across roguelite runs.

Targeting Steam Early Access as the initial release, with community feedback driving post-launch development.

---

## Core Value

**The maze IS the defense.** Unlike traditional tower defense where towers sit beside a fixed path, here every tower placed is a wall — enemies always have a valid route to the exit, but the player decides how long and how deadly that route is.

---

## What We're Building

### Core Loop
1. Player selects a **class/race** before each run (determines available tower pool)
2. Enemies spawn and pathfind toward the exit using the shortest available route
3. Player places towers to extend/redirect the enemy path and deal damage
4. Enemies reaching the exit cost lives
5. Between waves, player upgrades towers, manages resources, and refines the maze
6. Run ends on death or map clear — meta progression carries over permanently

### Tower-as-Wall System
- Towers are physical blockers — they occupy grid cells and enemies cannot pass through them
- **Path enforcement**: The game validates a walkable path always exists before allowing tower placement
- **Traps**: Separate from towers — floor-level items placed on walkable tiles that enemies step on (slow zones, damage floors, trigger effects)
- Enemies use dynamic pathfinding (A*) and re-route when new towers are placed mid-wave

### Class / Race System
- Each class unlocks a distinct tower pool (no cross-class towers in a run)
- Intra-class synergies: towers of the same class interact and buff each other
- Classes will specialize in different damage types, encouraging players to adapt to enemy rosters
- Meta progression: unlock new classes, upgrade class abilities permanently between runs
- Design target for Early Access: **3 classes**, each with 8–12 towers

### Elemental Status Effects
| Effect | Primary Behavior | Recommended Combo |
|--------|-----------------|-------------------|
| Frost | Slows enemy movement speed | Frost + Physical hit = Shatter (bonus damage) |
| Poison | Damage over time, stacks | Poison + Burn = Toxic Explosion (burst AoE) |
| Burn | Damage over time, spreads between nearby enemies | Burn + Frost = Steam (brief blind/confusion) |

Combo reactions are a stretch goal for Early Access — base effects ship first.

### Attack & Armor Type System
**Damage types:** Physical, Magic, Fire, Ice, Poison, Lightning
**Armor types:** Unarmored, Light, Heavy, Magic-Resistant, Elemental-Resistant, Boss

Counters (suggested):
- Physical → Light Armor (effective), Heavy Armor (ineffective)
- Fire → Unarmored (effective), Elemental-Resistant (ineffective)
- Magic → Heavy Armor (effective), Magic-Resistant (ineffective)
- Poison → stacks regardless of armor, reduced on Boss
- Each class specializes in 1–2 damage types → class choice matters against enemy roster

### Boss System
- **Mini-bosses**: Appear at end of every 5th wave — heavily armored, larger HP pool, special movement (teleport, shield, split)
- **Boss levels**: Dedicated milestone stages with unique mechanics that temporarily change rules (e.g., enemies can break 1 tower, boss spawns adds, path resets)
- Boss kills drop rare upgrade materials for meta progression

### Wave Modes
- **Timed Waves** (primary / v1): Countdown between waves, preparation phase, classic feel
- **Player-Triggered Waves** (secondary / v1): Player sends waves when ready, risk/reward bonus for early sending
- *(Continuous stream — deferred, out of scope for v1)*

### Roguelite Structure
- Each run is self-contained (class choice, tower upgrades, maze decisions)
- **Meta progression**: Permanent unlocks carry over — new towers, class upgrades, passive bonuses
- **Endless escalation mode**: One run that never ends, difficulty scales infinitely, leaderboard-eligible
- Both modes share the same meta progression pool

---

## Requirements

### Validated
*(None yet — ship to validate)*

### Active
- [ ] Core tower-placement + pathfinding loop
- [ ] 3 playable classes, each with distinct tower pools
- [ ] Elemental status effects (Frost, Poison, Burn)
- [ ] Attack/armor type damage matrix
- [ ] Trap system (floor-level path effects)
- [ ] Timed waves mode
- [ ] Player-triggered waves mode
- [ ] Mini-boss encounters (every 5th wave)
- [ ] Boss level milestones
- [ ] Roguelite meta progression (unlocks, class upgrades)
- [ ] Endless escalation mode
- [ ] 3D camera with usable play angle
- [ ] Steam Early Access release (storefront, build, basic achievements)

### Performance
- [ ] Game must be optimized for smooth performance without sacrificing visual/gameplay quality
- [ ] Dynamic pathfinding (A*) must handle many enemies re-routing simultaneously without frame drops
- [ ] Tower placement, effect rendering, and enemy counts should scale without degrading experience

### Monetization
- [ ] Paid game on Steam (buy-to-play, price TBD)
- [ ] DLC packs post-EA launch (content expansions — new classes, maps, enemies)
- No free-to-play, no microtransactions, no loot boxes

### Out of Scope (v1)
- Multiplayer — deferred post-EA launch
- DLC — post-EA only
- Continuous stream wave mode — deferred
- More than 3 classes at EA launch — expand post-launch via DLC/updates
- Elemental combo reactions — stretch goal, base effects first
- Full story/campaign — EA is run-based, no narrative required at launch

---

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Towers as maze walls | Core differentiator — the maze IS the defense | Confirmed |
| Always-valid pathfinding enforcement | Prevents cheese, preserves maze integrity | Confirmed |
| Class system over open tower pool | Creates identity, replayability, and synergy design space | Confirmed |
| Early Access launch | Build community early, validate core loop before full polish | Confirmed |
| 3D perspective | Modern feel, differentiates from 2D TD market | Confirmed |
| Roguelite + Endless as dual modes | Satisfies both structured-run and infinite-grind players | Confirmed |
| Elemental combos as stretch goal | Base effects ship first, combos add depth without blocking launch | Pending |
| Performance as a first-class requirement | Optimization must be built in from the start, not bolted on later | Confirmed |

---

## What "Done" Looks Like (Early Access)

A player can:
1. Pick a class and start a run
2. Place towers on a 3D grid map to build a killing maze
3. Survive escalating waves including mini-bosses and a boss level
4. Use elemental effects and exploit armor weaknesses
5. Die, carry meta progress forward, and start a new run feeling stronger
6. Play an endless mode and compare scores

---

*Last updated: 2026-03-09 after initialization*
