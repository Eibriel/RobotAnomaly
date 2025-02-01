extends Node3D

@export var design:DESIGN

enum DESIGN {
	PEACE,
	MAID
}

func _ready() -> void:
	$MeshInstance3D.visible = false
	$MeshInstance3D2.visible = false
	match design:
		DESIGN.PEACE:
			$MeshInstance3D.visible = true
		DESIGN.MAID:
			$MeshInstance3D2.visible = true
