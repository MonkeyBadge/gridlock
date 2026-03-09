# Features Research

> Research basis: Deep domain knowledge of tower defense, maze-builder, and roguelite genres
> as of mid-2025. Reference games: Defense Grid 1 & 2, Sanctum 1 & 2, Dungeon Defenders,
> Kingdom Rush series, Bloons TD 6, Creeper World, Mindustry, Deep Rock Galactic: Survivor,
> Brotato, Slay the Spire, Against the Storm, Vampire Survivors, 20 Minutes Till Dawn.

---

## Table Stakes (must have at EA launch)

These are features players assume exist before buying. Their absence triggers immediate refunds
and negative reviews — not "missing feature" reviews, but "broken/incomplete game" reviews.

### Core Gameplay Loop

**Wave-based enemy spawning with visible wave counter**
Players need to know where they are in the run at all times. Wave 7 of 20 feels different from
wave 7 of infinity. Show current wave, next wave preview, and (for finite modes) total waves.

**Tower placement with clear range/damage indicators**
Before placing a tower, players must see its attack radius as an overlay on the grid.
After placement, clicking a tower should show its live stats. No exceptions. Defense Grid set
this standard in 2008; anything less feels broken in 2025.

**Enemy health bars**
Every enemy needs a visible health bar. Floating bars above the enemy are standard.
For bosses, a dedicated large health bar UI element is required. Players need to track
whether their damage is landing.

**Enemy pathing preview / path visualization**
Show the current enemy path (or multiple paths) on the map at all times, ideally as a
highlighted ground overlay or arrow trail. Players must be able to plan around it. This is
doubly critical for a maze-builder where the path changes dynamically.

**Multiple tower types with distinct roles**
Minimum viable: a slow tower, a single-target DPS tower, an AoE tower, and a support/buff
tower. Players expect meaningful choice between tower categories, not just upgrades of the
same archetype.

**Tower upgrade system**
At minimum a linear upgrade path (Level 1 → 2 → 3) per tower. Players expect to invest
gold into towers mid-run. Branching upgrades (choose between two upgrade paths at tier 3)
are now near-standard following Kingdom Rush's influence.

**Economy / resource management**
A clear income loop: enemies drop gold on death, gold is spent on towers and upgrades,
there is never a question of "where does money come from." If the roguelite layer adds
separate run currencies, they must be visually distinct.

**Lives / health system**
Some amount of "leakage" must end the run eventually. Standard is either lives (enemies
that reach the exit subtract from a pool) or a base HP model. Players expect a clear
readout of remaining lives/HP at all times.

**Pause and speed controls**
Pause (spacebar), 1x speed, and 2x speed are the absolute minimum. Fast-forward at 3x or 4x
is expected for replaying earlier waves. Lack of fast-forward is a common review complaint.
For a roguelite with many runs, fast-forward is not optional.

**Mid-wave selling of towers**
Players must be able to sell towers mid-run for partial gold refund (standard is 50–75%).
This is essential for maze-builders where path optimization requires tearing down and
rebuilding.

**Clear win/loss feedback**
A run-end screen with: waves survived, enemies killed, damage dealt, and a prompt to
start a new run. For roguelites, this screen transitions to the meta-progression summary.

**Basic settings**
Volume controls (master, music, SFX separately), resolution/display mode, keybinding
display (rebinding is nice-to-have). These are non-negotiable on Steam.

**Stable performance**
A 3D maze-builder with dozens of towers firing simultaneously needs to hold 60 fps on
mid-range hardware (GTX 1060 / RX 580 tier). Frame drops during large waves are a top
complaint in Steam reviews for TD games. Profile and optimize before EA launch.

---

## Maze-TD Specifics

The maze-builder subgenre has its own contract with players beyond generic TD expectations.

**Valid-path enforcement with real-time feedback**
The single most important system in a maze-builder: the player must never be able to place
a tower that fully blocks all enemy paths. This requires a real-time pathfinding check on
every placement attempt. The standard UX is to turn the placement ghost red and show a
"path blocked" indicator if the placement would strand enemies. This must be instantaneous —
any perceivable lag here destroys the feel of maze-building.

Valid-path algorithm recommendation: incremental BFS/A* from every active spawn point to
every exit, evaluated on a shadow copy of the grid before committing placement. Cache the
result and only re-evaluate when placement geometry changes.

