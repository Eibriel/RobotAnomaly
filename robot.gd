#@tool
class_name Robot
extends Node3D

signal anomaly_failed
signal executive_finished

@export var glitch: GLITCHES = GLITCHES.NONE
@export var pose: POSES = POSES.NONE
@export var stalk_player: STALK
@export var sometimes_missing: bool

enum STALK {
	DISABLED,
	FOLLOW,
	SHOWUP
}

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
	#CRYING,
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

enum POSES {
	NONE,
	CLAPPING,
	SITTING
}

#var is_glitching := false
#var is_glitch_visible := false
var robot_id := 0
#var is_battery_loaded := true
var battery_charge := 0.0
var power_on := true
var glitch_executed := false
var glitch_dirty := true
var looking_player := false
var pose_dirty := true
var base_visible := true
var block_id := 0
var shutdown_time := 1.0

var snap_countdown := 0.0
var snap_rate := 2.0
var stalk_completed := false
var anim_camera_weight := 0.0

var is_demo := false
var is_event := false

var tween: Tween

#@onready var glitch_label := $GlitchLabel

var robj: Dictionary
var anim: AnimationPlayer
var skeleton: Skeleton3D

func _ready() -> void:
	#skeleton = %robotObject.get_node("Armature/Skeleton3D") as Skeleton3D
	#var battery_attachment := BoneAttachment3D.new()
	#battery_attachment.bone_name = "chest"
	#skeleton.add_child(battery_attachment)
	%robotObject.get_node("Armature/Skeleton3D/Battery_Attachment/Battery_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment/ShutDown_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/Camera_Attachment/Camera_Attachment").visible = false
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
	robj["arm"] = %robotObject.get_node("Armature/Skeleton3D/arm_L")
	
	#prints("GC", GLITCHES.size())
	%RobotBase.rotate_y(deg_to_rad(randf_range(0, 360)))
	if randf() < 0.5:
		%RobotBase/robot_base.get_node("ConcretePillar_A").visible = false
	else:
		%RobotBase/robot_base.get_node("ConcretePillar_B").visible = false
	
	skeleton = %robotObject.get_node("Armature/Skeleton3D") as Skeleton3D
	
	anim = %robotObject.get_node("AnimationPlayer") as AnimationPlayer
	anim.get_animation("Vibrating").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Rocking").loop_mode = Animation.LOOP_LINEAR
	#anim.get_animation("Timer").loop_mode = Animation.LOOP_LINEAR
	#anim.play("TouchingFace")
	
	var motor_sound_delay := create_tween()
	motor_sound_delay.tween_interval(randf()*2)
	motor_sound_delay.tween_callback(%RobotMotorAudioPlayer.play)

func rotate_base(delta: float, reverse:=false) -> void:
	return
	if not base_visible: return
	if glitch == GLITCHES.WALKS_NOT_LOOKING: return
	if glitch == GLITCHES.BLOCKING_PATH: return
	#%robotObject.rotate_y(deg_to_rad(120) * delta)
	if reverse:
		%RobotBody.rotate_y(deg_to_rad(-120) * delta)
	else:
		%RobotBody.rotate_y(deg_to_rad(120) * delta)

func robot_rotation(angle: float) -> void:
	%RobotBody.rotation.y = angle

func robot_position(pos: Vector3) -> void:
	%RobotBody.position = pos
	%RobotBase.position = pos
	update_base()

func play_animation(anim_name: String) -> void:
	anim.play(anim_name)

func charge_battery(delta: float) -> void:
	if not power_on: return
	if is_demo or is_event: return
	var prev_level = battery_charge
	battery_charge += delta * 14.0
	battery_charge = minf(battery_charge, 100.0)
	if prev_level != battery_charge and battery_charge >= 100.0:
		%RobotBatteryAudioPlayer.play()

func shutdown(delta: float) -> bool:
	if is_demo or is_event: return false
	if power_on:
		shutdown_time -= delta * 0.4
		if shutdown_time <= 0.0:
			shut_down()
			return true
	else:
		shutdown_time += delta * 0.4
		if shutdown_time >= 1.0:
			turn_on()
			return true
	return false

