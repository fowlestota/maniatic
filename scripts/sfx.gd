extends Node

func _play_sound(sound: String):
	if has_node(sound):
		var snd_node = get_node(sound)
		if snd_node is AudioStreamPlayer:
			snd_node.play()
