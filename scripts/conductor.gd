extends Node

var bpm: float = 120.0

var crochet: float
var step_crochet: float

var scroll_speed: float = 1.0

var song_position: float

func change_bpm(new_bpm: float):
	bpm = new_bpm
	_recalculate_values()
	
func _recalculate_values():
	crochet = (60 / bpm) * 1000
	step_crochet = crochet / 4
