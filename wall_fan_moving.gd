extends Node3D

func _ready() -> void:
	$WallFan/WallFan_blade.rotate_z(deg_to_rad(randf_range(0, 45)))

func _process(delta: float) -> void:
	$WallFan/WallFan_blade.rotate_z(delta)
