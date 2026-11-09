extends SceneTree
## Composition must work independently of the phase, without editing images.
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1024, 512)
	var presenter := (load("res://features/cutscene/cutscene.tscn") as PackedScene).instantiate() as EMACutscene
	root.add_child(presenter)
	await process_frame
	var background := GradientTexture2D.new()
	var second_background := GradientTexture2D.new()
	var actor := GradientTexture2D.new()
	var other_actor := GradientTexture2D.new()
	var data := EMACutsceneData.new()
	data.background = background
	data.overlays.assign([actor])
	for index in range(6):
		var entry := EMACutsceneLine.new()
		entry.text = "Fala %d" % index
		data.lines.append(entry)
	data.lines[1].background = second_background
	data.lines[1].overlays.assign([actor, other_actor])
	data.lines[3].clear_overlays = true
	data.lines[4].overlays.assign([other_actor])
	data.lines[5].clear_overlays = true
	data.lines[5].overlays.assign([actor, other_actor])
	presenter.play(data)
	_check(presenter.background.texture == background and presenter.overlays.get_child_count() == 1, "Play must apply the default backdrop and layers.")
	presenter.advance()
	_check(presenter.background.texture == second_background and presenter.overlays.get_child_count() == 2, "A line must replace the backdrop and display multiple images at once.")
	_check(presenter.overlays.get_child(0).texture == actor and presenter.overlays.get_child(1).texture == other_actor, "Layer ordering must match the authored array.")
	presenter.advance()
	_check(presenter.overlays.get_child_count() == 2 and presenter.background.texture == second_background, "Unspecified artwork must persist across dialogue.")
	presenter.advance()
	_check(presenter.overlays.get_child_count() == 0 and presenter.background.texture == second_background, "Clear layers must support background-only shots.")
	presenter.advance()
	_check(presenter.overlays.get_child_count() == 1 and presenter.overlays.get_child(0).texture == other_actor, "A new list must not append to previous layers.")
	presenter.advance()
	_check(presenter.overlays.get_child_count() == 2, "Explicit clear plus new layers must show the new list.")
	presenter.advance()
	_check(not presenter.playing and presenter.overlays.get_child_count() == 2, "Final composition must remain visible until dismissed under the phase fade.")
	presenter.dismiss()
	_check(presenter.overlays.get_child_count() == 0, "Dismiss must discard old overlays immediately.")
	presenter.play(data)
	_check(presenter.background.texture == background and presenter.overlays.get_child_count() == 1, "Replay must restore defaults without leaking prior layers.")
	_check(data.overlays.size() == 1 and data.lines[1].overlays.size() == 2, "Presentation must not mutate authored Resources.")
	for phase_path: String in ["res://features/phase_one/intro_cutscene.tres", "res://features/phase_two/intro_cutscene.tres"]:
		var authored := load(phase_path) as EMACutsceneData
		_check(authored.background.resource_path.begins_with("res://assets/team/"), "Intros must use the students' imported artwork.")
		presenter.play(authored)
		await process_frame
		await process_frame
		_check(presenter.overlays.get_child_count() == 1, "Present-day shot must display Tob over the background.")
		presenter.advance()
		_check(presenter.overlays.get_child_count() == 2, "Childhood shot must display the puppy and mother together.")
		await process_frame
		var dialogue_panel: PanelContainer = presenter.get_node("Screen/Layout/Stack/DialoguePanel")
		_check(presenter.background.get_global_rect() == Rect2(0, 0, 1024, 512), "Artwork must fill the complete base viewport.")
		_check(presenter.background.get_global_rect().encloses(dialogue_panel.get_global_rect()), "Dialogue must overlay the artwork inside the viewport.")
		_check(presenter.get_node("Screen/Layout").z_index > presenter.get_node("Screen/Artwork").z_index, "Dialogue and title must render above artwork.")
		for layer: TextureRect in presenter.overlays.get_children():
			_check(layer.get_global_rect() == presenter.background.get_global_rect(), "Transparent canvas layers must stay aligned with the backdrop.")
			_check(layer.texture.get_size() == authored.background.get_size(), "Team assets must retain their shared canvas dimensions.")
			_check(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Overlay images must not swallow advance clicks.")
			_check(layer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Team pixel art must use nearest filtering.")
			_check(layer.stretch_mode == presenter.background.stretch_mode and layer.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Background and sprites must use the same full-screen cover framing.")
	presenter.queue_free()
	await process_frame
	if not _failed:
		print("PASS: multiple backgrounds/layers, ordering, inheritance, clearing, replay, authored team art, layout and input isolation.")
	quit(1 if _failed else 0)
