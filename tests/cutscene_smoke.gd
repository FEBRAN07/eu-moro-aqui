extends SceneTree
## The reusable presenter must run without a phase or gameplay dependencies.
var _failed := false
var _finished_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _key(code: Key, pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	root.push_input(event)

func _run() -> void:
	var presenter := (load("res://features/cutscene/cutscene.tscn") as PackedScene).instantiate() as EMACutscene
	root.add_child(presenter)
	presenter.finished.connect(func() -> void: _finished_count += 1)
	await process_frame
	_check(not presenter.screen.visible, "Standalone presenter without preview data must load safely.")
	var data := EMACutsceneData.new()
	data.title = "Outra fase"
	var first := EMACutsceneLine.new()
	first.speaker = "Narrador"
	first.text = "Uma nova história."
	var second := EMACutsceneLine.new()
	second.speaker = "Criança"
	second.text = "Vamos ajudar!"
	# Use a self-contained fixture: the game's placeholder art can be replaced.
	second.background = GradientTexture2D.new()
	data.lines.assign([first, second])
	presenter.play(data)
	await process_frame
	_check(presenter.chapter.text == data.title and presenter.speaker.text == "Narrador", "Presenter must accept data from another phase.")
	_key(KEY_SPACE, true, true)
	_check(presenter.dialogue.text == first.text, "Key repeat must not skip dialogue.")
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	_check(presenter.dialogue.text == second.text and presenter.background.texture == second.background, "Keyboard must advance exactly one line and apply a background override.")
	_check(presenter.next_button.text == "Começar fase", "Last line must communicate the gameplay boundary.")
	# A click on the GUI button must not also trigger the screen click handler.
	presenter.play(data)
	await process_frame
	await process_frame
	var point := presenter.next_button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.global_position = point
		click.pressed = pressed
		root.push_input(click)
	_check(presenter.dialogue.text == second.text and presenter.playing and _finished_count == 0, "Button click must advance one line only.")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	presenter.advance()
	_check(not presenter.playing and _finished_count == 1, "Completion must emit exactly once despite repeated input.")
	presenter.dismiss()
	_check(not presenter.screen.visible, "Owner must be able to dismiss the cutscene under a fade.")
	presenter.play(data)
	_check(presenter.playing and presenter.dialogue.text == first.text and presenter.background.texture == null, "Replay must reset dialogue and background overrides.")
	var background_click := InputEventMouseButton.new()
	background_click.button_index = MOUSE_BUTTON_LEFT
	background_click.position = Vector2(600, 100)
	background_click.pressed = true
	root.push_input(background_click)
	_check(presenter.dialogue.text == second.text and presenter.playing, "Clicking the illustration must advance only one entry.")
	presenter.queue_free()
	await process_frame
	var preview: Node = (load("res://features/phase_one/intro_preview.tscn") as PackedScene).instantiate()
	root.add_child(preview)
	await process_frame
	_check(preview.playing and preview.background.texture != null, "F6 preview must play the authored intro without a phase controller.")
	preview.queue_free()
	await process_frame
	if not _failed:
		print("PASS: reusable cutscene data, speakers, illustrations, keyboard, mouse, repeat guard, single completion and replay.")
	quit(1 if _failed else 0)
