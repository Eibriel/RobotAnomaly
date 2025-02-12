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
	$Picture.mesh.material = mat

func _process(_delta: float) -> void:
	if not dirty: return
	#match banner:
		#BANNER_TYPE.SMALL:
			#$Banner01.visible = true
		#BANNER_TYPE.TALL:
			#$Banner02.visible = true
		#BANNER_TYPE.MEDIUM:
			#$Banner03.visible = true
	$Picture.mesh.size = size
	if texture:
		mat.albedo_texture = texture
