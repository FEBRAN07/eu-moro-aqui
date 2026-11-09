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
	_check(phase.state == phase.State.INTRO and phase.cutscene.playing and not phase.player.visible and not phase.ui.visible, "Third phase must begin with an isolated cutscene.")
	var position: Vector2 = phase.player.position
	Input.action_press(&"move_up")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_up")
	_check(phase.player.position == position, "Movement must remain blocked during the intro.")
	for line: EMACutsceneLine in phase.content.intro_cutscene.lines:
		_check(phase.cutscene.dialogue.text == line.text, "Third intro must display each GDD line in order.")
		phase.cutscene.advance()
	await phase.transition.finished
	_check(phase.state == phase.State.EXPLORE and phase.street.visible and not phase.house.visible, "Intro must fade into the stormy street.")
	_check(phase.ui.phase_title.text == "FASE 3" and phase.ui.objective.text.contains("tempestade"), "HUD must show the shelter goal.")

func _choice(phase: Node, index: int) -> void:
	_interact(phase, phase.tob.position)
	_check(phase.state == phase.State.CHOICE and phase.ui.choices.visible, "Tob must offer shelter choices.")
	phase.ui.advance_requested.emit()
	_check(phase.state == phase.State.CHOICE, "Generic advance must not bypass shelter choices.")
	phase.ui.choice_buttons[index].pressed.emit()

func _run() -> void:
	root.size = Vector2i(1024, 512)
	var phase: Node = (load("res://features/phase_three/phase_three.tscn") as PackedScene).instantiate()
	root.add_child(phase)
	phase.phase_completed.connect(func(_points: int) -> void: _rewards += 1)
	await process_frame
	var expected: Array[String] = [
		"Nossa essa brincadeira foi demais... estou feliz por ter um amigo que brinca comigo.",
		"Tá quente aqui né?! E sabe o que mais estou sentindo? Sinto cheiro de tempestade no ar...",
		"Minha mãe sempre falava que eu sou corajoso! Eu não tenho medo de chuvinhas... até gosto de me molhar, quando está calor, mas essa tempestade que está vindo aí é das grandes...",
		"Eu tenho um pouco de medo de tempestades... Onde será que vou me esconder?"
	]
	_check(phase.content.intro_cutscene.lines.size() == 4, "Phase three must contain exactly four cutscene lines.")
	for index in expected.size():
		_check(phase.content.intro_cutscene.lines[index].text == expected[index], "Cutscene wording must match the third phase of the GDD.")
	_check(phase.content.intro_cutscene.background.resource_path.ends_with("poste_chuvoso.png"), "Third cutscene must use the team's stormy pole art.")
	await _intro(phase)
	_choice(phase, 0)
	_check(phase.state == phase.State.FEEDBACK and not phase.cloth_placed and phase.affection == 0, "Cloth cannot be placed before fetching it.")
	phase.ui.advance_requested.emit()
	_choice(phase, 1)
	_check(phase.state == phase.State.FEEDBACK and not phase.doghouse.visible and _rewards == 0, "Doghouse cannot award hearts before fetching it.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.house.visible and not phase.street.visible and not phase.follow.following, "House transition must hide the rainy street and stop following.")
	_check(phase.house.target_at(Vector2(184, 244)) == null, "Old food interactions must be disabled in the shelter phase.")
	_interact(phase, Vector2(250, 280))
	_check(phase.has_cloth and phase.house.target_at(Vector2(250, 280)) == null, "Picked cloth must enter inventory and become unavailable.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(480, 280))
	_check(phase.has_kennel, "Doghouse pickup must enter inventory.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(415, 500))
	await phase.transition.finished
	_check(phase.has_cloth and phase.has_kennel, "Door transitions must preserve shelter materials.")
	_choice(phase, 0)
	_check(phase.cloth_placed and phase.cloth.visible and not phase.has_cloth and phase.affection == 0 and _rewards == 0, "Cloth outside must not complete or reward the phase.")
	_check(phase.ui.modal.theme_type_variation == &"ErrorMessage" and phase.ui.body.text == phase.content.bad_choice and phase.alert.stream != null, "Incorrect cloth shelter must show the GDD warning in red with an alert sound.")
	phase.ui.advance_requested.emit()
	_choice(phase, 1)
	_check(phase.state == phase.State.COMPLETE and phase.affection == 1 and _rewards == 1, "Placing a wooden doghouse must award one heart exactly once.")
	_check(phase.doghouse.visible and not phase.tob.visible and not phase.cloth.visible, "Doghouse outcome must visually shelter Tob instead of leaving him outside.")
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage", "Correct shelter must show green feedback.")
	phase.player.interaction_requested.emit()
	_check(_rewards == 1, "Completed solution must not grant duplicate hearts.")
	phase.ui.advance_requested.emit()
	_check(not phase.has_cloth and not phase.has_kennel and not phase.cloth_placed and not phase.doghouse.visible and phase.tob.visible and not phase.indoor_tob.visible, "Restart must reset inventory and both shelter outcomes.")
	phase.starting_affection = 4
	await _intro(phase)
	_choice(phase, 2)
	_check(phase.escorting and phase.affection == 0 and not phase.follow.following, "Inviting Tob must not immediately award hearts or move him during dialogue.")
	phase.ui.advance_requested.emit()
	var dog_before: Vector2 = phase.tob.position
	phase.player.position = Vector2(550, 430)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(phase.follow.following and phase.tob.position.distance_to(phase.player.position) < dog_before.distance_to(phase.player.position), "Tob must follow toward the player before entering the house.")
	_interact(phase, Vector2(317, 385))
	_check(phase.transition.busy and phase.affection == 0 and not phase.follow.following, "Door fade must block controls/following and delay reward until arrival.")
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.state == phase.State.COMPLETE and phase.affection == 2 and _rewards == 2, "Bringing Tob indoors must award two hearts after the transition.")
	_check(phase.house.visible and phase.indoor_tob.visible and not phase.tob.visible and not phase.street.visible, "Best outcome must show Tob in the house and hide the rainy street.")
	_check(phase.ui.body.text == phase.content.indoor_result and phase.ui.modal.theme_type_variation == &"SuccessMessage", "Best result must explain protection from rain, wind and fear.")
	_check(phase.ui.hearts.text.count("♥") == 6, "Third-phase HUD must support the maximum accumulated six hearts.")
	phase.player.interaction_requested.emit()
	_check(_rewards == 2, "Repeated interactions cannot duplicate the indoor reward.")
	phase.queue_free()
	await process_frame
	for path: String in ["res://features/phase_three/street.tscn", "res://features/phase_three/house.tscn", "res://features/phase_three/intro_preview.tscn", "res://features/shelter/doghouse.tscn"]:
		var component: Node = (load(path) as PackedScene).instantiate()
		root.add_child(component)
		await process_frame
		component.queue_free()
		await process_frame
	if not _failed:
		print("PASS: exact third-phase dialogue/art, blocked intro, item prerequisites, cloth warning, doghouse/1 heart, escort indoors/2 hearts, transitions, no duplicate rewards, reset and standalone scenes.")
	quit(1 if _failed else 0)
