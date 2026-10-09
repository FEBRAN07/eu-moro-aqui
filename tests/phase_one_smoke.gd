extends SceneTree
## Integration check: transitions preserve choices and both endings remain valid.
var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)

func _run() -> void:
	var scene: PackedScene = load("res://features/phase_one/phase_one.tscn")
	var phase: Node = scene.instantiate()
	root.add_child(phase)
	await process_frame
	await _finish_intro(phase)
	_check(phase.state == phase.State.EXPLORE, "Intro must enable exploration.")
	await physics_frame
	await physics_frame
	for polygon_name: String in ["Facade", "Roof"]:
		var visual: Polygon2D = phase.street.get_node("Scenery/" + polygon_name)
		var collision: CollisionPolygon2D = visual.get_node("Body/Collision")
		_check(collision.polygon == visual.polygon, polygon_name + " collision must match its visual contour.")
	_check(phase.player.test_move(Transform2D(0.0, Vector2(317, 420)), Vector2(0, -140)), "Facade must block movement from the front.")
	_check(phase.player.test_move(Transform2D(0.0, Vector2(630, 220)), Vector2(-120, 0)), "Facade must block movement from the right.")
	_check(phase.player.test_move(Transform2D(0.0, Vector2(40, 220)), Vector2(120, 0)), "Facade must block movement from the left.")
	# Above the facade, this swept feet shape can only hit the triangular roof.
	_check(phase.player.test_move(Transform2D(0.0, Vector2(610, 82)), Vector2(-55, 0)), "Roof must block movement along its sloping edge.")
	phase.player.position = Vector2(317, 420)
	Input.action_press(&"move_up")
	for frame in range(35):
		await physics_frame
	Input.action_release(&"move_up")
	_check(phase.player.position.y >= 355.9 and phase.player.position.y < 365, "Walking upwards must stop at the facade, not enter it.")
	_check(phase.street.target_at(phase.player.position).action_id == &"door", "Door must remain reachable outside the facade.")
	var initial: Vector2 = phase.player.position
	Input.action_press(&"move_right")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_right")
	_check(phase.player.position.x > initial.x, "Player must move with InputMap actions.")
	phase.player.position = Vector2(317, 385)
	phase.player.interaction_requested.emit()
	_check(phase.transition.busy, "Door must start a transition.")
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.house.visible and not phase.street.visible, "House must replace street.")
	_check(not phase.player.test_move(Transform2D(0.0, Vector2(317, 420)), Vector2(0, -140)), "Hidden street collisions must not block movement inside the house.")
	for item_name: String in ["Food", "Water"]:
		var item: EMAInteractable = phase.house.get_node("Interactions/" + item_name)
		var bowl: Sprite2D = item.get_node("Bowl")
		_check(bowl.texture is AtlasTexture and bowl.texture.atlas != null, item_name + " must display its imported bowl sprite.")
		_check(bowl.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Bowl sprites must preserve pixel art filtering.")
		_check(not item.get_node("Icon").visible and not item.get_node("Token").visible and not item.get_node("Outline").visible, "Bowl must replace the placeholder icon.")
	var leftovers: EMAInteractable = phase.house.get_node("Interactions/Leftovers")
	var food_sprite: Sprite2D = leftovers.get_node("FoodSprite")
	_check(food_sprite.texture != null and food_sprite.texture.get_size() == Vector2(32, 32), "Leftovers must display the imported cooked beef sprite.")
	_check(food_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and food_sprite.scale == Vector2(2, 2), "Leftovers must preserve pixel art with nearest filtering and integer scaling.")
	_check(not leftovers.get_node("Icon").visible and not leftovers.get_node("Token").visible and not leftovers.get_node("Outline").visible, "Cooked beef must replace the leftovers placeholder.")
	phase.player.position = Vector2(184, 244)
	phase.player.interaction_requested.emit()
	_check(not phase.has_food and phase.affection == 0, "Bad choice cannot grant food or hearts.")
	_check(phase.state == phase.State.FEEDBACK and phase.ui.body.text == phase.content.bad_choice, "Cooked beef interaction must retain educational feedback.")
	_check(phase.ui.modal.theme_type_variation == &"ErrorMessage", "Incorrect food choice must display a red message.")
	phase.ui.advance_requested.emit()
	phase.player.position = Vector2(452, 244)
	phase.player.interaction_requested.emit()
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage", "Collecting water must display a green message.")
	phase.ui.advance_requested.emit()
	phase.player.position = Vector2(415, 500)
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	phase.player.position = Vector2(720, 440)
	phase.player.interaction_requested.emit()
	_check(phase.state == phase.State.FEEDBACK and phase.affection == 0, "Water alone cannot complete the phase.")
	_check(phase.ui.modal.theme_type_variation == &"ErrorMessage", "Attempting to feed without food must display a red message.")
	phase.ui.advance_requested.emit()
	_check(phase.player.test_move(Transform2D(0.0, Vector2(317, 420)), Vector2(0, -140)), "Returning to the street must restore collisions.")
	phase.player.position = Vector2(317, 385)
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	phase.player.position = Vector2(318, 244)
	phase.player.interaction_requested.emit()
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage", "Collecting proper food must display a green message.")
	phase.ui.advance_requested.emit()
	_check(phase.house.target_at(Vector2(318, 244)) == null, "Collected item must no longer be selectable.")
	phase.player.position = Vector2(415, 500)
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	_check(phase.has_food and phase.has_water, "Transition must preserve collected items.")
	phase.player.position = Vector2(720, 440)
	phase.player.interaction_requested.emit()
	_check(phase.affection == 2 and phase.state == phase.State.COMPLETE, "Food and water must award two hearts.")
	_check(phase.ui.modal.theme_type_variation == &"SuccessMessage", "Successful completion must display a green message.")
	phase.ui.advance_requested.emit()
	_check(not phase.has_food and not phase.has_water and phase.affection == 0, "Restart must reset progress.")
	_check(phase.state == phase.State.INTRO and phase.cutscene.playing, "Restart must replay the introduction before gameplay.")
	await _finish_intro(phase)
	phase.player.position = Vector2(317, 385)
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	phase.player.position = Vector2(318, 244)
	phase.player.interaction_requested.emit()
	phase.ui.advance_requested.emit()
	phase.player.position = Vector2(415, 500)
	phase.player.interaction_requested.emit()
	await phase.transition.finished
	phase.player.position = Vector2(720, 440)
	phase.player.interaction_requested.emit()
	_check(phase.affection == 1 and phase.state == phase.State.COMPLETE, "Only food must award one heart.")
	phase.queue_free()
	await process_frame
	# Each reusable scene can also run independently (F6).
	for path: String in ["res://features/player/player.tscn", "res://features/environments/street.tscn", "res://features/environments/house.tscn", "res://features/ui/phase_ui.tscn", "res://features/ui/transition.tscn", "res://features/cutscene/cutscene.tscn"]:
		var component: Node = (load(path) as PackedScene).instantiate()
		root.add_child(component)
		await process_frame
		component.queue_free()
		await process_frame
	if not _failed:
		print("PASS: cutscene/gameplay separation, intro fade and replay, facade/roof collisions, hidden environment physics, movement, doors, choices, 1/2 hearts and standalone scenes.")
	quit(1 if _failed else 0)

func _finish_intro(phase: Node) -> void:
	_check(not phase.ui.visible and not phase.player.visible and not phase.street.visible and not phase.house.visible, "Gameplay and HUD must be hidden during the cutscene.")
	_check(phase.cutscene.screen.visible and phase.cutscene.background.texture != null, "Intro must display its static illustration.")
	var initial: Vector2 = phase.player.position
	Input.action_press(&"move_up")
	await physics_frame
	await physics_frame
	Input.action_release(&"move_up")
	_check(phase.player.position == initial, "Movement must remain disabled during the cutscene.")
	phase.ui.advance_requested.emit()
	_check(phase.state == phase.State.INTRO, "Gameplay dialogue UI cannot bypass the cutscene.")
	for entry: EMACutsceneLine in phase.content.intro_cutscene.lines:
		_check(phase.cutscene.dialogue.text == entry.text and phase.cutscene.speaker.text == entry.speaker, "Cutscene must present each authored line in order.")
		phase.cutscene.advance()
	_check(phase.state == phase.State.STARTING_GAMEPLAY and phase.transition.busy, "Last dialogue must start the intro-to-gameplay fade.")
	phase.cutscene.advance()
	_check(not phase.player.controls.enabled, "Player input must stay disabled until the fade finishes.")
	await phase.transition.finished
	_check(not phase.cutscene.screen.visible and phase.ui.visible and phase.player.visible and phase.street.visible, "Fade must replace the cutscene with gameplay and HUD.")