func _process(delta: float) -> void:
	if power_on:
		shutdown_time += delta * 0.1
		shutdown_time = min(shutdown_time, 1.0)
	%GlitchLabel.text = "%s" % GLITCHES.find_key(glitch)
	%IdLabel.text = "R%d" % robot_id
	%BatteryLabel.text = "%d%%" % battery_charge
	%BatteryRadialProgress.value = battery_charge
	%PowerRadialProgress.value = shutdown_time * 100.0
	if int(battery_charge) == 100:
		%BatteryIndicator.material = preload("res://materials/prototype_green_mat.tres")
	else:
		%BatteryIndicator.material = preload("res://materials/prototype_red_mat.tres")
	#
	var battery_bone := %robotObject.get_node("Armature/Skeleton3D/Battery_Attachment") as BoneAttachment3D
	var shutdown_bone := %robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment") as BoneAttachment3D
	var camera_bone := %robotObject.get_node("Armature/Skeleton3D/Camera_Attachment") as BoneAttachment3D
	%BatteryNode.global_position = battery_bone.global_position
	%BatteryNode.global_rotation = battery_bone.global_rotation
	%ShutdownNode.global_position = shutdown_bone.global_position
	%ShutdownNode.global_rotation = shutdown_bone.global_rotation
	var anim_cam_pos := camera_bone.global_position
	var anim_cam_rot := camera_bone.global_rotation
	var player_cam_pos: Vector3 = Global.player.get_camera().global_position
	var player_cam_rot: Vector3 = Global.player.get_camera().global_rotation
	%CameraNode.global_position = lerp(player_cam_pos, anim_cam_pos, anim_camera_weight)
	%CameraNode.global_rotation.x = lerp_angle(player_cam_rot.x, anim_cam_rot.x, anim_camera_weight)
	%CameraNode.global_rotation.y = lerp_angle(player_cam_rot.y, anim_cam_rot.y, anim_camera_weight)
	%CameraNode.global_rotation.z = lerp_angle(player_cam_rot.z, anim_cam_rot.z, anim_camera_weight)
	
	update_snap(delta)
	follow_head(delta)
	update_glitch()
	update_pose()
	update_base()
	update_follow(delta)
	update_blocking_path()
	update_door_open()
	update_stalk()

func update_stalk() -> void:
	if stalk_player == STALK.DISABLED: return
	if stalk_completed: return
	remove_base()
	for c:CollisionShape3D in %RobotStaticBody.get_children():
		c.disabled = true
	var player_pos: Vector3= Global.player.global_position
	match stalk_player:
		STALK.FOLLOW:
			var rotation_vector := Vector3.FORWARD.rotated(Vector3.UP, Global.player.rotation.y)*2
			#rotation_vector += Global.player.global_rotation.y
			#robot_position(player_pos - rotation_vector)
			%RobotBody.global_position = player_pos - rotation_vector
		STALK.SHOWUP:
			if not %VisibleOnScreenNotifier3D2.is_on_screen():
				robot_rotation(deg_to_rad(180))
				#robot_position(player_pos - Vector3(0, 0, -0.5))
				%RobotBody.global_position = player_pos - Vector3(0, 0, -0.5)
			else:
				stalk_completed = true
				grab_player()

func grab_player() -> void:
	var cam := get_viewport().get_camera_3d()
	%CameraRobot.keep_aspect = cam.keep_aspect
	%CameraRobot.fov = cam.fov
	#%CameraRobot.global_transform = cam.global_transform
	#%CameraNode.global_transform = cam.global_transform
	var cam_tween := create_tween()
	cam_tween.tween_property(self, "anim_camera_weight", 1.0, 0.2)
	%CameraRobot.current = true
	if not anim.is_playing():
		anim.play("AttackExec")
		Global.player.rumble(0.1)
		anim.connect("animation_finished", _on_attack_anim_finished)

func _on_attack_anim_finished(anim_name: String) -> void:
	if anim_name == "AttackExec":
		executive_finished.emit()

func update_door_open() -> void:
	if glitch != GLITCHES.DOOR_OPEN: return
	if is_demo: return
	var player_pos := Global.player.global_position
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	var dist := robot_pos.distance_to(player_pos)
	if dist < 10.0:
		anomaly_failed.emit()
	if dist < 13.0:
		Global.player.rumble(0.1)

