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

func _choice(phase: Node, point: Vector2, index: int) -> void:
	_interact(phase, point)
	_check(phase.state == phase.State.CHOICE and not phase.player.controls.enabled, "Care decisions must use the shared choice menu and block movement.")
	phase.ui.advance_requested.emit()
	_check(phase.state == phase.State.CHOICE, "Generic advance cannot bypass choices.")
	phase.ui.choice_buttons[index].pressed.emit()

func _intro(phase: Node) -> void:
	_check(phase.state == phase.State.INTRO and not phase.player.visible and not phase.ui.visible and not phase.howl.playing, "Fourth phase must begin with an isolated, quiet cutscene.")
	var initial: Vector2 = phase.player.position
	Input.action_press(&"move_down")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_down")
	_check(phase.player.position == initial, "Cutscene must block movement.")
	for entry: EMACutsceneLine in phase.content.intro_cutscene.lines:
		_check(phase.cutscene.dialogue.text == entry.text, "Fourth intro must display authored dialogue in order.")
		phase.cutscene.advance()
	await phase.transition.finished
	_check(phase.state == phase.State.EXPLORE and phase.street.visible and not phase.clinic.visible, "Intro must fade into the street after the storm.")
	_check(phase.howl.stream != null and phase._has_howled, "Gameplay must signal Tob's condition with a placeholder howl.")
	_check(phase.ui.phase_title.text == "FASE 4", "HUD must display the correct phase.")

func _run() -> void:
	root.size = Vector2i(1024, 512)
	var phase: Node = (load("res://features/phase_four/phase_four.tscn") as PackedScene).instantiate()
	root.add_child(phase)
	phase.phase_completed.connect(func(_points: int) -> void: _rewards += 1)
	await process_frame
	var expected: Array[String] = [
		"Ufa, essa tempestade foi assustadora! Ainda bem que tenho um amigo que me abrigou. Mamãe sempre dizia, devemos ser fiéis aos humanos, pois eles estão aqui para cuidar de nós e nós deles.",
		"Quando penso na mamãe meu coração aperta de saudades. Ela sempre cuidou de mim e me defendeu de tudo e de todos. Sinto tanto a falta dela. Será que ela está bem lá no céu?",
		"Nossa acho que estou com gripe canina. Meu corpo todo dói.... sinto que estou muito quente."
	]
	_check(phase.content.intro_cutscene.lines.size() == 3, "Fourth intro must contain exactly three GDD lines.")
	for index in expected.size():
		_check(phase.content.intro_cutscene.lines[index].text == expected[index], "Fourth intro wording must match the GDD exactly.")
	_check(phase.content.intro_cutscene.overlays[0].resource_path.ends_with("tob_doente.png"), "Fourth intro must use the team's sick Tob artwork.")
	await _intro(phase)
	_choice(phase, Vector2(720, 440), 1)
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0 and not phase.veterinary_guidance, "Medication path must not be available without professional guidance and adult help.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(560, 570))
	_check(phase.state == phase.State.FEEDBACK and not phase.transition.busy, "Clinic trip must require an accompanying adult.")
	phase.ui.advance_requested.emit()
	_choice(phase, Vector2(720, 440), 0)
	_check(not phase.water_offered, "Water must be fetched before it can be offered.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	await phase.transition.finished
	_check(phase.house.target_at(Vector2(184, 244)) == null, "Irrelevant food items must remain hidden and unavailable.")
	_interact(phase, Vector2(452, 244))
	_check(phase.has_water and phase.house.target_at(Vector2(452, 244)) == null, "Water must be collectible only once.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(415, 500))
	await phase.transition.finished
	_check(phase.has_water, "Door transitions must preserve water.")
	_choice(phase, Vector2(720, 440), 0)
	_check(phase.water_offered and phase.water_bowl.visible and phase.affection == 0 and _rewards == 0, "Only water must show the bowl without granting hearts or completing the phase.")
	_check(phase.ui.modal.theme_type_variation == &"ErrorMessage" and phase.ui.body.text == phase.content.bad_choice and phase.alert.stream != null, "Water-only choice must show educational red feedback and an alert.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	await phase.transition.finished
	_choice(phase, Vector2(570, 400), 0)
	_check(phase.veterinary_guidance and phase.street_mother.visible and phase.affection == 0, "Professional guidance must be obtained via adult dialogue, without an immediate reward.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(415, 500))
	await phase.transition.finished
	_choice(phase, Vector2(720, 440), 1)
	_check(phase.state == phase.State.COMPLETE and phase.affection == 1 and _rewards == 1, "Adult care following veterinary instructions must award exactly one heart.")
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage" and phase.ui.body.text.contains("prescrita"), "Adult-care result must explicitly retain prescription safeguards.")
	phase.player.interaction_requested.emit()
	_check(_rewards == 1, "Completed care cannot grant duplicate hearts.")
	phase.ui.advance_requested.emit()
	_check(not phase.has_water and not phase.water_offered and not phase.veterinary_guidance and not phase.adult_accompanies and not phase.street_mother.visible and not phase.water_bowl.visible, "Reset must clear all care flags and visuals.")
	phase.starting_affection = 6
	await _intro(phase)
	_interact(phase, Vector2(317, 385))
	await phase.transition.finished
	_choice(phase, Vector2(570, 400), 1)
	_check(phase.adult_accompanies and phase.affection == 0, "Asking the adult for a clinic trip must not complete the phase.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(415, 500))
	await phase.transition.finished
	_interact(phase, Vector2(560, 570))
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.clinic.visible and not phase.street.visible and phase.adult_accompanies and phase.affection == 0, "Trip must enter a separate clinic while preserving the adult flag and waiting for examination.")
	_interact(phase, Vector2(100, 540))
	await phase.transition.finished
	_check(phase.adult_accompanies, "Leaving the clinic must preserve the responsible adult's participation.")
	_interact(phase, Vector2(560, 570))
	await phase.transition.finished
	_interact(phase, Vector2(620, 290))
	_check(phase.state == phase.State.COMPLETE and phase.affection == 2 and _rewards == 2, "Veterinary assessment must award two hearts once.")
	_check(phase.ui.hearts.text.count("♥") == 8 and phase.ui.body.text == phase.content.vet_result, "HUD must support eight cumulative hearts and show the proper professional-care result.")
	phase.player.interaction_requested.emit()
	_check(_rewards == 2, "Repeated clinic interaction cannot duplicate the reward.")
	phase.queue_free()
	await process_frame
	for path: String in ["res://features/phase_four/street.tscn", "res://features/phase_four/house.tscn", "res://features/phase_four/clinic.tscn", "res://features/phase_four/intro_preview.tscn", "res://features/npc/adult.tscn"]:
		var component: Node = (load(path) as PackedScene).instantiate()
		root.add_child(component)
		await process_frame
		component.queue_free()
		await process_frame
	if not _failed:
		print("PASS: fourth-phase dialogue/art, isolated intro/howl, water warning, adult/professional prerequisites, 1/2 hearts, clinic/return, reset, eight hearts and standalone scenes.")
	quit(1 if _failed else 0)
