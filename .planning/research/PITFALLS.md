# Pitfalls Research

Sources: GDC post-mortems, published indie dev post-mortems (Blendo Games, Subset Games, Ninja Kiwi devlogs),
Steam review analysis, r/gamedev & TIGSource community knowledge, academic pathfinding literature,
and design writing by Josh Ge, Mike Stout, and others. No live web search was used; this reflects
knowledge through August 2025.

---

## Pathfinding Pitfalls

### 1. Recalculating the full grid every frame (or every placement)

**What it is:** The naive approach runs a full A* (or Dijkstra flood-fill) for every enemy every time
any tower is placed or removed. With 50 enemies and a 64x64 grid, this is catastrophic.

**Warning sign (early detection):** Placement feels "laggy" even in a small prototype with 10 towers
and 20 enemies. CPU spikes visible in the profiler exactly on placement events.

**Prevention:**
- Use a single shared flow-field (Dijkstra from goal outward). All enemies read the same field; only
  one recalculation per placement event is needed, not one per enemy.
- Dirty-flag the flow field. Only recompute when topology actually changes (tower placed/removed),
  not on every frame.
- For large grids, use hierarchical pathfinding (HPA*): cluster the grid, recompute the cluster
  graph on placement, and only re-resolve affected clusters rather than the full grid.
- Cap recalculation frequency with a cooldown (e.g., max once per 100ms), queuing rapid placements
  and processing them in one batch.

**Phase it surfaces:** Prototype/vertical slice — the moment you have more than ~30 simultaneous
enemies on a medium-sized grid.

---

### 2. Blocking all paths (the "no valid path" crash or freeze)

**What it is:** The player places a tower that completely seals the exit. The pathfinder either
returns null (crash if unhandled), enters an infinite loop, or all enemies stand still.

**Warning sign:** First time a tester builds a wall all the way across the map.

**Prevention:**
- Run a reachability pre-check (BFS from start to goal) *before* confirming placement. Only allow
  placement if the path remains valid. This is the canonical solution used by Gemcraft, Kingdom Rush
  mods, and virtually every maze-TD.
- Make the pre-check cheap: BFS on a boolean-only grid copy is O(W*H), fast even at 128x128.
- Decide your design stance up front: "you cannot place a wall that blocks all paths" (strict) vs.
  "enemies will find an alternative or die" (looser). Strict is friendlier; looser enables
  interesting choke designs but requires robust fallback behavior.
- Handle the null-path case defensively regardless — enemies should never be able to soft-lock the
  game.

**Phase it surfaces:** First playtest session, day one.

---

### 3. Enemies "teleporting" or cutting corners on diagonal moves

**What it is:** Diagonal pathfinding allows enemies to slide through the corner of two diagonally-
adjacent walls, visually clipping through geometry in a 3D game.

**Warning sign:** In 2D prototype, enemies appear to walk through wall corners.

**Prevention:**
- Disable diagonal movement entirely (4-directional grid), which is the simplest fix and works well
  for most maze-TDs.
- If diagonals are needed, apply corner-cutting prevention: a diagonal move is only valid if *both*
  adjacent orthogonal cells are also passable.
- In 3D, confirm that nav-mesh clearance radius matches the enemy's visual collision radius.

**Phase it surfaces:** Early prototype, first time diagonal movement is tested.

---

### 4. Enemies all taking the exact same path (herding / convoy behavior)

**What it is:** With a shared flow field, all enemies follow an identical route, forming a single
file convoy. This makes splash damage trivially powerful and removes interesting spread behavior.

**Warning sign:** Splash-damage towers become overwhelmingly dominant in early playtests; players
cluster all towers at one bottleneck.

**Prevention:**
- Add per-enemy path deviation: small random lateral offsets, formation spreading, or sub-tile
  jitter so enemies don't perfectly overlap.
- Use "smoothed" paths with funnel algorithms so enemies don't robotic zigzag on a grid.
- Consider multiple path candidates (k-shortest paths) and assign enemies to different ones based
  on spawn timing or enemy type, creating natural spread.

**Phase it surfaces:** Alpha playtesting, when the game starts to feel "solved."

---

### 5. Pathfinder not accounting for tower costs / enemy type preferences

**What it is:** All enemy types use the same flow field. A fast flyer ignores walls; a heavy tank
should prefer wide corridors. When the pathfinder doesn't model this, certain tower arrangements
are either irrelevant or broken for specific enemy types.

**Warning sign:** Flying enemies introduced in mid-development require a complete pathfinding
rewrite because the system has no concept of passability per enemy type.

