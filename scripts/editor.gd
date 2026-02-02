extends Control

@export var bpm: float = 120.0
@export_group("Preview Scenes")
@export var note_preview_scene: PackedScene
@export var middle_note_preview_scene: PackedScene

@export_group("Layout Settings")
@export var step_size: int = 48
@export var lane_width_small: int = 48
@export var lane_width_middle: int = 96

@onready var music = $Music
@onready var timeline = $Margin/Scroll
@onready var notes_container = $Margin/Scroll/Notes

@export_group("Nodes")
@export var bpm_value: SpinBox
@export var song_name_value: LineEdit
@export var artist_value: LineEdit
@export var note_type_value: SpinBox
@export var scroll_speed_value: SpinBox

var pixels_per_second: float = 400
var chart_data = [] 
var chart_json = [] 

func _ready():
	if bpm_value: bpm_value.value = bpm
	update_editor_settings()

func update_editor_settings():
	if bpm_value: bpm = bpm_value.value
	
	Conductor.change_bpm(bpm)
	var steps_per_second = (bpm / 60.0) * 4.0 
	pixels_per_second = steps_per_second * step_size
	setup_timeline()

func setup_timeline():
	if not music.stream or music.stream.get_length() <= 0: return
	
	var step_duration = Conductor.step_crochet / 1000.0
	var total_steps = music.stream.get_length() / step_duration
	
	notes_container.custom_minimum_size.y = total_steps * step_size
	print("Timeline height set to: ", notes_container.custom_minimum_size.y)

func get_formatted_time() -> String:
	var time = music.get_playback_position() if music.playing else timeline.scroll_vertical / pixels_per_second
	time = max(0.0, time)
	return "%02d:%02d" % [int(time / 60), int(time) % 60]

func _process(_delta):
	$Time.text = get_formatted_time()
	
	if Input.is_action_just_pressed("editor_save"): $SaveMT.show()
	if Input.is_action_just_pressed("editor_load"): $LoadMT.show()
	if Input.is_action_just_pressed("editor_load_audio"): $LoadAudio.show()
	if Input.is_action_just_pressed("editor_exit"): get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
	if Input.is_action_just_pressed("editor_play"):
		if music.playing: music.stop()
		else: music.play(timeline.scroll_vertical / pixels_per_second)
	
	if music.playing:
		timeline.set_deferred("scroll_vertical", int(music.get_playback_position() * pixels_per_second))

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			timeline.scroll_vertical -= step_size / 2.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			timeline.scroll_vertical += step_size / 2.0
			
		if event.pressed:
			var mouse_pos = notes_container.get_local_mouse_position()
			var total_width = (lane_width_small * 4) + lane_width_middle
			
			if mouse_pos.x < 0 or mouse_pos.x > total_width or mouse_pos.y < 0: return
			
			var step_index = int(floor(mouse_pos.y / step_size))
			var lane = _get_lane_from_pos(mouse_pos.x)

			if event.button_index == MOUSE_BUTTON_LEFT: add_note(step_index, lane, -1)
			elif event.button_index == MOUSE_BUTTON_RIGHT: remove_note(step_index, lane)

func add_note(s_index: int, l: int, type: int = -1):
	for note in chart_data:
		if note.step == s_index and note.lane == l: return
	
	var final_type = type if type != -1 else int(note_type_value.value)
	
	var scene = middle_note_preview_scene if l == 2 else note_preview_scene
	var new_note = scene.instantiate()
	notes_container.add_child(new_note)
	
	new_note.position = Vector2(_get_lane_x_ui(l), s_index * step_size)
	if new_note is Control:
		new_note.size.x = lane_width_middle if l == 2 else lane_width_small
	
	new_note.note_type = final_type
	
	chart_data.append({"step": s_index, "lane": l, "node": new_note})
	chart_json.append({"step": s_index, "lane": l, "type": final_type})

func remove_note(s_index: int, l: int):
	for i in range(chart_data.size() - 1, -1, -1):
		if chart_data[i].step == s_index and chart_data[i].lane == l:
			if is_instance_valid(chart_data[i].node): chart_data[i].node.queue_free()
			chart_data.remove_at(i)
			chart_json.remove_at(i)

func _get_lane_x_ui(lane: int) -> float:
	var x_offsets = [0, lane_width_small, lane_width_small * 2, 
					(lane_width_small * 2) + lane_width_middle, 
					(lane_width_small * 3) + lane_width_middle]
	return float(x_offsets[lane]) if lane < x_offsets.size() else 0.0

func _get_lane_from_pos(mouse_x: float) -> int:
	if mouse_x < lane_width_small: return 0
	if mouse_x < lane_width_small * 2: return 1
	if mouse_x < (lane_width_small * 2) + lane_width_middle: return 2
	if mouse_x < (lane_width_small * 3) + lane_width_middle: return 3
	return 4

func save_mt(path: String):
	var writer = ZIPPacker.new()
	if writer.open(path) != OK: return
	
	# Create Metadata dictionary from UI nodes
	var meta_data = {
		"bpm": bpm_value.value if bpm_value else bpm,
		"scroll_speed": scroll_speed_value.value if scroll_speed_value else 1.0,
		"song_name": song_name_value.text if song_name_value else "Unknown",
		"artist": artist_value.text if artist_value else "Unknown"
	}
	
	writer.start_file("meta.json")
	writer.write_file(JSON.stringify(meta_data).to_utf8_buffer())
	writer.close_file()
	
	writer.start_file("chart.json")
	writer.write_file(JSON.stringify(chart_json).to_utf8_buffer())
	writer.close_file()
	
	if music.stream:
		writer.start_file("audio.mp3")
		writer.write_file(music.stream.data)
		writer.close_file()
	writer.close()

func load_mt(path: String):
	var reader = ZIPReader.new()
	if reader.open(path) != OK: return

	if reader.file_exists("meta.json"):
		var meta = JSON.parse_string(reader.read_file("meta.json").get_string_from_utf8())
		
		# Populate UI Nodes from Meta
		if bpm_value: bpm_value.value = meta.get("bpm", 120.0)
		if scroll_speed_value: scroll_speed_value.value = meta.get("scroll_speed", 1.0)
		if song_name_value: song_name_value.text = meta.get("song_name", "")
		if artist_value: artist_value.text = meta.get("artist", "")
		
		bpm = meta.get("bpm", 120.0)
		update_editor_settings()

	if reader.file_exists("audio.mp3"):
		var stream = AudioStreamMP3.new()
		stream.data = reader.read_file("audio.mp3")
		music.stream = stream
		setup_timeline()

	for note in chart_data: 
		if is_instance_valid(note.node): note.node.queue_free()
	chart_data.clear()
	chart_json.clear()
	
	if reader.file_exists("chart.json"):
		var data = JSON.parse_string(reader.read_file("chart.json").get_string_from_utf8())
		if data is Array:
			for info in data:
				add_note(info.step, info.lane, info.get("type", 0))
	reader.close()

func change_bpm(value: float) -> void:
	bpm = value
	update_editor_settings()
	print("BPM updated to: ", bpm)
	
func load_audio(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var bytes = file.get_buffer(file.get_length())
		var stream = AudioStreamMP3.new()
		stream.data = bytes
		music.stream = stream
		
		setup_timeline()
		print("Audio loaded successfully!")
	else:
		print("Failed to open file at path: ", path)
