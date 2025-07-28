extends Control

const game_scene_path := "res://base.tscn"

var timer := 0.0
var waiting_key := false
var scene_changed := false

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
	
	var start_tween := create_tween().set_loops()
	start_tween.tween_property(%StartLabel, "modulate:a", 0.5, 1.0)
	start_tween.tween_property(%StartLabel, "modulate:a", 1.0, 1.0)
	
	var camera_tween := create_tween().set_loops().set_trans(Tween.TRANS_EXPO)
	camera_tween.tween_property(%Camera3D, "rotation_degrees:z", -13, 4.0)
	camera_tween.tween_property(%Camera3D, "rotation_degrees:z", -14, 4.0)
	
	var light_tween := create_tween().set_loops().set_trans(Tween.TRANS_CUBIC)
	light_tween.tween_property(%SpotLight3D, "light_energy", 1.0, 0.1)
	light_tween.tween_interval(4.0)
	light_tween.tween_property(%SpotLight3D, "light_energy", 0.5, 0.1)
	light_tween.tween_property(%SpotLight3D, "light_energy", 1.0, 0.1)
	light_tween.tween_interval(6.0)
	light_tween.tween_property(%SpotLight3D, "light_energy", 0.5, 0.1)
	light_tween.tween_property(%SpotLight3D, "light_energy", 1.0, 0.1)
	light_tween.tween_property(%SpotLight3D, "light_energy", 0.5, 0.1)
	light_tween.tween_property(%SpotLight3D, "light_energy", 1.0, 0.1)
	light_tween.tween_interval(2.0)
	light_tween.tween_property(%SpotLight3D, "light_energy", 0.5, 0.1)
	

func _process(delta: float) -> void:
	timer += delta
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(game_scene_path, progress)
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
		$%LoadingProgressBar.value = progress[0] * 100.0
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED and timer > 2.0:
		$%LoadingProgressBar.value = 100.0
		var load_tween := create_tween()
		load_tween.tween_property($EibrielLogo, "modulate:a", 0.0, 0.5)
		#load_tween.tween_callback(change_scene)
		load_tween.tween_property($WhiteColorRect, "modulate:a", 0.0, 0.5)
		load_tween.parallel().tween_property($LoadingProgressBar, "modulate:a", 0.0, 0.5)
		timer = -99999.0
		waiting_key = true

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		return
	if event is InputEventJoypadButton and event.button_index != 0:
		return
	
	if event.is_pressed():
		var load_tween := create_tween()
		load_tween.tween_property($BlackColorRect, "modulate:a", 1.0, 1.0)
		load_tween.tween_callback(change_scene)

#func start_game() -> void:
	#ResourceLoader.load_threaded_request(game_scene_path)

func change_scene() -> void:
	if scene_changed: return
	scene_changed = true
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(game_scene_path)
	#get_tree().change_scene_to_packed(new_scene)
	get_node("/root/Loading").queue_free()
	get_tree().root.add_child(new_scene.instantiate())