**Prevention:**
- Design your passability layer abstraction from day one: at minimum, two layers (ground, flying).
- Store multiple flow fields if needed (one per movement type), computed lazily and cached.
- Budget this cost in architecture before writing any enemy movement code.

**Phase it surfaces:** When the second enemy type is added (often mid-alpha).

---

### 6. Memory pressure from large flow-field grids

**What it is:** A 256x256 grid with 4-byte direction values per cell = 256KB per flow field. With
multiple enemy types and multiple active levels, this can silently bloat memory.

**Warning sign:** Memory usage creeping up in profiler during playtesting without an obvious cause.

**Prevention:**
- Use 2-bit direction encoding (only 4 cardinal directions needed) packed into bitfields.
- Reuse a single flow field buffer, recomputing on demand rather than keeping multiple cached.
- Profile memory at target platform spec early.

**Phase it surfaces:** Mid-alpha to beta, when level sizes and enemy variety increase.

---

## Maze-TD Design Pitfalls

### 1. The one optimal maze exists and players find it on game 2

**What it is:** Because the game is deterministic (fixed enemy paths, fixed tower stats), mathematics
eventually reveals a single dominant maze topology — usually a maximum-length serpentine — that
beats everything else. Players share it online and the game becomes a one-layout puzzle.

**Warning sign:** Playtesters stop experimenting with layouts after 3-4 sessions. Steam reviews say
"once you find the pattern it's just execution."

**Prevention:**
- Vary enemy entry/exit points per wave or per run so no single layout is universally optimal.
- Use multiple simultaneous entry points, making a single serpentine impossible.
- Introduce enemy types that explicitly punish long mazes (e.g., enemies that gain speed per tile
  traveled, or that split into faster units after a distance threshold).
- Give the roguelite meta a reason to use *different* layouts each run (class-specific towers that
  only synergize in certain spatial patterns).
- Consider soft anti-maze mechanics: enemies that become immune to slow effects after N slow
  applications, making "slow + long path" less dominant.

**Phase it surfaces:** Closed beta, when experienced players dominate the leaderboard with one build.

---

### 2. Maze complexity overwhelms new players (accessibility cliff)

**What it is:** The spatial reasoning required to build an effective maze is a hard skill gate.
Players who don't "see" the maze can't engage with the core loop at all.

**Warning sign:** New playtesters place towers randomly and die on wave 3 with no sense of why.

**Prevention:**
- Provide ghost-line overlays showing the current enemy path when hovering a placement.
- Show path-length delta ("+12 tiles" indicator) when placing a wall segment.
- Design the first few levels to have guided maze corridors, constraining the problem space.
- Separate "where to build" from "which tower to build" in early tutorials.

**Phase it surfaces:** First external playtest.

---

### 3. Towers-as-walls creates unsellable dead investments

**What it is:** If towers serve dual purpose as maze walls, removing a tower to reoptimize the maze
destroys your structure. Players feel locked into early decisions with no recourse.

**Warning sign:** Playtesters report feeling "stuck" mid-run because their early towers are now
blocking a better layout they can see.

**Prevention:**
- Allow selling towers (even at a loss) and explicitly design the sell mechanic with maze
  reconstruction in mind.
- Consider "free rotation/repositioning" during a grace period between waves.
- Some games (Dungeon Defenders lineage) allow free repositioning before round start — evaluate
  whether this fits your roguelite loop.
- Roguelite context actually helps: if runs are short (~30 min), players accept sunk costs more
  because the run ends before frustration peaks.

**Phase it surfaces:** Mid-alpha playtesting.

---

### 4. Economic balance: maze length scales faster than enemy HP

**What it is:** A longer maze path dramatically increases total DPS applied to each enemy (more
towers firing for longer transit time). If maze length isn't penalized, gold spent on maze
structure returns more than gold spent on tower quality.

**Warning sign:** Playtesters rarely upgrade towers; they just extend the maze indefinitely.

**Prevention:**
- Cap maze path length, or have enemies gain HP/speed bonuses as path length increases.
- Make gold/resource scarce enough that players choose between "more towers" and "better towers."
- Design tower placement costs to scale with maze length contribution (e.g., towers adjacent to
  long paths cost more).
- Regularly audit DPS-per-gold of "pure maze extension" vs. "tower upgrade" — they should be
  roughly equivalent.

**Phase it surfaces:** Closed alpha, during early economy tuning.

---

### 5. Players wall themselves into a corner (literal dead-end construction)

**What it is:** Player builds inward and inadvertently seals off valid placement space for future
towers, or creates a layout that is mechanically valid but spatially awkward.

**Warning sign:** Playtesters express frustration at late waves when they have gold but nowhere
useful to build.

