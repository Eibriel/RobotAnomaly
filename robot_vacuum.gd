extends Node3D

var brush_01: MeshInstance3D
var brush_02: MeshInstance3D

func _ready() -> void:
	brush_01 = $Roomba.get_node("RoombaBrush_001") as MeshInstance3D
	brush_02 = $Roomba.get_node("RoombaBrush_002") as MeshInstance3D

func _process(delta: float) -> void:
	brush_01.rotation.y -= PI * 2 * delta
	brush_02.rotation.y += PI * 2 * delta
