extends SceneTree
var _failed := false
var _rewards := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _interact(phase: Node, point: Vector2) -> void:
	phase.player.position = point
	phase.player.interaction_requested.emit()

func _intro(phase: Node) -> void:
	_check(phase.state == phase.State.INTRO and not phase.player.visible and not phase.ui.visible, "Final phase must start with an isolated cutscene.")
	_check(phase.cutscene.dialogue.text == "..." and phase.content.intro_cutscene.lines.size() == 1, "Tob's only introduction line must be the GDD silence.")
	phase.cutscene.advance()
	await phase.transition.finished
	_check(phase.state == phase.State.EXPLORE and phase.street.visible and phase.ui.phase_title.text == "FASE 5", "Silent intro must fade into the final gameplay.")
	var visual: AnimatedSprite2D = phase.tob.get_node("Visual")
	_check(visual.animation == &"rest" and visual.sprite_frames.get_frame_count(&"rest") == 1, "Tob must stay lying down without initiating conversation or following.")

func _choice(phase: Node, index: int) -> void:
	_interact(phase, Vector2(720, 440))
	_check(phase.state == phase.State.CHOICE and not phase.player.controls.enabled, "Child-initiated decisions must block movement.")
	_check(phase.ui.body.text.contains("não responde"), "Tob must remain silent while the child chooses an action.")
	phase.ui.advance_requested.emit()
	_check(phase.state == phase.State.CHOICE, "Generic advance cannot bypass final choices.")
	phase.ui.choice_buttons[index].pressed.emit()

func _finish_ending(phase: Node, points: int, previous_rewards: int) -> void:
	_check(phase.state == phase.State.ENDING and not phase.player.controls.enabled and _rewards == previous_rewards, "Ending must lock input and defer reward until its presentation is complete.")
	await phase.transition.finished
	_check(phase.cutscene.playing and not phase.player.visible and not phase.ui.visible, "Ending artwork must replace gameplay under the fade.")
	var story: EMACutsceneData = phase.content.adoption_ending if points == 2 else phase.content.temporary_ending
	for line: EMACutsceneLine in story.lines:
		_check(phase.cutscene.dialogue.text == line.text, "Ending must present the matching result story.")
		phase.cutscene.advance()
	_check(phase.transition.busy, "Ending completion must fade into the final summary.")
	await phase.transition.finished
	_check(phase.state == phase.State.COMPLETE and phase.affection == points and _rewards == previous_rewards + 1, "Final phase must award the selected result only once.")
	_check(phase.ui.heading.text.begins_with("Fim de jogo") and phase.ui.body.text.contains("Afeto acumulado:"), "Campaign closure must show a final result and cumulative score.")
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage" and not phase.player.controls.enabled, "Final result must keep movement locked and use success feedback.")
	for frame in range(3):
		await process_frame
	_check(Rect2(0, 0, 1024, 512).encloses(phase.ui.modal.get_global_rect()), "Final summary must fit the 1024x512 screen.")
	phase.player.interaction_requested.emit()
	_check(_rewards == previous_rewards + 1, "Repeat interactions must not duplicate final rewards.")

func _run() -> void:
	root.size = Vector2i(1024, 512)
	var phase: Node = (load("res://features/phase_five/phase_five.tscn") as PackedScene).instantiate()
	root.add_child(phase)
	phase.phase_completed.connect(func(_points: int) -> void: _rewards += 1)
	await process_frame
	_check(phase.content.intro_cutscene.overlays[0].resource_path.ends_with("tob_triste_deitado.png"), "Intro must use the team's sad lying Tob artwork.")
	await _intro(phase)
	_choice(phase, 1)
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0 and not phase.bed.visible, "Bed must be collected before it can be placed.")
	phase.ui.advance_requested.emit()
	_choice(phase, 0)
	_check(phase._leaving_alone and phase.affection == 0, "Petting and leaving must not grant affection.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	await phase.transition.finished
	_check(phase.state == phase.State.FEEDBACK and phase.ui.body.text == phase.content.bad_choice and phase.ui.modal.theme_type_variation == &"ErrorMessage" and _rewards == 0, "Returning inside while ignoring Tob must trigger the exact GDD warning without completing the phase.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(570, 400))
	_check(phase.state == phase.State.FEEDBACK and not phase.adopted, "Adoption must require bringing Tob inside first.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(250, 280))
	_check(phase.has_bed and phase.house.target_at(Vector2(250, 280)) == null, "Bed and blankets must be collectible once.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(415, 500))
	await phase.transition.finished
	_check(phase.has_bed, "Carrying the bed must survive door transitions.")
	_choice(phase, 1)
	_check(phase.bed.visible and not phase.adopted, "Temporary-care outcome must place the bed without pretending Tob was adopted.")
	await _finish_ending(phase, 1, 0)
	phase.ui.advance_requested.emit()
	_check(not phase.has_bed and not phase.carrying_tob and not phase.welcomed and not phase.adopted and not phase.bed.visible and not phase.indoor_tob.visible and phase.tob.visible, "Restart must reset both endings, bed collection, carrying and Tob's location.")
	phase.starting_affection = 8
	await _intro(phase)
	_choice(phase, 2)
	_check(phase.carrying_tob and phase.carried_tob.visible and not phase.tob.visible and phase.affection == 0, "Welcoming must visibly carry Tob without awarding adoption prematurely.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.welcomed and phase.indoor_tob.visible and not phase.carried_tob.visible and phase.affection == 0, "Arrival must place Tob indoors but still require the adoption request.")
	_interact(phase, Vector2(440, 420))
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0, "Petting indoors cannot bypass the adult's adoption conversation.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(570, 400))
	_check(phase.state == phase.State.CHOICE and phase.ui.body.text == "Mãe, deixa o Tob morar conosco", "Adoption conversation must use the GDD's explicit request.")
	phase.ui.choice_buttons[1].pressed.emit()
	_check(phase.state == phase.State.EXPLORE and not phase.adopted, "Exploring must close adoption choices without a reward.")
	_interact(phase, Vector2(570, 400))
	phase.ui.choice_buttons[0].pressed.emit()
	_check(phase.adopted, "Adult adoption choice must select the family ending.")
	await _finish_ending(phase, 2, 1)
	_check(phase.house.visible and phase.indoor_tob.visible and phase.ui.hearts.text.count("♥") == 10, "Adoption must end at home with Tob and support ten cumulative hearts.")
	phase.queue_free()
	await process_frame
	for path: String in ["res://features/phase_five/street.tscn", "res://features/phase_five/house.tscn", "res://features/phase_five/intro_preview.tscn", "res://features/shelter/dog_bed.tscn"]:
		var component: Node = (load(path) as PackedScene).instantiate()
		root.add_child(component)
		await process_frame
		component.queue_free()
		await process_frame
	if not _failed:
		print("PASS: silent GDD intro, child-initiated choices, ignoring warning, bed/1 heart, carrying/adult adoption/2 hearts, ending stories, final score, reset and standalone scenes.")
	quit(1 if _failed else 0)
