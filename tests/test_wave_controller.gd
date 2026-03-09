extends GutTest

var _wave_ctrl: Node
var _wave_defs: Array[WaveDefinition]


func before_each():
	# Build a minimal 2-wave setup for testing
	var group1 := SpawnGroupResource.new()
	group1.enemy_id = "basic"
	group1.count = 2
	group1.spawn_interval = 0.1
	group1.delay_from_wave_start = 0.0

	var def1 := WaveDefinition.new()
	def1.wave_number = 1
	def1.inter_wave_delay = 0.1  # Very short for test
	def1.groups = [group1]

	var def2 := WaveDefinition.new()
	def2.wave_number = 2
	def2.inter_wave_delay = 0.1
	def2.groups = [group1]

	_wave_defs = [def1, def2]

	_wave_ctrl = load("res://scripts/controllers/WaveController.gd").new()
	_wave_ctrl.wave_definitions = _wave_defs
	add_child_autofree(_wave_ctrl)

	# Set up a minimal grid so GridManager.spawn_positions[0] works
	var map_def := MapDefinition.new()
	map_def.grid_width = 5
	map_def.grid_height = 5
	map_def.spawn_positions = [Vector2i(0, 2)]
	map_def.exit_position = Vector2i(4, 2)
	map_def.static_object_positions = []
	GridManager.initialize_from_map(map_def)
	FlowFieldManager.recompute()


func test_timed_mode_launches_wave_on_timer():
	GameState.wave_mode = GameState.WaveMode.TIMED
	_wave_ctrl._ready()
	assert_false(_wave_ctrl.is_wave_active, "Wave should not be active before timer expires")
	# Simulate enough time passing to exhaust the inter_wave_delay (0.1s)
	_wave_ctrl._process(0.2)
	assert_true(_wave_ctrl.is_wave_active, "Wave should launch after timer expires in TIMED mode")


func test_player_triggered_mode_does_not_auto_launch():
	GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED
	_wave_ctrl._ready()
	_wave_ctrl._process(10.0)  # Simulate a lot of time passing
	assert_false(_wave_ctrl.is_wave_active,
		"Wave must not auto-launch in PLAYER_TRIGGERED mode regardless of time elapsed")


func test_player_triggered_mode_launches_on_signal():
	GameState.wave_mode = GameState.WaveMode.PLAYER_TRIGGERED
	_wave_ctrl._ready()
	_wave_ctrl._process(0.05)  # Some time, but not enough to trigger timed launch
	assert_false(_wave_ctrl.is_wave_active)
	_wave_ctrl.send_wave()
	_wave_ctrl._process(0.0)  # One more tick to process send_wave_pressed
	assert_true(_wave_ctrl.is_wave_active,
		"Wave should launch immediately after send_wave() is called")


func test_wave_counter_increments_after_wave_clear():
	GameState.wave_mode = GameState.WaveMode.TIMED
	_wave_ctrl._ready()
	var initial_index: int = _wave_ctrl.current_wave_index
	# Force wave to end by calling internal methods directly
	_wave_ctrl._launch_wave()
	_wave_ctrl._active_spawn_count = 0
	_wave_ctrl._spawns_dispatched = _wave_defs[0].get_total_enemy_count()
	_wave_ctrl._end_wave()
	assert_eq(_wave_ctrl.current_wave_index, initial_index + 1,
		"current_wave_index should increment after wave ends")
