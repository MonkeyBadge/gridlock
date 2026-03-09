extends PanelContainer

## BottomPanel — tower selection HUD panel.
## Phase 1: single Wall Tower button.
## Emits tower_selected(tower_type_id: String) when a tower type is chosen.
## Keyboard hotkey [1] also fires the signal.

signal tower_selected(tower_type_id: String)

@onready var _wall_btn: Button = $TowerButtons/WallTowerButton


func _ready() -> void:
	_wall_btn.pressed.connect(func(): tower_selected.emit("wall"))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			tower_selected.emit("wall")
