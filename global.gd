extends Node

var player: CharacterBody3D
var is_player_in_room: bool = false
var is_player_in_storage: bool = false
var is_player_grabbed: bool = false

var reset_save := false

const ROBOT = preload("res://robot.tscn")

var robot_stack: Array[Robot]
var stack_timer := 0.0
var strugle_timer := 0.0

func _process(delta: float) -> void:
	stack_timer += delta
	strugle_timer += delta
	if stack_timer > 0.1 and robot_stack.size() < 50:
		robot_stack.append(ROBOT.instantiate())
		stack_timer = 0.0
		#print("Instantiate robot")

func get_robot_instance() -> Robot:
	if robot_stack.size() > 0:
		return robot_stack.pop_front()
	else:
		return ROBOT.instantiate()

func set_blood_vignete(value: float) -> void:
	RenderingServer.global_shader_parameter_set("blood_vignete", value)

func set_rumble_vignete(value: float) -> void:
	RenderingServer.global_shader_parameter_set("rumble_vignete", value)

func should_robot_strugle() -> bool:
	if strugle_timer > 10*60:
		return true
	return false

func strugle_executed() -> void:
	strugle_timer = 0.0
	

func is_demo() -> bool:
	return false

func is_steam() -> bool:
	return OS.get_cmdline_user_args().has("--steam")

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
	
