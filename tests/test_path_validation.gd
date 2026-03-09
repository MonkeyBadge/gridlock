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


func test_open_grid_path_is_valid():
	var valid = FlowFieldManager.validate_placement(Vector2i(-1, -1))
	assert_true(valid, "Open grid should have a valid path")


func test_full_block_is_rejected():
	# Block the entire middle column.
	GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 2), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
	var valid = FlowFieldManager.validate_placement(Vector2i(-1, -1))
	assert_false(valid, "Fully blocked column should be rejected")


func test_partial_block_leaves_route_valid():
	# Block all but one cell in the middle column.
	GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
	# Cell (2,2) remains passable — one-cell gap in the column.
	var valid = FlowFieldManager.validate_placement(Vector2i(-1, -1))
	assert_true(valid, "Single gap in column should leave path valid")


func test_corner_block_leaves_route_valid():
	# Block two cells that form an L — route still available around the outside.
	GridManager.set_cell_state(Vector2i(1, 2), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(1, 3), GridCell.State.TOWER)
	var valid = FlowFieldManager.validate_placement(Vector2i(-1, -1))
	assert_true(valid, "Corner block should leave valid route around the outside")


func test_validation_does_not_modify_grid_on_rejection():
	# Block all but the last gap in the middle column.
	GridManager.set_cell_state(Vector2i(2, 0), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 1), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 3), GridCell.State.TOWER)
	GridManager.set_cell_state(Vector2i(2, 4), GridCell.State.TOWER)
	# Tentatively block cell (2,2) — this would disconnect the path.
	var valid = FlowFieldManager.validate_placement(Vector2i(2, 2))
	assert_false(valid, "Blocking last gap should be rejected")
	# Verify the real grid cell is still passable (validation must not modify grid).
	var cell = GridManager.get_cell(Vector2i(2, 2))
	assert_true(cell.passable, "Rejected placement must not modify the real grid")
