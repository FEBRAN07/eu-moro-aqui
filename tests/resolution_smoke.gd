extends SceneTree
## Test screen-space geometry as well as gameplay's unchanged world coordinates.
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _inside(control: Control, bounds: Rect2, context: String) -> void:
	var rect := control.get_global_rect()
	_check(bounds.grow(1).encloses(rect), "%s must fit (rect=%s, bounds=%s)." % [context, rect, bounds])

func _layout() -> void:
	for frame in range(3):
		await process_frame

func _run() -> void:
	root.size = Vector2i(1024, 512)
	_check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1024 and ProjectSettings.get_setting("display/window/size/viewport_height") == 512, "Base viewport must remain the user-configured 1024x512.")
	_check(ProjectSettings.get_setting("display/window/size/window_width_override") == 1024 and ProjectSettings.get_setting("display/window/size/window_height_override") == 512, "Initial window must match the base resolution.")
	var screen := Rect2(0, 0, 1024, 512)
	for path: String in ["res://features/phase_one/phase_one.tscn", "res://features/phase_two/phase_two.tscn", "res://features/phase_three/phase_three.tscn", "res://features/phase_four/phase_four.tscn", "res://features/phase_five/phase_five.tscn"]:
		var phase: Node = (load(path) as PackedScene).instantiate()
		if path.contains("phase_three"):
			phase.starting_affection = 4
		elif path.contains("phase_four"):
			phase.starting_affection = 6
		elif path.contains("phase_five"):
			phase.starting_affection = 8
		root.add_child(phase)
		await _layout()
		_inside(phase.cutscene.next_button, screen, "Cutscene advance button")
		var panel: PanelContainer = phase.cutscene.get_node("Screen/Layout/Stack/DialoguePanel")
		_inside(panel, screen, "Cutscene dialogue")
		_check(phase.cutscene.background.get_global_rect() == screen, "Cutscene artwork must cover the full viewport behind the dialogue.")
		for entry in phase.content.intro_cutscene.lines:
			await _layout()
			_check(phase.cutscene.dialogue.get_content_height() <= phase.cutscene.dialogue.size.y + 1, "Current cutscene lines must fit without clipping at the base resolution.")
			phase.cutscene.advance()
		await phase.transition.finished
		await _layout()
		var sidebar: PanelContainer = phase.ui.get_node("Root/Sidebar")
		_inside(sidebar, screen, "HUD")
		_inside(phase.ui.get_node("Root/Sidebar/Info/Controls"), screen, "HUD controls")
		phase.ui.update_overview("Praça", 4, "BRINCADEIRA\nPercurso: 3 / 3\nAgora faça carinho em Tob!", 4)
		await _layout()
		_inside(sidebar, screen, "HUD with four hearts and play progress")
		_inside(phase.ui.get_node("Root/Sidebar/Info/Controls"), screen, "HUD controls with play progress")
		phase.ui.update_overview("Rua — tempestade", 6, "ABRIGO\nTob segue você.\nEntre pela porta da casa.", 6)
		await _layout()
		_inside(sidebar, screen, "HUD with six hearts and shelter progress")
		_inside(phase.ui.get_node("Root/Sidebar/Info/Controls"), screen, "HUD controls with shelter progress")
		phase.ui.update_overview("Clínica veterinária", 8, "CUIDADO\nÁgua: oferecida\nAdulto vai à clínica.", 8)
		await _layout()
		_inside(sidebar, screen, "HUD with eight hearts and care progress")
		_inside(phase.ui.get_node("Root/Sidebar/Info/Controls"), screen, "HUD controls with care progress")
		phase.ui.update_overview("Casa", 10, "FAMÍLIA\nTob foi adotado!", 10)
		await _layout()
		_inside(sidebar, screen, "HUD with ten hearts")
		_inside(phase.ui.hearts, screen, "Ten hearts")
		_inside(phase.ui.get_node("Root/Sidebar/Info/Controls"), screen, "HUD controls with ten hearts")
		var neutral: EMAPhaseContent = load("res://features/phase_one/phase_content.tres")
		for text: String in [neutral.bad_choice, neutral.best_result, neutral.good_result]:
			phase.ui.show_message("Fase concluída! +2 corações", text)
			await _layout()
			_inside(phase.ui.modal, screen, "Feedback panel")
			_inside(phase.ui.next_button, screen, "Feedback button")
			_check(phase.ui.modal.get_global_rect().end.x <= sidebar.get_global_rect().position.x, "Feedback must not overlap the HUD.")
		var options: Array[Dictionary] = [{"id": &"stomp", "text": "Bater o pé"}, {"id": &"play", "text": "Correr e fazer carinho"}, {"id": &"cancel", "text": "Explorar"}]
		phase.ui.show_choices("Tob quer brincar", "Escolha como quer brincar com Tob.", options)
		await _layout()
		for button in phase.ui.choice_buttons:
			_inside(button, screen, "Choice button")
		phase.ui.hide_message()
		var areas: Array[EMAEnvironment] = [phase.street, phase.house]
		if path.contains("phase_two"):
			areas.append(phase.plaza)
		elif path.contains("phase_four"):
			areas.append(phase.clinic)
		for area in areas:
			_check(not area.get_node("StandaloneCamera").enabled, "Environment preview cameras must not compete with the phase camera.")
			if path.contains("phase_one"):
				phase._set_area(area)
			else:
				phase._travel(area)
				await phase.transition.finished
			await _layout()
			var gameplay := Rect2(0, 0, sidebar.get_global_rect().position.x, 512)
			for target: EMAInteractable in area.interactions.get_children():
				if not target.visible:
					continue
				var screen_point: Vector2 = target.get_global_transform_with_canvas().origin
				_check(gameplay.has_point(screen_point), "%s/%s must remain visible and reachable after camera fitting: %s." % [area.name, target.name, screen_point])
				var title: Label = target.get_node("Title")
				var title_end: Vector2 = title.get_global_transform_with_canvas() * title.size
				_check(title_end.y <= 512, "Interaction captions at the bottom of the map must not be clipped.")
			phase.player.position = area.walk_bounds.end
			var player_end: Vector2 = phase.player.get_global_transform_with_canvas() * Vector2(0, 66)
			_check(player_end.y <= 512, "Movement bounds must keep the player's lower labels inside the screen.")
		phase.queue_free()
		await process_frame
	for path: String in ["res://features/environments/street.tscn", "res://features/environments/house.tscn", "res://features/phase_two/plaza.tscn"]:
		var environment: Node = (load(path) as PackedScene).instantiate()
		root.add_child(environment)
		await _layout()
		_check(environment.get_node("StandaloneCamera").enabled, "Standalone environments must also use fitted framing for F6.")
		environment.queue_free()
		await process_frame
	if not _failed:
		print("PASS: 1024x512 viewport/window, HUD, dialogue, choices, cutscene artwork, map framing, interaction visibility and movement bounds.")
	quit(1 if _failed else 0)
