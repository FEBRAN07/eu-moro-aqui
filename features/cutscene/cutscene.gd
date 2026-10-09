extends CanvasLayer
class_name EMACutscene
## Presents story data only; the phase decides what happens after finished.
signal finished
@export var preview_data: EMACutsceneData
@onready var screen: Control = %Screen
@onready var background: TextureRect = %Background
@onready var chapter: Label = %Chapter
@onready var speaker: Label = %Speaker
@onready var dialogue: RichTextLabel = %Dialogue
@onready var progress: Label = %Progress
@onready var next_button: Button = %NextButton
var playing := false
var _data: EMACutsceneData
var _index := 0

func _ready() -> void:
	next_button.pressed.connect(advance)
	if preview_data:
		play(preview_data)
	else:
		screen.hide()

func play(data: EMACutsceneData) -> void:
	assert(data != null and data.is_valid(), "Assign a cutscene with nonempty dialogue entries.")
	_data = data
	_index = 0
	playing = true
	background.texture = data.background
	chapter.text = data.title
	next_button.disabled = false
	screen.show()
	_show_line()

func advance() -> void:
	if not playing:
		return
	_index += 1
	if _index == _data.lines.size():
		# Keep the illustration onscreen until the owner's fade covers it.
		playing = false
		next_button.disabled = true
		finished.emit()
	else:
		_show_line()

func dismiss() -> void:
	playing = false
	screen.hide()
	next_button.release_focus()

func _show_line() -> void:
	var entry := _data.lines[_index]
	if entry.background:
		background.texture = entry.background
	speaker.text = entry.speaker
	dialogue.text = entry.text
	dialogue.scroll_to_line(0)
	progress.text = "%d / %d" % [_index + 1, _data.lines.size()]
	next_button.text = "Começar fase" if _index == _data.lines.size() - 1 else "Continuar"

func _input(event: InputEvent) -> void:
	# Consume keyboard advance before gameplay receives it. Mouse clicks are
	# handled by GUI first, so pressing the button cannot also advance twice.
	if playing and not event is InputEventMouseButton and not event.is_echo() and (event.is_action_pressed(&"advance") or event.is_action_pressed(&"interact")):
		advance()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if playing and not event.is_echo() and event.is_action_pressed(&"advance"):
		advance()
		get_viewport().set_input_as_handled()

func _on_screen_gui_input(event: InputEvent) -> void:
	if playing and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance()
		screen.accept_event()
