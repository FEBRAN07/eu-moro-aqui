@tool
extends Node2D
class_name EMAInteractable

@export var action_id: StringName = &"food"
@export var title := "Pote de ração":
	set(value):
		title = value
		if is_node_ready():
			%Title.text = value
@export var radius := 68.0
var available := true

func _ready() -> void:
	%Title.text = title

func set_available(value: bool) -> void:
	available = value
	modulate = Color.WHITE if value else Color(0.6, 0.6, 0.6)
	%Indicator.visible = value

func is_near(point: Vector2) -> bool:
	return available and global_position.distance_to(point) < radius
