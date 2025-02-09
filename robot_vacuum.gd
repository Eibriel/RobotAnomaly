extends Node3D

var brush_01: MeshInstance3D
var brush_02: MeshInstance3D

var current_state := STATES.FORWARD
var collision_time := 0.0
var processing_time := 0.0
var rotating_time := 0.0

var bump_level := 100.0

enum STATES {
	FORWARD,
	COLLISION,
	PROCESSING_COLLISION,
	ROTATING,
	PAUSE,
	CIRCLES
}

func _ready() -> void:
	brush_01 = $Roomba.get_node("RoombaBrush_001") as MeshInstance3D
	brush_02 = $Roomba.get_node("RoombaBrush_002") as MeshInstance3D

func _process(delta: float) -> void:
	bump_level += delta * 1.4
	bump_level = min(bump_level, 100.0)
	#print(bump_level)
	brush_01.rotation.y -= PI * 2 * delta
	brush_02.rotation.y += PI * 2 * delta

	match current_state:
		STATES.FORWARD:
			translate_object_local(Vector3.BACK*delta*0.1)
			if position.z > 24.7 or position.z < 15.0:
				bump(false)
		STATES.COLLISION:
			collision_time += delta
			translate_object_local(Vector3.FORWARD*delta*0.1)
			if collision_time > 0.1:
				current_state = STATES.PROCESSING_COLLISION
				processing_time = 0
		STATES.PROCESSING_COLLISION:
			processing_time += delta
			if processing_time > 1.0:
				current_state = STATES.ROTATING
				rotating_time = 0
		STATES.ROTATING:
			rotating_time += delta
			rotate_y(PI * 2 * delta * 0.1)
			if rotating_time > 3.0:
				current_state = STATES.FORWARD
		STATES.CIRCLES:
			translate_object_local(Vector3.BACK*delta*0.1)
			rotate_y(PI * 2 * delta * 0.08)

func change_direction() -> void:
	current_state = STATES.ROTATING
	rotating_time = 0

func bump(with_sound:bool) -> void:
	current_state = STATES.COLLISION
	collision_time = 0
	#%RobotVacuumAudio["parameters/switch_to_clip"] = "Collision"
	if with_sound:
		bump_level -= 20.0
		bump_level = max(bump_level, 0)
		%RobotVacuumBumpAudio.volume_db = remap(bump_level, 0, 100, -30, 0)
		#print(%RobotVacuumBumpAudio.volume_db)
		%RobotVacuumBumpAudio.play()

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if current_state == STATES.CIRCLES: return
	bump(true)
