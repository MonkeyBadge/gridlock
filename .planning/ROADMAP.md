# Development Roadmap

*Derived from REQUIREMENTS.md, ARCHITECTURE.md, and SUMMARY.md — 2026-03-09*

---

## Overview

Seven phases derived directly from the build-order dependencies in ARCHITECTURE.md. Each phase produces a playable, testable slice. No phase begins until its predecessor is verified working.

| Phase | Name | Requirements |
|-------|------|--------------|
| 1 | The Maze Works | CORE-01, CORE-02, CORE-03, MAP-01, MAP-03, MAP-04, WAVE-01, WAVE-02, ENEMY-01, UI-01, UI-02, STEAM-04 |
| 2 | Towers Kill Things | DMG-01, DMG-02, DMG-03, ENEMY-02, CORE-04, CORE-05, UI-03, UI-04 |
| 3 | Status Effects & Traps | DMG-04, DMG-05, DMG-06, DMG-07, CORE-06, UI-05 |
| 4 | Classes & Synergies | CLASS-01, CLASS-02, CLASS-03, CLASS-04, CORE-07, CORE-08 |
| 5 | Bosses & Escalation | ENEMY-03, ENEMY-04, ENEMY-05, WAVE-03, WAVE-04, MAP-02 |
| 6 | Roguelite Loop | PROG-01, PROG-02, PROG-03, UI-06 |
| 7 | Steam & Polish | STEAM-01, STEAM-02, STEAM-03 |

---

## Phase 1: The Maze Works

**Goal:** A player can place towers on a 3D grid map, watch enemies pathfind through the maze they build, and lose lives when enemies reach the exit — with waves launching on a timer or on demand.

**Requirements:** CORE-01, CORE-02, CORE-03, MAP-01, MAP-03, MAP-04, WAVE-01, WAVE-02, ENEMY-01, UI-01, UI-02, STEAM-04

**Success Criteria:**
1. A tester can place a tower anywhere on the map; if that placement would seal off all exits the game rejects it and the tower does not appear.
2. While a wave is in progress, placing a new tower causes enemies already on the map to immediately re-route around the new obstacle without teleporting or freezing.
3. Multiple distinct enemy types are visible during waves — they differ in physical size and movement speed in ways a tester can observe without any UI labels.
4. The live path visualization (path overlay) updates on screen the instant a tower is placed or removed, before the next wave starts.
5. Tester can complete a run in both Timed Waves mode (countdown timer appears between waves) and Player-Triggered mode (a "Send Wave" button is visible and functional), and the game maintains a stable 60 fps throughout on the target hardware.

---

## Phase 2: Towers Kill Things

**Goal:** Towers deal damage to enemies using a full damage-type/armor-type matrix, enemies die, the player can sell towers mid-wave for a resource refund, and can upgrade towers during a run — making this the first complete playable game loop.

**Requirements:** DMG-01, DMG-02, DMG-03, ENEMY-02, CORE-04, CORE-05, UI-03, UI-04

**Success Criteria:**
1. A tester can identify at least two enemy armor types in a single wave and confirm (via floating damage numbers or a visible label) that the same tower deals different effective damage against each armor type.
2. Selecting a tower while placing it shows a visible range overlay; enemies within that radius are targeted and attacked, enemies outside it are ignored.
3. A tester can sell a tower mid-wave and receive a partial gold refund that is less than the tower's original cost — the refund amount is visible before confirming the sale.
4. A tester can spend in-run currency to upgrade a tower and observe at least one measurable change (attack speed, damage numbers, or range overlay) without restarting the run.
5. Pause, 1x speed, and 2x speed controls are accessible at all times; switching between them produces an observable change in wave tempo, and all enemy health bars remain visible at all speeds.

---

## Phase 3: Status Effects & Traps

**Goal:** Towers can inflict Frost, Poison, Burn, and at least one additional status effect on enemies; floor traps placed on walkable tiles trigger effects when enemies step on them; all active effects are visually indicated on affected enemies.

**Requirements:** DMG-04, DMG-05, DMG-06, DMG-07, CORE-06, UI-05

**Success Criteria:**
1. A tester places a Frost-applying tower and confirms that afflicted enemies visibly slow down; the minimum speed floor holds (enemies never stop completely from Frost alone).
2. A tester places a Poison-applying tower and confirms damage numbers continue ticking on an enemy after the tower has stopped targeting it (DoT persists); applying Poison multiple times produces stacking damage ticks.
3. A tester places a Burn-applying tower near a cluster of enemies and observes the Burn effect spreading to adjacent enemies without those neighbors being directly attacked.
4. A tester places a floor trap on a walkable tile; enemies that cross the tile are visibly affected (slowed, damaged, or otherwise altered) while enemies that do not cross it are unaffected.
5. All active status effects on an enemy are visible simultaneously on that enemy — either as particle effects, icon overlays, or both — without requiring the tester to open any menu.