**Dynamic path recalculation during waves**
When a tower is placed mid-wave, enemies already on the map must recalculate their paths
in real time. This includes enemies that are mid-corridor. The industry standard (from
Sanctum, Defense Grid 2) is to let enemies in transit finish their current segment, then
reroute at the next node. Enemies that get "trapped" by a sudden wall should backtrack
to the last valid waypoint.

**Path length as a strategic reward**
The entire point of maze-building is that longer paths = more time for towers to fire =
more effective defense. The UI should communicate this. Show path length (in seconds of
travel time, or tile count), ideally updating live as towers are placed. Defense Grid
made this its core feedback loop and it works.

**Spatial reasoning feedback**
3D introduces camera problems that 2D maze TDs avoid. Players must be able to:
- Rotate and zoom the camera freely during placement
- See "through" tall structures (transparency or cutaway when camera is behind a wall)
- Snap placement to a clear grid even in perspective view
- Optionally: a top-down 2D minimap overlay for maze planning

**Tower footprints as walls**
If towers physically occupy grid cells as maze walls, their visual language must make this
clear. Players should read "this is a wall segment that shoots" not "this is a floating turret."
The art direction needs to commit to the wall-tower duality — flat-topped parapets, tower
keep aesthetics, etc.

**Bottleneck and chokepoint design**
Good maze-TD maps have intentional chokepoints that the player finds and exploits. Maps need
to be wide enough to build in but structured enough that there are optimal solutions to
discover. Pure open-field grids feel empty; too many forced corridors remove player agency.
The sweet spot: open areas with 2–3 natural chokepoints per map that reward players for
finding them.

**Enemy pathing variety**
Enemies that bypass or adapt to mazes add tension: flyers that ignore ground paths, teleporters
that jump segments, burrowers that go underground, fast enemies that render long mazes less
effective. These are expected in any mature maze-TD. At minimum, one flying enemy type is
needed at launch.

**Map variety**
Multiple maps with different starting topographies. At minimum 3–4 distinct maps for EA.
Each should offer a different maze-building "puzzle" (single entry/exit vs. multiple, linear
vs. branching, open field vs. pre-existing walls).

---

## Roguelite Expectations

The roguelite layer has become its own genre contract. Players comparing this to Brotato,
Vampire Survivors, or Deep Rock Galactic: Survivor arrive with specific expectations.

**Clear run structure with escalating stakes**
Players expect to know the run's shape: how many floors/waves before a boss, how difficulty
scales, what triggers a run-end. Roguelites that obscure their structure feel unfair.
Present a run map or wave ladder showing upcoming milestones (mini-boss at wave 5, boss
at wave 10, etc.).

**Meaningful between-wave decisions**
The core roguelite feel comes from choices between waves. Standard patterns:
- Offer 3 random options (tower unlock, upgrade, buff) — pick 1
- Shop with limited stock that refreshes each wave
- Event cards with risk/reward tradeoffs
Every wave should have at least one decision point. Waves with no choices feel like
wasted time in a roguelite.

**Build diversity and synergy discovery**
Players need to feel like they are constructing a unique build each run. This requires
enough tower/upgrade combinations that no two runs feel identical. Synergies should be
discoverable (tooltips that hint at interactions) but not mandatory reading (intra-class
synergies should emerge naturally through play).

The class/race system described in the project is well-suited for this: each class
constrains the tower pool to a curated subset, ensuring intra-class synergies are dense
and reliable rather than sparse and accidental.

**Permanent meta-progression that feels meaningful**
Players expect to unlock something every 2–3 runs regardless of performance: new starting
classes, passive meta upgrades (small stat buffs), new tower variants, lore/map unlocks.
The pacing of unlocks is critical — too slow feels grindy, too fast removes the pull of
"one more run."

Meta-progression should not make runs trivially easier (a common complaint in Deep Rock:
Survivor late-meta). Keep power delta between a fresh profile and a fully unlocked profile
to roughly 15–25% effective power, with most of the unlock value being variety rather than
raw numbers.

**Run modifiers / curses / blessings**
Players expect optional difficulty modifiers that add variety and challenge. Common patterns:
- Curses (debuffs to the player) that are imposed by the game or chosen for rewards
- Relics/artifacts that dramatically alter gameplay rules
- Elite/modified enemies with additional traits (armored, fast, shielded)

