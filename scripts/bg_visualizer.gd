extends Node2D

@export_group("Visuals")
@export var bar_color: Color = Color.WHITE
@export var bar_count: int = 16
@export var total_width: float = 800.0
@export var max_height: float = 250.0
@export var spacing: float = 2.0
@export var show_reflection: bool = true
@export var reflection_opacity: float = 0.15

@export_group("Audio & Physics")
@export var bus_name: String = "Master"
@export var min_db: float = 60.0
@export var fall_speed: float = 10.0
@export var accel_speed: float = 25.0

var spectrum: AudioEffectSpectrumAnalyzerInstance
var bar_values: Array = []

func _ready():
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		spectrum = AudioServer.get_bus_effect_instance(bus_idx, 0)
	
	bar_values.resize(bar_count)
	bar_values.fill(0.0)

func _process(delta):
	if not spectrum: return
	
	var prev_hz = 20.0
	var max_hz = 11050.0

	for i in range(bar_count):
		var hz = float(i + 1) * max_hz / bar_count
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		
		var energy = clampf((linear_to_db(magnitude) + min_db) / min_db, 0.0, 1.0)
		var target_height = energy * max_height
		
		if target_height > bar_values[i]:
			bar_values[i] = lerp(bar_values[i], target_height, accel_speed * delta)
		else:
			bar_values[i] = lerp(bar_values[i], target_height, fall_speed * delta)
			
		prev_hz = hz

	queue_redraw()

func _draw():
	var single_bar_width = (total_width / bar_count) - spacing
	
	for i in range(bar_count):
		var x = i * (single_bar_width + spacing)
		var height = bar_values[i]
		
		var rect = Rect2(x, -height, single_bar_width, height)
		draw_rect(rect, bar_color)
		
		if show_reflection:
			var reflect_color = bar_color
			reflect_color.a = reflection_opacity
			var reflect_rect = Rect2(x, 0, single_bar_width, height)
			draw_rect(reflect_rect, reflect_color)