func update_blocking_path() -> void:
	if glitch != GLITCHES.BLOCKING_PATH: return
	if is_demo: return
	if not power_on: return
	var player_pos := Global.player.global_position
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	if robot_pos.distance_to(player_pos) < 1.0:
		anomaly_failed.emit()
	var dist := robot_pos.distance_to(player_pos)
	if dist < 2.0:
		Global.player.rumble(0.1)

func update_follow(delta: float) -> void:
	if glitch != GLITCHES.WALKS_NOT_LOOKING:
		return
	if is_demo: return
	var player_pos := to_local(Global.player.global_position)
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	if not is_on_screen() and Global.is_player_in_room and power_on:
		var player_pos_2d := Vector2(player_pos.x, player_pos.z)
		var robot_pos_2d := Vector2(robot_pos.x, robot_pos.z)
		var angle := robot_pos_2d.angle_to_point(player_pos_2d)
		
		var dir_to_player := (player_pos - robot_pos).normalized()
		var player_pos_short := robot_pos + dir_to_player
		
		var new_intersection := PhysicsRayQueryParameters3D.create(robot_pos, player_pos_short, 1<<1)
		var intersection := get_world_3d().direct_space_state.intersect_ray(new_intersection)
		
		if not intersection.is_empty():
			%RobotStepsAudioPlayer.stop()
			return
		else:
			Global.player.rumble()
			if not %RobotStepsAudioPlayer.playing:
				%RobotStepsAudioPlayer.play()
		
		%RobotBody.position += dir_to_player * delta * 2.0
		%RobotBody.rotation.y = -angle + deg_to_rad(90)
		#print(robot_pos.distance_to(player_pos))
		if robot_pos.distance_to(player_pos) < 2.0:
			anomaly_failed.emit()
	else:
		%RobotStepsAudioPlayer.stop()
	
	if robot_pos.distance_to(player_pos) < 1.0:
		Global.player.rumble(0.1)

func update_base() -> void:
	$BaseShadowPlane.position = %RobotBase.position
	$BaseShadowPlane.position.y = 0.01

func update_snap(delta: float) -> void:
	if glitch != GLITCHES.COUNTDOWN: return
	if not power_on: return
	if Global.is_player_in_room:
		snap_countdown += delta
	if snap_countdown >= snap_rate:
		snap_countdown = 0.0
		if not is_demo:
			snap_rate *=  0.90
		if snap_rate < 0.1:
			snap_rate = 0.1
			anomaly_failed.emit()
		var speed := 1.0
		if snap_rate < anim.get_animation("Timer").length:
			speed = anim.get_animation("Timer").length / snap_rate
		anim.play("Timer", -1, speed)
		if not is_demo:
			%RobotAudioPlayer.play()
			Global.player.rumble(0.5*speed)
		#prints("Snap!", snap_rate, speed)

func set_glitch(new_glitch: GLITCHES, _is_demo := false) -> void:
	if new_glitch == glitch: return
	glitch_dirty = true
	glitch = new_glitch
	is_demo = _is_demo
	if is_demo:
		silence_motor()

func silence_motor() -> void:
	%RobotMotorAudioPlayer.volume_db = -60

func set_pose(new_pose: POSES) -> void:
	if new_pose == pose: return
	pose_dirty = true
	pose = new_pose

func update_pose() -> void:
	if not pose_dirty: return
	pose_dirty = false
	
	match pose:
		POSES.CLAPPING:
			anim.play("Clapping")
			%RobotClappingAudioPlayer.play(randf()*2)
		POSES.SITTING:
			anim.play("ExecutiveSitting")

