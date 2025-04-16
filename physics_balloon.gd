extends RigidBody3D


func _ready() -> void:
	$Brain.visible = false
	$BrainTube2.visible = false
	$Balloon.visible = true
	$BrainTube2.rotation_degrees.y = randf_range(0, 360)

func turn_into_brain() -> void:
	#$Brain.visible = true
	$BrainTube2.visible = true
	$Balloon.visible = false

func _process(_delta: float) -> void:
	$BrainTube2.global_position.x = global_position.x
	$BrainTube2.global_position.y = 0.058
	$BrainTube2.global_position.z = global_position.z
