extends GutTest

var _map_def: MapDefinition


func before_each():
	_map_def = MapDefinition.new()
	_map_def.grid_width = 5
	_map_def.grid_height = 5
	_map_def.spawn_positions = [Vector2i(0, 2)]
	_map_def.exit_position = Vector2i(4, 2)
	_map_def.static_object_positions = []
	GridManager.initialize_from_map(_map_def)
	FlowFieldManager.recompute()


func test_exit_cell_direction_is_zero_vector():
	var dir = FlowFieldManager.get_direction(Vector2i(4, 2))
	assert_eq(dir, Vector2i.ZERO, "Exit cell direction should be zero vector")


func test_adjacent_to_exit_points_at_exit():
	# Cell directly left of exit (3,2) should point right toward exit (4,2).
	var dir = FlowFieldManager.get_direction(Vector2i(3, 2))
	assert_eq(dir, Vector2i(1, 0), "Cell adjacent to exit should point toward exit")


func test_flow_field_version_increments_on_recompute():
	var version_before = FlowFieldManager.current_version
	GridManager.set_cell_state(Vector2i(1, 1), GridCell.State.TOWER)
	FlowFieldManager.recompute()
	assert_gt(FlowFieldManager.current_version, version_before,
		"Flow field version should increment after recompute")


func test_unreachable_cell_has_zero_direction():
	# Block all four neighbors of cell (1,1) to isolate it.
	GridManager.set_cell_state(Vector2i(1, 0), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(0, 1), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(1, 2), GridCell.State.TOWER)
	FlowFieldManager.recompute()
	var dir = FlowFieldManager.get_direction(Vector2i(1, 1))
	assert_eq(dir, Vector2i.ZERO, "Isolated cell should have zero direction (unreachable)")
