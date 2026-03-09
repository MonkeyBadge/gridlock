extends Node

## EnemyManager — autoload singleton for enemy data pool and rendering.
## Manages all active enemies as data records (Dictionaries), drives per-frame
## movement via the flow field, and updates MultiMeshInstance3D transforms.
##
## Architecture (ADR-05, ADR-06):
##   - One MultiMeshInstance3D per enemy type (MMI_Basic, MMI_Fast, MMI_Heavy)
##   - Enemies are pure data records — NOT scene nodes
##   - Four-directional movement only (no diagonals)
##   - is_mid_transition guard prevents direction snap mid-cell (Risk 3 mitigation)
##   - Position jitter assigned at spawn, held constant per enemy (Risk 8 mitigation)
##   - Inactive pool slots are moved to Vector3(0, -1000, 0) off-screen (Risk 4 mitigation)

# Enemy record Dictionary schema:
#   "id": int           — index into the per-type pool array
#   "type_id": String   — matches EnemyDefinition.enemy_id
#   "world_pos": Vector3
#   "grid_pos": Vector2i
#   "direction": Vector2i   — current movement direction (one of 4 cardinal dirs or Vector2i.ZERO)
#   "progress": float       — 0.0–1.0 fraction through current cell transition
#   "is_mid_transition": bool  — true while moving between cells; delays direction re-read
#   "jitter": Vector2       — assigned at spawn, constant per enemy
#   "cached_field_version": int
#   "active": bool

var _enemy_defs: Dictionary = {}       # enemy_id -> EnemyDefinition
var _pools: Dictionary = {}            # enemy_id -> Array of enemy record Dicts
var _pool_counters: Dictionary = {}    # enemy_id -> next available pool index
var _active_enemies: Array = []        # flat list of active enemy records
var _multi_mesh_nodes: Dictionary = {} # enemy_id -> MultiMeshInstance3D

signal enemy_reached_exit(enemy_record: Dictionary)


func initialize(enemy_definitions: Array, multi_mesh_parent: Node) -> void:
	for def in enemy_definitions:
		_enemy_defs[def.enemy_id] = def

		# Locate the corresponding MMI_* child node by name convention
		var node_name: String = "MMI_" + def.enemy_id.capitalize()
		var mmi = multi_mesh_parent.get_node_or_null(node_name)
		if mmi != null:
			_multi_mesh_nodes[def.enemy_id] = mmi
			# Assign mesh from definition (may be null in Phase 1 — placeholder)
			if def.mesh != null and mmi.multimesh != null:
				mmi.multimesh.mesh = def.mesh
		else:
			push_warning("EnemyManager.initialize: could not find node '%s' under '%s'" % [node_name, multi_mesh_parent.name])

		_pools[def.enemy_id] = []
		_pool_counters[def.enemy_id] = 0


func prepare_wave(wave_def: WaveDefinition) -> void:
	_active_enemies.clear()

	# Calculate total enemy count per type from wave groups
	var counts: Dictionary = {}
	for group in wave_def.groups:
		if not counts.has(group.enemy_id):
			counts[group.enemy_id] = 0
		counts[group.enemy_id] += group.count

	# Pre-size MultiMesh and initialize pool records for each type
	for type_id in counts:
		var count: int = counts[type_id]
		var mmi = _multi_mesh_nodes.get(type_id)
		if mmi == null:
			push_warning("EnemyManager.prepare_wave: no MultiMeshInstance3D for type '%s'" % type_id)
			continue

		# Resize the multimesh instance_count
		mmi.multimesh.instance_count = count

		# Hide all instances off-screen
		var hide_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, -1000.0, 0.0))
		for i in range(count):
			mmi.multimesh.set_instance_transform(i, hide_transform)

		# Build pool records
		_pools[type_id] = []
		for i in range(count):
			_pools[type_id].append({
				"id": i,
				"type_id": type_id,
				"world_pos": Vector3.ZERO,
				"grid_pos": Vector2i.ZERO,
				"direction": Vector2i.ZERO,
				"progress": 0.0,
				"is_mid_transition": false,
				"jitter": Vector2.ZERO,
				"cached_field_version": 0,
				"active": false,
			})
		_pool_counters[type_id] = 0