**Prevention:**
- Visualize remaining buildable area as part of the UI.
- Design the grid to be large enough that this is rare, but small enough that choices feel
  meaningful.
- Consider "reserve zones" — regions the player cannot build in, ensuring corridors remain.

**Phase it surfaces:** Mid-alpha.

---

### 6. Boss encounters break the maze meta

**What it is:** Bosses are typically immune to slow, take reduced damage from DoT, or have special
movement (flight, tunneling). This invalidates the maze the player spent the entire run building,
creating a frustrating "your strategy doesn't work here" moment.

**Warning sign:** Playtesters build a maze all run and feel cheated when the boss ignores it.

**Prevention:**
- Communicate boss properties clearly *before* the wave (telegraphing).
- Ensure bosses have weaknesses that reward *some* aspect of the maze (e.g., immune to slow but
  double damage from tower fire in a long corridor).
- Design bosses as "stress tests" of the maze, not negations of it.
- Boss behavior should be a known variable players can plan around, not a surprise.

**Phase it surfaces:** Boss implementation (mid-to-late alpha).

---

## Roguelite Pitfalls

### 1. Run length is too long for the variance

**What it is:** Roguelites derive fun from "fast failure + learning." If runs take 60-90 minutes,
a single bad RNG roll in minute 5 causes 85 minutes of frustrating inevitability. Players quit
mid-run rather than finish a doomed run.

**Warning sign:** Playtest sessions consistently show player quit rates of >30% before the final
boss.

**Prevention:**
- Target 20-40 minute runs for a roguelite TD at launch. Expand with difficulty modifiers later.
- Ensure build-defining choices occur within the first 10 minutes so players know early whether
  their run has a viable identity.
- If a run is unwinnable, make it *obviously* unwinnable quickly (fast difficulty spike) rather
  than slowly (gradual attrition over an hour).

**Phase it surfaces:** First full-run playtesting.

---

### 2. Meta progression makes the base game trivial (power creep inflation)

**What it is:** Permanent unlocks accumulate, and the base difficulty is tuned for "no unlocks."
After 10 hours of play, the game becomes so easy the core loop is meaningless.

**Warning sign:** Veteran playtesters breeze through content that stumped new players; Steam reviews
say "fun for a few hours then too easy."

**Prevention:**
- Tune base difficulty for a partially-unlocked state (the median playthrough experience), not the
  zero-unlock state.
- Use meta unlocks to broaden options (unlock new classes, tower types) rather than purely
  increasing raw stats.
- Add a "challenge mode" or ascension system (like Hades' heat) early in development so experienced
  players have a difficulty ceiling to push against.
- Audit unlock power budget regularly: each unlock should add ~5-10% capability, not 30%.

**Phase it surfaces:** After 10-15 hours of playtesting, once the meta is populated.

---

### 3. RNG offering is "pick from three bad options"

**What it is:** Roguelite offers (cards, upgrades, tower choices) are randomly selected from the
full pool. Early in a run, players are offered three items none of which fit their current build.
The "correct" choice is the least-bad option, which feels like no choice at all.

**Warning sign:** Playtesters say "I never feel excited about the upgrade screen." Qualitative
feedback: "it feels random in a bad way."

**Prevention:**
- Weight offers toward the player's current class and already-selected towers (contextual offer
  pools).
- "Pity" mechanics: track offers a player has been shown and hasn't picked; increase their weight
  to decrease next time.
