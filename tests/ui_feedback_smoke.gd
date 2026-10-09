extends SceneTree
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
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
	ui.queue_free()
	await process_frame
	if not _failed:
		print("PASS: green/red feedback styles, neutral reset and shared theme isolation.")
	quit(1 if _failed else 0)
