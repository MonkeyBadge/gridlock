extends Node3D

## PathOverlay — animated path visualization overlay.
## A flat PlaneMesh covering the grid with a ShaderMaterial that renders
## glowing directional arrows pointing toward the exit. Satisfies UI-01.
##
## Shader receives the flow field as a per-cell direction texture (RG float,
## one texel per grid cell). Updated whenever FlowFieldManager emits
## flow_field_updated. Toggle visibility with the P key.

@onready var _mesh: MeshInstance3D = $Mesh
var _direction_texture: ImageTexture = null
var _elapsed: float = 0.0


func _ready() -> void:
	FlowFieldManager.flow_field_updated.connect(_on_flow_field_updated)
	# If flow field already computed, build texture immediately
	if FlowFieldManager.current_version > 0:
		_rebuild_texture()


func _process(delta: float) -> void:
	if not visible or _direction_texture == null:
		return
	_elapsed += delta
	# Pass animated time offset to shader — creates flowing arrow effect
	var mat: ShaderMaterial = _mesh.material_override
	if mat:
		mat.set_shader_parameter("time_offset", fmod(_elapsed * 0.8, 1.0))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:  # Toggle path overlay with P key
			set_visible_overlay(not visible)
			get_viewport().set_input_as_handled()


func _on_flow_field_updated(_version: int) -> void:
	_rebuild_texture()


func _rebuild_texture() -> void:
	var w: int = GridManager.grid_width
	var h: int = GridManager.grid_height
	if w == 0 or h == 0:
		return
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var dir: Vector2i = FlowFieldManager.get_direction(Vector2i(x, y))
			# Encode direction in RG channels, remapped [-1,1] -> [0,1]
			var r: float = (float(dir.x) + 1.0) * 0.5
			var g: float = (float(dir.y) + 1.0) * 0.5
			img.set_pixel(x, y, Color(r, g, 0.0, 1.0))
	if _direction_texture == null:
		_direction_texture = ImageTexture.create_from_image(img)
	else:
		_direction_texture.update(img)
	var mat: ShaderMaterial = _mesh.material_override
	if mat:
		mat.set_shader_parameter("direction_texture", _direction_texture)
		mat.set_shader_parameter("grid_width", w)
		mat.set_shader_parameter("grid_height", h)


func set_visible_overlay(is_visible: bool) -> void:
	visible = is_visible
