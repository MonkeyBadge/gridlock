extends Node

## FlowFieldManager autoload singleton.
## Owns the current flow field direction array and version counter.
## Calls the C# pathfinding layer via PathfindingBridge.
## Enemies read their movement direction from get_direction().

var _bridge: PathfindingBridge

## The last computed direction array. Each element is a Vector2i.
## Indexed as grid_pos.x + grid_pos.y * GridManager.grid_width.
var current_directions: Array = []

## The flow field version. Incremented each time recompute() is called.
## Enemies cache this value and re-read their direction when it changes.
var current_version: int = 0

## Emitted after each successful recompute. Subscribers update visuals/caches.
signal flow_field_updated(version: int)


func _ready() -> void:
	_bridge = PathfindingBridge.new()
	# Connect to grid_changed but do NOT auto-recompute.
	# Only TowerPlacer calls recompute() after a confirmed placement.
	GridManager.grid_changed.connect(_on_grid_changed)


## Recompute the flow field from the current GridManager state.
## Call this after every confirmed tower placement or removal.
func recompute() -> void:
	if GridManager.cells.is_empty():
		return

	current_directions = _bridge.compute_flow_field(
		GridManager.grid_width,
		GridManager.grid_height,
		GridManager.cells,
		GridManager.exit_position
	)
	current_version = _bridge.get_flow_field_version()
	emit_signal("flow_field_updated", current_version)


## Get the direction for a cell. Returns Vector2i.ZERO if no flow field or unreachable.
func get_direction(grid_pos: Vector2i) -> Vector2i:
	if current_directions.is_empty():
		return Vector2i.ZERO
	var idx: int = grid_pos.x + grid_pos.y * GridManager.grid_width
	if idx < 0 or idx >= current_directions.size():
		return Vector2i.ZERO
	return current_directions[idx]


## Check whether placing a tower at tentative_cell would keep all spawns reachable.
func validate_placement(tentative_cell: Vector2i) -> bool:
	return _bridge.is_path_valid(
		GridManager.grid_width,
		GridManager.grid_height,
		GridManager.cells,
		GridManager.spawn_positions,
		GridManager.exit_position,
		tentative_cell
	)


## Called when the grid changes. Currently a no-op: we do not auto-recompute.
## TowerPlacer is responsible for calling recompute() after confirmed placements.
func _on_grid_changed() -> void:
	pass
