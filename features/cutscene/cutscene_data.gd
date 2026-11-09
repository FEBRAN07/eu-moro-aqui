extends Resource
class_name EMACutsceneData
## Phase-independent story data, editable in the Inspector.
@export var title := ""
@export var finish_button_text := "Começar fase"
@export var background: Texture2D
## Transparent full-canvas layers, rendered in array order over the background.
@export var overlays: Array[Texture2D] = []
@export var lines: Array[EMACutsceneLine] = []

func is_valid() -> bool:
	if lines.is_empty():
		return false
	for entry in lines:
		if entry == null or entry.text.strip_edges().is_empty():
			return false
	return true
