# Test Framework Setup

## GUT (Godot Unit Testing) Installation

GUT cannot be installed via command line. It requires the Godot editor. Follow these steps:

### Option A: Godot AssetLib (Recommended)

1. Open the Godot editor with this project.
2. Click the **AssetLib** tab in the top-center of the editor.
3. Search for **"GUT"**.
4. Click **"Gut - Godot Unit Testing"** by bitwes.
5. Click **Download**, then **Install**.
6. GUT files will be placed under `res://addons/gut/`.
7. Go to **Project → Project Settings → Plugins**.
8. Find **GUT** in the list and set it to **Enable**.
9. A **GUT** panel will appear in the bottom dock.

### Option B: Manual Download

1. Go to: https://github.com/bitwes/Gut/releases
2. Download the latest `gut_9.x.zip` (use GUT 9.x for Godot 4.x).
3. Extract the zip into `res://addons/gut/`.
4. In Godot editor: **Project → Project Settings → Plugins → GUT → Enable**.

### Verification

After installation, verify GUT is working:

1. In the GUT panel (bottom dock), click **Run All**.
2. All 17 tests should show as **pending** (yellow/orange) — not failed, not errored.
3. The test suite should exit with code 0.

### Headless CLI Run

Once GUT is installed, run tests headlessly:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected output: 17 tests, all pending. Exit code 0.

### Test Files

The following test stub files are ready for implementation:

| File | Tests |
|------|-------|
| `test_grid_manager.gd` | 5 pending tests — GridCell state, passability, tower placement constraints |
| `test_path_validation.gd` | 5 pending tests — BFS flood-fill validation scenarios |
| `test_flow_field.gd` | 4 pending tests — Dijkstra directions, version counter, unreachable cells |
| `test_wave_controller.gd` | 4 pending tests — Timed and Player-Triggered wave mode behavior |
| `test_enemy_manager.gd` | 3 pending tests — Life deduction, flow field version tracking, pool sizing |

All tests use `pending("not implemented")` bodies. Implement them as each system is built.
