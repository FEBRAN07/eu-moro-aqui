extends SceneTree
## Tob must remain reusable without a phase controller.
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
	var packed := load("res://features/tob/tob.tscn") as PackedScene
	var tob := packed.instantiate() as EMAInteractable
	var other := packed.instantiate() as EMAInteractable
	root.add_child(tob)
	root.add_child(other)
	await process_frame
	_check(tob.action_id == &"tob" and tob.title == "Falar com Tob", "Reusable Tob must retain its interaction contract.")
	_check(tob.is_near(tob.global_position) and not tob.is_near(tob.global_position + Vector2(200, 0)), "Tob must retain proximity interaction.")
	_check(tob.get_node("Title").text == tob.title and tob.get_node("Indicator").visible, "Standalone Tob must initialize its title and indicator.")
	var visual: AnimatedSprite2D = tob.get_node("Visual")
	_check(visual.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and visual.scale == Vector2(2, 2), "Tob must preserve pixel art filtering and integer scale.")
	_check(visual.is_playing() and visual.animation == &"idle", "Tob must autoplay the idle animation.")
	var frames := visual.sprite_frames
	_check(frames.get_frame_count(&"idle") == 8 and frames.get_animation_loop(&"idle"), "Idle must contain eight looping frames.")
	for index in range(8):
		var texture := frames.get_frame_texture(&"idle", index) as AtlasTexture
		_check(texture != null and texture.region == Rect2(index * 64, 0, 64, 48), "Idle must use the first row of the supplied sprite sheet.")
		if texture:
			_check(texture.atlas.get_size() == Vector2(512, 432), "Tob must use the imported dog sheet.")
	var initial_frame := visual.frame
	await create_timer(0.25).timeout
	_check(visual.frame != initial_frame, "Idle must advance over time.")
	tob.set_available(false)
	_check(not tob.is_near(tob.global_position) and not tob.get_node("Indicator").visible, "Tob must support the existing availability API.")
	_check(other.available and other.get_node("Indicator").visible, "Separate Tob instances must not share availability state.")
	tob.queue_free()
	other.queue_free()
	await process_frame
	var street := (load("res://features/environments/street.tscn") as PackedScene).instantiate() as EMAEnvironment
	root.add_child(street)
	await process_frame
	var street_tob: EMAInteractable = street.get_node("Interactions/Tob")
	_check(street_tob.scene_file_path == packed.resource_path, "Street must instance the reusable Tob scene.")
	_check(street_tob.position == Vector2(720, 440) and street.target_at(street_tob.global_position) == street_tob, "Street must preserve Tob's position and interaction discovery.")
	_check(not street_tob.has_node("Body") and street_tob.has_node("Visual"), "Old placeholder polygons must be replaced by the sprite.")
	street.queue_free()
	await process_frame
	if not _failed:
		print("PASS: standalone Tob, idle frames/playback, pixel art, independent instances and Street integration.")
	quit(1 if _failed else 0)
