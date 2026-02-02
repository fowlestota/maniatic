extends Resource
class_name GameSettings

enum NoteColorType { SILVER, CYAN, BLUE, DARK_BLUE, PURPLE, GREEN, RED, ORANGE, YELLOW, PINK, WHITE }

const NOTE_COLORS_MAP := {
	NoteColorType.RED:       Color("#da2424"),
	NoteColorType.ORANGE:    Color("#ef6e10"),
	NoteColorType.YELLOW:    Color("#ece910"),
	NoteColorType.GREEN:     Color("#08b23b"),
	NoteColorType.CYAN:      Color("#5ee9e9"),
	NoteColorType.BLUE:      Color("#2890dc"),
	NoteColorType.DARK_BLUE: Color("#1831a7"),
	NoteColorType.PURPLE:    Color("a251cfff"),
	NoteColorType.PINK:      Color("#f94e6d"),
	NoteColorType.SILVER:    Color("#8b97b6"),
	NoteColorType.WHITE:     Color("#c5cddb"),
}

@export_group("Audio")
@export var music_volume: float = 0.6
@export var sfx_volume: float = 1.0

@export_group("Visuals")
@export var note_colors: Array[NoteColorType] = [
	NoteColorType.PURPLE,
	NoteColorType.BLUE,
	NoteColorType.WHITE,
	NoteColorType.GREEN,
	NoteColorType.RED,
]

@export_group("Controls")
@export var keybinds: Dictionary = {}

func save_settings():
	var settings = GameSettings.new()
	settings.music_volume = 0.6
	settings.note_colors = note_colors
	
	ResourceSaver.save(settings, "user://settings.tres")

func load_settings():
	if FileAccess.file_exists("user://settings.tres"):
		var settings = load("user://settings.tres") as GameSettings
		
		var music_bus = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_volume_linear(music_bus, settings.music_volume)
		
		return settings
