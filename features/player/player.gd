extends CharacterBody2D
class_name EMAPlayer

signal interaction_requested
@export var speed := 280.0
@export var walk_bounds := Rect2(38, 125, 792, 485)
@onready var controls: EMAPlayerInput = %PlayerInput
@onready var prompt: Label = %Prompt

func _ready() -> void:
	controls.interaction_requested.connect(func() -> void: interaction_requested.emit())

func set_enabled(value: bool) -> void:
	controls.enabled = value
	if not value:
		velocity = Vector2.ZERO
		prompt.hide()

func set_prompt(text: String) -> void:
	prompt.text = "[E] " + text
	prompt.visible = not text.is_empty() and controls.enabled

func _physics_process(_delta: float) -> void:
	velocity = controls.direction() * speed
	move_and_slide()
	position = position.clamp(walk_bounds.position, walk_bounds.end)
