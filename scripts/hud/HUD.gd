extends CanvasLayer

## HUD — root CanvasLayer that assembles all HUD sub-scenes.
## Call setup(wave_controller, total_waves) from Game.tscn after
## WaveController is available to wire all signal connections.

@onready var top_bar: PanelContainer = $TopBar
@onready var send_wave_btn: Button = $SendWaveButton
@onready var toast: Node = $ToastNotification


## Called by Game.tscn after WaveController is ready.
## Wires wave_started and inter_wave_tick signals to TopBar and SendWaveButton.
func setup(wave_controller: Node, total_waves: int) -> void:
	send_wave_btn.setup(wave_controller, GameState.wave_mode)
	top_bar.update_wave(1, total_waves)
	wave_controller.wave_started.connect(func(wn: int): top_bar.update_wave(wn, total_waves))
	wave_controller.inter_wave_tick.connect(
		func(t: float): top_bar.update_timer(t, GameState.wave_mode))


## Show the "path blocked" toast — called by TowerPlacer on invalid placement.
func show_path_blocked_toast() -> void:
	toast.show_message()
