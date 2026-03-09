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
- [ ] **MAP-01**: A set of hand-crafted maps with distinct shapes and layouts available at launch
- [ ] **MAP-02**: Each map has multiple spawn and goal point configurations players can choose from
- [ ] **MAP-03**: Maps contain pre-placed static objects (rocks, ruins, terrain features) that block both tower placement and enemy movement
- [ ] **MAP-04**: Static map objects create strategic constraints players must work around or exploit when building their maze

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

- Procedurally generated maps — defer to post-EA update
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

| Requirement | Description (short) | Phase |
|-------------|---------------------|-------|
| CORE-01 | Towers physically block enemy movement on 3D grid | 1 |
| CORE-02 | Game enforces valid enemy path before confirming placement | 1 |
| CORE-03 | Enemies dynamically re-route when towers are placed or removed | 1 |
| CORE-04 | Player can sell towers mid-wave for partial resource refund | 2 |
| CORE-05 | Player can upgrade towers during a run using in-run currency | 2 |
| CORE-06 | Player can place floor traps on walkable tiles | 3 |
| CORE-07 | Player selects class/race at run start to determine tower pool | 4 |
| CORE-08 | Same-class towers activate intra-class synergy bonuses | 4 |
| MAP-01 | Hand-crafted maps with distinct shapes and layouts | 1 |
| MAP-02 | Multiple spawn and goal point configurations per map | 5 |
| MAP-03 | Maps contain pre-placed static objects blocking placement and movement | 1 |
| MAP-04 | Static objects create strategic constraints players exploit | 1 |
| WAVE-01 | Timed Waves mode (countdown, prep phase) | 1 |
| WAVE-02 | Player-Triggered mode (manual wave send for bonus rewards) | 1 |
| WAVE-03 | Endless Escalation mode (infinitely scaling, leaderboard-eligible) | 5 |
| WAVE-04 | Enemy difficulty, count, and composition scale across waves | 5 |
| ENEMY-01 | Multiple enemy types with different speeds, HP, and sizes | 1 |
| ENEMY-02 | Enemies have armor types interacting with tower damage types | 2 |
| ENEMY-03 | Mini-bosses every 5th wave with higher HP and special movement | 5 |
| ENEMY-04 | Dedicated boss levels at run milestones with unique mechanics | 5 |
| ENEMY-05 | Bosses follow maze path with special abilities (jump, armor change) | 5 |
| CLASS-01 | 3 distinct playable classes at EA launch | 4 |
| CLASS-02 | Each class has unique pool of 8–12 towers | 4 |
| CLASS-03 | Each class specializes in 1–2 damage types | 4 |
| CLASS-04 | Synergy bonuses are qualitative enablers, not multiplicative multipliers | 4 |
| DMG-01 | 6 damage types: Physical, Magic, Fire, Ice, Poison, Lightning | 2 |
| DMG-02 | 6 armor types: Unarmored, Light, Heavy, Magic-Resistant, Elemental-Resistant, Boss | 2 |
| DMG-03 | Damage matrix determines effectiveness per damage-type/armor-type pair | 2 |
| DMG-04 | Frost status effect slows enemy movement (min 20% base speed floor) | 3 |
| DMG-05 | Poison status effect applies stackable damage over time | 3 |
| DMG-06 | Burn status effect applies DoT and spreads to nearby enemies | 3 |
| DMG-07 | At least 1–2 additional status effects designed and added before launch | 3 |
| UI-01 | Live path visualization updates in real time as towers are placed | 1 |
| UI-02 | Tower range overlay shown when placing or selecting a tower | 1 |
| UI-03 | Pause, 1x, and 2x speed controls available at all times during a run | 2 |
| UI-04 | Health bars visible on all enemies | 2 |
| UI-05 | Active status effects visible on enemies | 3 |
| UI-06 | Run stats screen shown at end of each run | 6 |
| PROG-01 | Meta progression: permanent unlocks carry over between runs | 6 |
| PROG-02 | Meta unlocks broaden options rather than inflate raw stats | 6 |
| PROG-03 | Run history screen shows past run performance | 6 |
| STEAM-01 | Steam Achievements (meaningful milestones) | 7 |
| STEAM-02 | Steam Cloud Saves (run and meta progress synced) | 7 |
| STEAM-03 | Steam Leaderboards for Endless Escalation mode | 7 |
| STEAM-04 | Stable 60 fps performance target throughout | 1 |

---

*Last updated: 2026-03-09 after requirements definition*
