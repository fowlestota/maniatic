extends Control

func play_map() -> void:
	$LoadMT.show()

func editor() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/editor.tscn"))

func load_mt(path: String) -> void:
	Global.file = path
	get_tree().change_scene_to_packed(preload("res://scenes/level.tscn"))

func show_keybinds() -> void:
	$Keybinds.show()

func close_keybinds() -> void:
	$Keybinds.hide()
