extends Node2D

@export var strum_line: Marker2D

@export_group("Note Scenes")
@export var note_scene: PackedScene
@export var bomb_scene: PackedScene
@export var middle_note_scene: PackedScene
@export var middle_bomb_scene: PackedScene

@export_group("Strum Scenes")
@export var strum_marker_scene: PackedScene
@export var middle_strum_marker_scene: PackedScene

@export_group("Layout Settings")
@export_range(0.0, 1.0) var screen_ratio_x: float = 0.5
@export var note_size: float = 48.0
@export var middle_note_size: float = 96.0
@export var note_spacing: float = 12.0
@export var middle_lane_extra_spacing: float = 24.0 

@export var chart_file_path: String = "res://assets/songs/testing.mt"

var last_song_pos: float = 0.0

var lanes: Array[Array] = [[], [], [], [], []] 
var playing: bool = false
var counting_down: bool = false
var done: bool = false

var alive = true

func _ready() -> void:
	if Global.file != "": chart_file_path = Global.file
	
	var level_data = _load_mt_package(chart_file_path)
	if level_data.is_empty(): return
	
	var meta = level_data["metadata"]
	
	var level_name = meta.get("song_name", "Level")
	
	if level_name == "mt_tutorial":
		Global.tutorial_mode = true
	
	Conductor.change_bpm(meta.get("bpm", 120.0))
	Conductor.scroll_speed = meta.get("scroll_speed", 1.0)
	
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = level_data["audio"]
	$Music.stream = audio_stream
	
	_spawn_strums()
	_spawn_notes_from_json(level_data["chart"])
	
	Conductor.song_position = -Conductor.crochet * 4
	counting_down = true
	
	Global.health = 0.5
	Global.score = 0
	
	$CanvasLayer/HealthBar.value = Global.health
	$CanvasLayer/Score.text = "0"

func _load_mt_package(path: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(path) != OK: return {}

	var level_data = {
		"audio": reader.read_file("audio.mp3"),
		"chart": JSON.parse_string(reader.read_file("chart.json").get_string_from_utf8()),
		"metadata": JSON.parse_string(reader.read_file("meta.json").get_string_from_utf8())
	}
	reader.close()
	return level_data

func _spawn_notes_from_json(data: Array):
	for note_data in data:
		_spawn_note(note_data.get("step", 0), note_data.get("lane", 0), int(note_data.get("type", 0)))

func _spawn_note(step: float, lane: int, type: int):
	var scene_to_spawn: PackedScene
	if lane == 2:
		scene_to_spawn = middle_bomb_scene if type == 1 else middle_note_scene
	else:
		scene_to_spawn = bomb_scene if type == 1 else note_scene
	
	if not scene_to_spawn: return

	var note = scene_to_spawn.instantiate()
	note.strum_time = step 
	note.lane = lane
	note.global_position.x = _calculate_lane_x(lane)
	note.target_y = strum_line.global_position.y
	
	$Notes.add_child(note)
	lanes[lane].append(note)

func _process(delta: float) -> void:
	$CanvasLayer/Score.text = str(Global.score)
	$CanvasLayer/HealthBar.value = lerp($CanvasLayer/HealthBar.value, Global.health, 0.2)

	if counting_down:
		Conductor.song_position += delta * 1000
		if Conductor.song_position >= 0:
			$Music.play()
			counting_down = false
			playing = true
			Conductor.song_position = 0
	elif playing:
		var raw_pos = $Music.get_playback_position()
		var latency = AudioServer.get_output_latency()
		Conductor.song_position = (raw_pos + latency) * 1000
		_check_for_misses()
	elif done:
		Conductor.song_position += delta * 1000
		if Conductor.song_position >= last_song_pos + 1000:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
		
	if Global.health <= 0 and alive:
		die()
		
func die():
	alive = false
	$AnimationPlayer.play("die")
	await $AnimationPlayer.animation_finished
	get_tree().reload_current_scene()

func _spawn_strums():
	for lane in range(5):
		var strum: StrumMarker = middle_strum_marker_scene.instantiate() if lane == 2 else strum_marker_scene.instantiate()
		strum.lane = lane
		add_child(strum)
		strum.global_position = Vector2(_calculate_lane_x(lane), strum_line.global_position.y)

func _calculate_lane_x(lane_index: int) -> float:
	var center_anchor = get_viewport_rect().size.x * screen_ratio_x
	var total_middle_gap = note_spacing + middle_lane_extra_spacing
	var total_width = (4 * note_size) + middle_note_size + (2 * note_spacing) + (2 * total_middle_gap)
	var start_x = center_anchor - (total_width / 2.0)
	
	match lane_index:
		0: return start_x + (note_size / 2.0)
		1: return start_x + note_size + note_spacing + (note_size / 2.0)
		2: return center_anchor - (middle_note_size / 2.0)
		3: return center_anchor + (middle_note_size / 2.0) + total_middle_gap - (note_size / 2.0)
		4: return center_anchor + (middle_note_size / 2.0) + total_middle_gap + note_size + note_spacing - (note_size / 2.0)
		_: return 0.0

func _check_for_misses():
	for lane_index in range(5):
		if lanes[lane_index].is_empty(): continue
		var target_note = lanes[lane_index][0]
		# If the note passes the hit window, it's a miss
		if Conductor.song_position > (target_note.strum_time * Conductor.step_crochet) + Global.hit_window:
			_miss_note(lane_index, target_note)

func _miss_note(lane_index: int, note: Node):
	lanes[lane_index].pop_front()
	
	if note.has_method("miss"): 
		note.miss()
	else: 
		note.queue_free()

func _input(event: InputEvent) -> void:
	if not playing: return
	var actions = ["note_left", "note_down", "note_middle", "note_up", "note_right"]
	for i in range(5):
		if event.is_action_pressed(actions[i]):
			_attempt_hit(i)

func _attempt_hit(lane_index: int) -> void:
	if lanes[lane_index].is_empty(): return
	var target_note = lanes[lane_index][0]
	var target_time_ms = target_note.strum_time * Conductor.step_crochet
	var distance = abs(Conductor.song_position - target_time_ms)
	
	if distance <= Global.hit_window:
		lanes[lane_index].pop_front()
		
		target_note.hit(distance)

func _complete_song():
	playing = false
	done = true
	last_song_pos = $Music.stream.get_length() * 1000
	Conductor.song_position = last_song_pos