- Guarantee at least one "build identity" offer per wave threshold (e.g., every 5 waves, one offer
  is guaranteed to synergize with the player's dominant tower type).
- Slay the Spire's approach: separate the card pool into tiers so early-game offers are never
  end-game items that don't fit yet.

**Phase it surfaces:** Mid-alpha, as soon as the offer system has more than 20 items.

---

### 4. No "build identity" moment — runs feel samey

**What it is:** With a large homogeneous upgrade pool, every run feels like the same generic tower
defense. The roguelite layer fails to create distinct run characters.

**Warning sign:** Playtesters can't describe their run in one sentence. "I just upgraded whatever."

**Prevention:**
- Front-load identity-defining choices: class selection, starting relic, or first major upgrade
  should be binary enough to set a direction.
- Design upgrades as build *enablers* rather than stat increments — "this tower now poisons" is
  more identity-defining than "+10% damage."
- Cross-class synergy items should be rare and dramatic, not frequent and mild.

**Phase it surfaces:** Mid-alpha, after the first full playthrough cycle.

---

### 5. Permanent meta progression is gated behind randomness

**What it is:** Meta unlocks require specific in-run achievements ("kill the ice boss with fire
towers") that may not naturally occur in normal play, causing unlock systems to stall.

**Warning sign:** Playtesters report never seeing certain unlocks despite 10+ hours of play.

**Prevention:**
- Meta unlocks should be achievable through deliberate play, not RNG. "Reach wave 20" is good;
  "get offered the ice upgrade three times in one run" is bad.
- Track progress across runs (e.g., cumulative gold spent unlocks the next tier) rather than
  requiring specific one-run conditions.

**Phase it surfaces:** Beta, during unlock rate analysis.

---

### 6. The meta progression spoils the in-run economy

**What it is:** Permanent "start with extra gold" or "towers cost 10% less" upgrades distort the
carefully-tuned in-run economy. The earlier economic balance sessions become irrelevant.

**Prevention:**
- Separate meta-economy modifiers from core economy modifiers in the design document and in code.
- Test the in-run economy in isolation (with meta progression disabled) regularly throughout
  development.
- Prefer meta unlocks that add options (new tower types, new relics) over ones that change numeric
  economy values.

**Phase it surfaces:** Mid-to-late alpha as meta progression is implemented.

---

## Class & Synergy Pitfalls

### 1. One class is objectively the best ("just play the wizard")

**What it is:** With asymmetric classes and tower pools, balance is inherently hard. One class
synergizes better with the current meta enemy lineup, making all other classes feel like handicap
modes.

**Warning sign:** 70%+ of playtester runs use the same class. Steam launch reviews say "X class is
broken OP."

**Prevention:**
- Each class should have a different *type* of power, not different amounts. "Glass cannon vs.
  sustained damage vs. AoE control" is more balanceable than "fast damage vs. slow damage vs.
  medium damage."
- Design enemy types that specifically threaten each class's win condition, ensuring no class
  has a universally dominant strategy.
- Lock-in balance check: before launch, ensure no class has >40% run win-rate in internal testing
  across all difficulty levels.
- Patch velocity matters: plan for a 2-week post-launch balance patch cycle; don't expect to ship
  perfectly balanced.

**Phase it surfaces:** Closed beta with multiple experienced playtesters.

---

### 2. One class is dead on arrival (universally weakest)

**What it is:** The flip side of the above. A class that nobody plays because it's mechanically
inferior or because it requires expertise the game never teaches.

**Warning sign:** A class has <5% pick rate in playtesting data.

**Prevention:**
- After each balance pass, specifically play the least-picked class and assess whether it's weak
  or just hard to understand.
- Buff underperforming classes with *flavor* (unique mechanics) before buffing with numbers — a
  class that does something interesting is more forgiving of a slight power deficit.
- Pair each class with a simple starter relic that sets up its primary strategy, reducing the
  skill floor for learning it.

**Phase it surfaces:** Closed beta.

---

### 3. Synergy graph becomes incomprehensible

**What it is:** Each new class/synergy interaction multiplies cognitive load. At ~4 classes with
~6 synergies each, plus cross-class combos, players can no longer evaluate what synergizes with
what without a spreadsheet.

**Warning sign:** Playtesters report confusion about why a combo "doesn't work" or why damage
numbers are unexpected. Bug reports that turn out to be "working as intended but unintuitive."

**Prevention:**
- Draw the synergy graph literally — nodes are towers/classes, edges are interactions. If it has
  more than 30 edges at launch, cut aggressively.
- Favor "obvious" synergies over "discovered" synergies. Elemental interactions (fire melts ice
  armor) are obvious. "+8% speed to adjacent towers of same element" is discovered.
- In-game encyclopedia/glossary is load-bearing infrastructure, not nice-to-have.
- Test: can a new player explain all synergies of one class after 30 minutes of play? If not,
  reduce synergy count or improve communication.

**Phase it surfaces:** Mid-alpha, as synergy count crosses ~15 total interactions.

---

### 4. Intra-class synergies make mixing classes pointless

**What it is:** Intra-class bonuses are tuned so strongly that mixing classes is a strict power
downgrade. The "class system" becomes "pick one class and only buy that class's towers."

**Warning sign:** Playtesters never mix classes, even in late-game when they have abundant gold
and all their class towers are maxed.

**Prevention:**
- Intra-class synergies should provide *qualitative* bonuses (enabling effects), not purely
  multiplicative damage bonuses. Multiplicative stacking inevitably dominates.
- Design at least one "bridge" mechanic per class pair that rewards cross-class play (e.g., a
  relic that requires two different class towers adjacent to activate).
- The "mixed build penalty" should be zero or minimal; the incentive to stay in-class should come
  from enablers, not from punishing mixing.

**Phase it surfaces:** Mid-alpha, when tower pools are fully populated.

---

### 5. New classes are designed in isolation, break existing synergies

**What it is:** A new class added in Early Access interacts unexpectedly with existing synergies,
creating either an OP combo nobody intended or making an old class obsolete.

**Warning sign:** Class release patch causes immediate community discovery of a dominant combo
within 48 hours.

**Prevention:**
- Maintain a "synergy matrix" document (rows = classes, columns = towers/effects, cells = known
  interactions). Update it with every new class.
- Before shipping a new class, run automated balance tests (even rough simulation) against all
  existing class pairings.
- Stage class releases with clear "this class interacts with X and Y" patch notes so players can
  help spot unintended combos early.

**Phase it surfaces:** EA content updates.

---

## Status Effect Pitfalls

### 1. Stacking infinite DoT kills performance

**What it is:** Each active status effect tick is a game object update. If 50 enemies each have 8
stacking poison applications and poison ticks every 0.5 seconds, you have 800 update events per
second just for poison.

**Warning sign:** Profiler shows "StatusEffectManager.Update()" consuming >5% of frame time with
only 30 enemies on screen.

**Prevention:**
- Use a "collapse" model: instead of N individual poison stacks each ticking independently,
  maintain (damage_per_tick, stack_count, duration) as a struct per enemy. One tick event fires,
  multiplies by stack count, resolves in one operation.
- Cap stacks per effect type (e.g., max 5 poison stacks) — both a balance and a performance
  decision.
- Pool status effect objects; never allocate during gameplay.
- Consider a global "tick budget" system: all DoT effects tick on a shared timer, not per-entity
  per-frame.

**Phase it surfaces:** Mid-alpha, once multiple status-applying towers exist and enemy counts scale.

---

### 2. Status effect interactions create opaque damage numbers

**What it is:** Wet + Lightning = Shocked = 1.5x damage multiplier. Burning + Poison =
Septic = DoT amplification. When 3-4 effects interact, the actual damage dealt is incomprehensible
to the player, making balance impossible to feel.

**Warning sign:** Playtesters frequently ask "why did that enemy die so fast?" or "why is my damage
so low right now?" Number pop-ups appear to be arbitrary.

**Prevention:**
- Budget interactions: no more than 2-level interaction chains (A+B = AB; not A+B+C = ABC).
  The combinatorial explosion of 3-way interactions is unmanageable.
- Make interactions visible: when a combined effect triggers, show a distinct VFX and a named
  effect label ("Shocked!") that players can learn to recognize.
- Design interactions as *binary triggers* (if wet and lightning hit, trigger a shock burst) rather
  than multiplicative modifiers to hidden stats, which are invisible by nature.
- Create a "damage breakdown" tooltip on enemies in debug mode; ship a simplified version of it
  for players.

**Phase it surfaces:** Mid-alpha, once 3+ status effects exist.

---

### 3. Crowd control stacking makes the game trivially easy

**What it is:** Multiple slow effects stack multiplicatively (or even additively), reducing enemy
speed to near-zero. Combined with a long maze, enemies never reach the exit. Difficulty evaporates.

**Warning sign:** Playtesters report "I built a slow tower wall and nothing gets through, it's
boring."

**Prevention:**
- Apply "diminishing returns" to slow stacking (standard: each additional slow applies to the
  remaining speed, not the base speed).
- Hard floor on enemy move speed (e.g., minimum 20% of base speed, never slower).
- Enemies that have been slowed for more than X seconds gain a brief "momentum burst" (immune to
  slow for 1 second), preventing indefinite freeze.
- Design some enemy types as "slow-immune" or "slow-resistant" to force players out of pure CC
  builds.

**Phase it surfaces:** First time a slow tower is placed adjacent to another slow tower in
playtesting.

---

### 4. Attack/armor type matrix becomes a lookup table, not intuitive knowledge

**What it is:** With 5+ damage types and 5+ armor types, the full matrix is 25+ interactions. No
player memorizes this. They either ignore it (build whatever) or consult a wiki, neither of which
is good game design.

**Warning sign:** Playtesters never switch tower types in response to enemy composition because
they don't know which type is effective.

**Prevention:**
- Limit the matrix to 3-4 damage types and 3-4 armor types at launch. 9-16 interactions is the
  maximum for learnable-without-a-wiki.
- Make type effectiveness visually obvious: color coding, distinct impact VFX, and explicit UI
  indicators ("Effective!" / "Resistant" on damage numbers).
- Use named elemental logic that matches player intuition: fire melts ice armor, lightning ignores
  physical armor, poison bypasses magic shields. Intuitive naming reduces cognitive load.
- Design the matrix so players can "discover" it through play rather than front-loading it in a
  tutorial.

**Phase it surfaces:** When the second damage type is added (early alpha).

---

### 5. Status effects visually clutter the screen

**What it is:** Each status effect has particles, overlays, or animations. At 50 enemies with 3
effects each, the screen becomes visually unreadable — players can't see enemy health, movement,
or their own towers.

**Warning sign:** Playtesters cover their eyes or zoom out to maximum when lots of effects trigger.

**Prevention:**
- Budget VFX slots per enemy: maximum 2 simultaneous visual status indicators.
- Use a priority system: the "most important" effect (highest threat, most recently applied) takes
  the visual slot; others are shown as simple icons in the enemy's UI bar.
- Ensure all status VFX are togglable in settings for players with visual sensitivity needs — and
  test with them off to ensure the game is still readable.
- Keep status VFX at low particle counts (4-8 particles per effect) — the cumulative total with
  50 enemies is 200-400 particles, which is manageable.

**Phase it surfaces:** Mid-alpha performance and playtest review.

---

### 6. DoT damage is untelegraphed and feels like invisible damage

**What it is:** Players see the enemy's health bar drop between their tower shots with no visible
cause. They can't tell if the DoT is working, or if they've lost control of the damage model.

**Warning sign:** Playtesters attribute DoT kills to the wrong tower or don't realize DoT is
contributing significantly to DPS.

**Prevention:**
- Show a distinct damage number color/style for DoT ticks (e.g., green for poison, orange for
  burn) separate from direct hit numbers.
- Add a subtle tick VFX on the enemy model (a small pulse or color flash) coinciding with each
  DoT tick.
- Implement a post-wave damage breakdown screen showing DPS contribution by tower and effect type.

**Phase it surfaces:** Early alpha, first time DoT towers are implemented.

---

## Scope & Team Pitfalls

### 1. The "one more system" trap (feature creep before the core is fun)

**What it is:** Developers add content (new classes, new enemy types, new biomes) before the core
loop is proven fun. Each new feature increases the surface area requiring balance without
validating whether the foundation is solid.

**Warning sign:** The design document grows but playtest sessions don't get more fun. Testers
enjoy specific moments but can't articulate why the whole game is compelling.

**Prevention:**
- Establish a "vertical slice" milestone: one class, one biome, 5 waves, all core systems active.
  The vertical slice must be genuinely fun before any new systems are added.
- Lock a "feature freeze" date at least 4 months before EA launch. New features after that date
  require removing an existing feature of equivalent scope.
- Keep a "cut list" alongside the design document: things you *want* to add but are explicitly
  deferred to post-EA. Externalizing the cut list makes cutting feel less like failure.

**Phase it surfaces:** Continuously throughout development; worst in mid-alpha.

---

### 2. Technical debt from "I'll fix it later" pathfinding/systems code

**What it is:** Early prototype pathfinding is written quickly and not refactored. As features
accumulate, the quick solution becomes load-bearing infrastructure that's expensive to change.
Mid-alpha rewrites of core systems are common causes of project abandonment.

**Warning sign:** "We can't add flying enemies because the pathfinder doesn't support movement
types" — any sentence starting with "we can't add X because the pathfinder..."

**Prevention:**
- Design the pathfinding API contract before writing the implementation: what does the caller
  need? What does the pathfinder need to know? Code to the interface.
- Schedule a "systems refactor sprint" at the end of the vertical slice, before adding content.
  This is the cheapest time to pay down technical debt.
- Write at least one integration test for pathfinding behavior (valid path found, invalid path
  blocked) so refactors don't silently break behavior.

**Phase it surfaces:** Transition from prototype to alpha.

---

### 3. Balance work is done by the developer, not by naive testers

**What it is:** Developers know all the tricks, all the tower stats, all the synergies. Their sense
of difficulty is miscalibrated. A game that feels "appropriately challenging" to the developer
feels "brutally hard" to the average player.

**Warning sign:** Developer passes wave 20 comfortably; the first external tester dies on wave 8.

**Prevention:**
- Separate "developer playtesting" (finding bugs, testing edge cases) from "naive playtesting"
  (finding difficulty calibration).
- Get at least 5 external testers who have never seen the game and observe them play without
  coaching. Don't explain anything; watch where they get stuck.
- Use analytics (even simple CSV logs) to track wave death rates across testers. Wave with >50%
  death rate is too hard; wave with 0% death rate is too easy.

**Phase it surfaces:** Closed alpha.

---

### 4. Art/audio scope expands to match ambition, killing productivity

**What it is:** 3D game with multiple classes means multiple tower models, VFX per effect per
tower type, UI for progression systems, enemy animations. Art scope is the single most common
killer of indie 3D games.

**Warning sign:** Programming is waiting on art assets to test systems. Or art is being redone
because systems changed.

**Prevention:**
- Use a strict "art placeholder" policy: grey-box geometry and programmer art for ALL content until
  the gameplay is locked. Never block a design decision on art.
- Define your art style (modular, low-poly, stylized, etc.) for minimum viable assets, not maximum
  quality. One beautiful tower set beats four half-finished tower sets.
- Budget art time explicitly: if one tower model takes 8 hours, and you plan 40 tower types, that's
  320 hours of 3D modeling alone. Is that realistic?
- Procedural/modular tower construction (base + weapon attachment + material swap) dramatically
  reduces art scope while increasing apparent variety.

**Phase it surfaces:** Transition from prototype to alpha; worsens throughout.

---

### 5. Roguelite meta progression designed before content is complete

**What it is:** Meta progression balances against a content set that keeps changing. Every time a
new class is added, every existing unlock needs to be re-evaluated. Balance work is done twice.

**Prevention:**
- Implement meta progression UI and systems early (so the feel is tested), but populate it sparsely.
  Add all content before tuning unlock rates and power values.
- Use a "meta progression freeze" milestone: no new unlocks after this point, only tuning.

**Phase it surfaces:** Late alpha/early beta.

---

### 6. No analytics means flying blind

**What it is:** Without data, all balance decisions are based on developer intuition. You don't know
which wave kills most players, which class is underplayed, or which towers are never built.

**Warning sign:** Post-EA launch: "we think players are struggling with wave 10" when the data
would show it's actually wave 15.

**Prevention:**
- Implement minimal telemetry from day one: wave reached at death, class selected, towers built
  at run end. CSV file export is sufficient pre-EA.
- Privacy-respecting, opt-in analytics. Unity Analytics, a custom endpoint, or even Steam's
  built-in achievement tracking can provide signal.
- Instrument the single most important question first: "where do players die?"

**Phase it surfaces:** Beta; critical at EA launch.

---

## Steam Early Access Pitfalls

### 1. Launching too early with too little content

**What it is:** The minimum viable EA launch is higher than most indie developers expect. Players
expect at minimum 2-3 hours of non-repetitive content, meaningful progression, and a clear
content roadmap. Launching with a "vertical slice" as an EA product results in immediate negative
reviews.

**Warning sign (pre-launch):** Internal estimate of "content hours" is under 3 hours for a first-
time player. No roadmap document exists.

**Prevention:**
- Target 4-6 hours of first-playthrough content before EA launch. Replayability from roguelite
  variance can extend this, but base content must be there.
- Write and publish the EA roadmap *before* launch. It's a trust contract with early adopters.
- Read your Steam store page from the perspective of someone who has never heard of your game.
  Is it clear what's in the game *right now*?

**Phase it surfaces:** 6-8 weeks before planned EA launch.

---

### 2. Performance is "acceptable" on developer hardware but not on player hardware

**What it is:** The developer has a high-end machine. The median Steam player has a mid-range 2018-
era system. A game that runs at 60fps on an RTX 3080 may run at 20fps on an GTX 1060, which is
still in the top 25% of Steam hardware (per Steam Hardware Survey).

**Warning sign:** No playtesting on low-spec hardware. No minimum spec defined.

**Prevention:**
- Define minimum spec early (a specific CPU/GPU/RAM target) and test on actual hardware matching
  that spec monthly during alpha.
- For this project specifically: flow-field pathfinding with 100+ enemies, status effect particle
  systems, and 3D geometry all need explicit performance budgets.
- Target 60fps on a GTX 1060 equivalent as a hard requirement, not a nice-to-have.
- Use Unity's Profiler (or equivalent) with "development build on target spec" as a monthly ritual.

**Phase it surfaces:** Beta; catastrophic if unaddressed at EA launch.

---

### 3. The review score death spiral

**What it is:** Steam's algorithm heavily weights early reviews. Mixed reviews in the first week
suppress visibility permanently, even if the game improves dramatically. An EA launch with 60%
positive in week one is very hard to recover from.

**Warning sign:** Any known content-completeness, balance, or performance issue that isn't fixed
before launch.

**Prevention:**
- Fix all known "negative review triggers" before launch: crashes, progression blockers, egregious
  balance issues, missing core features that the store page implies are present.
- Soft-launch to a small group (itch.io, Discord playtest, closed beta keys) to collect a round of
  real-player feedback before EA goes live.
- The minimum bar: the game should be fun and stable enough that a player who paid full price feels
  they got value *right now*, not "once it's done."

**Phase it surfaces:** 4 weeks before EA launch.

---

### 4. Roadmap promises over-commit and under-deliver

**What it is:** EA roadmaps with specific dates and specific features create contractual
expectations. Indie developers routinely miss these, eroding community trust. Each missed milestone
generates negative forum posts and review bombing.

**Warning sign:** Roadmap has feature-complete milestones with specific dates more than 6 months
out.

**Prevention:**
- Use "seasons" or vague time horizons ("early 2027") rather than specific dates.
- Roadmap in terms of content categories, not feature lists: "new class + associated towers" not
  "15 new towers with full synergy matrix and boss."
- Under-promise, over-deliver. Shipping something early and unannounced creates goodwill;
  shipping something late that was promised creates resentment.
- Build a 30-50% time buffer into any timeline you communicate externally.

**Phase it surfaces:** When writing the EA store page.

---

### 5. No community feedback loop post-launch

**What it is:** Developers go heads-down post-launch to implement the roadmap. No active presence
in Steam discussions or Discord means player-reported bugs sit unfixed, community interprets
silence as abandonment, and review score drifts negative.

**Warning sign:** Steam discussions go more than 48 hours without a developer response in the first
month post-EA.

**Prevention:**
- Allocate explicit time (2-4 hours per week minimum) for community engagement in the first
  3 months of EA.
- Triage bug reports weekly. Hotfix critical issues within 72 hours of identification.
- A public Trello/GitHub issues board or changelog lets players see that feedback is being acted on
  without requiring individual responses to every post.
- "Thank you for the report, we've logged this" is sufficient for most bug reports — players want
  acknowledgment, not a promise.

**Phase it surfaces:** Week 1-2 post EA launch.

---

### 6. Pricing wrong for the content/audience

**What it is:** EA pricing has an implicit social contract: lower price = more forgiveness for
missing features. A $20 EA game with 4 hours of content faces harsher review standards than a
$10 EA game with the same content. Overpricing at EA launch with the intent to raise price on
1.0 is a common mistake; the Steam algorithm rewards games that *raise* price at 1.0, but only
if early reviews are good enough to maintain visibility.

**Warning sign:** Store page price is set based on "what the game will be worth at 1.0" rather
than "what the game is worth right now."

**Prevention:**
- Price EA at 70-80% of your intended 1.0 price.
- For a roguelite TD in this genre, study comparable EA titles: typical range is $10-15 EA for
  indie, $15-20 for polished.
- Commit to "price will increase at 1.0" in the store description — this is standard and
  well-received.

**Phase it surfaces:** Store page creation, 8-10 weeks before EA launch.

---

### 7. Ignoring Steam Next Fest / demo strategy

**What it is:** Steam Next Fest (held ~6x/year) is the single highest-ROI marketing event for
indie games. A demo during Next Fest can generate thousands of wishlists. Developers who launch
EA without having done Next Fest leave their primary organic discovery tool unused.

**Warning sign:** No demo exists. No Next Fest participation planned.

**Prevention:**
- Build a standalone demo (first 2-3 waves, one class, no meta progression) early enough to
  participate in a Next Fest before your EA launch.
- A "demo → wishlist → EA launch" funnel is the standard successful indie playbook.
- Target at least 5,000 wishlists before EA launch as a signal of viable audience. Below 2,000
  wishlists at launch is a strong predictor of commercial failure.

**Phase it surfaces:** 6+ months before planned EA launch.

---

## Cross-Cutting Notes

These pitfalls interact in predictable ways specific to this project:

1. **Pathfinding + Status Effects + Performance**: The triple threat for this game. All three
   systems generate per-frame work. They must share a performance budget and be profiled together,
   not in isolation. A game that runs fine with pathfinding and fine with status effects may crater
   when both are active under load.

2. **Class system + Roguelite offers + Balance**: Class-specific tower pools mean the offer system
   must be class-aware, or every offer session will feel bad. This is a systems integration problem
   that should be designed in the same sprint, not bolted together later.

3. **Maze-builder + Boss encounters + Telegraphing**: Bosses that bypass the maze invalidate the
   player's primary expression of skill. This is the single highest-risk design tension in this
   specific project. Resolve the boss-vs-maze design philosophy before alpha, in writing.

4. **Scope + EA expectations + Small team**: The scope of systems described (3D, pathfinding, 4+
   classes, roguelite meta, status matrix, boss fights) is a 3-4 person team's 2-year project.
   A solo developer should plan for 3-4 years or make aggressive cuts. The roguelite meta
   progression can be the first EA-only feature deferred post-launch if needed.
