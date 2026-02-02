extends Panel
class_name Note

var strum_time: float
var target_y: float
var lane: int = 0

var generousness: float = 0.005

@export var damage_note: bool = false
@export var colored: bool = true

func _process(_delta: float) -> void:
	global_position.y = target_y - (Conductor.song_position - (strum_time * Conductor.step_crochet)) * (0.3 * Conductor.scroll_speed)
	if colored:
		modulate = Global.settings.NOTE_COLORS_MAP[Global.settings.note_colors[lane]]

func hit(timing_error: float):
	if damage_note:
		Global.health -= 0.1
		Global.score -= 50
	else:
		SFX._play_sound("Hit")
		Global.health += 0.05 * snapped(((Global.hit_window - timing_error) / Global.hit_window), generousness)
		Global.score += 500 * snapped(((Global.hit_window - timing_error) / Global.hit_window), generousness)
	
	queue_free()

func miss():
	if not damage_note:
		Global.health -= 0.075
		Global.score -= 100
