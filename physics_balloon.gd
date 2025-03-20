extends RigidBody3D


func _ready() -> void:
	$Brain.visible = false
	$Balloon.visible = true

func turn_into_brain() -> void:
	$Brain.visible = true
	$Balloon.visible = false
