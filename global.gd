extends Node

var player: CharacterBody3D
var is_player_in_room: bool = false
var is_player_in_storage: bool = false
var is_player_grabbed: bool = false

var game_settings:GameSettingsResource

var robot_cache: Node3D

var reset_save := false
var is_reset := false

const ROBOT = preload("res://robot.tscn")

var robot_stack: Array[Robot]
var stack_timer := 0.0
var strugle_timer := 0.0
var angry_timer := 0.0
var noise_timer := 0.0
var turned_off_light := false

var recording_trailer:= false

func _ready() -> void:
	strugle_executed()
	noise_executed()

func _process(delta: float) -> void:
	stack_timer += delta
	strugle_timer -= delta
	strugle_timer = max(strugle_timer, 0)
	noise_timer -= delta
	noise_timer = max(noise_timer, 0)
	if angry_timer >= 0:
		angry_timer += delta
	if stack_timer > 0.1 and robot_stack.size() < 50:
		var r := ROBOT.instantiate()
		robot_cache.add_child(r)
		robot_stack.append(r)
		stack_timer = 0.0
		#print("Instantiate robot")

func get_robot_instance() -> Robot:
	if robot_stack.size() > 0:
		var r = robot_stack.pop_front()
		if not is_instance_valid(r):
			push_error("Robot instance not valid!")
			return ROBOT.instantiate()
		return r
	else:
		return ROBOT.instantiate()

func set_blood_vignete(value: float) -> void:
	RenderingServer.global_shader_parameter_set("blood_vignete", value)

func set_rumble_vignete(value: float) -> void:
	RenderingServer.global_shader_parameter_set("rumble_vignete", value)

func reset_timers() -> void:
	angry_executed()
	strugle_executed()
	noise_executed()

func should_robots_be_angry() -> bool:
	if angry_timer > 17*60:
		return true
	return false

func angry_executed() -> void:
	angry_timer = -1.0

func should_robot_strugle() -> bool:
	if strugle_timer <= 0:
		return true
	return false

func strugle_executed() -> void:
	strugle_timer = 8 * randi_range(1, 4) * 60

func should_fire_noise(light:=false) -> bool:
	if not turned_off_light and light:
		turned_off_light = true
		return true
	if noise_timer <= 0:
		return true
	return false

func noise_executed() -> void:
	noise_timer = 4 * randi_range(1, 10) * 60

func is_demo() -> bool:
	#return OS.has_feature("demo")
	if not is_export():
		#return true
		pass
	return OS.get_cmdline_user_args().has("--demo")

func is_steam() -> bool:
	return OS.get_cmdline_user_args().has("--steam")

func is_export() -> bool:
	return OS.has_feature("template")

func is_playtest() -> bool:
	if not is_export():
		#return true
		pass
	return OS.get_cmdline_user_args().has("--playtest")

func is_nomber_between(number: float, min: float, max: float) -> bool:
	if min > max:
		var tmp := min
		min = max
		max = tmp
	if number > min and number < max:
		return true
	else:
		return false

func is_point_inside(x_min: float, x_max: float, y_min: float, y_max: float, point_2d: Vector2) -> bool:
	return is_nomber_between(point_2d.x, x_min, x_max) and \
		is_nomber_between(point_2d.y, y_min, y_max)
	
