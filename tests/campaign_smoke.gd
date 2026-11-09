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
	_check(second.ui.next_button.text == "Próxima fase", "Second phase must now offer progression to the shelter phase.")
	second.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 2 and game.total_affection == 3, "Progression to phase three must preserve previous affection.")
	var third: Node = game.current_phase
	_check(third.starting_affection == 3 and third.cutscene.playing, "Third phase must begin with its own cutscene and accumulated affection.")
	await _intro(third)
	_interact(third, Vector2(720, 440))
	third.ui.choice_buttons[2].pressed.emit()
	third.ui.advance_requested.emit()
	_interact(third, Vector2(317, 385))
	await third.transition.finished
	_check(third.affection == 2 and game.total_affection == 5, "Third-phase reward must add to the campaign total exactly once.")
	_check(third.ui.next_button.text == "Próxima fase", "Third phase must offer progression to the care phase.")
	third.ui.advance_requested.emit()
	third.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 3 and game.total_affection == 5, "Fourth phase must preserve affection from the first three phases.")
	var fourth: Node = game.current_phase
	_check(fourth.starting_affection == 5 and fourth.cutscene.playing, "Care phase must start with its own cutscene.")
	await _intro(fourth)
	_interact(fourth, Vector2(317, 385))
	await fourth.transition.finished
	_interact(fourth, Vector2(570, 400))
	fourth.ui.choice_buttons[1].pressed.emit()
	fourth.ui.advance_requested.emit()
	_interact(fourth, Vector2(415, 500))
	await fourth.transition.finished
	_interact(fourth, Vector2(560, 570))
	await fourth.transition.finished
	_interact(fourth, Vector2(620, 290))
	_check(fourth.affection == 2 and game.total_affection == 7, "Veterinary care must add its reward to the campaign total once.")
	_check(fourth.ui.next_button.text == "Próxima fase", "Care phase must lead to the final phase.")
	fourth.ui.advance_requested.emit()
	fourth.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 4 and game.total_affection == 7, "Final phase must preserve prior affection.")
	var fifth: Node = game.current_phase
	_check(fifth.starting_affection == 7 and fifth.cutscene.playing, "Final phase must start with its silent intro.")
	await _intro(fifth)
	_interact(fifth, Vector2(720, 440))
	fifth.ui.choice_buttons[2].pressed.emit()
	fifth.ui.advance_requested.emit()
	_interact(fifth, Vector2(317, 385))
	await fifth.transition.finished
	_interact(fifth, Vector2(570, 400))
	fifth.ui.choice_buttons[0].pressed.emit()
	_check(game.total_affection == 7, "Final reward must wait for the ending narrative.")
	await fifth.transition.finished
	for entry in fifth.content.adoption_ending.lines:
		fifth.cutscene.advance()
	await fifth.transition.finished
	_check(fifth.affection == 2 and game.total_affection == 9, "Adoption must add the final reward once.")
	_check(fifth.ui.next_button.text == "Reiniciar jogo", "Final result must offer a full campaign restart.")
	fifth.ui.advance_requested.emit()
	fifth.ui.advance_requested.emit()
	await game.transition.finished
	_check(game.phase_index == 0 and game.total_affection == 0 and game.current_phase.cutscene.playing, "Restart must reset campaign affection and return to the first intro.")
	game.queue_free()
	await process_frame
	if not _failed:
		print("PASS: progression through five phases, ending, duplicate-input guard, cumulative affection and complete campaign restart.")
	quit(1 if _failed else 0)
