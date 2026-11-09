extends Node2D
## Final choices and story outcome. Tob remains silent; the child initiates care.
signal affection_changed(total: int)
signal phase_completed(affection: int)
signal next_phase_requested
enum State { INTRO, TRAVEL, EXPLORE, CHOICE, FEEDBACK, ENDING, COMPLETE }
@export var content: EMAPhaseFiveContent
@export var starting_affection := 0
@export var completion_button_text := "Jogar novamente"
@export var continue_on_complete := false
@onready var street: EMAEnvironment = %Street
@onready var house: EMAEnvironment = %House
@onready var player: EMAPlayer = %Player
@onready var ui: EMAPhaseUI = %PhaseUI
@onready var cutscene: EMACutscene = %Cutscene
@onready var transition: EMATransition = %Transition
@onready var alert: AudioStreamPlayer = %Alert
@onready var tob: EMAInteractable = street.get_node("%Tob")
@onready var indoor_tob: EMAInteractable = house.get_node("%Tob")
@onready var carried_tob: Node2D = %CarriedTob
@onready var bed: Node2D = street.get_node("%Bed")
var state := State.INTRO
var affection := 0
var has_bed := false
var carrying_tob := false
var welcomed := false
var adopted := false
var _leaving_alone := false
var _intro_transition := false
var _starting_ending := false
var _finishing_ending := false
var _choice_context: StringName
var _active_area: EMAEnvironment
var _pending_area: EMAEnvironment
var _ending_data: EMACutsceneData

func _ready() -> void:
	assert(content != null and content.intro_cutscene.is_valid() and content.temporary_ending.is_valid() and content.adoption_ending.is_valid())
	player.interaction_requested.connect(_interact)
	ui.advance_requested.connect(_advance)
	ui.choice_selected.connect(_choose)
	cutscene.finished.connect(_on_story_finished)
	transition.covered.connect(_on_covered)
	transition.finished.connect(_resume)
	ui.configure_phase("FASE 5", "Ajude Tob a ter uma família.", "Acolha Tob e converse com a mãe sobre adoção.")
	_restart()

func _restart() -> void:
	state = State.INTRO
	affection = 0
	has_bed = false
	carrying_tob = false
	welcomed = false
	adopted = false
	_leaving_alone = false
	_intro_transition = false
	_starting_ending = false
	_finishing_ending = false
	_active_area = null
	_ending_data = null
	_choice_context = &""
	tob.show()
	indoor_tob.hide()
	carried_tob.hide()
	bed.hide()
	house.set_item_available(&"bed", true)
	street.set_active(false)
	house.set_active(false)
	player.set_enabled(false)
	player.walk_bounds = street.walk_bounds
	player.position = Vector2(445, 430)
	player.hide()
	ui.hide_message()
	ui.hide()
	cutscene.process_mode = Node.PROCESS_MODE_INHERIT
	cutscene.play(content.intro_cutscene)

func _physics_process(_delta: float) -> void:
	if state == State.EXPLORE:
		var target := _active_area.target_at(player.global_position)
		player.set_prompt(target.title if target else "")

func _on_story_finished() -> void:
	if state == State.INTRO:
		_intro_transition = true
		_travel(street)
	elif state == State.ENDING and not transition.busy:
		_finishing_ending = true
		cutscene.process_mode = Node.PROCESS_MODE_DISABLED
		transition.play()

func _travel(area: EMAEnvironment) -> void:
	_pending_area = area
	state = State.TRAVEL
	player.set_enabled(false)
	ui.hide_message()
	transition.play()

func _activate_area(area: EMAEnvironment) -> void:
	street.set_active(area == street)
	house.set_active(area == house)
	_active_area = area
	player.walk_bounds = area.walk_bounds
	player.global_position = area.spawn.global_position

func _on_covered() -> void:
	if _starting_ending:
		_starting_ending = false
		street.set_active(false)
		house.set_active(false)
		player.hide()
		ui.hide()
		cutscene.play(_ending_data)
		cutscene.next_button.disabled = true
		return
	if _finishing_ending:
		_finishing_ending = false
		cutscene.dismiss()
		_activate_area(house if adopted else street)
		player.show()
		ui.show()
		_show_final_result()
		return
	_activate_area(_pending_area)
	if carrying_tob and _active_area == house:
		carrying_tob = false
		carried_tob.hide()
		welcomed = true
		indoor_tob.show()
	if _intro_transition:
		_intro_transition = false
		cutscene.dismiss()
		player.position = Vector2(445, 430)
		player.show()
		ui.show()
	_refresh_ui()

