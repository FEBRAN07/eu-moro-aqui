extends Node
class_name EMAFollowComponent
## Optional presentation/motion component; it does not own phase progress.
@export var actor: Node2D
@export var target: Node2D
@export var speed := 250.0
@export var stop_distance := 42.0
var following := false

func _physics_process(delta: float) -> void:
	if following and is_instance_valid(actor) and is_instance_valid(target):
		var distance := actor.global_position.distance_to(target.global_position)
		if distance > stop_distance:
			actor.global_position = actor.global_position.move_toward(target.global_position, minf(speed * delta, distance - stop_distance))
