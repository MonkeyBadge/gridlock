extends Node

## GridManager autoload singleton.
## Owns the authoritative logical grid (flat Array of GridCell objects).
## All coordinate conversions are centralized here.
## Other systems query this for passability and cell state.

## 2 Godot world units per grid cell (per RESEARCH.md architecture decision).
const CELL_SIZE: float = 2.0

## Flat array of GridCell objects indexed as x + y * grid_width.
var cells: Array = []

var grid_width: int = 0
var grid_height: int = 0
var spawn_positions: Array[Vector2i] = []
var exit_position: Vector2i = Vector2i(-1, -1)

## Emitted after any cell state mutation. Subscribers (e.g. FlowFieldManager) can listen.
signal grid_changed


## Initialize the grid from a MapDefinition resource.
## Called by the map scene's _ready() function.
func initialize_from_map(map_def: MapDefinition) -> void:
	grid_width = map_def.grid_width
	grid_height = map_def.grid_height
	spawn_positions = map_def.spawn_positions.duplicate()
	exit_position = map_def.exit_position

	cells.clear()
	cells.resize(grid_width * grid_height)

	for y in range(grid_height):
		for x in range(grid_width):
			var cell := GridCell.new()
			cell.position = Vector2i(x, y)
			cell.state = GridCell.State.EMPTY
			cells[x + y * grid_width] = cell

	# Apply spawn states
	for pos in map_def.spawn_positions:
		set_cell_state(pos, GridCell.State.SPAWN)

	# Apply exit state
	set_cell_state(map_def.exit_position, GridCell.State.EXIT)

	# Apply static object states (pre-placed terrain, rocks, ruins)
	for pos in map_def.static_object_positions:
		set_cell_state(pos, GridCell.State.STATIC_OBJECT)


## Return the GridCell at grid position pos, or null if out of bounds.
func get_cell(pos: Vector2i) -> GridCell:
	if not is_in_bounds(pos):
		return null
	return cells[pos.x + pos.y * grid_width]


## Set the state of a cell and emit grid_changed.
func set_cell_state(pos: Vector2i, state: GridCell.State) -> void:
	var cell := get_cell(pos)
	if cell == null:
		return
	cell.state = state
	emit_signal("grid_changed")


## Return whether the cell at pos is passable (enemies can walk through it).
func is_passable(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return get_cell(pos).passable


## Convert a 3D world position to the grid cell that contains it.
## Uses XZ plane; Y axis is ignored.
func world_to_grid(world_pos: Vector3) -> Vector2i:
	var gx: int = int(world_pos.x / CELL_SIZE)
	var gy: int = int(world_pos.z / CELL_SIZE)
	# Guard negative coordinates (floor toward negative infinity for negatives)
	if world_pos.x < 0.0:
		gx -= 1
	if world_pos.z < 0.0:
		gy -= 1
	return Vector2i(gx, gy)


## Convert a grid position to the world-space center of that cell.
## Returns the center of the cell on the XZ plane at Y=0.
func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(
		grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
		0.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5
	)


## Return whether pos is within grid bounds.
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


## Return whether a tower can be placed at pos.
## Does NOT run path validation — that is done separately via PathfindingBridge.
## Returns false if the cell is not EMPTY (cannot place on SPAWN, EXIT, STATIC_OBJECT, or TOWER).
func can_place_tower(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	var cell := get_cell(pos)
	return cell.state == GridCell.State.EMPTY