---

## Phase 4: Classes & Synergies

**Goal:** The player selects one of three distinct classes at run start; each class provides an exclusive pool of 8–12 towers specialized in 1–2 damage types; placing towers of the same class near each other activates visible qualitative synergy bonuses.

**Requirements:** CLASS-01, CLASS-02, CLASS-03, CLASS-04, CORE-07, CORE-08

**Success Criteria:**
1. The class selection screen presents exactly three classes; after choosing one, the tower placement panel shows only that class's towers — no towers from the other two classes appear.
2. A tester starting as each of the three classes observes a meaningfully different available tower roster: tower names, icons, and stated damage types differ between classes.
3. Placing two or more towers of the same class adjacent to each other produces a visible synergy indicator (tooltip, glow, stat change) that is absent when the towers are placed far apart and not in a qualifying configuration.
4. Synergy bonuses change the type or mode of a tower's behavior (e.g., gaining a new effect, changing targeting mode, enabling an aura) rather than simply adding a percentage multiplier to a stat — a tester can describe the behavioral difference without reading a number.
5. After a run ends with one class, starting a new run with a different class produces a noticeably different tower-building experience — the tester can name at least one mechanical difference without prompting.

---

## Phase 5: Bosses & Escalation

**Goal:** Mini-bosses appear every fifth wave with elevated HP and special movement abilities; dedicated boss-level milestone encounters alter the rules of that encounter; endless escalation mode runs indefinitely with growing difficulty; maps support multiple spawn and goal point configurations.

**Requirements:** ENEMY-03, ENEMY-04, ENEMY-05, WAVE-03, WAVE-04, MAP-02

**Success Criteria:**
1. A tester playing to wave 10 encounters a visually distinct, larger enemy on waves 5 and 10 with a dedicated health bar UI element; the tester can observe at least one special movement behavior (teleport, brief shield, or split) that normal enemies do not have.
2. At a designated run milestone wave, the encounter introduces at least one rule-change mechanic that is announced to the player in advance (e.g., a boss can break one tower, spawns add enemies, or the path resets); the mechanic resolves and normal play resumes after the boss is defeated.
3. Bosses follow the player-built maze path as their default routing — a tester can verify this by building a long spiral maze and watching the boss traverse it; special abilities only deviate from the path momentarily.
4. In Endless Escalation mode, a tester can play past what would be the normal run-end wave count and confirms that enemy difficulty (HP, speed, or count) continues increasing without a hard stop or error.
5. On the map selection screen (or run start), a tester can choose between at least two different spawn/goal point configurations on the same map and confirms that enemies spawn from and walk toward the selected points.

---

## Phase 6: Roguelite Loop

**Goal:** Permanent meta progression carries over between runs — unlocking new towers and class upgrades — and a run history screen lets players review past performance; the end-of-run stats screen captures meaningful per-run data.

**Requirements:** PROG-01, PROG-02, PROG-03, UI-06

**Success Criteria:**
1. After completing or failing a run, a tester sees a run stats screen showing at minimum: waves survived, total enemies killed, and total damage dealt — this screen appears before returning to the main menu.
2. A tester plays two runs back to back; after the second run, a meta progression unlock (a new tower or class upgrade) is available that was not present before the first run — and it persists after closing and reopening the game.
3. All meta unlocks expand the player's options (new towers available, new synergy rules, new ability behaviors) rather than increasing a numeric stat like "deal 10% more damage globally"; a tester can describe what each unlock enables, not just what number it changes.
4. A run history screen is accessible from the main menu and displays results from at least the last 5 completed runs including class used and wave reached; the list persists across game restarts.

---

## Phase 7: Steam & Polish

**Goal:** The game is integrated with Steam Achievements, Cloud Saves, and Leaderboards; the Endless Escalation leaderboard is populated and functional; all systems meet the stable 60 fps performance target and are validated on minimum-spec hardware.

**Requirements:** STEAM-01, STEAM-02, STEAM-03, STEAM-04

**Success Criteria:**
1. A tester achieves a meaningful in-game milestone (e.g., first boss kill, first class unlocked) and observes the corresponding Steam Achievement notification appear without any additional action required.
2. A tester completes a run on one machine, verifies the run history is saved, then launches the game on a second Steam account machine and confirms the meta progress and run history are present via Steam Cloud Saves.
3. An Endless Escalation score is submitted and appears on the Steam Leaderboard with the correct wave count; the leaderboard is visible from within the game without opening a browser.
4. A tester runs the game on GTX 1060-tier hardware during a peak wave (maximum enemy count, active status effects, multiple towers firing) and the frame counter does not drop below 60 fps for more than one second continuously.

---

*Last updated: 2026-03-09*
