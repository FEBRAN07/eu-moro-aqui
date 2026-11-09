extends Node2D
## Phase-specific shelter choices; presentation and movement remain shared scenes.
signal affection_changed(total: int)
signal phase_completed(affection: int)
signal next_phase_requested
enum State { INTRO, TRAVEL, EXPLORE, CHOICE, FEEDBACK, COMPLETE }
@export var content: EMAPhaseThreeContent
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
@onready var follow: EMAFollowComponent = street.get_node("%Follow")
@onready var cloth: Polygon2D = street.get_node("%PlacedCloth")
@onready var doghouse: Node2D = street.get_node("%Doghouse")
var state := State.INTRO
var affection := 0
var has_cloth := false
var has_kennel := false
var cloth_placed := false
var escorting := false
var _active_area: EMAEnvironment
var _pending_area: EMAEnvironment
var _intro_transition := false
var _bringing_inside := false

func _ready() -> void:
	assert(content != null and content.intro_cutscene != null and content.intro_cutscene.is_valid())
	player.interaction_requested.connect(_interact)
	ui.advance_requested.connect(_advance)
	ui.choice_selected.connect(_choose)
	cutscene.finished.connect(_finish_intro)
	transition.covered.connect(_on_covered)
	transition.finished.connect(_resume)
	follow.target = player
	ui.configure_phase("FASE 3", "Ajude Tob a se abrigar da tempestade.", "Fale com Tob ou busque materiais na casa.")
	_restart()

func _restart() -> void:
	state = State.INTRO
	affection = 0
	has_cloth = false
	has_kennel = false
	cloth_placed = false
	escorting = false
	_bringing_inside = false
	_intro_transition = false
	follow.following = false
	cloth.hide()
	doghouse.hide()
	tob.show()
	tob.position = Vector2(720, 440)
	indoor_tob.hide()
	house.set_item_available(&"cloth", true)
	house.set_item_available(&"kennel", true)
	street.set_active(false)
	house.set_active(false)
	_active_area = null
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
	_bringing_inside = escorting and _active_area == street and area == house
	_pending_area = area
	state = State.TRAVEL
	player.set_enabled(false)
	follow.following = false
	ui.hide_message()
	transition.play()

func _on_covered() -> void:
	street.set_active(_pending_area == street)
	house.set_active(_pending_area == house)
	_active_area = _pending_area
	player.walk_bounds = _active_area.walk_bounds
	player.global_position = _active_area.spawn.global_position
	if _bringing_inside:
		tob.hide()
		indoor_tob.show()
	if _intro_transition:
		_intro_transition = false
		cutscene.dismiss()
		player.position = Vector2(445, 430)
		player.show()
		ui.show()
	_refresh_ui()

func _resume() -> void:
	if _bringing_inside:
		_bringing_inside = false
		escorting = false
		_complete(2, content.indoor_result)
		return
	state = State.EXPLORE
	ui.hide_message()
	player.set_enabled(true)
	follow.following = escorting and _active_area == street
	_refresh_ui()

func _interact() -> void:
	if state != State.EXPLORE:
		return
	var target := _active_area.target_at(player.global_position)
	if target == null:
		return
	match target.action_id:
		&"door": _travel(house if _active_area == street else street)
		&"cloth":
			has_cloth = true
			target.set_available(false)
			_feedback("Você pegou o pano", content.cloth_picked)
		&"kennel":
			has_kennel = true
			target.set_available(false)
			_feedback("Você pegou a casinha", content.kennel_picked)
		&"tob":
			if escorting:
				_feedback("Tob está seguindo você", "Leve Tob até a porta e entre em casa para protegê-lo da tempestade.")
			else:
				state = State.CHOICE
				player.set_enabled(false)
				ui.show_choices("Tob precisa de abrigo", "Você pode buscar materiais dentro de casa ou levar Tob para um lugar protegido.", [{"id": &"cloth", "text": "Pano ao relento"}, {"id": &"kennel", "text": "Montar casinha"}, {"id": &"indoors", "text": "Levar para casa"}])
	_refresh_ui()

func _choose(id: StringName) -> void:
	if state != State.CHOICE:
		return
	match id:
		&"cloth":
			if not has_cloth and not cloth_placed:
				_feedback("Busque um pano", "Entre na casa e pegue o pano. Depois, volte até Tob.")
			else:
				has_cloth = false
				cloth_placed = true
				cloth.show()
				alert.play()
				_feedback("O pano não é um abrigo", content.bad_choice, EMAPhaseUI.Feedback.ERROR)
		&"kennel":
			if not has_kennel:
				_feedback("Busque a casinha de madeira", "Entre na casa e pegue a casinha. Depois, volte até Tob para montá-la perto do poste.")
			else:
				has_kennel = false
				cloth.hide()
				cloth_placed = false
				doghouse.show()
				tob.hide()
				_complete(1, content.kennel_result)
		&"indoors":
			escorting = true
			_feedback("Vamos entrar em casa, Tob!", "Tob vai acompanhar você. Vá até a porta e entre em casa para abrigá-lo da chuva e do vento.")
		_:
			_resume()
	_refresh_ui()

func _feedback(title: String, message: String, tone: EMAPhaseUI.Feedback = EMAPhaseUI.Feedback.NEUTRAL) -> void:
	state = State.FEEDBACK
	player.set_enabled(false)
	follow.following = false
	ui.show_message(title, message, "Continuar", tone)

func _complete(points: int, message: String) -> void:
	if state == State.COMPLETE:
		return
	affection = points
	state = State.COMPLETE
	player.set_enabled(false)
	follow.following = false
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
	var details := "ABRIGO\nPano: %s\nCasinha: %s" % ["levando" if has_cloth else "no poste" if cloth_placed else "não", "levando" if has_kennel else "não"]
	if escorting:
		details = "ABRIGO\nTob segue você.\nEntre pela porta da casa."
	elif indoor_tob.visible:
		details = "ABRIGO\nTob está dentro de casa."
	elif doghouse.visible:
		details = "ABRIGO\nCasinha montada junto ao poste."
	ui.update_overview(_active_area.display_name, starting_affection + affection, details, 6 if starting_affection > 0 else 2)
