@tool
extends Node3D

@export var banner: = BANNER_TYPE.SMALL :
	set(value):
		banner = value
		dirty = true
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
enum BANNER_TYPE {
	SMALL,
	TALL,
	MEDIUM
}

var dirty: bool = true
var mat: StandardMaterial3D

func _ready() -> void:
	#mat = preload("res://banner.tscn::StandardMaterial3D_05pf3")
	mat = StandardMaterial3D.new()
	mat.metallic_specular = 0.23
	mat.roughness = 0.2
	$Picture.mesh.material = mat

func _process(_delta: float) -> void:
	if not dirty: return
	dirty = false
	#match banner:
		#BANNER_TYPE.SMALL:
			#$Banner01.visible = true
		#BANNER_TYPE.TALL:
			#$Banner02.visible = true
		#BANNER_TYPE.MEDIUM:
			#$Banner03.visible = true
	$Picture.mesh.size = size * banner_scale
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