func update_glitch() -> void:
	if not glitch_dirty: return
	glitch_dirty = false
	#
	robj["antena_l"].visible = true
	robj["eye_left"].visible = true
	robj["antena_base_l"].visible = true
	robj["arm"].visible = true
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
			robj["arm"].visible = false
		GLITCHES.CHEST_CONNECTION:
			robj["chest_connection"].visible = true
		GLITCHES.CLOCK_HEART:
			robj["clock_heart"].visible = true
		GLITCHES.WRIST_SCARF:
			robj["scarf"].visible = true
		GLITCHES.RED_EYES:
			robj["red_eyes"].visible = true
		GLITCHES.FOLLOWING_EYES:
			#robj["red_eyes"].visible = true
			looking_player = true
		#GLITCHES.SMILING:
		#	robj["red_eyes"].visible = true
		GLITCHES.GIGGLING:
			#robj["red_eyes"].visible = true
			anim.play("Laughter")
			if not is_demo:
				%RobotLaughAudioPlayer.play()
		#GLITCHES.CRYING:
		#	robj["red_eyes"].visible = true
		GLITCHES.LOOKING_HAND:
			anim.play("LookingHand")
		GLITCHES.TOUCHING_FACE:
			anim.play("TouchingFace")
		GLITCHES.POINTING_FINGER:
			#robj["red_eyes"].visible = true
			anim.play("PointingFinger")
		GLITCHES.KNIFE_HAND:
			robj["knife"].visible = true
		GLITCHES.ROCKING:
			anim.play("Rocking")
		GLITCHES.SHAKING:
			anim.play("Vibrating")
		GLITCHES.BLINKING_EYES:
			robj["red_eyes"].visible = true
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				tween.tween_interval(0.15)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(1.5)
		GLITCHES.PROCESSING:
			robj["red_eyes"].visible = true
			if not tween:
				tween = create_tween()
				tween.set_loops()
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(0.1)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				tween.tween_interval(0.12)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(0.2)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				tween.tween_interval(0.22)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				tween.tween_interval(0.12)
				tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				tween.tween_interval(0.09)
		GLITCHES.FACING_WRONG_DIRECTION:
			%RobotBody.rotation.y = deg_to_rad(0+randi_range(-10, 10))
		GLITCHES.MISSING_EYE:
			robj["eye_left"].visible = false
		GLITCHES.MISSING_ENTIRELY:
			%RobotBody.position = Vector3.ZERO
			%RobotBody.position.y = -20
		GLITCHES.DRIPPING_OIL:
			setup_oil_dripping()
		GLITCHES.GRAFFITY:
			setup_graffity()
		GLITCHES.BLOCKING_PATH:
			# TODO fix position (global, local)
			%RobotBody.position = Vector3.ZERO
			%RobotBody.rotation = Vector3.ZERO
			match block_id:
				0:
					%RobotBody.position.x = 0.28
					anim.play("HoldingHands_B")
				1:
					%RobotBody.position.x = -0.28
					anim.play("HoldingHands_A")
		GLITCHES.COUNTDOWN:
			%RobotBody.position = Vector3(0.8, 0, 0)
			%RobotBody.rotation.y = deg_to_rad(-45)
			anim.play("Timer")
		GLITCHES.DOOR_OPEN:
			%RobotBody.position = Vector3(-15, 0, 0)
			%RobotBody.rotation.y = deg_to_rad(90)
		GLITCHES.WALKS_NOT_LOOKING:
			%RobotBody.position = Vector3.ZERO
			%RobotBody.rotation.y = deg_to_rad(0)
		GLITCHES.EXTRA_ROBOTS:
			if not is_demo:
				var pos := %RobotBody.position as Vector3
				pos.x += randf() * 0.2
				pos.y = 0.2
				pos.z += randf() * 0.2
				robot_position(pos)

#func remove_glitch():
	##is_glitching = false
	##is_glitch_visible = false
	#glitch = GLITCHES.NONE
	#anim.pause()

func remove_base() -> void:
	%RobotBase.visible = false
	$BaseShadowPlane.visible = false
	base_visible = false
	for c:CollisionShape3D in %RobotBaseStaticBody.get_children():
		c.set_deferred("disabled", true)

func disable_colliders() -> void:
	for c:CollisionShape3D in %RobotBaseStaticBody.get_children():
		c.disabled = true
	for c:CollisionShape3D in %RobotStaticBody.get_children():
		c.disabled = true

