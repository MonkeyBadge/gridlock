extends Node

## Game — root scene controller.
## Wires all systems built across Plans 01–05 into a single playable game.
## Initialization order:
##   1. Map01._ready() fires first (child node), calling GridManager.initialize_from_map
##      and FlowFieldManager.recompute automatically.
##   2. EnemyManager.initialize() — called here with enemy defs + EnemyMultiMesh parent.
##   3. TowerPlacer gets camera and toast references.
##   4. HUD.setup() wires WaveController signals to TopBar and SendWaveButton.
##   5. Cross-system signals connected (BottomPanel → TowerPlacer, FlowField → PathOverlay).
##
## STEAM-04 performance note (manual session recorded externally — see STEAM-04-perf-checklist.md):
##   Minimum FPS observed: TBD (requires hardware playtest)
##   FPS during tower placement: TBD
##   Draw calls at peak enemy count: TBD

@onready var _map: Node3D = $Map01
@onready var _enemy_mm: Node3D = $EnemyMultiMesh
@onready var _tower_placer: Node3D = $TowerPlacer
@onready var _wave_controller: Node = $WaveController
@onready var _path_overlay: Node3D = $PathOverlay
@onready var _camera_rig: Node3D = $CameraRig
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	# Step 1: Map01._ready() has already run (child nodes fire before parent).
	# GridManager and FlowFieldManager are initialized by the time we reach here.

	# Step 2: Initialize EnemyManager with enemy definitions and the MultiMesh parent.
	var enemy_defs: Array[EnemyDefinition] = []
	for tres_path: String in [
		"res://data/enemies/enemy_basic.tres",
		"res://data/enemies/enemy_fast.tres",
		"res://data/enemies/enemy_heavy.tres",
	]:
		var def := load(tres_path) as EnemyDefinition
		if def != null:
			enemy_defs.append(def)
	EnemyManager.initialize(enemy_defs, _enemy_mm)

	# Step 3: Wire TowerPlacer — camera for raycasting, toast for rejection feedback.
	_tower_placer.camera = _camera_rig.get_camera()
	_tower_placer.toast = _hud.toast

	# Step 4: Wire HUD — pass WaveController and total wave count.
	_hud.setup(_wave_controller, _wave_controller.wave_definitions.size())

	# Step 5: Connect BottomPanel tower_selected to placement activation.
	var bottom_panel: Node = _hud.get_node("BottomPanel")
	bottom_panel.tower_selected.connect(_on_tower_selected)

	# Step 6: PathOverlay is already connected to FlowFieldManager.flow_field_updated
	# in its own _ready(). No extra wiring needed here.

	# Step 7: Default wave mode is TIMED (set in GameState).
	# Uncomment the line below to test PLAYER_TRIGGERED mode:
	# GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED


func _on_tower_selected(tower_type_id: String) -> void:
	# In Phase 1 only the "wall" tower type exists.
	if tower_type_id == "wall":
		_tower_placer.activate_placement_mode()
