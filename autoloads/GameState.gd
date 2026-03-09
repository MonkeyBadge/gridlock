extends Node

## GameState — autoload singleton for run-level state.
## Holds lives, current wave index, wave mode, and gold (stub).
## Referenced by WaveController, EnemyManager, and HUD.

enum WaveMode { TIMED, PLAYER_TRIGGERED }

var player_hp: int = 20
var current_wave_index: int = 0
var wave_mode: WaveMode = WaveMode.TIMED
var gold: int = 0  # Stub — always 0 in Phase 1; Phase 2 will populate.

signal lives_changed(new_lives: int)
signal wave_mode_changed(new_mode: WaveMode)
signal game_over


func deduct_life() -> void:
	player_hp -= 1
	lives_changed.emit(player_hp)
	if player_hp <= 0:
		game_over.emit()


func reset() -> void:
	player_hp = 20
	current_wave_index = 0
	wave_mode = WaveMode.TIMED
	gold = 0
