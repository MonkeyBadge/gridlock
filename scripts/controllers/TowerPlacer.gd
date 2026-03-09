extends Node3D

## TowerPlacer controller.
## Handles cursor-to-grid raycasting, hover ghost preview with live BFS validation,
## single-click placement that commits a tower to the grid, FlowField recompute
## after placement, and toast notification on invalid placement rejection.
## Implements CORE-01, CORE-02, and CORE-03.

@export var ghost_scene: PackedScene
@export var tower_wall_scene: PackedScene
## Assign the ToastNotification node from the HUD in the scene.
@export var toast: Node
## Assign the active Camera3D from the scene.
@export var camera: Camera3D

var _ghost: Node3D = null
var _is_placement_mode: bool = false
## Cache the last hovered grid cell. Only re-run BFS when the cell changes (Risk 1 mitigation).
var _last_hover_cell: Vector2i = Vector2i(-1, -1)
var _hover_cell_valid: bool = false
## Track all placed tower nodes for potential future removal (CORE-04, Phase 2).
var _placed_towers: Array[Node3D] = []
## UI-02 range overlay stub: zero-radius torus, toggled on tower selection.
## Phase 2 will set the actual range radius when towers have attack range.
@onready var _range_overlay: MeshInstance3D = $RangeOverlay


func _ready() -> void:
	_ghost = ghost_scene.instantiate()
	add_child(_ghost)
	_ghost.visible = false
	_range_overlay.visible = false


func activate_placement_mode() -> void:
	_is_placement_mode = true
	_ghost.visible = true


func deactivate_placement_mode() -> void:
	_is_placement_mode = false
	_ghost.visible = false
	_range_overlay.visible = false
	_last_hover_cell = Vector2i(-1, -1)


## Called when BottomPanel emits tower_selected(tower_type_id).
## Wired by Game.tscn after assembly.
func _on_tower_type_selected(_tower_type_id: String) -> void:
	activate_placement_mode()
	# Show range overlay at ghost position during placement mode
	_range_overlay.visible = _is_placement_mode
	_range_overlay.global_position = _ghost.global_position


func _input(event: InputEvent) -> void:
	if not _is_placement_mode:
		return
	if event is InputEventMouseMotion:
		_update_hover(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_place()


## Raycast cursor position onto the Y=0 grid plane, find the hovered cell,
## and update the ghost position and validity color.
## Only reruns BFS when the cursor crosses a cell boundary.
func _update_hover(screen_pos: Vector2) -> void:
	if camera == null:
		return

	# Manual plane intersection: find where the ray from the camera hits Y=0.
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var dir: Vector3 = camera.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.001:
		return  # Ray is parallel to the ground plane — no intersection.
	var t: float = -from.y / dir.y
	if t < 0.0:
		return  # Intersection is behind the camera.
	var hit_pos: Vector3 = from + dir * t

	var cell: Vector2i = GridManager.world_to_grid(hit_pos)

	# BFS optimization: skip recompute if the cell has not changed.
	if cell == _last_hover_cell:
		return
	_last_hover_cell = cell

	# Move the ghost and range overlay to the hovered cell center.
	_ghost.global_position = GridManager.grid_to_world(cell)
	_range_overlay.global_position = _ghost.global_position

	# Validate placement.
	if not GridManager.is_in_bounds(cell):
		_hover_cell_valid = false
	elif not GridManager.can_place_tower(cell):
		# Cell is SPAWN, EXIT, TOWER, or STATIC_OBJECT.
		_hover_cell_valid = false
	else:
		# BFS reachability check — only runs when the cell changes.
		_hover_cell_valid = FlowFieldManager.validate_placement(cell)

	_ghost.set_valid(_hover_cell_valid)


## Attempt to place a tower at the last hovered cell.
## On valid placement: commits to grid, recomputes flow field, spawns mesh.
## On invalid placement: shows toast, leaves grid unchanged (CORE-02).
func _attempt_place() -> void:
	if not GridManager.is_in_bounds(_last_hover_cell):
		return

	if not _hover_cell_valid:
		# CORE-02: rejected placement — grid state must not change.
		if toast != null:
			toast.show_message()
		return

	# CORE-01: commit tower to the grid (marks cell impassable).
	GridManager.set_cell_state(_last_hover_cell, GridCell.State.TOWER)

	# CORE-03: recompute flow field so all enemies re-route on next movement tick.
	FlowFieldManager.recompute()

	# Spawn the permanent tower mesh at the cell world position.
	var tower: Node3D = tower_wall_scene.instantiate()
	get_tree().current_scene.add_child(tower)
	tower.global_position = GridManager.grid_to_world(_last_hover_cell)
	_placed_towers.append(tower)

	# Invalidate hover cache so the ghost re-validates on next mouse move.
	_last_hover_cell = Vector2i(-1, -1)