func follow_head(_delta: float) -> void:
	var head_id := skeleton.find_bone("head")
	if not looking_player or not power_on:
		skeleton.clear_bones_global_pose_override()
		return
	var pos := skeleton.get_bone_global_pose(head_id).origin
	var player_eyes := Global.player.global_position + Vector3(0, 1.7, 0)
	
	var player_pos := Global.player.global_position
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	
	var local_player_pos := %RobotBody.to_local(player_pos) as Vector3
	
	var player_pos_2d := Vector2(local_player_pos.x, local_player_pos.z)
	#var robot_pos_2d := Vector2(robot_pos.x, robot_pos.z)
	#var angle: float = robot_pos_2d.angle_to_point(player_pos_2d) + %RobotBody.rotation.y
	var angle: float = Vector2.ZERO.angle_to_point(player_pos_2d) + %RobotBody.rotation.y
	var local_angle:float = angle - %RobotBody.rotation.y
	#if angle > PI*2:
		#angle -= PI
	#elif angle < 0:
		#angle += PI
	#print(local_angle)
	if local_angle > 0.1 and local_angle < 3.0:
		bone_look_at(head_id, pos, skeleton.to_local(player_eyes))


func bone_look_at(bone_index:int, bone_global_position:Vector3, target_global_position:Vector3, lerp_amount:float = 1.0):
	var bone_transform = skeleton.get_bone_global_pose_no_override(bone_index)
	#var bone_origin = bone_global_position
	bone_transform.basis = bone_transform.basis.looking_at( -(target_global_position - bone_global_position).normalized())
	bone_transform.origin = bone_global_position
	skeleton.set_bone_global_pose_override(bone_index, bone_transform, lerp_amount, true)

func setup_graffity() -> void:
	add_detail(%robotObject, preload("res://objects/details/robot_graffity.png"))

func setup_oil_dripping() -> void:
	add_detail(%robotObject, preload("res://objects/details/oil_dripping.png"))

func add_detail(rnode: Node, detail_texture) -> void:
	for c in rnode.get_children(true):
		if c is MeshInstance3D:
			var mesh = c.mesh.duplicate()
			c.mesh = mesh
			for s in c.mesh.get_surface_count():
				var mat := c.mesh.surface_get_material(s) as StandardMaterial3D
				# TODO reuse materials
				# Todo only apply on arms
				mat = mat.duplicate(true)
				mat.detail_enabled = true
				mat.detail_mask = detail_texture
				c.mesh.surface_set_material(s, mat)
		add_detail(c, detail_texture)

func shut_down() -> void:
	%RobotShutdownAudioPlayer.play()
	power_on = false
	anim.play("Shut_Down", 1.0)
	var shut_down_tween := create_tween()
	shut_down_tween.tween_property(%RobotLaughAudioPlayer, "pitch_scale", 0.2, 3)
	shut_down_tween.tween_callback(%RobotLaughAudioPlayer.stop)
	shut_down_tween.tween_callback(turn_off_glitches)
	#%RobotLaughAudioPlayer.stop()ss
	%RobotMotorAudioPlayer["parameters/switch_to_clip"] = "Off"

func turn_on() -> void:
	power_on = true
	anim.play("Idle", 1.0)
	#var shut_down_tween := create_tween()
	#shut_down_tween.tween_property(%RobotLaughAudioPlayer, "pitch_scale", 0.2, 3)
	#shut_down_tween.tween_callback(%RobotLaughAudioPlayer.stop)
	#shut_down_tween.tween_callback(turn_off_glitches)
	#%RobotLaughAudioPlayer.stop()ss
	%RobotMotorAudioPlayer["parameters/switch_to_clip"] = "Working"

func turn_off_glitches() -> void:
	robj["red_eyes"].visible = false

func grab_battery() -> void:
	if glitch_executed:
		anomaly_failed.emit()
		return
	glitch_executed = true
	anim.play("GrabsBattery")
	Global.player.rumble(0.1)
	# TODO add looking_player
	# when it's fixed
	#looking_player = true

func poke() -> void:
	#$Glitch.visible = is_glitching
	pass

func set_id(id: int) -> void:
	robot_id = id

func is_on_screen() -> bool:
	return %VisibleOnScreenNotifier3D.is_on_screen()
