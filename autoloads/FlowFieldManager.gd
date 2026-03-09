extends Node

## FlowFieldManager autoload singleton.
## Owns the current flow field direction array and version counter.
## Pure GDScript implementation — Dijkstra BFS from exit, BFS flood-fill for validation.
## (C# layer kept as reference but not used — GDScript is fast enough for 20x20 grid.)

## The last computed direction array. Each element is a Vector2i.
## Indexed as grid_pos.x + grid_pos.y * GridManager.grid_width.
var current_directions: Array = []

## Incremented on each recompute. Enemies cache this and re-read when it changes.
var current_version: int = 0

signal flow_field_updated(version: int)


func _ready() -> void:
	GridManager.grid_changed.connect(_on_grid_changed)


## Recompute the flow field from the current GridManager state.
## Call after every confirmed tower placement or removal.
func recompute() -> void:
	if GridManager.cells.is_empty():
		return
	current_directions = _compute_flow_field(
		GridManager.grid_width,
		GridManager.grid_height,
		GridManager.cells,
		GridManager.exit_position
	)
	current_version += 1
	emit_signal("flow_field_updated", current_version)


## Get the movement direction for a grid cell. Returns Vector2i.ZERO if unreachable.
func get_direction(grid_pos: Vector2i) -> Vector2i:
	if current_directions.is_empty():
		return Vector2i.ZERO
	var idx: int = grid_pos.x + grid_pos.y * GridManager.grid_width
	if idx < 0 or idx >= current_directions.size():
		return Vector2i.ZERO
	return current_directions[idx]


## Check whether placing a tower at tentative_cell keeps all spawns reachable.
func validate_placement(tentative_cell: Vector2i) -> bool:
	return _is_path_valid(
		GridManager.grid_width,
		GridManager.grid_height,
		GridManager.cells,
		GridManager.spawn_positions,
		GridManager.exit_position,
		tentative_cell
	)


func _on_grid_changed() -> void:
	pass


# --- Dijkstra BFS from exit outward ---
func _compute_flow_field(width: int, height: int, cells: Array, exit_pos: Vector2i) -> Array:
	var size: int = width * height
	var distances: Array = []
	distances.resize(size)
	for i in range(size):
		distances[i] = INF

	var directions: Array = []
	directions.resize(size)
	for i in range(size):
		directions[i] = Vector2i.ZERO

	var exit_idx: int = exit_pos.x + exit_pos.y * width
	distances[exit_idx] = 0.0

	var queue: Array = [exit_pos]
	var head: int = 0

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var current_dist: float = distances[current.x + current.y * width]
		for neighbor in _get_passable_neighbors(current, width, height, cells, Vector2i(-1, -1)):
			var n_idx: int = neighbor.x + neighbor.y * width
			if current_dist + 1.0 < distances[n_idx]:
				distances[n_idx] = current_dist + 1.0
				queue.append(neighbor)

	# Build direction map: each cell points toward neighbor with lowest distance
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var idx: int = x + y * width
			if pos == exit_pos:
				directions[idx] = Vector2i.ZERO
				continue
			var best_dir := Vector2i.ZERO
			var best_dist: float = INF
			for neighbor in _get_passable_neighbors(pos, width, height, cells, Vector2i(-1, -1)):
				var n_idx: int = neighbor.x + neighbor.y * width
				if distances[n_idx] < best_dist:
					best_dist = distances[n_idx]
					best_dir = neighbor - pos
			directions[idx] = best_dir

	return directions


# --- BFS flood-fill validation ---
func _is_path_valid(width: int, height: int, cells: Array, spawn_positions: Array,
		exit_pos: Vector2i, tentative_block: Vector2i) -> bool:
	var size: int = width * height
	var visited: Array = []
	visited.resize(size)
	for i in range(size):
		visited[i] = false

	var exit_idx: int = exit_pos.x + exit_pos.y * width
	visited[exit_idx] = true
	var queue: Array = [exit_pos]
	var head: int = 0

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for neighbor in _get_passable_neighbors(current, width, height, cells, tentative_block):
			var n_idx: int = neighbor.x + neighbor.y * width
			if not visited[n_idx]:
				visited[n_idx] = true
				queue.append(neighbor)

	for spawn_pos in spawn_positions:
		var s_idx: int = spawn_pos.x + spawn_pos.y * width
		if not visited[s_idx]:
			return false
	return true


# --- Shared neighbor helper ---
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

func _get_passable_neighbors(pos: Vector2i, width: int, height: int,
		cells: Array, exclude: Vector2i) -> Array:
	var result: Array = []
	for d: Vector2i in DIRS:
		var n: Vector2i = pos + d
		if n.x < 0 or n.x >= width or n.y < 0 or n.y >= height:
			continue
		if n == exclude:
			continue
		var idx: int = n.x + n.y * width
		if cells[idx].passable:
			result.append(n)
	return result
