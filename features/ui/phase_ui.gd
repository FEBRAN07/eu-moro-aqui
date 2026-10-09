extends CanvasLayer
class_name EMAPhaseUI

signal advance_requested
enum Feedback { NEUTRAL, SUCCESS, ERROR }
@onready var location: Label = %Location
@onready var hearts: Label = %Hearts
@onready var inventory: Label = %Inventory
@onready var modal: PanelContainer = %Modal
@onready var heading: Label = %Heading
@onready var body: Label = %Body
@onready var next_button: Button = %NextButton

func _ready() -> void:
	next_button.pressed.connect(func() -> void: advance_requested.emit())

func update_status(area_name: String, affection: int, food: bool, water: bool) -> void:
	location.text = "Local: " + area_name
	hearts.text = ("♥" if affection >= 1 else "♡") + "   " + ("♥" if affection >= 2 else "♡")
	inventory.text = "LEVANDO\n" + ("Ração" if food else "Sem ração") + "\n" + ("Água fresca" if water else "Sem água")

func show_message(title: String, message: String, button_text := "Continuar", feedback: Feedback = Feedback.NEUTRAL) -> void:
	# Theme variations affect only this message, never the shared HUD/cutscene.
	match feedback:
		Feedback.SUCCESS:
			modal.theme_type_variation = &"SuccessMessage"
		Feedback.ERROR:
			modal.theme_type_variation = &"ErrorMessage"
		_:
			modal.theme_type_variation = &""
	heading.text = title
	body.text = message
	next_button.text = button_text
	modal.show()

func hide_message() -> void:
	modal.hide()
	modal.theme_type_variation = &""

func _unhandled_input(event: InputEvent) -> void:
	if modal.visible and not event.is_echo() and (event.is_action_pressed(&"advance") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"restart")):
		advance_requested.emit()
		get_viewport().set_input_as_handled()
