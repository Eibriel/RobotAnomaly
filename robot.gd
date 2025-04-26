#@tool
class_name Robot
extends Node3D

signal anomaly_failed
#signal executive_finished

@export var glitch: GLITCHES = GLITCHES.NONE
@export var pose: POSES = POSES.NONE
@export var stalk_player: STALK
@export var sometimes_missing: bool
@export var is_event := false
@export var force_no_battery := false
@export var hide_base := false
@export var lock_buttons := false
@export var lock_shutdown_button := false
@export var battery_charge := 0.0
@export var looking_player := false
@export var cast_shadows := true
@export var red_eyes := false
@export var strugle := false

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
	#BACK_BOX,
	#WRIST_SCARF,
	EYES_AROUND_HEAD,
	LONG_FINGERS,
	BRAIN_EXTENSION,
	
	#RED_EYES,
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
	#PROCESSING, #(BLINKING_LIGHTS)
	FACING_WRONG_DIRECTION,
	EXTRA_EYE,
	GRAFFITY,
	#DRIPPING_OIL,
	EXTRA_ROBOTS,
	
	# ATTACKS
	BLOCKING_PATH,
	GRABS_BATTERY,
	WALKS_NOT_LOOKING,
	DOOR_OPEN,
	COUNTDOWN, #DROPS FROM CEILING
	#LIGHTS_OFF
}

enum POSES {
	NONE,
	CLAPPING,
	SITTING,
	SITTING_BODY,
	HOLDING_VACUUM,
	HOLDING_VACUUM_B,
	RUNNING,
	HOLDING_BRAIN,
	LOOKING_DOWN
}

#var is_glitching := false
#var is_glitch_visible := false
var robot_id := 0
#var is_battery_loaded := true
#var battery_charge := 0.0
var power_on := true
var glitch_executed := false
var glitch_dirty := true
var pose_dirty := true
var base_visible := true
var block_id := 0
var shutdown_time := 1.0
var recharge_cooldown := 0.0
var neck_rotation_y := 0.0

var snap_countdown := 0.0
var snap_rate := 2.0
var snap_completed := false
var stalk_completed := false
var follow_completed := false
var anim_camera_weight := 0.0
var strugle_seek := 0.0
var follows_player_speed := 0.0

var is_demo := false

var tween: Tween

#@onready var glitch_label := $GlitchLabel

var robj: Dictionary
var anim: AnimationPlayer
var skeleton: Skeleton3D

var pressing_off_button := 0.0

const ROBOT_BASEB_MATERIAL = preload("res://materials/robot_mats/Robot_BaseB_Material.tres")

