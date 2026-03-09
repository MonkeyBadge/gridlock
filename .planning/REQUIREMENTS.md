# Requirements

## v1 Requirements (Early Access Launch)

### Core Loop
- [ ] **CORE-01**: Player can place towers on a 3D grid that physically block enemy movement
- [ ] **CORE-02**: Game enforces a valid enemy path exists before confirming any tower placement
- [ ] **CORE-03**: Enemies dynamically re-route when towers are placed or removed
- [ ] **CORE-04**: Player can sell towers mid-wave for a partial resource refund
- [ ] **CORE-05**: Player can upgrade towers during a run using in-run currency
- [ ] **CORE-06**: Player can place floor traps on walkable tiles that trigger effects when enemies step on them
- [ ] **CORE-07**: Player starts each run by selecting a class/race that determines their available tower pool
- [ ] **CORE-08**: Towers of the same class have intra-class synergy bonuses that activate when placed together

### Maps
- [ ] **MAP-01**: Maps are procedurally generated with varied shapes each run
- [ ] **MAP-02**: Entry and exit points vary between generated maps
- [ ] **MAP-03**: Generated maps are always solvable (valid enemy path guaranteed at start)

### Wave Modes
- [ ] **WAVE-01**: Player can play in Timed Waves mode (countdown between waves, prep phase)
- [ ] **WAVE-02**: Player can play in Player-Triggered mode (manually send next wave for bonus rewards)
- [ ] **WAVE-03**: Player can play Endless Escalation mode (infinitely scaling difficulty, leaderboard-eligible)
- [ ] **WAVE-04**: Enemies scale in difficulty, count, and composition as waves progress

### Enemies
- [ ] **ENEMY-01**: Multiple distinct enemy types with different speeds, HP, and sizes
- [ ] **ENEMY-02**: Enemies have armor types that interact with tower damage types (damage matrix)
- [ ] **ENEMY-03**: Mini-bosses appear every 5th wave with higher HP and special movement abilities
- [ ] **ENEMY-04**: Dedicated boss levels appear as run milestones with unique encounter mechanics
- [ ] **ENEMY-05**: Bosses follow the maze path but have special abilities (e.g. jump to skip a section, mid-fight armor type change)

### Classes & Towers
- [ ] **CLASS-01**: 3 distinct playable classes ship at EA launch
- [ ] **CLASS-02**: Each class has a unique pool of 8–12 towers not shared with other classes
- [ ] **CLASS-03**: Each class specializes in 1–2 damage types influencing tower attack effectiveness
- [ ] **CLASS-04**: Tower synergy bonuses are qualitative enablers (not multiplicative multipliers)

### Damage & Status Effects
- [ ] **DMG-01**: 6 damage types: Physical, Magic, Fire, Ice, Poison, Lightning
- [ ] **DMG-02**: 6 armor types: Unarmored, Light, Heavy, Magic-Resistant, Elemental-Resistant, Boss
- [ ] **DMG-03**: Damage matrix determines effectiveness of each damage type vs each armor type
- [ ] **DMG-04**: Frost status effect slows enemy movement speed (with hard floor: minimum 20% base speed)
- [ ] **DMG-05**: Poison status effect applies stackable damage over time
- [ ] **DMG-06**: Burn status effect applies damage over time and spreads to nearby enemies
- [ ] **DMG-07**: Additional status effects to be designed and added (at minimum 1–2 more before launch)

### UI & Feedback
- [ ] **UI-01**: Live path visualization updates in real time as towers are placed
- [ ] **UI-02**: Tower range overlay shown when placing or selecting a tower
- [ ] **UI-03**: Pause, 1x, and 2x speed controls available at all times during a run
- [ ] **UI-04**: Health bars visible on all enemies
- [ ] **UI-05**: Active status effects visible on enemies
- [ ] **UI-06**: Run stats screen shown at end of each run (waves survived, enemies killed, damage dealt, etc.)

### Progression
- [ ] **PROG-01**: Meta progression system: permanent unlocks carry over between runs
- [ ] **PROG-02**: Meta unlocks broaden options (new towers, class upgrades) rather than inflate raw stats
- [ ] **PROG-03**: Run history screen shows past run performance

### Steam & Platform
- [ ] **STEAM-01**: Steam Achievements (meaningful milestones, not padding)
- [ ] **STEAM-02**: Steam Cloud Saves (run and meta progress synced)
- [ ] **STEAM-03**: Steam Leaderboards for Endless Escalation mode scores
- [ ] **STEAM-04**: Stable 60fps performance target throughout

---

## v2 Requirements (Post-EA Updates)

- Colorblind / icon mode for damage types and status effects
- Controller / gamepad support
- Continuous stream wave mode
- Elemental combo reactions (Frost + hit = Shatter, Burn + Poison = Toxic Explosion)
- Multiplayer (co-op or competitive)
- Additional classes beyond 3
- DLC content packs (new classes, maps, enemy types)
- Free-to-play / microtransaction model (evaluate post-EA)

---

## Out of Scope

- Story / narrative campaign — EA is run-based, no narrative required
- More than 3 classes at EA launch — expand via updates/DLC
- Continuous stream wave mode — design creates mid-placement frustration
- Multiplayer — post-EA milestone

---

## Traceability

*(To be filled by roadmap)*

---

*Last updated: 2026-03-09 after requirements definition*
