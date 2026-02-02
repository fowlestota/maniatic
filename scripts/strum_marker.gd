extends Panel
class_name StrumMarker

var lane: int = 0

func _ready() -> void:
	match lane:
		0:
			$Label.text = "D"
		1:
			$Label.text = "F"
		2:
			$Label.text = "SPACE"
		3:
			$Label.text = "J"
		4:
			$Label.text = "K"

func _process(delta: float) -> void:
	if Global.tutorial_mode:
		$Label.visible = true
	else:
		$Label.visible = false
