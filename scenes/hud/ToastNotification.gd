extends CanvasLayer

@export var display_duration: float = 2.0


func show_message(message: String = "") -> void:
	if message != "":
		$Panel/Message.text = message
	visible = true
	var tween = create_tween()
	tween.tween_interval(display_duration)
	tween.tween_callback(func(): visible = false)
