extends Panel
class_name StrumMarker

var lane: int = 0

func _ready() -> void:
	match lane:
		0:
			$Label.text = Global.get_input_key("note_left")
		1:
			$Label.text = Global.get_input_key("note_down")
		2:
			$Label.text = Global.get_input_key("note_middle")
		3:
			$Label.text = Global.get_input_key("note_up")
		4:
			$Label.text = Global.get_input_key("note_right")

func _process(delta: float) -> void:
	if Global.tutorial_mode:
		$Label.visible = true
	else:
		$Label.visible = false
