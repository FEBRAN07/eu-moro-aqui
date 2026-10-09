extends Node2D
## Owns phase progress. Scenes own movement, visuals, input and transitions.
signal affection_changed(total: int)
signal phase_completed(affection: int)

enum State { INTRO, STARTING_GAMEPLAY, EXPLORE, FEEDBACK, COMPLETE }
@export var content: EMAPhaseContent
@onready var street: EMAEnvironment = %Street
@onready var house: EMAEnvironment = %House
@onready var player: EMAPlayer = %Player
@onready var ui: EMAPhaseUI = %PhaseUI
@onready var transition: EMATransition = %Transition
@onready var cutscene: EMACutscene = %Cutscene
var state: State = State.INTRO
var has_food := false
var has_water := false
var affection := 0
var _active_area: EMAEnvironment

func _ready() -> void:
	assert(content != null and content.intro_cutscene != null and content.intro_cutscene.is_valid(), "Assign phase content and its intro cutscene in Inspector.")
	player.interaction_requested.connect(_interact)
	ui.advance_requested.connect(_advance)
	cutscene.finished.connect(_finish_intro)
	transition.covered.connect(_on_transition_covered)
	transition.finished.connect(_resume_exploration)
	_restart()

func _physics_process(_delta: float) -> void:
	if state == State.EXPLORE and not transition.busy:
		var target := _active_area.target_at(player.global_position)
		player.set_prompt(target.title if target else "")

func _restart() -> void:
	has_food = false
	has_water = false
	affection = 0
	state = State.INTRO
	_set_area(street)
	player.position = Vector2(445, 430)
	house.set_item_available(&"food", true)
	house.set_item_available(&"water", true)
	player.set_enabled(false)
	player.hide()
	ui.hide_message()
	ui.hide()
	street.set_active(false)
	house.set_active(false)
	_refresh_ui()
	cutscene.play(content.intro_cutscene)

func _finish_intro() -> void:
	if state != State.INTRO:
		return
	state = State.STARTING_GAMEPLAY
	transition.play()

func _on_transition_covered() -> void:
	if state == State.STARTING_GAMEPLAY:
		cutscene.dismiss()
		_set_area(street)
		player.position = Vector2(445, 430)
		player.show()
		ui.show()
	else:
		_swap_area()

func _advance() -> void:
	match state:
		State.FEEDBACK:
			_resume_exploration()
		State.COMPLETE:
			_restart()

func _interact() -> void:
	if state != State.EXPLORE or transition.busy:
		return
	var target := _active_area.target_at(player.global_position)
	if not target:
		return
	match target.action_id:
		&"door":
			player.set_enabled(false)
			transition.play()
		&"leftovers":
			_feedback("Essa escolha pode machucar o Tob", content.bad_choice, EMAPhaseUI.Feedback.ERROR)
		&"food":
			has_food = true
			target.set_available(false)
			_feedback("Você pegou ração adequada", content.food_choice, EMAPhaseUI.Feedback.SUCCESS)
		&"water":
			has_water = true
			target.set_available(false)
			_feedback("Você preparou água fresca", content.water_choice, EMAPhaseUI.Feedback.SUCCESS)
		&"tob":
			if has_food:
				_complete()
			else:
				_feedback("Tob está com fome", "Entre na casa e procure ração na cozinha para alimentar Tob.", EMAPhaseUI.Feedback.ERROR)
	_refresh_ui()

func _feedback(title: String, message: String, feedback: EMAPhaseUI.Feedback = EMAPhaseUI.Feedback.NEUTRAL) -> void:
	state = State.FEEDBACK
	player.set_enabled(false)
	ui.show_message(title, message, "Continuar", feedback)

func _complete() -> void:
	affection = 2 if has_water else 1
	state = State.COMPLETE
	player.set_enabled(false)
	affection_changed.emit(affection)
	phase_completed.emit(affection)
	ui.show_message("Fase concluída! +%d coração%s" % [affection, "s" if affection == 2 else ""], content.best_result if has_water else content.good_result, "Jogar novamente", EMAPhaseUI.Feedback.SUCCESS)

func _set_area(area: EMAEnvironment) -> void:
	_active_area = area
	street.set_active(area == street)
	house.set_active(area == house)
	player.walk_bounds = area.walk_bounds
	player.global_position = area.spawn.global_position
	_refresh_ui()

func _swap_area() -> void:
	_set_area(house if _active_area == street else street)

func _resume_exploration() -> void:
	state = State.EXPLORE
	ui.hide_message()
	player.set_enabled(true)

func _refresh_ui() -> void:
	ui.update_status(_active_area.display_name, affection, has_food, has_water)