func _resume() -> void:
	if state == State.ENDING:
		cutscene.process_mode = Node.PROCESS_MODE_INHERIT
		cutscene.next_button.disabled = false
		return
	if state == State.COMPLETE:
		return
	if _leaving_alone and _active_area == house:
		_leaving_alone = false
		alert.play()
		_feedback("Tob ainda precisa de você", content.bad_choice, EMAPhaseUI.Feedback.ERROR)
		return
	state = State.EXPLORE
	ui.hide_message()
	player.set_enabled(true)
	_refresh_ui()

func _interact() -> void:
	if state != State.EXPLORE:
		return
	var target := _active_area.target_at(player.global_position)
	if target == null:
		return
	match target.action_id:
		&"door": _travel(house if _active_area == street else street)
		&"bed":
			has_bed = true
			target.set_available(false)
			_feedback("Você pegou a caminha", content.bed_picked)
		&"adult":
			if not welcomed:
				_feedback("Primeiro acolha Tob", "Aproxime-se dele na rua e traga-o para dentro de casa. Depois, converse com a mãe sobre adoção.")
			else:
				_choice_context = &"adult"
				state = State.CHOICE
				player.set_enabled(false)
				ui.show_choices("Uma família para Tob", "Mãe, deixa o Tob morar conosco", [{"id": &"adopt", "text": "Pedir adoção"}, {"id": &"cancel", "text": "Explorar"}])
		&"tob":
			if _active_area == house:
				_feedback("Tob está acolhido", "Agora fale com a mãe e peça que Tob faça parte da família.")
			else:
				_choice_context = &"tob"
				state = State.CHOICE
				player.set_enabled(false)
				ui.show_choices("Você se aproxima de Tob", "Tob está deitado, triste e não responde. O que você vai fazer?", [{"id": &"ignore", "text": "Carinho e ir embora"}, {"id": &"bed", "text": "Levar caminha"}, {"id": &"welcome", "text": "Acolher em casa"}])
	_refresh_ui()

func _choose(id: StringName) -> void:
	if state != State.CHOICE:
		return
	if _choice_context == &"adult":
		if id == &"adopt" and welcomed and _active_area == house:
			adopted = true
			_begin_ending(2, content.adoption_ending)
		else:
			_resume()
		return
	_leaving_alone = false
	match id:
		&"ignore":
			_leaving_alone = true
			_feedback("Você fez carinho em Tob", "Tob continua deitado e sozinho. Você decide voltar para dentro de casa.")
		&"bed":
			if not has_bed:
				_feedback("Busque a caminha", "Entre na casa e pegue a caminha com mantas. Depois, volte até Tob.")
			else:
				has_bed = false
				bed.show()
				_begin_ending(1, content.temporary_ending)
		&"welcome":
			carrying_tob = true
			tob.hide()
			carried_tob.show()
			_feedback("Você acolheu Tob", "Você fez carinho e recolheu Tob. Leve-o até a porta e entre em casa; depois, fale com a mãe sobre adoção.")
		_: _resume()
	_refresh_ui()

func _feedback(title: String, message: String, tone: EMAPhaseUI.Feedback = EMAPhaseUI.Feedback.NEUTRAL) -> void:
	state = State.FEEDBACK
	player.set_enabled(false)
	ui.show_message(title, message, "Continuar", tone)

func _begin_ending(points: int, story: EMACutsceneData) -> void:
	state = State.ENDING
	affection = points
	_ending_data = story
	_starting_ending = true
	player.set_enabled(false)
	ui.hide_message()
	cutscene.process_mode = Node.PROCESS_MODE_DISABLED
	transition.play()

func _show_final_result() -> void:
	if state == State.COMPLETE:
		return
	state = State.COMPLETE
	player.set_enabled(false)
	affection_changed.emit(starting_affection + affection)
	phase_completed.emit(affection)
	_refresh_ui()
	var message := content.adoption_result if adopted else content.temporary_result
	message += "\nAfeto nesta fase: %d / 2\nAfeto acumulado: %d / 10" % [affection, starting_affection + affection]
	ui.show_message("Fim de jogo — Tob tem uma família!" if adopted else "Fim de jogo — Um cuidado temporário", message, completion_button_text, EMAPhaseUI.Feedback.SUCCESS)

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
	var details := "FAMÍLIA\nCaminha: %s" % ("levando" if has_bed else "não")
	if adopted:
		details = "FAMÍLIA\nTob foi adotado!"
	elif welcomed:
		details += "\nConverse com a mãe."
	elif carrying_tob:
		details += "\nLeve Tob para casa."
	elif bed.visible:
		details = "FAMÍLIA\nCaminha com mantas no poste."
	ui.update_overview(_active_area.display_name, starting_affection + affection, details, 10 if starting_affection > 0 else 2)
