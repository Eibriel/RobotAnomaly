#@tool
class_name Robot
extends Node3D

@export var glitch: GLITCHES
@export var force_glitch: bool
@export var sometimes_missing: bool

enum GLITCHES {
	NONE,
	
	BROKEN_ANTENA,
	TELESCOPIC_EYES,
	DOUNLE_ANTENA,
	CHEST_CONNECTION,
	OCTOPUS,
	KNIFE_HAND,
	LONG_ANTENA,
	SPIDER,
	TENTACLE_ARM,
	MISSING_EYE,
	CLOCK_HEART,
	HEAD_BOX,
	BACK_BOX,
	WRIST_SCARF,
	EYES_AROUND_HEAD,
	LONG_FINGERS,
	BRAIN_EXTENSION,
	
	RED_EYES,
	FOLLOWING_EYES,
	POINTING_FINGER,
#	SMILING,
	GIGGLING,
	CRYING,
	ROCKING, #(MOVING_LIKE_PENDULUM)
	LOOKING_HAND,
	TOUCHING_FACE,
	MISSING_ENTIRELY,
	BLINKING_EYES,
	SHAKING,
	PROCESSING, #(BLINKING_LIGHTS)
	FACING_WRONG_DIRECTION,
	EXTRA_EYE,
	GRAFFITY,
	DRIPPING_OIL,
	EXTRA_ROBOTS,
	
	# ATTACKS
	BLOCKING_PATH,
	GRABS_BATTERY,
	WALKS_NOT_LOOKING,
	DOOR_OPEN,
	COUNTDOWN, #DROPS FROM CEILING
	LIGHTS_OFF
}

#var is_glitching := false
#var is_glitch_visible := false
var robot_id := 0

#var is_battery_loaded := true
var battery_charge := 0

var power_on := true

var tween: Tween
#var skeleton: Skeleton3D
	
#@onready var glitch_label := $GlitchLabel

var robj: Dictionary

func _ready() -> void:
	#skeleton = %robotObject.get_node("Armature/Skeleton3D") as Skeleton3D
	#var battery_attachment := BoneAttachment3D.new()
	#battery_attachment.bone_name = "chest"
	#skeleton.add_child(battery_attachment)
	%robotObject.get_node("Armature/Skeleton3D/Battery_Attachment/Battery_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment/ShutDown_Attachment").visible = false
	#if OS.has_feature("debug"):
	#	$GlitchLabel.visible = false
	robj["octopus"] = %robotObject.get_node("Armature/Skeleton3D/BackTentacles")
	robj["spider"] = %robotObject.get_node("Armature/Skeleton3D/BackSpider")
	robj["extra_eye"] = %robotObject.get_node("Armature/Skeleton3D/EyeExtra")
	robj["eyes_around"] = %robotObject.get_node("Armature/Skeleton3D/EyesAround")
	robj["head_box"] = %robotObject.get_node("Armature/Skeleton3D/HeadBox")
	robj["antena_l"] = %robotObject.get_node("Armature/Skeleton3D/Antena_L")
	robj["antena_base_l"] = %robotObject.get_node("Armature/Skeleton3D/AntenaBase_L")
	robj["antena_r"] = %robotObject.get_node("Armature/Skeleton3D/Antena_R")
	robj["antena_base_r"] = %robotObject.get_node("Armature/Skeleton3D/AntenaBase_R")
	robj["tentacle"] = %robotObject.get_node("Armature/Skeleton3D/Tentacle")
	robj["chest_connection"] = %robotObject.get_node("Armature/Skeleton3D/ChestConnection")
	robj["clock_heart"] = %robotObject.get_node("Armature/Skeleton3D/ClockHearth")
	robj["scarf"] = %robotObject.get_node("Armature/Skeleton3D/Scarf")
	robj["telescopic_eye"] = %robotObject.get_node("Armature/Skeleton3D/EyeTelescopic")
	robj["brain_extension"] = %robotObject.get_node("Armature/Skeleton3D/BrainExtension")
	robj["long_antena"] = %robotObject.get_node("Armature/Skeleton3D/AntenaLong_L")
	robj["red_eyes"] = %robotObject.get_node("Armature/Skeleton3D/RedEyes")
	robj["back_box"] = %robotObject.get_node("Armature/Skeleton3D/BackBox")
	robj["eye_left"] = %robotObject.get_node("Armature/Skeleton3D/Eye_L")
	robj["long_fingers"] = %robotObject.get_node("Armature/Skeleton3D/LongFingers_R")
	robj["knife"] = %robotObject.get_node("Armature/Skeleton3D/Knife")
	
	#prints("GC", GLITCHES.size())

func rotate_base(delta: float) -> void:
	%robotObject.rotate_y(deg_to_rad(80) * delta)