**Endless / escalation mode**
Explicitly called out in the project, and it is expected. Players who master the finite run
want an infinite mode to test their optimal builds. Endless mode must have visibly escalating
difficulty — not just more HP scaling, but new enemy types, new modifiers, speed increases.
Leaderboards (even local) for endless wave count are expected.

**Run history / stats**
After each run, show: waves cleared, enemies killed, damage dealt per tower type, gold
spent. A "run summary" screen. Ideally a simple run history log (last 10 runs). Players
use these stats to evaluate their builds and improve. Their absence makes the roguelite
feel shallow.

**Accessible early, deep late**
First run should be winnable or at least reach wave 5+ for a new player without reading
documentation. Depth should reveal itself over multiple runs. Tutorial or guided first run
is expected — not a full manual, but a "here's how to place your first tower" guided wave 1.

---

## Steam Requirements

These are platform-level expectations. Some are enforced by Valve; most are community-enforced
via reviews.

**Steam Achievements**
Non-negotiable for any Steam game. Players check achievement lists before buying.
Minimum viable: 20–30 achievements covering:
- Story/progression milestones (complete first run, reach wave 20, defeat first boss)
- Build diversity (win with each class)
- Challenge feats (complete a run without selling any towers, win with max curse level)
- Discovery/exploration (find a rare synergy combo, unlock all towers of a class)
- Endless mode milestones (reach wave 50, wave 100)
Avoid achievements that require extreme grind (10,000 enemies killed) — they read as
padding and get called out in reviews.

**Steam Cloud Saves**
Required. Players switch between desktop and Steam Deck, or reinstall Windows. Loss of
meta-progression is a one-star review. Implement early; retrofitting is painful.

**Steam Deck compatibility**
As of 2025, "Playable" or "Verified" Deck rating is a significant sales driver for
indie games. Requirements:
- Native controller support with all actions accessible (no mouse-required UI flows)
- Readable UI at 1280x800 — audit all font sizes and tooltip widths
- No mandatory keyboard/text input during gameplay
- Stable 40+ fps on Deck hardware (roughly GTX 1050 equivalent)
Maze placement via controller is a design challenge: consider a grid cursor system (like
Into the Breach or Dungeon Defenders) rather than trying to replicate free mouse aim.

**Controller support**
Expected by ~30–40% of Steam TD players. For a 3D game, this is closer to 50% expectation.
A controller layout must exist at launch; "keyboard/mouse only" is a negative review trigger.
Does not need to be perfect at EA launch, but must be functional.

**Trading cards**
Players notice their absence. Low effort for the developer (static card artwork + badge
artwork). Submit to Steam for approval; Valve processes these during the EA period.
Recommended: 5–8 cards featuring tower classes or enemy types.

**Early Access communication**
Steam's EA norms require:
- A public roadmap (can be a pinned forum post or store page section)
- Patch notes for every update (Steam news posts)
- A clear statement of what is and is not in the EA build on the store page
- Developer responses in the Steam forums, especially in the first 2 weeks post-launch
Silence after launch is interpreted as abandonment. Even a brief "working on it" reply
to bug reports matters.

**System requirements (accurate)**
List both minimum and recommended. Minimum should reflect the lowest hardware you have
actually tested on. Incorrect system requirements (listing too-low minimums) generate
performance complaint reviews.

**Content warnings / mature content**
If the game has any violence, flag it accurately. The absence of appropriate flags can
trigger reports.

---

## Differentiators

Assessment of the project's planned features against the current market landscape.

### Genuinely Unique or Rare

**Towers-as-maze-walls in 3D**
Most maze-TDs are 2D (Defense Grid, Mindustry) or use separate wall/tower objects
(Sanctum uses both guns and walls as distinct objects). A true 3D environment where the
tower IS the wall segment — with camera, lighting, and spatial puzzle implications — is
not well-represented in the current market. This is a legitimate visual and design
differentiator.

