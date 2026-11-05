extends Node2D
## Session owner: retains affection across phases, without a global singleton.
@export var phases: Array[PackedScene] = []
@onready var transition: EMATransition = %CampaignTransition
var current_phase: Node
var phase_index := 0
var total_affection := 0
var _pending_index := 0
var _changing := false

func _ready() -> void:
	assert(not phases.is_empty())
	transition.covered.connect(_swap_phase)
	transition.finished.connect(_enable_phase)
	_load_phase()

func _load_phase() -> void:
	current_phase = phases[phase_index].instantiate()
	current_phase.continue_on_complete = true
	current_phase.completion_button_text = "Próxima fase" if phase_index < phases.size() - 1 else "Reiniciar jogo"
	if phase_index > 0:
		current_phase.starting_affection = total_affection
	current_phase.next_phase_requested.connect(_request_next)
	current_phase.phase_completed.connect(_record_reward)
	if _changing:
		current_phase.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(current_phase)

func _record_reward(points: int) -> void:
	# Assign the total, rather than accumulating signals that could be repeated.
	total_affection = points + (current_phase.starting_affection if phase_index > 0 else 0)

func _request_next() -> void:
	if _changing:
		return
	_changing = true
	_pending_index = (phase_index + 1) % phases.size()
	if _pending_index == 0:
		total_affection = 0
	current_phase.process_mode = Node.PROCESS_MODE_DISABLED
	transition.play()

func _swap_phase() -> void:
	remove_child(current_phase)
	current_phase.queue_free()
	phase_index = _pending_index
	_load_phase()

func _enable_phase() -> void:
	current_phase.process_mode = Node.PROCESS_MODE_INHERIT
	_changing = false
