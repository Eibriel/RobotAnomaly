extends CharacterBody3D

const SPEED := 6.0 # * 10.0
#const JUMP_VELOCITY := 4.5
const ACCEL := 5.0

@export var sensitivity := 0.15
@export var min_angle := -80
@export var max_angle := 90

@onready var head = $Head

var look_rot : Vector2
var rumble_tween: Tween

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	%HoldedBattery.visible = false
	%HoldedIdNote.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_rot.y -= (event.screen_relative.x * sensitivity)
		look_rot.x -= (event.screen_relative.y * sensitivity)
		look_rot.x = clamp(look_rot.x, min_angle, max_angle)

func battery_visible(vis: bool) -> void:
	#%HoldedBattery.visible = vis
	pass

func note_visible(vis: bool) -> void:
	#%HoldedIdNote.visible = vis
	pass

func _physics_process(delta: float) -> void:
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
		velocity.x = lerpf(velocity.x, direction.x * SPEED, ACCEL * delta)
		velocity.z = lerpf(velocity.z, direction.z * SPEED, ACCEL * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, ACCEL * delta)
		velocity.z = lerpf(velocity.z, 0.0, ACCEL * delta)

	move_and_slide()
	
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y

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
			randf()*0.05,
			randf()*0.05,
			randf()*0.05,
		), 0.02)
	rumble_tween.tween_property(%CharacterCamera, "position", Vector3.ZERO, 0.02)
