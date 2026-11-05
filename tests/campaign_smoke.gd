extends SceneTree
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _intro(phase: Node) -> void:
	for entry in phase.content.intro_cutscene.lines:
		phase.cutscene.advance()
	await phase.transition.finished

func _interact(phase: Node, point: Vector2) -> void:
	phase.player.position = point
	phase.player.interaction_requested.emit()

func _run() -> void:
	var game: Node = (load("res://features/campaign/campaign.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var first: Node = game.current_phase
	await _intro(first)
	_interact(first, Vector2(317, 385))
	await first.transition.finished
	_interact(first, Vector2(318, 244))
	first.ui.advance_requested.emit()
	_interact(first, Vector2(452, 244))
	first.ui.advance_requested.emit()
	_interact(first, Vector2(415, 500))
	await first.transition.finished
	_interact(first, Vector2(720, 440))
	_check(first.affection == 2 and first.ui.next_button.text == "Próxima fase", "Campaign must offer progression after phase one.")
	first.ui.advance_requested.emit()
	first.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 1 and game.total_affection == 2, "Phase progression must preserve affection without double counting repeated input.")
	var second: Node = game.current_phase
	_check(second.starting_affection == 2 and second.cutscene.playing, "Phase two must start with its own cutscene and prior affection.")
	await _intro(second)
	_interact(second, Vector2(317, 385))
	await second.transition.finished
	_interact(second, Vector2(360, 320))
	await create_timer(1.0).timeout
	_check(second.affection == 1 and second.ui.hearts.text.count("♥") == 3, "HUD must combine prior affection with phase-two rewards.")
	_check(game.total_affection == 3, "Campaign must own the complete cumulative affection after both rewards.")
	_check(second.ui.next_button.text == "Reiniciar jogo", "Last implemented phase must offer a full campaign restart.")
	second.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 0 and game.total_affection == 0 and game.current_phase.cutscene.playing, "Restart must reset campaign affection and return to the first intro.")
	game.queue_free()
	await process_frame
	if not _failed:
		print("PASS: phase-one to phase-two progression, duplicate-input guard, cumulative affection and complete campaign restart.")
	quit(1 if _failed else 0)
