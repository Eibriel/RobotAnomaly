extends Control

const game_scene_path := "res://base.tscn"

var timer := 0.0

func _ready() -> void:
	var load_tween := create_tween()
	load_tween.tween_property($BlackColorRect, "modulate:a", 0.0, 2.0)
	#load_tween.tween_callback(start_game)#.set_delay(1.0)
	
	ResourceLoader.load_threaded_request(game_scene_path)
	
	# Disable all controllers, just in case
	var actions := InputMap.get_actions()
	for action in actions:
		var inputs := InputMap.action_get_events(action)
		for input in inputs:
			if input is InputEventJoypadButton or input is InputEventJoypadMotion:
				# -1 seems to be "all devices", 99 is unreasonable
				input.device = 99

func _process(delta: float) -> void:
	timer += delta
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(game_scene_path, progress)
	$%LoadingProgressBar.value = progress[0] * 100.0
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED and timer > 2.0:
		var load_tween := create_tween()
		load_tween.tween_property($EibrielLogo, "modulate:a", 0.0, 0.5)
		load_tween.tween_callback(change_scene)
		timer = -99999.0

#func start_game() -> void:
	#ResourceLoader.load_threaded_request(game_scene_path)

func change_scene() -> void:
	var new_scene = ResourceLoader.load_threaded_get(game_scene_path)
	get_tree().change_scene_to_packed(new_scene)
