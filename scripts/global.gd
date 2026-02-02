extends Node

signal change_health(value: int)

var tutorial_mode: bool = false
var settings: GameSettings

var file: String = ""

var health: float = 0.5:
	set(val):
		if val <= 1:
			health = val
		else:
			health = 1
var score: int = 0:
	get():
		return score
	set(val):
		score = val
		change_health.emit(val)

var hit_window: int = 150

func _ready() -> void:
	load_settings()

func save_settings():
	if settings:
		ResourceSaver.save(settings, "user://settings.tres")
		print("Settings saved successfully.")

func load_settings():
	if FileAccess.file_exists("user://settings.tres"):
		settings = load("user://settings.tres")
		_apply_stored_keybinds()
	else:
		settings = GameSettings.new()

func _apply_stored_keybinds():
	if not settings or settings.keybinds.is_empty():
		return
		
	for action in settings.keybinds:
		var keycode = settings.keybinds[action]
		var new_event = InputEventKey.new()
		new_event.physical_keycode = keycode
		
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, new_event)
	print("Keybinds applied to InputMap.")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_exit()

func _on_exit():
	print("Game is closing! Saving data...")
	
	save_settings()
	
	get_tree().quit()