func spawn_enemy(type_id: String, spawn_position: Vector2i) -> void:
	if not _pools.has(type_id):
		push_warning("EnemyManager.spawn_enemy: unknown type_id '%s'" % type_id)
		return

	var pool: Array = _pools[type_id]
	var idx: int = _pool_counters.get(type_id, 0)
	if idx >= pool.size():
		push_warning("EnemyManager.spawn_enemy: pool exhausted for type '%s'" % type_id)
		return

	var enemy: Dictionary = pool[idx]
	_pool_counters[type_id] = idx + 1

	var def = _enemy_defs.get(type_id)
	if def == null:
		push_warning("EnemyManager.spawn_enemy: no EnemyDefinition for type '%s'" % type_id)
		return

	# Apply per-enemy position jitter (±position_jitter * CELL_SIZE)
	var cell_size: float = GridManager.CELL_SIZE if "CELL_SIZE" in GridManager else 2.0
	var jitter_range: float = cell_size * def.position_jitter
	enemy["jitter"] = Vector2(
		randf_range(-jitter_range, jitter_range),
		randf_range(-jitter_range, jitter_range)
	)

	enemy["active"] = true
	enemy["grid_pos"] = spawn_position
	enemy["world_pos"] = GridManager.grid_to_world(spawn_position)
	enemy["progress"] = 0.0
	enemy["is_mid_transition"] = false

	# Read initial direction from flow field if available
	if FlowFieldManager.current_version > 0:
		enemy["direction"] = FlowFieldManager.get_direction(spawn_position)
		enemy["cached_field_version"] = FlowFieldManager.current_version
	else:
		enemy["direction"] = Vector2i.ZERO
		enemy["cached_field_version"] = 0

	_active_enemies.append(enemy)


func _process(delta: float) -> void:
	# Guard: flow field not yet computed — skip movement entirely
	if FlowFieldManager.current_version == 0:
		return

	var to_remove: Array = []

	for enemy in _active_enemies:
		if not enemy["active"]:
			to_remove.append(enemy)
			continue

		var type_id: String = enemy["type_id"]
		var def = _enemy_defs.get(type_id)
		if def == null:
			continue

		# Update direction from flow field if version changed and not mid-transition
		if not enemy["is_mid_transition"] and enemy["cached_field_version"] != FlowFieldManager.current_version:
			enemy["direction"] = FlowFieldManager.get_direction(enemy["grid_pos"])
			enemy["cached_field_version"] = FlowFieldManager.current_version

		# Advance movement: progress in cells-per-second
		enemy["progress"] = enemy["progress"] + def.speed * delta

		var reached_exit := false
		while enemy["progress"] >= 1.0:
			enemy["progress"] -= 1.0
			var dir: Vector2i = enemy["direction"]
			enemy["grid_pos"] = enemy["grid_pos"] + dir

			# Check if the enemy has reached the exit
			if enemy["grid_pos"] == GridManager.exit_position:
				GameState.deduct_life()
				enemy_reached_exit.emit(enemy)
				_deactivate_enemy(enemy)
				reached_exit = true
				break

			# Cell step completed — clear mid-transition and read new direction
			enemy["is_mid_transition"] = false
			enemy["direction"] = FlowFieldManager.get_direction(enemy["grid_pos"])
			enemy["cached_field_version"] = FlowFieldManager.current_version

		if reached_exit:
			to_remove.append(enemy)
			continue

		# Compute render position: lerp between current cell and next cell center
		var base_pos: Vector3 = GridManager.grid_to_world(enemy["grid_pos"])
		var dir3 := Vector3(float(enemy["direction"].x), 0.0, float(enemy["direction"].y))
		var cell_size: float = GridManager.CELL_SIZE if "CELL_SIZE" in GridManager else 2.0
		var next_pos: Vector3 = base_pos + dir3 * cell_size
		var jitter: Vector2 = enemy["jitter"]
		var render_pos: Vector3 = base_pos.lerp(next_pos, enemy["progress"]) + Vector3(jitter.x, 0.5, jitter.y)

		# Update MultiMesh transform for this enemy's instance slot
		var mmi = _multi_mesh_nodes.get(type_id)
		if mmi != null:
			var scaled_basis := Basis.IDENTITY.scaled(def.scale)
			var t := Transform3D(scaled_basis, render_pos)
			mmi.multimesh.set_instance_transform(enemy["id"], t)

		# Mark as mid-transition for the next frame
		enemy["is_mid_transition"] = true

	# Remove deactivated enemies from the active list
	for e in to_remove:
		_active_enemies.erase(e)


func _deactivate_enemy(enemy: Dictionary) -> void:
	enemy["active"] = false
	# Move the MultiMesh instance off-screen
	var mmi = _multi_mesh_nodes.get(enemy["type_id"])
	if mmi != null:
		var hide_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, -1000.0, 0.0))
		mmi.multimesh.set_instance_transform(enemy["id"], hide_transform)


func get_active_enemy_count() -> int:
	return _active_enemies.size()