func _ready() -> void:
	#skeleton = %robotObject.get_node("Armature/Skeleton3D") as Skeleton3D
	#var battery_attachment := BoneAttachment3D.new()
	#battery_attachment.bone_name = "chest"
	#skeleton.add_child(battery_attachment)
	%robotObject.get_node("Armature/Skeleton3D/Battery_Attachment/Battery_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment/ShutDown_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/Camera_Attachment/Camera_Attachment").visible = false
	%robotObject.get_node("Armature/Skeleton3D/Head_Attachment/Head_Attachment").visible = false
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
	robj["red_eyes"] = %robotObject.get_node("Armature/Skeleton3D/RedEyes/RedEyes")
	robj["white_eyes"] = %robotObject.get_node("Armature/Skeleton3D/WhiteEyes/WhiteEyes")
	robj["back_box"] = %robotObject.get_node("Armature/Skeleton3D/BackBox")
	robj["eye_left"] = %robotObject.get_node("Armature/Skeleton3D/Eye_L")
	robj["long_fingers"] = %robotObject.get_node("Armature/Skeleton3D/LongFingers_R")
	robj["knife"] = %robotObject.get_node("Armature/Skeleton3D/Knife")
	robj["arm"] = %robotObject.get_node("Armature/Skeleton3D/arm_L")
	robj["battery_radial"] = %robotObject.get_node("Armature/Skeleton3D/Battery_RadialProgress/Battery_RadialProgress")
	robj["battery_body"] = %robotObject.get_node("Armature/Skeleton3D/BatteryBody/BatteryBody")
	robj["power_radial"] = %robotObject.get_node("Armature/Skeleton3D/OffButton_RadialProgress/OffButton_RadialProgress")
	robj["off_button"] = %robotObject.get_node("Armature/Skeleton3D/OffButton/OffButton")
	robj["off_button_base"] = %robotObject.get_node("Armature/Skeleton3D/OffButtonBase/OffButtonBase")
	#
	robj["bw_head"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_Head")
	robj["bw_chest"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_Chest")
	robj["bw_waist"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_Waist")
	robj["bw_forearm_l"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_ForeArm_L")
	robj["bw_forearm_r"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_ForeArm_R")
	robj["bw_upperarm_l"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_UpperArm_L")
	robj["bw_upperarm_r"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_UpperArm_R")
	robj["bw_leg_l"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_Leg_L")
	robj["bw_leg_r"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_Leg_R")
	robj["bw_legb_l"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_LegB_L")
	robj["bw_legb_r"] = %robotObject.get_node("Armature/Skeleton3D/BarbedWire_LegB_R")
	
	robj["off_button"].visible = false
	
	#prints("GC", GLITCHES.size())
	%RobotBase.rotate_y(deg_to_rad(randf_range(0, 360)))
	if randf() < 0.5:
		%RobotBase/robot_base.get_node("ConcretePillar_A").visible = false
	else:
		%RobotBase/robot_base.get_node("ConcretePillar_B").visible = false
	if randf() < 0.5:
		%RobotBaseB/robot_base2.get_node("ConcretePillar_A").visible = false
		%RobotBaseB/robot_base2.get_node("ConcretePillar_B").material_override = ROBOT_BASEB_MATERIAL
	else:
		%RobotBaseB/robot_base2.get_node("ConcretePillar_B").visible = false
		%RobotBaseB/robot_base2.get_node("ConcretePillar_A").material_override = ROBOT_BASEB_MATERIAL
	
	skeleton = %robotObject.get_node("Armature/Skeleton3D") as Skeleton3D
	
	anim = %robotObject.get_node("AnimationPlayer") as AnimationPlayer
	anim.get_animation("Vibrating").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Rocking").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Strugling").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Nails").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Arms").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Tentacle").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Spider").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Running").loop_mode = Animation.LOOP_LINEAR
	anim.get_animation("Walking").loop_mode = Animation.LOOP_LINEAR
	#anim.get_animation("RunningStairs").loop_mode = Animation.LOOP_LINEAR
	#anim.get_animation("Timer").loop_mode = Animation.LOOP_LINEAR
	#anim.play("TouchingFace")
	## NOTE this allows the head to point at player while
	## an animation is running, don't know why
	anim.process_thread_group = Node.PROCESS_THREAD_GROUP_MAIN_THREAD
	anim.process_thread_messages = true
	
	var motor_sound_delay := create_tween()
	motor_sound_delay.tween_interval(randf()*2)
	#motor_sound_delay.tween_callback(%RobotMotorAudioPlayer.play)
	
	const ROBOT_SITTINGBODY = preload("res://objects/robot_sittingbody.glb")
	var sit_anim := ROBOT_SITTINGBODY.get_animation("SittingBody")
	var global_library = anim.get_animation_library("")
	global_library.add_animation("SittingBody", sit_anim)
	
	if not cast_shadows:
		recursive_cast_shadows_off(%robotObject)
	
	# NOTE White Eyes are deprecated
	const ROBOT_FACE = preload("res://materials/robot_mats/Robot_face.tres")
	var white_eyes_mesh:Mesh = robj["white_eyes"].mesh as Mesh
	white_eyes_mesh.surface_set_material(0, ROBOT_FACE)
	robj["white_eyes"].visible = false
	
	if not is_event:
		robj["bw_head"].visible = false
		robj["bw_chest"].visible = false
		robj["bw_waist"].visible = false
		robj["bw_forearm_l"].visible = false
		robj["bw_forearm_r"].visible = false
		robj["bw_upperarm_l"].visible = false
		robj["bw_upperarm_r"].visible = false
		robj["bw_leg_l"].visible = false
		robj["bw_leg_r"].visible = false
		robj["bw_legb_l"].visible = false
		robj["bw_legb_r"].visible = false
	
	strugle_seek = randf_range(0, 2.0)

func recursive_cast_shadows_off(node) -> void:
	for c in node.get_children():
		if c is MeshInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		recursive_cast_shadows_off(c)

var rotation_sound_time := 0.0
func rotate_base(delta: float, reverse:=false) -> void:
	if not base_visible: return
	if glitch == GLITCHES.WALKS_NOT_LOOKING: return
	if glitch == GLITCHES.BLOCKING_PATH: return
	if glitch == GLITCHES.COUNTDOWN: return
	if glitch == GLITCHES.EXTRA_ROBOTS: return
	if glitch == GLITCHES.DOOR_OPEN: return
	#return
	#%robotObject.rotate_y(deg_to_rad(120) * delta)
	if reverse:
		%RobotBody.rotate_y(deg_to_rad(-120) * delta)
		%RobotBaseB.rotate_y(deg_to_rad(-120) * delta)
	else:
		%RobotBody.rotate_y(deg_to_rad(120) * delta)
		%RobotBaseB.rotate_y(deg_to_rad(120) * delta)
	
	if not %RotatingRobotSound.playing:
		%RotatingRobotSound.play(rotation_sound_time)

func stop_action() -> void:
	rotation_sound_time = %RotatingRobotSound.get_playback_position()
	%RotatingRobotSound.stop()
	if anim.is_playing() and anim.current_animation == "Strugling":
		strugle_seek = anim.current_animation_position
		match glitch:
			GLITCHES.TENTACLE_ARM:
				anim.play("Tentacle", 1.0)
			GLITCHES.SPIDER:
				anim.play("Spider", 1.0)
			GLITCHES.LONG_FINGERS:
				anim.play("Nails", 1.0)
			GLITCHES.OCTOPUS:
				anim.play("Arms", 1.0)
			_:
				anim.play("Idle", 1.0)

func robot_rotation(angle: float) -> void:
	%RobotBody.rotation.y = angle

func robot_position(pos: Vector3) -> void:
	%RobotBody.position = pos
	%RobotBase.position = pos
	%RobotBaseB.position = pos
	update_base()

func get_robot_global_position() -> Vector3:
	return %RobotBody.global_position

func first_frame_animation(anim_name: String) -> void:
	anim.play(anim_name, -1, 0)

func play_animation(anim_name: String, speed: float = 1.0) -> void:
	anim.play(anim_name, -1, speed)
	anim.seek(0.0)

func charge_battery(delta: float) -> bool:
	if not power_on: return false
	if is_demo or is_event: return false
	if glitch == GLITCHES.DOOR_OPEN: return false
	if lock_buttons: return false
	var prev_level = battery_charge
	battery_charge -= delta * 14.0 * 4.0
	battery_charge = clampf(battery_charge, 0.0, 100.0)
	if prev_level != battery_charge and battery_charge >= 100.0:
		#%RobotBatteryAudioPlayer.play()
		pass
	if prev_level != battery_charge and battery_charge <= 0.0:
		deactivate_angry()
		%RobotBatteryAudioPlayer.play()
	recharge_cooldown = 20.0
	if battery_charge == 0:
		return true
	return false

## Deprecated
func update_auto_battery(delta) -> void:
	if false:
		if glitch == GLITCHES.NONE: return
		if not power_on: return
		if force_no_battery: return
		if recharge_cooldown == 0:
			battery_charge += delta * 14.0 * 0.5
			battery_charge = min(100.0, battery_charge)

func shutdown(delta: float) -> bool:
	if is_demo or is_event: return false
	if lock_buttons: return false
	if lock_power_button: return false
	if lock_shutdown_button: return false
	if power_on:
		pressing_off_button += delta * 8.0
		shutdown_time -= delta * 0.4
		if strugle and glitch != GLITCHES.FOLLOWING_EYES:
			if not anim.is_playing():
				anim.play("Strugling", 0.5)
				anim.seek(strugle_seek)
			Global.strugle_executed()
		if shutdown_time <= 0.0:
			shut_down()
			return true
	else:
		pressing_off_button += delta * 8.0
		shutdown_time += 1.0 # delta * 0.4
		if shutdown_time >= 1.0:
			turn_on()
			return true
	return false

func play_process(stop:=false) -> void:
	if is_demo: return
	if lock_buttons: return
	if is_event: return
	if glitch == GLITCHES.DOOR_OPEN: return
	if stop:
		%RobotButtonAudioPlayer.stop()
		return
	if not %RobotButtonAudioPlayer.playing:
		%RobotButtonAudioPlayer.play()

func _process(delta: float) -> void:
	recharge_cooldown -= delta
	recharge_cooldown = max(recharge_cooldown, 0)
	if power_on:
		shutdown_time += delta * 0.1
		shutdown_time = min(shutdown_time, 1.0)
	else:
		shutdown_time -= delta * 0.1
		shutdown_time = max(shutdown_time, 0.0)
	%GlitchLabel.text = "%s" % GLITCHES.find_key(glitch)
	%IdLabel.text = "R%d" % robot_id
	%BatteryLabel.text = "%d%%" % battery_charge
	#%BatteryRadialProgress.value = battery_charge
	#%PowerRadialProgress.value = shutdown_time * 100.0
	%BatteryLight.light_energy = battery_charge * 0.01
	%PowerLight.light_energy = shutdown_time * 0.3
	
	if int(battery_charge) >= 100 or true:
		#%BatteryIndicator.material = preload("res://materials/prototype_red_mat.tres")
		%BatteryLight.light_color = Color.RED
	else:
		#%BatteryIndicator.material = preload("res://materials/prototype_green_mat.tres")
		%BatteryLight.light_color = Color.GREEN
	
	if is_demo:
		%BatteryLight.light_energy = 0
		%PowerLight.light_energy = 0
	
	if %BatteryLight.light_energy > 0:
		%BatteryLight.visible = true
	else:
		%BatteryLight.visible = false
	if %PowerLight.light_energy > 0:
		%PowerLight.visible = true
	else:
		%PowerLight.visible = false
	#
	var battery_bone := %robotObject.get_node("Armature/Skeleton3D/Battery_Attachment") as BoneAttachment3D
	var shutdown_bone := %robotObject.get_node("Armature/Skeleton3D/ShutDown_Attachment") as BoneAttachment3D
	%BatteryNode.global_position = battery_bone.global_position
	%BatteryNode.global_rotation = battery_bone.global_rotation
	%ShutdownNode.global_position = shutdown_bone.global_position
	%ShutdownNode.global_rotation = shutdown_bone.global_rotation
	var camera_bone := %robotObject.get_node("Armature/Skeleton3D/Camera_Attachment/Camera_Attachment") as Node3D # BoneAttachment3D
	var player_cam: Camera3D = Global.player.get_camera()
	%CameraNode.global_transform = player_cam.global_transform.interpolate_with(camera_bone.global_transform, anim_camera_weight)
	
	if hide_base:
		remove_base()
	
	# NOTE stupid workaround to wrong AABB
	#%robotObject.position.y = randf() * 0.01
	
	update_snap(delta)
	follow_head(delta)
	update_glitch()
	update_pose()
	update_base()
	update_follow(delta)
	update_blocking_path()
	update_door_open()
	update_stalk()
	update_auto_battery(delta)
	update_radial(delta)
	if follows_player_speed > 0:
		walk_towards_player(delta, follows_player_speed)


func update_radial(_delta: float) -> void:
	#pressing_off_button -= delta * 2.0
	#pressing_off_button = clampf(pressing_off_button, 0, 0.2)
	#robj["off_button"].position.x = -pressing_off_button * 0.01
	var battery_instance:MeshInstance3D = robj["battery_radial"]
	battery_instance["instance_shader_parameters/amount"] = battery_charge * 0.01
	
	var power_instance:MeshInstance3D = robj["power_radial"]
	power_instance["instance_shader_parameters/amount"] = shutdown_time

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

var grab_anim_started := false
func grab_player() -> void:
	if Global.is_player_grabbed: return
	Global.is_player_grabbed = true
	var cam := get_viewport().get_camera_3d()
	%CameraRobot.keep_aspect = cam.keep_aspect
	%CameraRobot.fov = cam.fov
	#%CameraRobot.global_transform = cam.global_transform
	#%CameraNode.global_transform = cam.global_transform
	var cam_tween := create_tween()
	cam_tween.tween_property(self, "anim_camera_weight", 1.0, 0.2)
	var blood_tween := create_tween()
	blood_tween.tween_method(Global.set_blood_vignete, 0.0, 1.0, 1.0)
	#Global.set_blood_vignete(1.0)
	%CameraRobot.current = true
	if not grab_anim_started:
		grab_anim_started = true
		$AttackSound.play()
		if randf() < 0.5:
			anim.play("AttackExec")
		else:
			anim.play("AttackB")
		anim.speed_scale = 1.0
		Global.player.rumble(0.1)
		anim.connect("animation_finished", _on_attack_anim_finished)

func _on_attack_anim_finished(anim_name: String) -> void:
	const attack_anims := [
		"AttackExec",
		"AttackB"
	]
	if attack_anims.has(anim_name):
		#executive_finished.emit()
		anomaly_failed.emit()

func update_door_open() -> void:
	if glitch != GLITCHES.DOOR_OPEN: return
	if is_demo: return
	var player_pos := Global.player.global_position
	player_pos.y = 0
	%RobotBody.position = Vector3(-4.5, 0, 0)
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	var dist := robot_pos.distance_to(player_pos)
	if dist < 1.0:
		#anomaly_failed.emit()
		grab_player()
	if dist < 4.0:
		Global.player.rumble(0.1)

func update_blocking_path() -> void:
	if glitch != GLITCHES.BLOCKING_PATH: return
	if is_demo: return
	if not power_on: return
	var player_pos := Global.player.global_position
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	var min_distance := 1.0
	if Global.recording_trailer:
		min_distance = 2.0
	if robot_pos.distance_to(player_pos) < min_distance:
		grab_player()
		#anomaly_failed.emit()
	var dist := robot_pos.distance_to(player_pos)
	if dist < 4.0:
		Global.player.rumble(0.1)

func update_follow(delta: float) -> void:
	#if Global.is_player_grabbed: return
	if glitch != GLITCHES.WALKS_NOT_LOOKING:
		return
	if is_demo: return
	if follow_completed: return
	
	if not is_on_screen() and Global.is_player_in_room and power_on:
		anim.speed_scale = 1.0
		
		if not walk_towards_player(delta, 1.0):
			%RobotStepsAudioPlayer.stop()
			return
		
		Global.player.rumble()
		if not %RobotStepsAudioPlayer.playing:
			%RobotStepsAudioPlayer.play()
		
	else:
		anim.speed_scale = 0.0
		%RobotStepsAudioPlayer.stop()
	if power_on:
		var player_pos := Global.player.global_position
		player_pos.y = 0
		var robot_pos: Vector3 = %RobotBody.global_position
		robot_pos.y = 0
		#prints("rumble", robot_pos, player_pos, robot_pos.distance_to(player_pos))
		if robot_pos.distance_to(player_pos) < 3.0:
			Global.player.rumble(0.1)
		if robot_pos.distance_to(player_pos) < 1.0:
			#anomaly_failed.emit()
			grab_player()
			follow_completed = true

func walk_towards_player(delta:float, speed: float) -> bool:
	var player_pos := Global.player.global_position
	player_pos.y = 0
	var robot_pos: Vector3 = %RobotBody.global_position
	robot_pos.y = 0
	#var robot_pos_2d := Vector2(robot_pos.x, robot_pos.z)
	
	var local_player_pos := %RobotBody.to_local(player_pos) as Vector3
	var player_pos_2d := Vector2(local_player_pos.x, local_player_pos.z)
	var angle: float = Vector2.ZERO.angle_to_point(player_pos_2d) - %RobotBody.global_rotation.y
	
	var dir_to_player := (player_pos - robot_pos).normalized()
	var player_pos_short := robot_pos + dir_to_player
	
	var new_intersection := PhysicsRayQueryParameters3D.create(robot_pos, player_pos_short, 1<<1)
	var intersection := get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if not intersection.is_empty():
		return false
	%RobotBody.global_position += dir_to_player * delta * 2.0 * speed
	%RobotBody.global_rotation.y = -angle + deg_to_rad(90)
	return true

func update_base() -> void:
	$BaseShadowPlane.position = %RobotBase.position
	$BaseShadowPlane.position.y = 0.015

func update_snap(delta: float) -> void:
	if glitch != GLITCHES.COUNTDOWN: return
	if snap_completed: return
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
			snap_completed = true
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

func scale_robot(scale_val:float) -> void:
	%robotObject.scale = Vector3.ONE * scale_val

func make_angry() -> void:
	if glitch != GLITCHES.NONE: return
	robj["red_eyes"].visible = true
	looking_player = true
	battery_charge = 100.0
	lock_buttons = true

func deactivate_angry() -> void:
	if glitch != GLITCHES.NONE: return
	robj["red_eyes"].visible = false
	looking_player = false

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
		POSES.SITTING_BODY:
			anim.play("SittingBody")
		POSES.HOLDING_VACUUM:
			anim.play("HoldingVacuum")
		POSES.HOLDING_VACUUM_B:
			anim.play("HoldingVacuum_b")
		POSES.RUNNING:
			anim.play("Running")
		POSES.HOLDING_BRAIN:
			anim.play("HoldingBrain")
		POSES.LOOKING_DOWN:
			anim.play("LookingDown")

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
	
	if red_eyes:
		robj["red_eyes"].visible = true
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
			anim.play("Spider")
		GLITCHES.OCTOPUS:
			robj["octopus"].visible = true
			anim.play("Arms")
		GLITCHES.HEAD_BOX:
			robj["head_box"].visible = true
		#GLITCHES.BACK_BOX:
		#	robj["back_box"].visible = true
		GLITCHES.TELESCOPIC_EYES:
			robj["telescopic_eye"].visible = true
		GLITCHES.BRAIN_EXTENSION:
			robj["brain_extension"].visible = true
		GLITCHES.LONG_ANTENA:
			robj["long_antena"].visible = true
		GLITCHES.LONG_FINGERS:
			robj["long_fingers"].visible = true
			anim.play("Nails")
		GLITCHES.TENTACLE_ARM:
			robj["tentacle"].visible = true
			robj["arm"].visible = false
			anim.play("Tentacle")
		GLITCHES.CHEST_CONNECTION:
			robj["chest_connection"].visible = true
		GLITCHES.CLOCK_HEART:
			robj["clock_heart"].visible = true
		#GLITCHES.WRIST_SCARF:
		#	robj["scarf"].visible = true
		#GLITCHES.RED_EYES:
		#	robj["red_eyes"].visible = true
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
		#GLITCHES.PROCESSING:
			#robj["red_eyes"].visible = true
			#if not tween:
				#tween = create_tween()
				#tween.set_loops()
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				#tween.tween_interval(0.1)
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				#tween.tween_interval(0.12)
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				#tween.tween_interval(0.2)
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				#tween.tween_interval(0.22)
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(true))
				#tween.tween_interval(0.12)
				#tween.tween_callback(robj["red_eyes"].set_visible.bind(false))
				#tween.tween_interval(0.09)
		GLITCHES.FACING_WRONG_DIRECTION:
			%RobotBody.rotation.y = deg_to_rad(5+randi_range(-10, 10))
			if is_demo:
				%RobotBody.rotation.y = deg_to_rad(90)
		GLITCHES.MISSING_EYE:
			robj["eye_left"].visible = false
		GLITCHES.MISSING_ENTIRELY:
			%RobotBody.position = Vector3.ZERO
			%RobotBody.position.y = -20
		#GLITCHES.DRIPPING_OIL:
		#	setup_oil_dripping()
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
			if is_demo:
				%RobotBody.position.x = 0.0
		GLITCHES.DOOR_OPEN:
			%RobotBody.position = Vector3(-15, 0, 0)
			%RobotBody.rotation.y = deg_to_rad(90)
			robj["red_eyes"].visible = true
		GLITCHES.WALKS_NOT_LOOKING:
			%RobotBody.position = Vector3.ZERO
			%RobotBody.rotation.y = deg_to_rad(0)
			anim.play("Walking")
			if is_demo:
				anim.speed_scale = 0.0
		GLITCHES.EXTRA_ROBOTS:
			if not is_demo:
				var pos := %RobotBody.position as Vector3
				pos.x += randf() * 0.3
				pos.y = 0.0
				pos.z += randf() * 0.3
				robot_position(pos)
				remove_base()
		GLITCHES.GRABS_BATTERY:
			if is_demo:
				anim.play("GrabsBattery")

#func remove_glitch():
	##is_glitching = false
	##is_glitch_visible = false
	#glitch = GLITCHES.NONE
	#anim.pause()

func remove_base() -> void:
	%RobotBase.visible = false
	%RobotBaseB.visible = false
	$BaseShadowPlane.visible = false
	base_visible = false
	for c:CollisionShape3D in %RobotBaseStaticBody.get_children():
		c.set_deferred("disabled", true)

func disable_colliders() -> void:
	for c:CollisionShape3D in %RobotBaseStaticBody.get_children():
		c.disabled = true
	for c:CollisionShape3D in %RobotStaticBody.get_children():
		c.disabled = true

func follow_head(delta: float) -> void:
	if not looking_player or not power_on:
		skeleton.clear_bones_global_pose_override()
		return
	var head_attachment: Node3D= %robotObject.get_node("Armature/Skeleton3D/Head_Attachment/Head_Attachment")
	var head_id := skeleton.find_bone("head")
	var player_eyes := Global.player.global_position + Vector3(0, 1.7, 0)
	head_attachment.look_at(player_eyes, Vector3.UP, true)
	var neck_rotation: Vector3 = head_attachment.rotation_degrees
	neck_rotation.x = clamp(neck_rotation.x, -60, 80)
	neck_rotation.y = clamp(neck_rotation.y, -50, 50)
	
	neck_rotation_y = lerp_angle(neck_rotation_y, deg_to_rad(neck_rotation.y), 2 * delta)
	
	var new_rotation := Quaternion.from_euler(
		Vector3(deg_to_rad(neck_rotation.x), neck_rotation_y, 0))
	skeleton.set_bone_pose_rotation(head_id, new_rotation)
	

func follow_head_old(_delta: float) -> void:
	# TODO use LookAtBone3D
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
	var mat_cache:Array[StandardMaterial3D] = []
	var mat_chache_mod:Array[StandardMaterial3D] = []
	for c in rnode.get_children(true):
		if c is MeshInstance3D:
			if not ["body", "arm_L"].has(c.name): continue
			var mesh = c.mesh.duplicate()
			c.mesh = mesh
			for s in c.mesh.get_surface_count():
				var mat := c.mesh.surface_get_material(s) as StandardMaterial3D
				if not mat: continue
				if not mat_cache.has(mat):
					mat_cache.append(mat)
					var mat_new = mat.duplicate(true)
					mat_new.detail_enabled = true
					mat_new.detail_mask = detail_texture
					c.mesh.surface_set_material(s, mat_new)
					mat_chache_mod.append(mat_new)
				else:
					var mat_id = mat_cache.find(mat)
					c.mesh.surface_set_material(s, mat_chache_mod[mat_id])
		add_detail(c, detail_texture)

var lock_power_button := false
func shut_down() -> void:
	%RobotShutdownAudioPlayer.play()
	power_on = false
	lock_power_button = true
	battery_charge = 0.0
	anim.play("Shut_Down", 1.0)
	#const ROBOT_FACE = preload("res://materials/robot_mats/Robot_face.tres")
	#var white_eyes_mesh:Mesh = robj["white_eyes"].mesh as Mesh
	#white_eyes_mesh.surface_set_material(0, ROBOT_FACE)
	#var red_eyes_mesh:Mesh = robj["red_eyes"].mesh as Mesh
	#red_eyes_mesh.surface_set_material(0, ROBOT_FACE)
	var shut_down_tween := create_tween()
	shut_down_tween.tween_property(%RobotLaughAudioPlayer, "pitch_scale", 0.2, 3)
	shut_down_tween.tween_callback(%RobotLaughAudioPlayer.stop)
	shut_down_tween.tween_callback(turn_off_glitches)
	#%RobotLaughAudioPlayer.stop()ss
	%RobotMotorAudioPlayer["parameters/switch_to_clip"] = "Off"
	
	var bat_tween := create_tween()
	bat_tween.set_ease(Tween.EASE_OUT)
	bat_tween.set_trans(Tween.TRANS_ELASTIC)
	bat_tween.tween_property(robj["power_radial"], "position:z", -0.1, 0.6)
	bat_tween.parallel().tween_property(robj["battery_body"], "position:z", 0.1, 0.6)
	#bat_tween.parallel().tween_property(robj["off_button"], "position:x", 0.1, 0.6)
	bat_tween.tween_interval(2.0)
	bat_tween.tween_callback(robj["power_radial"].set_visible.bind(false))
	bat_tween.tween_callback(robj["battery_body"].set_visible.bind(false))
	#bat_tween.tween_callback(robj["off_button"].set_visible.bind(false))
	bat_tween.tween_callback(func(): lock_power_button = false)

func turn_on() -> void:
	power_on = true
	anim.play("Idle", 1.0)
	%RobotPowerupAudioPlayer.play()
	robj["power_radial"].position.z = 0
	robj["battery_body"].position.z = 0
	#robj["off_button"].position.x = 0
	robj["power_radial"].set_visible(true)
	robj["battery_body"].set_visible(true)
	#robj["off_button"].set_visible(true)
	#
	#const ROBOT_RED_GLOW = preload("res://materials/robot_mats/Robot_Red_Glow.tres")
	#const ROBOT_WHITE_GLOW = preload("res://materials/robot_mats/Robot_White_Glow.tres")
	#var white_eyes_mesh:Mesh = robj["white_eyes"].mesh as Mesh
	#white_eyes_mesh.surface_set_material(0, ROBOT_WHITE_GLOW)
	#var red_eyes_mesh:Mesh = robj["red_eyes"].mesh as Mesh
	#red_eyes_mesh.surface_set_material(0, ROBOT_RED_GLOW)
	#var shut_down_tween := create_tween()
	#shut_down_tween.tween_property(%RobotLaughAudioPlayer, "pitch_scale", 0.2, 3)
	#shut_down_tween.tween_callback(%RobotLaughAudioPlayer.stop)
	#shut_down_tween.tween_callback(turn_off_glitches)
	#%RobotLaughAudioPlayer.stop()ss
	%RobotMotorAudioPlayer["parameters/switch_to_clip"] = "Working"

func turn_off_glitches() -> void:
	if tween and tween.is_valid():
		tween.stop()
	robj["red_eyes"].visible = false
	

func grab_battery() -> void:
	if glitch_executed:
		anomaly_failed.emit()
		lock_buttons = true
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
