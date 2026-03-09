extends GutTest

var _map_def: MapDefinition


func before_each():
	_map_def = MapDefinition.new()
	_map_def.grid_width = 5
	_map_def.grid_height = 5
	_map_def.spawn_positions = [Vector2i(0, 2)]
	_map_def.exit_position = Vector2i(4, 2)
	_map_def.static_object_positions = [Vector2i(2, 0)]
	GridManager.initialize_from_map(_map_def)


func test_cell_initialized_passable():
	var cell = GridManager.get_cell(Vector2i(1, 1))
	assert_not_null(cell, "Cell should not be null")
	assert_true(cell.passable, "Empty cell should be passable after initialization")


func test_tower_placement_marks_cell_impassable():
	GridManager.set_cell_state(Vector2i(1, 1), GridCell.State.TOWER)
	var cell = GridManager.get_cell(Vector2i(1, 1))
	assert_false(cell.passable, "Cell should be impassable after tower placement")
	assert_eq(cell.state, GridCell.State.TOWER)


func test_static_object_cell_is_impassable():
	var cell = GridManager.get_cell(Vector2i(2, 0))
	assert_false(cell.passable, "Static object cell should be impassable at initialization")
	assert_eq(cell.state, GridCell.State.STATIC_OBJECT)


func test_spawn_cell_cannot_receive_tower():
	var can_place = GridManager.can_place_tower(Vector2i(0, 2))
	assert_false(can_place, "Spawn cell should not accept tower placement")


func test_exit_cell_cannot_receive_tower():
	var can_place = GridManager.can_place_tower(Vector2i(4, 2))
	assert_false(can_place, "Exit cell should not accept tower placement")
