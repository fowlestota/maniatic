extends Panel
class_name NotePreview

var note_time: float = 0.0
var lane: int = 0
var note_type: int = 0:
	set(val):
		note_type = val
		add_theme_stylebox_override("panel", load("res://assets/prefab/note_styles/%s.tres" %[val]))

func setup(t: float, l: int, type: int):
	note_time = t
	lane = l
	note_type = type
	
	position.x = lane * 64
