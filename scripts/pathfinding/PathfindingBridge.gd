class_name PathfindingBridge
extends RefCounted

## GDScript adapter that instantiates C# FlowField and PathValidator objects.
## This is the clean GDScript/C# boundary defined in ADR-02.
## The rest of the GDScript codebase calls this class; it never calls C# directly.

var _flow_field: FlowField
var _path_validator: PathValidator


func _init() -> void:
	_flow_field = FlowField.new()
	_path_validator = PathValidator.new()


## Compute the flow field for the current grid state.
## width, height: grid dimensions.
## cells: Array of GridCell objects from GridManager.
## exit_cell: the exit position.
## Returns an Array[Vector2i] of per-cell directions.
func compute_flow_field(
		width: int,
		height: int,
		cells: Array,
		exit_cell: Vector2i) -> Array:
	var passable_array := _build_passable_array(cells)
	return _flow_field.Compute(width, height, passable_array, exit_cell)


## Validate whether placing a tower at tentative_block would still leave all spawns reachable.
## cells: Array of GridCell objects from GridManager.
## spawn_positions: Array[Vector2i] of spawn points.
## exit_cell: the exit position.
## tentative_block: the cell the player wants to place a tower on.
## Returns true if all spawns remain reachable; false if the placement would block the path.
func is_path_valid(
		width: int,
		height: int,
		cells: Array,
		spawn_positions: Array,
		exit_cell: Vector2i,
		tentative_block: Vector2i) -> bool:
	var passable_array := _build_passable_array(cells)
	var spawn_array: Array[Vector2i] = []
	for pos in spawn_positions:
		spawn_array.append(pos)
	return _path_validator.IsPathValid(width, height, passable_array, spawn_array, exit_cell, tentative_block)


## Return the current flow field version counter.
## Enemies cache this value and re-read their direction when it changes.
func get_flow_field_version() -> int:
	return _flow_field.Version


## Build a flat Array[bool] of passable flags from GridManager's cell array.
func _build_passable_array(cells: Array) -> Array[bool]:
	var result: Array[bool] = []
	result.resize(cells.size())
	for i in range(cells.size()):
		result[i] = cells[i].passable
	return result
