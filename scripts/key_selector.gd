extends Button
class_name KeySelector

@export var action_name: String = "note_middle"

var is_listening: bool = false

func _ready():
	_update_display()
	set_process_unhandled_input(false)

func _toggled(toggled_on: bool):
	if toggled_on:
		is_listening = true
		text = "..."
		set_process_unhandled_input(true)
	else:
		is_listening = false
		_update_display()
		set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		_update_action_binding(event)
		button_pressed = false
		_toggled(false)
		
		get_viewport().set_input_as_handled()

func _update_action_binding(new_event: InputEvent):
	if new_event is InputEventKey:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, new_event)
		
		Global.settings.keybinds[action_name] = new_event.physical_keycode
		
		Global.save_settings() 
		
		print("Action ", action_name, " bound to ", new_event.as_text())

func _update_display():
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		text = events[0].as_text().trim_suffix(" - Physical")
	else:
		text = "None"
