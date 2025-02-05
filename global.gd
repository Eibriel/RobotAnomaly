extends Node

var player: CharacterBody3D
var is_player_in_room: bool = false

const ROBOT = preload("res://robot.tscn")

var robot_stack: Array[Robot]
var stack_timer := 0.0

func _process(delta: float) -> void:
	stack_timer += delta
	if stack_timer > 0.1 and robot_stack.size() < 50:
		robot_stack.append(ROBOT.instantiate())
		stack_timer = 0.0

func get_robot_instance() -> Robot:
	if robot_stack.size() > 0:
		return robot_stack.pop_front()
	else:
		return ROBOT.instantiate()
