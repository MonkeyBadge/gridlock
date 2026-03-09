extends Node

## WaveController — drives the wave lifecycle.
## Not an autoload — lives in the game scene (scenes/game/WaveController.tscn).
##
## Supports two wave modes (ADR-07):
##   TIMED:            inter_wave_timer counts down and auto-launches the wave at 0.
##   PLAYER_TRIGGERED: timer still counts down for HUD display, but wave only launches
##                     when send_wave() is called (Spacebar or UI button).

@export var wave_definitions: Array[WaveDefinition] = []

var current_wave_index: int = 0
var is_wave_active: bool = false
var inter_wave_timer: float = 0.0
var send_wave_pressed: bool = false

var _active_spawn_count: int = 0
var _spawns_dispatched: int = 0
var _spawns_completed: int = 0

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal inter_wave_tick(time_remaining: float)
signal all_waves_complete


func _ready() -> void:
	EnemyManager.enemy_reached_exit.connect(_on_enemy_reached_exit)
	_begin_inter_wave_phase()


func _begin_inter_wave_phase() -> void:
	if current_wave_index >= wave_definitions.size():
		all_waves_complete.emit()
		return

	var wave_def: WaveDefinition = wave_definitions[current_wave_index]
	inter_wave_timer = wave_def.inter_wave_delay
	send_wave_pressed = false
	is_wave_active = false


func _process(delta: float) -> void:
	if is_wave_active:
		return

	inter_wave_timer = max(0.0, inter_wave_timer - delta)
	inter_wave_tick.emit(inter_wave_timer)

	match GameState.wave_mode:
		GameState.WaveMode.TIMED:
			if inter_wave_timer <= 0.0:
				_launch_wave()
		GameState.WaveMode.PLAYER_TRIGGERED:
			if send_wave_pressed:
				_launch_wave()


func send_wave() -> void:
	send_wave_pressed = true
	# TODO: Phase 2 — award bonus gold if inter_wave_timer > threshold.


func _launch_wave() -> void:
	if current_wave_index >= wave_definitions.size():
		return

	is_wave_active = true
	var wave_def: WaveDefinition = wave_definitions[current_wave_index]

	_active_spawn_count = wave_def.get_total_enemy_count()
	_spawns_dispatched = 0
	_spawns_completed = 0

	GameState.current_wave_index = current_wave_index
	EnemyManager.prepare_wave(wave_def)
	wave_started.emit(wave_def.wave_number)

	for group in wave_def.groups:
		_schedule_spawn_group(group)


func _schedule_spawn_group(group: SpawnGroupResource) -> void:
	await get_tree().create_timer(group.delay_from_wave_start).timeout

	for i in range(group.count):
		var spawn_pos: Vector2i = GridManager.spawn_positions[0]  # Phase 1: single spawn point
		EnemyManager.spawn_enemy(group.enemy_id, spawn_pos)
		_spawns_dispatched += 1

		if i < group.count - 1:
			await get_tree().create_timer(group.spawn_interval).timeout

	_check_wave_completion()


func _on_enemy_reached_exit(_enemy_record: Dictionary) -> void:
	_spawns_completed += 1
	_check_wave_completion()


func _check_wave_completion() -> void:
	# Wave ends when all spawn coroutines are done dispatching AND
	# all dispatched enemies have reached the exit.
	if not is_wave_active:
		return

	var total: int = wave_definitions[current_wave_index].get_total_enemy_count()
	if _spawns_dispatched >= total and _spawns_completed >= total:
		_end_wave()


func _end_wave() -> void:
	is_wave_active = false
	var wave_number: int = wave_definitions[current_wave_index].wave_number
	current_wave_index += 1
	wave_completed.emit(wave_number)
	_begin_inter_wave_phase()