func _process(_delta: float) -> void:
	%GlitchLabel.text = "%s" % GLITCHES.find_key(glitch)
	%IdLabel.text = "R%d" % robot_id
	%BatteryLabel.text = "%d%%" % battery_charge
	if int(battery_charge) == 100:
		%BatteryIndicator.material = preload("res://materials/prototype_green_mat.tres")
	else:
		%BatteryIndicator.material = preload("res://materials/prototype_red_mat.tres")
	#
	var battery_bone := %robotObject.get_node("Armature/Skeleton3D/Battery_Attachment") as BoneAttachment3D
	var shutdown_bone := %robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment") as BoneAttachment3D
	%BatteryNode.global_position = battery_bone.global_position
	%BatteryNode.global_rotation = battery_bone.global_rotation
	%ShutdownNode.global_position = shutdown_bone.global_position
	%ShutdownNode.global_rotation = shutdown_bone.global_rotation
	#
	robj["antena_l"].visible = true
	robj["eye_left"].visible = true
	robj["antena_base_l"].visible = true
	#
	robj["octopus"].visible = false
	robj["spider"].visible = false
	robj["extra_eye"].visible = false
	robj["eyes_around"].visible = false
	robj["head_box"].visible = false
	robj["antena_r"].visible = false
	robj["antena_base_r"].visible = false
	robj["tentacle"].visible = false
	robj["chest_connection"].visible = false
	robj["clock_heart"].visible = false
	robj["scarf"].visible = false
	robj["telescopic_eye"].visible = false
	robj["brain_extension"].visible = false
	robj["long_antena"].visible = false
	robj["red_eyes"].visible = false
	robj["back_box"].visible = false
	robj["long_fingers"].visible = false
	robj["knife"].visible = false
	#
	if glitch == GLITCHES.NONE:
		if tween and tween.is_valid():
			tween.stop()
	match glitch:
		GLITCHES.DOUNLE_ANTENA:
			robj["antena_r"].visible = true
			robj["antena_base_r"].visible = true
		GLITCHES.BROKEN_ANTENA:
			robj["antena_l"].visible = false
			robj["antena_base_l"].visible = false
		GLITCHES.EXTRA_EYE:
			robj["extra_eye"].visible = true
		GLITCHES.EYES_AROUND_HEAD:
			robj["eyes_around"].visible = true
		GLITCHES.SPIDER:
			robj["spider"].visible = true
		GLITCHES.OCTOPUS:
			robj["octopus"].visible = true
		GLITCHES.HEAD_BOX:
			robj["head_box"].visible = true
		GLITCHES.BACK_BOX:
			robj["back_box"].visible = true
		GLITCHES.TELESCOPIC_EYES:
			robj["telescopic_eye"].visible = true
		GLITCHES.BRAIN_EXTENSION:
			robj["brain_extension"].visible = true
		GLITCHES.LONG_ANTENA:
			robj["long_antena"].visible = true
		GLITCHES.LONG_FINGERS:
			robj["long_fingers"].visible = true
		GLITCHES.TENTACLE_ARM:
			robj["tentacle"].visible = true
		GLITCHES.CHEST_CONNECTION:
			robj["chest_connection"].visible = true
		GLITCHES.CLOCK_HEART:
			robj["clock_heart"].visible = true
		GLITCHES.WRIST_SCARF:
			robj["scarf"].visible = true
		GLITCHES.RED_EYES:
			robj["red_eyes"].visible = true
		GLITCHES.FOLLOWING_EYES:
			robj["red_eyes"].visible = true
		#GLITCHES.SMILING:
		#	robj["red_eyes"].visible = true
		GLITCHES.GIGGLING:
			robj["red_eyes"].visible = true
		GLITCHES.CRYING:
			robj["red_eyes"].visible = true
		GLITCHES.LOOKING_HAND:
			robj["red_eyes"].visible = true
		GLITCHES.TOUCHING_FACE:
			robj["red_eyes"].visible = true
		GLITCHES.POINTING_FINGER:
			robj["red_eyes"].visible = true
		GLITCHES.KNIFE_HAND:
			robj["knife"].visible = true
		GLITCHES.ROCKING:
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_property(%RobotBody, "position:x", 0.1, 0.1)
				tween.tween_property(%RobotBody, "position:x", 0, 0.1)
		GLITCHES.SHAKING:
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_property(%RobotBody, "position:x", 0.05, 0.05)
				tween.tween_property(%RobotBody, "position:x", -0.05, 0.05)
		GLITCHES.BLINKING_EYES:
			robj["red_eyes"].visible = true
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				tween.tween_interval(0.8)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(3.0)
		GLITCHES.PROCESSING:
			robj["red_eyes"].visible = true
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(0.2)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
		GLITCHES.FACING_WRONG_DIRECTION:
			%RobotBody.rotation.y = deg_to_rad(80)
		GLITCHES.MISSING_EYE:
			robj["eye_left"].visible = false
		GLITCHES.MISSING_ENTIRELY:
			%RobotBody.global_position = Vector3.ZERO
		GLITCHES.DRIPPING_OIL:
			robj["red_eyes"].visible = true
		GLITCHES.GRAFFITY:
			robj["knife"].visible = true
		GLITCHES.BLOCKING_PATH:
			%RobotBody.global_position = Vector3.ZERO
		GLITCHES.COUNTDOWN:
			%RobotBody.global_position = Vector3.ZERO
		GLITCHES.DOOR_OPEN:
			%RobotBody.global_position = Vector3.ZERO
		GLITCHES.WALKS_NOT_LOOKING:
			%RobotBody.global_position = Vector3.ZERO

func remove_glitch():
	#is_glitching = false
	#is_glitch_visible = false
	glitch = GLITCHES.NONE

func shut_down():
	power_on = false
	var anim := %robotObject.get_node("AnimationPlayer") as AnimationPlayer
	anim.play("Shut_Down")

func poke():
	#$Glitch.visible = is_glitching
	pass

func set_id(id: int) -> void:
	robot_id = id

func is_on_screen() -> bool:
	return $VisibleOnScreenNotifier3D.is_on_screen()
