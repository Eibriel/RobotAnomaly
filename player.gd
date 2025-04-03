extends CharacterBody3D

const SPEED := 7.0
#const JUMP_VELOCITY := 4.5
const ACCEL := 5.0

@export var rotation_accel := 12.0
@export var sensitivity := 0.15
@export var camera_shake := 1.0
@export var min_angle := -80.0
@export var max_angle := 90.0
@export var height := 1.9

@onready var head = $Head

var look_rot : Vector2
var rumble_tween: Tween
var rumble_time := 0.0
var rumble_pause := 0.0
var breathing_tween: Tween
var halt_velocity:= false
var walking_sound_state: WALKING_SOUND
var movement_locked:= true
var slow_down := false

enum WALKING_SOUND {
	QUIET,
	WALKING,
	STOPING
}

func _ready() -> void:
	%HoldedBattery.visible = false
	%HoldedIdNote.visible = false
	$StepsAudio.stream_paused = true
	update_breathing_tween()

func update_breathing_tween() -> void:
	if breathing_tween:
		breathing_tween.stop()
	breathing_tween = create_tween()
	breathing_tween.set_loops()
	#breathing_tween.set_ease(Tween.EASE_IN_OUT)
	breathing_tween.set_trans(Tween.TRANS_SINE)
	breathing_tween.tween_property($Head, "position:y", height+(0.005*camera_shake), 2.0)
	breathing_tween.tween_property($Head, "position:y", height-(0.005*camera_shake), 2.0)

func _input(event: InputEvent) -> void:
	if movement_locked: return
	if event is InputEventMouseMotion:
		look_rot.y -= (event.screen_relative.x * sensitivity)
		look_rot.x -= (event.screen_relative.y * sensitivity)
		look_rot.x = clamp(look_rot.x, min_angle, max_angle)

func battery_visible(_vis: bool) -> void:
	#%HoldedBattery.visible = vis
	pass

func note_visible(_vis: bool) -> void:
	#%HoldedIdNote.visible = vis
	pass

func get_camera() -> Camera3D:
	return %CharacterCamera

func lock_movement() -> void:
	movement_locked = true

func unlock_movement() -> void:
	movement_locked = false

func play_scary_noise() -> void:
	$ScaryAudio.position.x = randf_range(-3, 3)
	$ScaryAudio.play()

func _physics_process(delta: float) -> void:
	if halt_velocity:
		velocity = Vector3.ZERO
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_locked:
		head.rotation_degrees.x = 0
		rotation_degrees.y = 0
		$StairAudio["parameters/switch_to_clip"] = "Silence"
		return

	var speed_modifier := 1.0
	if Global.recording_trailer:
		speed_modifier = 0.1
		rotation_accel = 1.4
		sensitivity = 0.17

	var camera_dir := Input.get_vector("camera_down", "camera_up", "camera_right", "camera_left")
	look_rot += camera_dir * delta * sensitivity * 1500.0
	look_rot.x = clamp(look_rot.x, min_angle, max_angle)
	
	var speed_calc = SPEED
	if slow_down:
		speed_calc = SPEED * 0.9
	if not slow_down and is_on_floor() and Input.is_action_pressed("Sprint"):
		speed_calc *= 2.0
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * speed_calc, ACCEL * speed_modifier * delta)
		velocity.z = lerpf(velocity.z, direction.z * speed_calc, ACCEL * speed_modifier * delta)
		$StepsAudio.stream_paused = false
		if not Global.is_player_in_room:
			if walking_sound_state != WALKING_SOUND.WALKING:
				if not Global.recording_trailer:
					$StairAudio["parameters/switch_to_clip"] = "Walking"
				walking_sound_state = WALKING_SOUND.WALKING
	else:
		$StepsAudio.stream_paused = true
		if walking_sound_state != WALKING_SOUND.STOPING:
			#$StairAudio["parameters/switch_to_clip"] = "Stoping"
			$StairAudio["parameters/switch_to_clip"] = "Silence"
			walking_sound_state = WALKING_SOUND.STOPING
		velocity.x = lerpf(velocity.x, 0.0, ACCEL * speed_modifier * delta)
		velocity.z = lerpf(velocity.z, 0.0, ACCEL * speed_modifier * delta)
	
	if Global.is_player_in_room:
		if walking_sound_state != WALKING_SOUND.STOPING:
			#$StairAudio["parameters/switch_to_clip"] = "Stoping Short"
			$StairAudio["parameters/switch_to_clip"] = "Silence"
			walking_sound_state = WALKING_SOUND.STOPING

	move_and_slide()
	var final_look_rot:Vector2
	final_look_rot = Vector2(look_rot)
	if Global.game_settings.invert_x:
		final_look_rot.x *= -1
	if Global.game_settings.invert_y:
		final_look_rot.y *= -1
	if halt_velocity:
		head.rotation_degrees.x = 0
		rotation_degrees.y = 0
	else:
		if true:
			head.rotation_degrees.x = rad_to_deg( lerp_angle(deg_to_rad(head.rotation_degrees.x), deg_to_rad(final_look_rot.x), rotation_accel * delta) )
			rotation_degrees.y = rad_to_deg( lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(final_look_rot.y), rotation_accel * delta) )
		else:
			head.rotation_degrees.x = final_look_rot.x
			rotation_degrees.y = final_look_rot.y
	
	halt_velocity = false

func _process(delta: float) -> void:
	if rumble_time > 0.0:
		if rumble_pause > 0.0:
			rumble_pause -= delta
		else:
			rumble_time -= delta
		Global.set_rumble_vignete(clampf(rumble_time, 0.0, 1.0))
		if $RumbleAudio["parameters/switch_to_clip"] != "Rumble":
			$RumbleAudio["parameters/switch_to_clip"] = "Rumble"
		if not(rumble_tween and rumble_tween.is_running()):
			rumble_tween = create_tween()
			rumble_tween.tween_property(%CharacterCamera, "position", Vector3(
				randf()*0.03,
				randf()*0.03,
				randf()*0.03,
			), 0.02)
	else:
		if $RumbleAudio["parameters/switch_to_clip"] != "Silence":
			$RumbleAudio["parameters/switch_to_clip"] = "Silence"
			%CharacterCamera.position = Vector3.ZERO
		

func rumble(pause: float = 0.0) -> void:
	rumble_pause = pause
	rumble_time = 0.3

func rumble_old(pause: float = 0.0) -> void:
	if rumble_tween and rumble_tween.is_running():
		return
	if rumble_tween:
		rumble_tween.stop()
		#rumble_tween.free() # Can't free a RefCounted object.
	if not $RumbleAudio.playing:
		$RumbleAudio.play()
	rumble_tween = create_tween()
	rumble_tween.tween_interval(pause)
	rumble_tween.tween_callback($RumbleAudio.set_stream_paused.bind(false))
	for _n in 15:
		rumble_tween.tween_property(%CharacterCamera, "position", Vector3(
			randf()*0.03,
			randf()*0.03,
			randf()*0.03,
		), 0.02)
	rumble_tween.tween_property(%CharacterCamera, "position", Vector3.ZERO, 0.02)
	rumble_tween.tween_callback($RumbleAudio.set_stream_paused.bind(true))
