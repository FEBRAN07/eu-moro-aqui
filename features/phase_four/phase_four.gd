extends Node2D
## Care decisions are phase-owned; no child chooses a diagnosis or medication dose.
signal affection_changed(total: int)
signal phase_completed(affection: int)
signal next_phase_requested
enum State { INTRO, TRAVEL, EXPLORE, CHOICE, FEEDBACK, COMPLETE }
@export var content: EMAPhaseFourContent
@export var starting_affection := 0
@export var completion_button_text := "Jogar novamente"
@export var continue_on_complete := false
@onready var street: EMAEnvironment = %Street
@onready var house: EMAEnvironment = %House
@onready var clinic: EMAEnvironment = %Clinic
@onready var player: EMAPlayer = %Player
@onready var ui: EMAPhaseUI = %PhaseUI
@onready var cutscene: EMACutscene = %Cutscene
@onready var transition: EMATransition = %Transition
@onready var alert: AudioStreamPlayer = %Alert
@onready var howl: AudioStreamPlayer = %Howl
@onready var water_bowl: Sprite2D = street.get_node("%WaterBowl")
@onready var street_mother: EMAInteractable = street.get_node("%Mother")
var state := State.INTRO
var affection := 0
var has_water := false
var water_offered := false
var veterinary_guidance := false
var adult_accompanies := false
var _has_howled := false
var _choice_context: StringName
var _active_area: EMAEnvironment
var _pending_area: EMAEnvironment
var _intro_transition := false

func _ready() -> void:
	assert(content != null and content.intro_cutscene != null and content.intro_cutscene.is_valid())
	player.interaction_requested.connect(_interact)
	ui.advance_requested.connect(_advance)
	ui.choice_selected.connect(_choose)
	cutscene.finished.connect(_finish_intro)
	transition.covered.connect(_on_covered)
	transition.finished.connect(_resume)
	ui.configure_phase("FASE 4", "Cuide de Tob.", "Tob parece doente. Peça ajuda a um adulto e a um veterinário.")
	_restart()

func _restart() -> void:
	state = State.INTRO
	affection = 0
	has_water = false
	water_offered = false
	veterinary_guidance = false
	adult_accompanies = false
	_has_howled = false
	_intro_transition = false
	_active_area = null
	_choice_context = &""
	water_bowl.hide()
	street_mother.hide()
	house.set_item_available(&"water", true)
	howl.stop()
	alert.stop()
	for area in [street, house, clinic]:
		area.set_active(false)
	player.set_enabled(false)
	player.walk_bounds = street.walk_bounds
	player.position = Vector2(445, 430)
	player.hide()
	ui.hide_message()
	ui.hide()
	cutscene.play(content.intro_cutscene)

func _physics_process(_delta: float) -> void:
	if state == State.EXPLORE:
		var target := _active_area.target_at(player.global_position)
		player.set_prompt(target.title if target else "")

func _finish_intro() -> void:
	if state == State.INTRO:
		_intro_transition = true
		_travel(street)

func _travel(area: EMAEnvironment) -> void:
	_pending_area = area
	state = State.TRAVEL
	player.set_enabled(false)
	ui.hide_message()
	transition.play()

func _on_covered() -> void:
	for area in [street, house, clinic]:
		area.set_active(area == _pending_area)
	_active_area = _pending_area
	player.walk_bounds = _active_area.walk_bounds
	player.global_position = _active_area.spawn.global_position
	if _intro_transition:
		_intro_transition = false
		cutscene.dismiss()
		player.position = Vector2(445, 430)
		player.show()
		ui.show()
	_refresh_ui()

func _resume() -> void:
	state = State.EXPLORE
	ui.hide_message()
	player.set_enabled(true)
	if not _has_howled and _active_area == street:
		_has_howled = true
		howl.play()
	_refresh_ui()

