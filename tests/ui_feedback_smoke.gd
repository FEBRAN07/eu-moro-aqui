extends SceneTree
var _failed := false
var _selected: StringName = &""
var _selection_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
	# Headless windows default to 64x64; GUI hit tests need the intended viewport.
	root.size = Vector2i(1152, 648)
	var ui := (load("res://features/ui/phase_ui.tscn") as PackedScene).instantiate() as EMAPhaseUI
	root.add_child(ui)
	await process_frame
	var sidebar: PanelContainer = ui.get_node("Root/Sidebar")
	var neutral := ui.modal.get_theme_stylebox("panel") as StyleBoxFlat
	var neutral_color := neutral.bg_color
	ui.show_message("Correto", "Ração e água fresca.", "Continuar", EMAPhaseUI.Feedback.SUCCESS)
	var green := ui.modal.get_theme_stylebox("panel") as StyleBoxFlat
	_check(green.bg_color.g > green.bg_color.r and green.bg_color.g > green.bg_color.b, "Success panel must resolve to a green style.")
	ui.show_message("Incorreto", "Restos temperados.", "Continuar", EMAPhaseUI.Feedback.ERROR)
	var red := ui.modal.get_theme_stylebox("panel") as StyleBoxFlat
	_check(red.bg_color.r > red.bg_color.g and red.bg_color.r > red.bg_color.b, "Error panel must resolve to a red style.")
	_check(sidebar.get_theme_stylebox("panel") == neutral and neutral.bg_color == neutral_color, "Feedback must not mutate the shared theme or sidebar.")
	ui.show_message("Informação", "Mensagem neutra.")
	_check(ui.modal.get_theme_stylebox("panel") == neutral, "Default message must reset the feedback color.")
	ui.show_message("Correto", "Outra mensagem.", "Continuar", EMAPhaseUI.Feedback.SUCCESS)
	ui.hide_message()
	_check(not ui.modal.visible and ui.modal.theme_type_variation == &"", "Hiding a message must reset its style.")
	ui.choice_selected.connect(func(id: StringName) -> void:
		_selected = id
		_selection_count += 1)
	ui.show_choices("Escolha", "Uma ação por vez.", [{"id": &"play", "text": "Brincar"}, {"id": &"cancel", "text": "Voltar"}])
	await process_frame
	await process_frame
	_check(not ui.next_button.visible and ui.choice_buttons[0].has_focus(), "Choice menu must focus its first option and hide generic advance.")
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_ENTER
		key.keycode = KEY_ENTER
		key.pressed = pressed
		root.push_input(key)
	_check(_selected == &"play" and _selection_count == 1 and not ui.modal.visible, "Keyboard must select exactly one choice and close the menu.")
	ui.show_choices("Escolha", "Outra ação.", [{"id": &"play", "text": "Brincar"}, {"id": &"cancel", "text": "Voltar"}])
	await process_frame
	await process_frame
	var point := ui.choice_buttons[1].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.global_position = point
		click.pressed = pressed
		root.push_input(click)
	_check(_selected == &"cancel" and _selection_count == 2, "Mouse must select the requested option without double activation (selected=%s, count=%d, point=%s)." % [_selected, _selection_count, point])
	ui.queue_free()
	await process_frame
	if not _failed:
		print("PASS: green/red feedback styles, neutral reset, shared theme isolation and keyboard/mouse choices.")
	quit(1 if _failed else 0)
