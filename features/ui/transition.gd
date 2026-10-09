extends CanvasLayer
class_name EMATransition

signal covered
signal finished
@export var duration := 0.22
@onready var cover: ColorRect = %Cover
var busy := false
var _tween: Tween

func play() -> void:
	if busy:
		return
	busy = true
	cover.show()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(cover, "color:a", 1.0, duration)
	_tween.tween_callback(func() -> void: covered.emit())
	_tween.tween_property(cover, "color:a", 0.0, duration)
	_tween.tween_callback(_finish)

func _finish() -> void:
	busy = false
	cover.hide()
	finished.emit()
