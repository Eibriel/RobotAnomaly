extends Node3D

@export var drawing: Texture

var mat: StandardMaterial3D

func _ready() -> void:
	mat = StandardMaterial3D.new()
	mat.albedo_texture = drawing
	mat.metallic = 0.33
	mat.metallic_specular = 0.0
	mat.roughness = 0.31
	%MeshInstance3D.set_surface_override_material(0, mat)
