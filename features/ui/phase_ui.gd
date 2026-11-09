extends CanvasLayer
class_name EMAPhaseUI

signal advance_requested
signal choice_selected(id: StringName)
enum Feedback { NEUTRAL, SUCCESS, ERROR }
@onready var location: Label = %Location
@onready var hearts: Label = %Hearts
@onready var inventory: Label = %Inventory
@onready var modal: PanelContainer = %Modal
@onready var heading: Label = %Heading
@onready var body: Label = %Body
@onready var next_button: Button = %NextButton
@onready var choices: HBoxContainer = %Choices
@onready var choice_buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var phase_title: Label = %PhaseTitle
@onready var objective: Label = %Objective
@onready var hint: Label = %Hint
var _choice_ids: Array[StringName] = []

func _ready() -> void:
	next_button.pressed.connect(func() -> void: advance_requested.emit())
	for index in choice_buttons.size():
		choice_buttons[index].pressed.connect(_select_choice.bind(index))

func configure_phase(title: String, goal: String, instructions: String) -> void:
	phase_title.text = title
	objective.text = "Objetivo:\n" + goal
	hint.text = instructions

func update_overview(area_name: String, affection: int, details: String, capacity := 2) -> void:
	location.text = "Local: " + area_name
	hearts.add_theme_font_size_override("font_size", 17 if capacity > 8 else 20 if capacity > 6 else 26 if capacity > 4 else 32)
	hearts.text = "♥".repeat(clampi(affection, 0, capacity)) + "♡".repeat(maxi(0, capacity - affection))
	inventory.text = details

func update_status(area_name: String, affection: int, food: bool, water: bool) -> void:
	location.text = "Local: " + area_name
	hearts.text = ("♥" if affection >= 1 else "♡") + "   " + ("♥" if affection >= 2 else "♡")
	inventory.text = "LEVANDO\n" + ("Ração" if food else "Sem ração") + "\n" + ("Água fresca" if water else "Sem água")

func show_message(title: String, message: String, button_text := "Continuar", feedback: Feedback = Feedback.NEUTRAL) -> void:
	choices.hide()
	_choice_ids.clear()
	next_button.show()
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

func show_choices(title: String, message: String, options: Array[Dictionary]) -> void:
	assert(not options.is_empty() and options.size() <= choice_buttons.size())
	show_message(title, message)
	next_button.hide()
	choices.show()
	for index in choice_buttons.size():
		choice_buttons[index].visible = index < options.size()
		if index < options.size():
			_choice_ids.append(options[index]["id"])
			choice_buttons[index].text = options[index]["text"]
	choice_buttons[0].grab_focus()

func _select_choice(index: int) -> void:
	if not modal.visible or not choices.visible or index >= _choice_ids.size():
		return
	var id := _choice_ids[index]
	hide_message()
	choice_selected.emit(id)

func hide_message() -> void:
	modal.hide()
	choices.hide()
	_choice_ids.clear()
	modal.theme_type_variation = &""

func _unhandled_input(event: InputEvent) -> void:
	if modal.visible and not choices.visible and not event.is_echo() and (event.is_action_pressed(&"advance") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"restart")):
		advance_requested.emit()
		get_viewport().set_input_as_handled()
