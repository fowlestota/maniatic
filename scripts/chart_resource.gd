# chart_data.gd
extends Resource
class_name Chart

@export var name: String = "Level"
@export var artist: String = "Artist"
@export var mapper: String = "Mapper"
@export var bpm: float = 120.0
@export var scroll_speed: float = 1.0

func to_dict() -> Dictionary:
	return {
		"name": name,
		"artist": artist,
		"mapper": mapper,
		"bpm": bpm,
		"scroll_speed": scroll_speed
	}

func from_dict(data: Dictionary):
	name = data.get("name", "Unknown")
	artist = data.get("artist", "Unknown")
	mapper = data.get("mapper", "Unknown")
	bpm = data.get("bpm", 120.0)
	scroll_speed = data.get("scroll_speed", 1.0)
