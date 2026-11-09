extends Camera2D
## Fit legacy map coordinates without scaling physics bodies or the CanvasLayer UI.
@export var design_size := Vector2(890, 648)
@export var sidebar_width := 224.0
@export var standalone_only := false

func _ready() -> void:
	enabled = not standalone_only or get_parent().get_parent() == get_tree().root
	if not enabled:
		return
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var viewport_size := get_viewport_rect().size
	var available := Vector2(maxf(1, viewport_size.x - sidebar_width), viewport_size.y)
	var factor := minf(available.x / design_size.x, available.y / design_size.y)
	zoom = Vector2.ONE * factor
	# Keep world origin at the screen's top-left; UI remains in viewport coordinates.
	position = viewport_size / (2.0 * factor)
	force_update_scroll()
