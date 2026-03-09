extends Node3D

## CameraRig — three-node camera hierarchy controller.
## Hierarchy: CameraRig (this node) → CameraPivot (Node3D) → Camera3D
##
## Navigation behaviors:
##   - 60° default tilt from vertical (TILT_DEFAULT_DEGREES = -60.0)
##   - Three zoom levels with Tween transitions
##   - WASD + edge-scroll + middle-click-drag pan
##   - Hard map-edge clamping on every pan update
##   - Quick reset (R or Home key) — tweens to map center, resets tilt and zoom
##   - Click-to-follow: left-click raycast locks rig to entity world position
##   - Escape clears follow target

const ZOOM_DISTANCES: Array = [50.0, 30.0, 12.0]  # Overview, Standard, Detail
const ZOOM_TWEEN_DURATION: float = 0.3
const TILT_DEFAULT_DEGREES: float = -60.0
const TILT_MIN_DEGREES: float = -80.0   # Near top-down
const TILT_MAX_DEGREES: float = -45.0   # Maximum 3D tilt
const PAN_SPEED_KEYBOARD: float = 15.0  # World units per second
const PAN_SPEED_EDGE: float = 12.0
const EDGE_SCROLL_MARGIN: float = 40.0  # Pixels from screen edge
const DRAG_SENSITIVITY: float = 0.015   # World units per pixel

@export var map_width_units: float = 40.0   # grid_width * CELL_SIZE (20 * 2.0)
@export var map_height_units: float = 40.0  # grid_height * CELL_SIZE (20 * 2.0)

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

var _zoom_level: int = 1       # 0=Overview, 1=Standard, 2=Detail
var _is_dragging: bool = false
var _drag_start_mouse: Vector2
var _drag_start_rig_pos: Vector3
var _follow_target: Node3D = null  # click-to-follow target
var _active_zoom_tween: Tween = null


func _ready() -> void:
	# Use GridManager dimensions if available
	if Engine.has_singleton("GridManager"):
		var gm = Engine.get_singleton("GridManager")
		map_width_units = gm.grid_width * gm.CELL_SIZE
		map_height_units = gm.grid_height * gm.CELL_SIZE
	elif get_node_or_null("/root/GridManager") != null:
		var gm = get_node("/root/GridManager")
		map_width_units = gm.grid_width * gm.CELL_SIZE
		map_height_units = gm.grid_height * gm.CELL_SIZE

	global_position = Vector3(map_width_units * 0.5, 0.0, map_height_units * 0.5)
	_camera.position.z = ZOOM_DISTANCES[_zoom_level]
	_pivot.rotation_degrees.x = TILT_DEFAULT_DEGREES


func _process(delta: float) -> void:
	# Follow target lock (click-to-follow)
	if _follow_target != null and is_instance_valid(_follow_target):
		var target_xz = Vector3(_follow_target.global_position.x, 0.0, _follow_target.global_position.z)
		global_position = target_xz
		_clamp_to_map_bounds()
		return  # Skip pan input while following

	# WASD pan
	var pan_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    pan_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  pan_dir.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  pan_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): pan_dir.x += 1.0

	# Edge-scroll pan
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if mouse_pos.x < EDGE_SCROLL_MARGIN:              pan_dir.x -= 1.0
	if mouse_pos.x > vp_size.x - EDGE_SCROLL_MARGIN:  pan_dir.x += 1.0
	if mouse_pos.y < EDGE_SCROLL_MARGIN:              pan_dir.z -= 1.0
	if mouse_pos.y > vp_size.y - EDGE_SCROLL_MARGIN:  pan_dir.z += 1.0

	# Apply pan
	if pan_dir != Vector3.ZERO:
		global_position += pan_dir.normalized() * PAN_SPEED_KEYBOARD * delta
		_clamp_to_map_bounds()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(_zoom_level - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(_zoom_level + 1)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = event.pressed
			if _is_dragging:
				_drag_start_mouse = event.position
				_drag_start_rig_pos = global_position
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)

	if event is InputEventMouseMotion and _is_dragging:
		var delta_mouse: Vector2 = event.position - _drag_start_mouse
		var pan_offset: Vector3 = Vector3(-delta_mouse.x, 0.0, -delta_mouse.y) * DRAG_SENSITIVITY * ZOOM_DISTANCES[_zoom_level]
		global_position = _drag_start_rig_pos + pan_offset
		_clamp_to_map_bounds()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R or event.keycode == KEY_HOME:
			_reset_camera()
		if event.keycode == KEY_ESCAPE:
			_follow_target = null  # Clear follow lock on Escape


func _set_zoom(level: int) -> void:
	level = clamp(level, 0, ZOOM_DISTANCES.size() - 1)
	if level == _zoom_level:
		return
	_zoom_level = level

	if _active_zoom_tween != null and _active_zoom_tween.is_valid():
		_active_zoom_tween.kill()
	_active_zoom_tween = create_tween()
	_active_zoom_tween.tween_property(_camera, "position:z", ZOOM_DISTANCES[level], ZOOM_TWEEN_DURATION)


func _clamp_to_map_bounds() -> void:
	global_position.x = clamp(global_position.x, 0.0, map_width_units)
	global_position.z = clamp(global_position.z, 0.0, map_height_units)
	global_position.y = 0.0  # Rig stays on XZ plane


func _reset_camera() -> void:
	_follow_target = null
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(self, "global_position",
		Vector3(map_width_units * 0.5, 0.0, map_height_units * 0.5), 0.4)
	t.tween_property(_pivot, "rotation_degrees:x", TILT_DEFAULT_DEGREES, 0.4)
	_set_zoom(1)  # Reset to Standard zoom


func _handle_left_click(screen_pos: Vector2) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + _camera.project_ray_normal(screen_pos) * 1000.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	var result: Dictionary = space_state.intersect_ray(query)
	if result and result.collider is Node3D:
		_follow_target = result.collider
	else:
		_follow_target = null


## Returns the Camera3D node — used by TowerPlacer to project rays.
func get_camera() -> Camera3D:
	return _camera
