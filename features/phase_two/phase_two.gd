extends Node2D
## Owns phase-two choices and progress. Shared scenes own UI, movement and fade.
signal affection_changed(total: int)
signal phase_completed(affection: int)
signal next_phase_requested
enum State { INTRO, TRAVEL, EXPLORE, CHOICE, FEEDBACK, PLAYING, THROWING, COMPLETE }
@export var content: EMAPhaseTwoContent
@export var starting_affection := 0
@export var completion_button_text := "Jogar novamente"
@export var continue_on_complete := false
@onready var street: EMAEnvironment = %Street
@onready var house: EMAEnvironment = %House
@onready var plaza: EMAEnvironment = %Plaza
@onready var player: EMAPlayer = %Player
@onready var ui: EMAPhaseUI = %PhaseUI
@onready var cutscene: EMACutscene = %Cutscene
@onready var transition: EMATransition = %Transition
@onready var alert: AudioStreamPlayer = %Alert
@onready var route: Node2D = plaza.get_node("%Route")
@onready var companion: EMAInteractable = plaza.get_node("%Tob")
@onready var follow: EMAFollowComponent = plaza.get_node("%Follow")
@onready var stick: Line2D = house.get_node("%Stick")
var state := State.INTRO
var affection := 0
var route_index := 0
var _playing_together := false
var _active_area: EMAEnvironment
var _pending_area: EMAEnvironment
var _intro_transition := false
var _throw_tween: Tween

func _ready() -> void:
	assert(content != null and content.intro_cutscene.is_valid())
	player.interaction_requested.connect(_interact)
	ui.advance_requested.connect(_advance)
	ui.choice_selected.connect(_choose)
	cutscene.finished.connect(_finish_intro)
	transition.covered.connect(_on_covered)
	transition.finished.connect(_resume)
	follow.target = player
	ui.configure_phase("FASE 2", "Brinque com Tob.", "Fale com Tob, procure a janela na casa ou vá à praça.")
	_restart()

func _restart() -> void:
	affection = 0
	route_index = 0
	_playing_together = false
	state = State.INTRO
	follow.following = false
	stick.hide()
	for point in route.get_children():
		point.modulate = Color.WHITE
	for area in [street, house, plaza]:
		area.set_active(false)
	player.set_enabled(false)
	player.walk_bounds = street.walk_bounds
	player.position = Vector2(445, 430)
	player.hide()
	ui.hide_message()
	ui.hide()
	cutscene.play(content.intro_cutscene)

func _physics_process(_delta: float) -> void:
	if state != State.EXPLORE and state != State.PLAYING:
		return
	var target := _active_area.target_at(player.global_position)
	player.set_prompt(target.title if target else "")
	if state == State.PLAYING and route_index < route.get_child_count():
		var point := route.get_child(route_index) as Marker2D
		if player.global_position.distance_to(point.global_position) < 38 and companion.global_position.distance_to(player.global_position) < 100:
			point.modulate = Color(0.45, 0.8, 0.5)
			route_index += 1
			_refresh_ui()

func _finish_intro() -> void:
	if state != State.INTRO:
		return
	_intro_transition = true
	_travel(street)

func _travel(area: EMAEnvironment) -> void:
	_pending_area = area
	state = State.TRAVEL
	player.set_enabled(false)
	follow.following = false
	ui.hide_message()
	transition.play()

func _on_covered() -> void:
	for area in [street, house, plaza]:
		area.set_active(area == _pending_area)
	_active_area = _pending_area
	player.walk_bounds = _active_area.walk_bounds
	player.global_position = _active_area.spawn.global_position
	if _active_area == plaza:
		companion.position = Vector2(250, 470)
	if _intro_transition:
		_intro_transition = false
		cutscene.dismiss()
		player.position = Vector2(445, 430)
		player.show()
		ui.show()
	_refresh_ui()

func _resume() -> void:
	state = State.PLAYING if _playing_together and _active_area == plaza else State.EXPLORE
	follow.following = state == State.PLAYING
	ui.hide_message()
	player.set_enabled(true)
	_refresh_ui()

func _interact() -> void:
	if state != State.EXPLORE and state != State.PLAYING:
		return
	var target := _active_area.target_at(player.global_position)
	if target == null:
		return
	match target.action_id:
		&"door": _travel(house if _active_area == street else street)
		&"plaza": _travel(plaza)
		&"exit_plaza": _travel(street)
		&"stick": _throw_stick()
		&"tob":
			if _playing_together and _active_area == plaza:
				if route_index == route.get_child_count():
					_complete(2, content.together_result)
				else:
					_feedback("Vamos brincar mais um pouco!", "Passe pelos três pontos da praça com Tob. Depois, aproxime-se dele e faça carinho.")
			else:
				state = State.CHOICE
				player.set_enabled(false)
				ui.show_choices("Tob quer brincar", "Você pode brincar junto na praça ou entrar em casa e jogar um graveto pela janela.", [{"id": &"stomp", "text": "Bater o pé"}, {"id": &"play", "text": "Correr e fazer carinho"}, {"id": &"cancel", "text": "Explorar"}])

func _choose(id: StringName) -> void:
	if state != State.CHOICE:
		return
	match id:
		&"stomp":
			alert.play()
			_feedback("Isso assusta o Tob", content.bad_choice, EMAPhaseUI.Feedback.ERROR)
		&"play":
			_playing_together = true
			_travel(plaza)
		_:
			_resume()

func _feedback(title: String, message: String, tone: EMAPhaseUI.Feedback = EMAPhaseUI.Feedback.NEUTRAL) -> void:
	state = State.FEEDBACK
	player.set_enabled(false)
	follow.following = false
	ui.show_message(title, message, "Continuar", tone)

func _throw_stick() -> void:
	state = State.THROWING
	player.set_enabled(false)
	stick.position = Vector2(360, 260)
	stick.modulate.a = 1.0
	stick.show()
	_throw_tween = create_tween()
	_throw_tween.tween_property(stick, "position", Vector2(500, 200), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_throw_tween.tween_property(stick, "modulate:a", 0.0, 0.2)
	_throw_tween.tween_callback(func() -> void:
		stick.hide()
		_complete(1, content.stick_result))

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
	var details := "BRINCADEIRA\nProcure Tob ou a janela da casa."
	if _playing_together:
		details = "BRINCADEIRA\nPercurso: %d / %d\n" % [route_index, route.get_child_count()]
		details += "Agora faça carinho em Tob!" if route_index == route.get_child_count() else "Visite os pontos em ordem com Tob."
	ui.update_overview(_active_area.display_name, starting_affection + affection, details, 4 if starting_affection > 0 else 2)
