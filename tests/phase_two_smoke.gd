extends SceneTree
var _failed := false
var _rewards := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _intro(phase: Node) -> void:
	_check(phase.state == phase.State.INTRO and not phase.player.visible and not phase.ui.visible, "Phase two must start with an isolated cutscene.")
	var initial: Vector2 = phase.player.position
	Input.action_press(&"move_up")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_up")
	_check(phase.player.position == initial, "Movement must be blocked in the cutscene.")
	for entry: EMACutsceneLine in phase.content.intro_cutscene.lines:
		_check(phase.cutscene.dialogue.text == entry.text, "Cutscene must display each supplied line in order.")
		phase.cutscene.advance()
	_check(phase.transition.busy, "Final line must trigger the gameplay fade.")
	await phase.transition.finished
	_check(phase.state == phase.State.EXPLORE and phase.street.visible and not phase.house.visible and not phase.plaza.visible, "Intro must fade into the street only.")
	_check(phase.ui.phase_title.text == "FASE 2" and phase.ui.objective.text.contains("Brinque com Tob"), "HUD must display phase two's goal.")

func _interact(phase: Node, point: Vector2) -> void:
	phase.player.position = point
	phase.player.interaction_requested.emit()

func _run() -> void:
	var phase: Node = (load("res://features/phase_two/phase_two.tscn") as PackedScene).instantiate()
	root.add_child(phase)
	phase.phase_completed.connect(func(_points: int) -> void: _rewards += 1)
	await process_frame
	var expected: Array[String] = [
		"Hummm estava muito boa essa comida. Ela tem tudo o que eu preciso para me manter vivo e forte, para correr, pular e brincar.",
		"Sabe, minha mãe e eu adorávamos brincar um com o outro. Ela me ensinou que quando a gente está brincando tem que morder de leve, sem força... Outra coisa que mamãe me ensinou é que não podemos morder nos olhos, pois isso pode ser machucar pra valer.",
		"Era maravilhoso brincar com minha mãe! Sinto muito falta dela.",
		"Queria tanto brincar com alguém... me sinto tão sozinho e triste... Será que você pode brincar comigo?"
	]
	_check(phase.content.intro_cutscene.lines.size() == expected.size(), "Intro must have exactly four lines.")
	for index in expected.size():
		_check(phase.content.intro_cutscene.lines[index].text == expected[index], "Phase-two text must exactly match the user's wording.")
	var first_intro: EMACutsceneData = load("res://features/phase_one/intro_cutscene.tres")
	_check(phase.content.intro_cutscene.background == first_intro.background, "Intro must reuse phase one's placeholder illustration.")
	await _intro(phase)
	_interact(phase, Vector2(720, 440))
	_check(phase.state == phase.State.CHOICE and phase.ui.choices.visible and not phase.player.controls.enabled, "Tob must open a choice menu and block movement.")
	phase.ui.advance_requested.emit()
	_check(phase.state == phase.State.CHOICE, "Generic advance must not select or skip a choice.")
	phase.ui.choice_buttons[0].pressed.emit()
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0 and _rewards == 0, "Stomping must show feedback without completing or rewarding.")
	_check(phase.ui.modal.theme_type_variation == &"ErrorMessage" and phase.ui.body.text == phase.content.bad_choice, "Stomping must retain the GDD warning in a red panel.")
	_check(phase.alert.stream != null, "Wrong choice must have an alert sound.")
	phase.ui.advance_requested.emit()
	_interact(phase, Vector2(317, 385))
	await phase.transition.finished
	_check(phase.house.visible and not phase.street.visible, "Phase two must allow entry into the house.")
	_check(phase.house.target_at(Vector2(184, 244)) == null, "Hidden food items from phase one must not remain interactable.")
	_interact(phase, Vector2(360, 320))
	_check(phase.state == phase.State.THROWING and phase.stick.visible, "Window action must animate throwing the stick.")
	phase.player.interaction_requested.emit()
	await create_timer(1.0).timeout
	_check(phase.state == phase.State.COMPLETE and phase.affection == 1 and _rewards == 1, "Throwing the stick must award one heart exactly once.")
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage", "Correct solution must display green feedback.")
	phase.ui.advance_requested.emit()
	_check(phase.affection == 0 and phase.route_index == 0 and not phase.follow.following, "Restart must reset phase-two progress.")
	await _intro(phase)
	_interact(phase, Vector2(720, 440))
	phase.ui.choice_buttons[2].pressed.emit()
	_check(phase.state == phase.State.EXPLORE, "Exploring must close the menu without a reward.")
	_interact(phase, Vector2(560, 570))
	await phase.transition.finished
	_check(phase.plaza.visible, "Plaza gate must lead to the separate plaza environment.")
	_interact(phase, phase.companion.position)
	phase.ui.choice_buttons[1].pressed.emit()
	await phase.transition.finished
	_check(phase.state == phase.State.PLAYING and phase.follow.following, "Playing together must enable Tob's follower component.")
	_interact(phase, phase.companion.position)
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0, "Petting before the route cannot prematurely award hearts.")
	phase.ui.advance_requested.emit()
	phase.player.position = Vector2(440, 450)
	var dog_before: Vector2 = phase.companion.position
	await physics_frame
	await physics_frame
	await physics_frame
	_check(phase.companion.position.distance_to(phase.player.position) < dog_before.distance_to(phase.player.position), "Tob must actually follow the player in physics ticks.")
	for point: Marker2D in phase.route.get_children():
		phase.player.global_position = point.global_position
		phase.companion.global_position = point.global_position + Vector2(-45, 0)
		await physics_frame
		await physics_frame
		await physics_frame
	_check(phase.route_index == 3 and phase.affection == 0, "Route must require all three points and wait for final petting.")
	phase.companion.position = Vector2(120, 550)
	_interact(phase, Vector2(80, 550))
	_check(phase.transition.busy, "Nearest interaction must allow exiting the plaza even when Tob is following nearby.")
	await phase.transition.finished
	_check(phase.route_index == 3 and not phase.follow.following, "Leaving the plaza must preserve route progress and stop the follower.")
	_interact(phase, Vector2(560, 570))
	await phase.transition.finished
	_check(phase.state == phase.State.PLAYING and phase.route_index == 3, "Returning must resume the existing play session without clearing progress.")
	_interact(phase, phase.companion.position)
	_check(phase.state == phase.State.COMPLETE and phase.affection == 2 and _rewards == 2, "Running together then petting must award two hearts.")
	_check(phase.ui.body.text == phase.content.together_result, "Best result must mention affection, time together and licks.")
	phase.player.interaction_requested.emit()
	_check(_rewards == 2, "Completed phase must ignore repeat interactions.")
	phase.queue_free()
	await process_frame
	for path: String in ["res://features/phase_two/street.tscn", "res://features/phase_two/house.tscn", "res://features/phase_two/plaza.tscn", "res://features/phase_two/intro_preview.tscn"]:
		var component: Node = (load(path) as PackedScene).instantiate()
		root.add_child(component)
		await process_frame
		component.queue_free()
		await process_frame
	if not _failed:
		print("PASS: exact phase-two dialogue, isolated intro, choices, alert, doors, stick animation/1 heart, plaza/following/petting/2 hearts, reset and standalone scenes.")
	quit(1 if _failed else 0)
