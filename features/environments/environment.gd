extends Node2D
class_name EMAEnvironment

@export var display_name := "Rua"
@export var walk_bounds := Rect2(38, 125, 792, 485)
@onready var spawn: Marker2D = %Spawn
@onready var interactions: Node2D = %Interactions

func set_active(value: bool) -> void:
	visible = value
	# Hidden scenery must also leave the physics world. StaticBody2D uses
	# DISABLE_MODE_REMOVE by default when its inherited process mode is disabled.
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED

func target_at(point: Vector2) -> EMAInteractable:
	# Scene children are the source of truth for positions and interaction ids.
	for child in interactions.get_children():
		var target := child as EMAInteractable
		if target and target.is_near(point):
			return target
	return null

func set_item_available(id: StringName, value: bool) -> void:
	for child in interactions.get_children():
		var item := child as EMAInteractable
		if item and item.action_id == id:
			item.set_available(value)