func _interact() -> void:
	if state != State.EXPLORE:
		return
	var target := _active_area.target_at(player.global_position)
	if target == null:
		return
	match target.action_id:
		&"door": _travel(house if _active_area == street else street)
		&"exit_clinic": _travel(street)
		&"clinic":
			if adult_accompanies:
				_travel(clinic)
			else:
				_feedback("Chame um adulto", "Entre na casa e fale com a mãe para levar Tob ao veterinário com segurança.")
		&"water":
			has_water = true
			target.set_available(false)
			_feedback("Você pegou água limpa", content.water_picked)
		&"adult": _show_adult_choices()
		&"vet":
			if adult_accompanies:
				_complete(2, content.vet_result)
			else:
				_feedback("Precisamos de um responsável", "Chame um adulto para acompanhar a avaliação de Tob e as orientações do veterinário.")
		&"tob":
			if _active_area == clinic:
				_feedback("Tob aguarda avaliação", "Fale com o veterinário para que Tob seja examinado e receba os cuidados necessários.")
			else:
				_choice_context = &"tob"
				state = State.CHOICE
				player.set_enabled(false)
				ui.show_choices("Tob não está bem", "Você percebe que Tob precisa de cuidado. Como vai ajudá-lo?", [{"id": &"water", "text": "Água apenas"}, {"id": &"adult_care", "text": "Cuidado com adulto"}, {"id": &"vet", "text": "Buscar veterinário"}])
	_refresh_ui()

func _show_adult_choices() -> void:
	_choice_context = &"adult"
	state = State.CHOICE
	player.set_enabled(false)
	ui.show_choices("Vamos ajudar Tob", "Você chama a mãe: Temos que levar o Tob no médico.", [{"id": &"guidance", "text": "Pedir orientação"}, {"id": &"appointment", "text": "Ir ao veterinário"}, {"id": &"cancel", "text": "Explorar"}])

func _choose(id: StringName) -> void:
	if state != State.CHOICE:
		return
	if _choice_context == &"adult":
		match id:
			&"guidance":
				veterinary_guidance = true
				street_mother.show()
				_feedback("Orientação antes de medicar", content.guidance)
			&"appointment":
				adult_accompanies = true
				street_mother.show()
				_feedback("Vamos à clínica", content.referral)
			_: _resume()
	else:
		match id:
			&"water":
				if has_water or water_offered:
					has_water = false
					water_offered = true
					water_bowl.show()
					alert.play()
					_feedback("Só água não é suficiente", content.bad_choice, EMAPhaseUI.Feedback.ERROR)
				else:
					_feedback("Busque água limpa", "Você encontra água na casa. Depois, volte até Tob. Também é importante chamar um adulto.")
			&"adult_care":
				if veterinary_guidance:
					_complete(1, content.adult_result)
				else:
					_feedback("Não dê remédios por conta própria", "Chame a mãe na casa. Antes de qualquer medicamento, o adulto precisa de orientação veterinária.")
			&"vet":
				if adult_accompanies:
					_travel(clinic)
				else:
					_feedback("Precisamos de ajuda adulta", "Entre na casa e convide a mãe para levar Tob ao veterinário.")
			_: _resume()
	_refresh_ui()

func _feedback(title: String, message: String, tone: EMAPhaseUI.Feedback = EMAPhaseUI.Feedback.NEUTRAL) -> void:
	state = State.FEEDBACK
	player.set_enabled(false)
	ui.show_message(title, message, "Continuar", tone)

func _complete(points: int, message: String) -> void:
	if state == State.COMPLETE:
		return
	affection = points
	state = State.COMPLETE
	player.set_enabled(false)
	affection_changed.emit(starting_affection + affection)
	phase_completed.emit(affection)
	_refresh_ui()
	ui.show_message("Fase concluída! +%d coração%s" % [points, "s" if points == 2 else ""], message, completion_button_text, EMAPhaseUI.Feedback.SUCCESS)

func _advance() -> void:
	if state == State.FEEDBACK:
		_resume()
	elif state == State.COMPLETE:
		if continue_on_complete:
			next_phase_requested.emit()
		else:
			_restart()

func _refresh_ui() -> void:
	if _active_area == null:
		return
	var details := "CUIDADO\nÁgua: %s" % ("levando" if has_water else "oferecida" if water_offered else "não")
	if adult_accompanies:
		details += "\nAdulto vai à clínica."
	elif veterinary_guidance:
		details += "\nAdulto orientado."
	else:
		details += "\nChame um adulto."
	ui.update_overview(_active_area.display_name, starting_affection + affection, details, 8 if starting_affection > 0 else 2)