**Class/race gating of tower pools**
Most roguelite TDs offer random tower offerings from a universal pool (e.g., Brotato's
item pool, Deep Rock: Survivor's weapon pool). Hard class-gating with intra-class
synergies designed together is rarer — it's closer to Slay the Spire's character-specific
card sets applied to TD. This is a meaningful differentiator in the roguelite TD space
because it makes runs feel fundamentally different rather than "same pool, different luck."

**Damage matrix (attack type vs. armor type)**
This exists in some strategy games (StarCraft, Warcraft III) but is uncommon in TD games.
Most TDs have flat damage or simple resistances. A structured 3x3 or 4x4 matrix creates
a "counter-picking" meta that encourages reading enemy compositions and adjusting tower
selection. This is a genuine depth differentiator if surfaced clearly in the UI.

### Good but Not Unique

**Elemental status effects (Frost, Poison, Burn)**
Present in Kingdom Rush, Bloons BTD6, and most modern TDs. Not a differentiator, but
players will expect these and their absence would be odd given the genre has normalized them.
The differentiator opportunity is in interaction chaining: Burn + Poison = amplified DoT?
Frost + Burn = steam explosion? Status interactions that aren't in other TDs would stand out.

**Floor traps**
Present in Dungeon Defenders and some dungeon-crawler TDs. Uncommon in the pure maze-TD
subgenre. A mild differentiator — positions the game more in "dungeon defense" territory,
which has good connotations. Execution (traps that matter vs. traps that are always wrong
to invest in) is what will determine whether this is a real differentiator.

**Mini-bosses every 5th wave**
Standard in modern TDs (Kingdom Rush, Bloons BTD6, Deep Rock: Survivor). Not a
differentiator, but it is a table-stakes-adjacent feature for roguelite pacing.

**Boss levels as dedicated encounters**
Treated as separate "floors" or levels rather than just a hard wave — this is less common
in pure TD and more common in dungeon defenders/roguelite hybrids. Positions the game
well in the "roguelite run with boss checkpoints" structure popularized by Hades and Slay
the Spire. A mild differentiator.

**Timed waves + Player-triggered waves**
Player-triggered waves (sending the next wave early for a gold bonus) is a Kingdom Rush
staple and is broadly expected. Both modes existing together is clean design — casual players
use timed, optimizers use triggered. Not a differentiator but good polish.

### Opportunities Not Yet in the Plan

**Maze scoring / efficiency metrics**
Post-wave feedback on maze efficiency (e.g., "your maze achieved 42 seconds of enemy
travel time — optimal is 60 seconds") would be unique and directly serve the maze-builder
fantasy of optimization. No major maze-TD surfaces this well.

**Asymmetric enemy routing**
Multiple spawn points where enemies take different routes and you must design a maze that
handles all of them simultaneously. This turns maze design into a constraint-satisfaction
puzzle. Sanctum 2 touched this; no game has made it the center of the experience.

**Replay / ghost run**
Show a ghost of your previous run's maze layout as an optional overlay. Lets players
see how their maze evolved and learn from past attempts. Novel in the TD space.

---

## Anti-Features (avoid these)

These are patterns documented across Steam review analysis for TD and roguelite games that
directly cause negative reviews and player drop-off.

**Pay-to-win or pay-to-convenience DLC**
Any DLC that sells tower types, classes, or meta-progression upgrades that affect balance
will trigger "P2W" reviews, regardless of how minor the advantage is. Keep all DLC
cosmetic (skins, card backs, soundtracks) for the EA period. Premium content = new
classes/maps as part of 1.0 launch or major paid expansions only.

**Opaque damage numbers / hidden math**
If the damage matrix and status effect interactions are not clearly documented in-game
(tooltips, a codex, or a damage calculator), players will feel cheated when their
intuitively good strategy fails due to hidden mechanics. "You died because of math you
couldn't see" is a guaranteed 1-star review trigger.

**Mandatory perfect maze builds (one optimal solution)**
If there is a single correct maze layout for each map and everything else fails, the game
becomes a puzzle game with fake freedom. Reviewers will correctly identify this and call
it out. Multiple viable strategies must exist per map, per class.

**Runaway difficulty spikes without telegraph**
Difficulty should escalate at a pace the player can feel coming. A wave that suddenly
introduces a new mechanic (first flyer, first armored enemy) must be telegraphed one wave
in advance ("INCOMING: Shielded enemies next wave"). Surprise deaths feel unfair in TD;
deaths the player saw coming feel earned.

**Slow early game**
The most common death of roguelite TDs on Steam: the first 10 minutes are boring. If wave 1
through wave 4 require no real decisions and cannot fail, you have already lost casual
players. The early game should offer real (but forgiving) decisions immediately.

**Unskippable animations and long death screens**
When a run ends, players want to immediately see results and start a new run. Long death
animations, unskippable cutscenes, or slow menu transitions compound the frustration of
losing. Death-to-new-run time should be under 15 seconds.

**Inconsistent tower performance (feels random)**
If towers appear to miss, deal wildly varying damage, or behave unpredictably without
clear telegraphing, players perceive it as "bugged." Even if by design, variance must be
clearly communicated (show min-max damage ranges on tower stat cards). Unexplained
variance = "broken game" reviews.

**No mid-run saving (for long sessions)**
If a run takes 45+ minutes and the game doesn't auto-save mid-run, players who crash or
quit mid-run lose all progress. This is especially punishing in roguelites. Implement
run-suspend saves (save state that deletes on run completion or death) before EA launch.

**Excessive mandatory grind before fun begins**
Meta-progression that locks core classes or mechanics behind 10+ hours of play is
consistently criticized in roguelite reviews. Players want to see the breadth of content
within the first 3–5 hours.

**3D camera that fights the player**
In a 3D maze-builder, a bad camera will be mentioned in nearly every negative review.
Specific failure modes: camera that clips through towers, loses orientation mid-placement,
can't zoom out far enough to see the full maze, or has a fixed angle that hides tile
adjacency. Camera is not a "nice to have" — it is load-bearing infrastructure.

**Ignoring the Steam forums / going dark post-launch**
EA games that go silent after launch see review scores drop over time even if the game
itself is fine. A 2-week radio silence window is enough for players to start writing
"dev abandoned this" reviews. Establish a response cadence before launch.

---

## Deferred / Post-EA

Features worth building eventually but which should not delay EA launch.

**Multiplayer / co-op**
Sanctum's co-op is beloved; Dungeon Defenders built its identity on it. For a small team,
co-op multiplayer is a 6–12 month post-EA addition. Designing the architecture to support
it later (separating input from game state) is worth doing early, but don't ship it in EA.

**Map editor / Workshop support**
Steam Workshop integration for custom maps is a strong long-tail retention feature.
Not required at EA. Requires stable map format/API first.

**Speedrun / challenge modes**
Daily challenges, seeded runs, and official speedrun category support. Build after the
core loop is locked. Add leaderboards via Steam API once the meta is stable.

**Full voice acting**
Atmospheric VO for tower types, enemy types, and narration is a production value upgrade.
Placeholder sound design is acceptable for EA. Many successful EA TDs (Brotato, Dungeon
Clawler) launched with minimal VO.

**Localization beyond English**
Simplified Chinese, German, Brazilian Portuguese, and Russian cover ~60% of the non-English
Steam market. Target these for 1.0 or a major EA update. Designing for localization from day
one (no hardcoded strings, UI layouts that accommodate longer text) is worth doing early.

**Lore / narrative layer**
Codex entries, environmental storytelling, in-run flavor text. Adds depth but is not expected
at EA for a mechanical TD game. Add progressively to justify updates and maintain press coverage.

**Trading card foils and badge sets**
Basic trading cards at launch; foil variants and gem crafting integration can be added in
a post-EA update.

**Advanced accessibility options**
Colorblind modes (critical for status effect color-coding — add this earlier than expected),
UI scaling, subtitles for any VO. Colorblind support should arguably be in the Table Stakes
category given how frequently its absence is mentioned in TD reviews where color-coded
damage types are central.

> **Note on colorblind support:** Given that this game's core mechanics rely on color-coded
> damage types (Frost = blue, Poison = green, Burn = orange/red) and an attack/armor type
> matrix, colorblind accessibility is higher priority than typical. Recommend including
> at least deuteranopia/protanopia modes at EA launch, or using shape/icon coding in
> addition to color for all status effect indicators.

**Prestige / New Game+ system**
Post-endless escalation layer for players who have "solved" the game. Common in successful
roguelites (Hades' Heat system, Slay the Spire Ascension). Design the hooks for this at
architecture level, ship it as a major 1.0 or post-1.0 feature.
