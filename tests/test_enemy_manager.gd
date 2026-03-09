extends GutTest


func before_each():
	var map_def := MapDefinition.new()
	map_def.grid_width = 10
	map_def.grid_height = 5
	map_def.spawn_positions = [Vector2i(0, 2)]
	map_def.exit_position = Vector2i(9, 2)
	map_def.static_object_positions = []
	GridManager.initialize_from_map(map_def)
	FlowFieldManager.recompute()

	# Initialize EnemyManager with a basic enemy definition
	var def := EnemyDefinition.new()
	def.enemy_id = "basic"
	def.speed = 10.0  # Fast for test purposes
	def.scale = Vector3.ONE
	def.position_jitter = 0.0

	# Create a minimal MultiMeshInstance3D parent for the test
	var mm_parent := Node3D.new()
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "MMI_Basic"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 0
	mmi.multimesh = mm
	mm_parent.add_child(mmi)
	add_child_autofree(mm_parent)
	EnemyManager.initialize([def], mm_parent)


func test_enemy_reaches_exit_deducts_life():
	var initial_hp: int = GameState.player_hp
	# Prepare pool for 1 enemy, then spawn adjacent to the exit
	var group := SpawnGroupResource.new()
	group.enemy_id = "basic"
	group.count = 1
	group.spawn_interval = 0.0
	group.delay_from_wave_start = 0.0
	var wave_def := WaveDefinition.new()
	wave_def.wave_number = 1
	wave_def.groups = [group]
	EnemyManager.prepare_wave(wave_def)
	EnemyManager.spawn_enemy("basic", Vector2i(8, 2))
	# Simulate enough time for the enemy to cross one cell at speed=10.0
	EnemyManager._process(0.15)  # 0.15s * 10 cells/s = 1.5 cells > 1 cell step
	assert_lt(GameState.player_hp, initial_hp,
		"Player HP should decrease when enemy reaches exit")


func test_enemy_reads_updated_flow_field_on_version_change():
	var group := SpawnGroupResource.new()
	group.enemy_id = "basic"
	group.count = 1
	group.spawn_interval = 0.0
	group.delay_from_wave_start = 0.0
	var wave_def := WaveDefinition.new()
	wave_def.wave_number = 1
	wave_def.groups = [group]
	EnemyManager.prepare_wave(wave_def)
	EnemyManager.spawn_enemy("basic", Vector2i(0, 2))
	var enemy: Dictionary = EnemyManager._active_enemies[0]
	var old_version: int = FlowFieldManager.current_version
	# Trigger a recompute to increment version
	FlowFieldManager.recompute()
	assert_gt(FlowFieldManager.current_version, old_version,
		"Flow field version should have incremented")
	# Before _process runs, cached_field_version is stale
	assert_ne(enemy["cached_field_version"], FlowFieldManager.current_version,
		"Enemy cache should be stale before next process tick")
	# After _process, cache should be updated
	EnemyManager._process(0.0)
	assert_eq(enemy["cached_field_version"], FlowFieldManager.current_version,
		"Enemy should update cached_field_version on next process tick")


func test_enemy_pool_size_matches_wave_definition():
	var group := SpawnGroupResource.new()
	group.enemy_id = "basic"
	group.count = 5
	group.spawn_interval = 0.0
	group.delay_from_wave_start = 0.0

	var wave_def := WaveDefinition.new()
	wave_def.wave_number = 1
	wave_def.groups = [group]

	EnemyManager.prepare_wave(wave_def)
	assert_eq(EnemyManager._multi_mesh_nodes["basic"].multimesh.instance_count,
		wave_def.get_total_enemy_count(),
		"MultiMesh instance_count should equal total enemy count from wave definition")
