extends Button

## SendWaveButton — triggers WaveController.send_wave().
## Visible ONLY in PLAYER_TRIGGERED mode (hidden by default).
## Spacebar shortcut also fires when visible.
##
## Call setup(wave_controller, wave_mode) from HUD.gd after assembly.

# Assigned by HUD.gd after assembly
var _wave_controller: Node = null


func _ready() -> void:
	pressed.connect(_on_pressed)
	visible = false  # Hidden by default; shown only in PLAYER_TRIGGERED mode


func setup(wave_controller: Node, wave_mode: GameState.WaveMode) -> void:
	_wave_controller = wave_controller
	visible = (wave_mode == GameState.WaveMode.PLAYER_TRIGGERED)


func _on_pressed() -> void:
	if _wave_controller != null:
		_wave_controller.send_wave()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_on_pressed()
			get_viewport().set_input_as_handled()
