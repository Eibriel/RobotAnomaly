@tool
extends Node3D

@export var texture: Texture :
	set(value):
		texture = value
		dirty = true
@export var size: Vector2 = Vector2(1,1) :
	set(value):
		size = value
		dirty = true
@export var banner_scale: float = 1.0 :
	set(value):
		banner_scale = value
		dirty = true
@export var frame_size: Vector2 = Vector2(0.01,0.01) :
	set(value):
		frame_size = value
		dirty = true
@export var broken: bool = false :
	set(value):
		broken = value
		dirty = true
@export var broken_scale: float = 1.0 :
	set(value):
		broken_scale = value
		dirty = true
@export var broken_offset: Vector2 = Vector2(1,1) :
	set(value):
		broken_offset = value
		dirty = true

var dirty: bool = true
var mat: StandardMaterial3D

func _ready() -> void:
	mat = StandardMaterial3D.new()
	mat.metallic_specular = 0.23
	mat.roughness = 0.2
	$Picture.mesh.material = mat
	dirty = true

func _process(_delta: float) -> void:
	if not dirty: return
	dirty = false
	$Picture.mesh.size = size * banner_scale
	$TopFrame.position.y = size.y * 0.5 * banner_scale
	$BottomFrame.position.y = size.y * -0.5 * banner_scale
	$RightFrame.position.x = size.x * 0.5 * banner_scale
	$LeftFrame.position.x = size.x * -0.5 * banner_scale
	$TopFrame.mesh.size.x = size.x * banner_scale + frame_size.x
	$TopFrame.mesh.size.y = frame_size.x
	$TopFrame.mesh.size.z = frame_size.y
	$LeftFrame.mesh.size.y = size.y * banner_scale - frame_size.x
	$LeftFrame.mesh.size.x = frame_size.x
	$LeftFrame.mesh.size.z = frame_size.y
	if texture:
		mat.albedo_texture = texture
	if broken:
		mat.detail_enabled = true
		mat.detail_albedo = preload("res://textures/shuttered_glass.png")
		mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		mat.uv2_triplanar = true
		mat.uv2_scale = Vector3.ONE * broken_scale
		mat.uv2_offset = Vector3(broken_offset.x, 0, broken_offset.y)
	else:
		mat.detail_enabled = false
