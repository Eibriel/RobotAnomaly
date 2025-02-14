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
var breathing_tween: Tween
var halt_velocity:= false
var walking_sound_state: WALKING_SOUND

enum WALKING_SOUND {
	QUIET,
	WALKING,
	STOPING
}

func _ready() -> void:
	%HoldedBattery.visible = false
	%HoldedIdNote.visible = false
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

func _physics_process(delta: float) -> void:
	if halt_velocity:
		velocity = Vector3.ZERO
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_on_floor() and Input.is_action_pressed("Sprint"):
			direction *= 2
		velocity.x = lerpf(velocity.x, direction.x * SPEED, ACCEL * delta)
		velocity.z = lerpf(velocity.z, direction.z * SPEED, ACCEL * delta)
		$StepsAudio.stream_paused = false
		if not Global.is_player_in_room:
			if walking_sound_state != WALKING_SOUND.WALKING:
				$StairAudio["parameters/switch_to_clip"] = "Walking"
				walking_sound_state = WALKING_SOUND.WALKING
	else:
		$StepsAudio.stream_paused = true
		if walking_sound_state != WALKING_SOUND.STOPING:
			$StairAudio["parameters/switch_to_clip"] = "Stoping"
			walking_sound_state = WALKING_SOUND.STOPING
		velocity.x = lerpf(velocity.x, 0.0, ACCEL * delta)
		velocity.z = lerpf(velocity.z, 0.0, ACCEL * delta)
	
	if Global.is_player_in_room:
		if walking_sound_state != WALKING_SOUND.STOPING:
			$StairAudio["parameters/switch_to_clip"] = "Stoping Short"
			walking_sound_state = WALKING_SOUND.STOPING

	move_and_slide()
	if halt_velocity:
		head.rotation_degrees.x = 0
		rotation_degrees.y = 0
	else:
		if true:
			head.rotation_degrees.x = rad_to_deg( lerp_angle(deg_to_rad(head.rotation_degrees.x), deg_to_rad(look_rot.x), rotation_accel * delta) )
			rotation_degrees.y = rad_to_deg( lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(look_rot.y), rotation_accel * delta) )
		else:
			head.rotation_degrees.x = look_rot.x
			rotation_degrees.y = look_rot.y
	
	halt_velocity = false

func rumble(pause: float = 0.0) -> void:
	if rumble_tween and rumble_tween.is_running():
		return
	if rumble_tween:
		rumble_tween.stop()
		#rumble_tween.free() # Can't free a RefCounted object.
	rumble_tween = create_tween()
	rumble_tween.tween_interval(pause)
	for _n in 15:
		rumble_tween.tween_property(%CharacterCamera, "position", Vector3(
			randf()*0.03,
			randf()*0.03,
			randf()*0.03,
		), 0.02)
	rumble_tween.tween_property(%CharacterCamera, "position", Vector3.ZERO, 0.02)
