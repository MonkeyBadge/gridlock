extends PanelContainer

## TopBar — top HUD bar showing lives, wave counter, gold, and timer.
## Connects to GameState.lives_changed on _ready.
## WaveController signals are wired by HUD.gd after assembly.

@onready var _lives_label: Label = $Bar/LivesLabel
@onready var _wave_label: Label = $Bar/WaveLabel
@onready var _gold_label: Label = $Bar/GoldLabel
@onready var _timer_label: Label = $Bar/TimerLabel


func _ready() -> void:
	GameState.lives_changed.connect(_on_lives_changed)
	# Initialise display from current GameState
	_lives_label.text = "Hearts %d" % GameState.player_hp
	_gold_label.text = "Gold: -"


func update_wave(current: int, total: int) -> void:
	_wave_label.text = "Wave %d / %d" % [current, total]


func update_timer(time_remaining: float, wave_mode: GameState.WaveMode) -> void:
	if wave_mode == GameState.WaveMode.TIMED:
		_timer_label.text = "Next: %ds" % int(ceil(time_remaining))
	else:
		if time_remaining > 0:
			_timer_label.text = "Ready (%ds)" % int(ceil(time_remaining))
		else:
			_timer_label.text = "READY"


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = "Hearts %d" % new_lives
