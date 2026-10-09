extends Node
class_name EMAPlayerInput

signal interaction_requested
var enabled := true

func direction() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if enabled else Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if enabled and event.is_action_pressed(&"interact") and not event.is_echo():
		interaction_requested.emit()
		get_viewport().set_input_as_handled()
