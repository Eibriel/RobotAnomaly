extends Node3D

@export var seconds := 0.0

func _process(_delta: float) -> void:
	var minutes := seconds / 60.0
	var hours := minutes / 60.0
	$clock/clock_second.rotation.z = deg_to_rad(floor(-seconds) * (360.0/60.0))
	$clock/clock_minute.rotation.z = deg_to_rad(-minutes * (360.0/60.0))
	$clock/clock_hour.rotation.z = deg_to_rad(-hours * (360.0/12.0))
