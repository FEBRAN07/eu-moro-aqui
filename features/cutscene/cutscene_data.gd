extends Resource
class_name EMACutsceneData
## Phase-independent story data, editable in the Inspector.
@export var title := ""
@export var background: Texture2D
@export var lines: Array[EMACutsceneLine] = []

func is_valid() -> bool:
	if lines.is_empty():
		return false
	for entry in lines:
		if entry == null or entry.text.strip_edges().is_empty():
			return false
	return true
