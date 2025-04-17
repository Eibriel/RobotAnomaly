extends Node3D

@export var pose: POSES = POSES.NONE
@export var body: BODY = BODY.ROBOT


enum POSES {
	NONE,
	TAPPING_SIGN,
	SHUTDOWN,
	SITDOWN,
	LAYING_DOWN
}

enum BODY {
	CEO,
	ROBOT
}

var MIKE_ALGER_CLOTHES = preload("res://materials/ceo/MikeAlger_Clothes.tres")
var MIKE_ALGER_HAIR = preload("res://materials/ceo/MikeAlger_Hair.tres")
var MIKE_ALGER_SKIN = preload("res://materials/ceo/MikeAlger_Skin.tres")

func _ready() -> void:
	$robot_male/AnimationPlayer.get_animation("TappingSign").loop_mode = Animation.LOOP_LINEAR
	
	match body:
		BODY.ROBOT:
			$CEO.visible = false
		BODY.CEO:
			$robot_male.visible = false
	
	match pose:
		POSES.TAPPING_SIGN:
			$robot_male/AnimationPlayer.play("TappingSign")
		POSES.SHUTDOWN:
			$robot_male/AnimationPlayer.play("Shutdown")
		POSES.SITDOWN:
			$robot_male/AnimationPlayer.play("Sitdown")
			$CEO/AnimationPlayer.play("Sitdown")
		POSES.LAYING_DOWN:
			$robot_male/AnimationPlayer.play("LayingDown")
			$CEO/AnimationPlayer.play("Dead")
		_:
			$robot_male/AnimationPlayer.play("Idle")
			$CEO/AnimationPlayer.play("Standing")

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	var cam := get_viewport().get_camera_3d()
	var dist := global_position.distance_to(cam.global_position)
	
	var black_weight := clampf(remap(dist, 30, 32, 0.0, 1.0), 0.0, 1.0)
	var mat_albedo:Color = lerp(Color.BLACK, Color.WHITE, black_weight)
	MIKE_ALGER_CLOTHES.albedo_color = mat_albedo
	MIKE_ALGER_HAIR.albedo_color = mat_albedo
	MIKE_ALGER_SKIN.albedo_color = mat_albedo
	
	#var scale_weight := smoothstep(0.8, 1.1, clampf(remap(dist, 28, 30, 0.0, 1.0), 1.0, 0.0))
	var scale_weight := clampf(remap(dist, 28, 30, 0.9, 1.1), 0.0, 1.0)
	$CEO.scale = Vector3.ONE * scale_weight
	
	if dist > 30:
		match body:
			BODY.ROBOT:
				$robot_male.visible = false
				$CEO.visible = true
			BODY.CEO:
				$CEO.visible = false
				$robot_male.visible = true
	elif dist > 28:
		match body:
			BODY.ROBOT:
				$CEO.visible = true
				$robot_male.visible = true
			BODY.CEO:
				$CEO.visible = true
				$robot_male.visible = true
	else:
		match body:
			BODY.ROBOT:
				$CEO.visible = false
				$robot_male.visible = true
			BODY.CEO:
				$CEO.visible = true
				$robot_male.visible = false
