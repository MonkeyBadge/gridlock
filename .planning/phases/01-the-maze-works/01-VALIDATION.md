---
phase: 1
slug: the-maze-works
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-09
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Testing) 9.x |
| **Config file** | `res://addons/gut/` — Wave 0 installs |
| **Quick run command** | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` |
| **Full suite command** | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | CORE-01 | unit | `godot --headless ... test_grid_manager.gd` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 1 | CORE-02 | unit | `godot --headless ... test_path_validation.gd` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | CORE-03 | integration | `godot --headless ... test_flow_field.gd` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 1 | MAP-01 | unit | `godot --headless ... test_grid_manager.gd` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 1 | MAP-03 | unit | `godot --headless ... test_grid_manager.gd` | ❌ W0 | ⬜ pending |
| 1-02-03 | 02 | 1 | MAP-04 | manual | N/A — playtest only | N/A | ⬜ pending |
| 1-03-01 | 03 | 2 | WAVE-01 | integration | `godot --headless ... test_wave_controller.gd` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 2 | WAVE-02 | integration | `godot --headless ... test_wave_controller.gd` | ❌ W0 | ⬜ pending |
| 1-04-01 | 04 | 2 | ENEMY-01 | unit + manual | `godot --headless ... test_enemy_manager.gd` | ❌ W0 | ⬜ pending |
| 1-05-01 | 05 | 3 | UI-01 | integration | `godot --headless ... test_flow_field.gd` | ❌ W0 | ⬜ pending |
| 1-05-02 | 05 | 3 | UI-02 | manual | N/A — visual verification | N/A | ⬜ pending |
| 1-06-01 | 06 | 3 | STEAM-04 | manual | N/A — performance session on hardware | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `res://tests/test_grid_manager.gd` — stubs for CORE-01, MAP-01, MAP-03
- [ ] `res://tests/test_path_validation.gd` — stubs for CORE-02
- [ ] `res://tests/test_flow_field.gd` — stubs for CORE-03, UI-01
- [ ] `res://tests/test_wave_controller.gd` — stubs for WAVE-01, WAVE-02
- [ ] `res://tests/test_enemy_manager.gd` — stubs for ENEMY-01
- [ ] GUT plugin installed and enabled in Project Settings → Plugins

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Static objects create strategic routing constraints | MAP-04 | "Strategic interest" is subjective — no quantifiable assertion | Playtest with a tester: confirm enemies cannot pass through static objects and that routing around them feels meaningful |
| Tower range overlay appears on tower selection | UI-02 | Visual/scene inspection required | Select a tower, confirm range overlay `MeshInstance3D` toggles visible at cursor position |
| Stable 60fps during peak wave | STEAM-04 | Hardware-dependent frame timing | Run 5-wave session on GTX 1060-tier hardware; pin FPS monitor in Godot Debugger; confirm no sustained drops below 60fps during tower placement mid-wave |
| Enemy size and speed differences are observable | ENEMY-01 (partial) | Human perceptual judgment | Watch a wave with all 3 enemy types; tester must identify size/speed differences without UI labels |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
