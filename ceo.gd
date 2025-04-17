extends Node3D

@export var pose: POSES = POSES.NONE

enum POSES {
	NONE,
	SITDOWN,
	LAYING_DOWN
}

func _ready() -> void:
	#$CEO/AnimationPlayer.get_animation("TappingSign").loop_mode = Animation.LOOP_LINEAR
	
	match pose:
		POSES.SITDOWN:
			$CEO/AnimationPlayer.play("Sitdown")
		POSES.LAYING_DOWN:
			$CEO/AnimationPlayer.play("Dead")
		_:
			$CEO/AnimationPlayer.play("Standing")
