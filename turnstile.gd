extends Node3D

@export var energy := 0.0
@export var blocked := false

var is_open := false
var anim: AnimationPlayer

func _ready() -> void:
	anim = $turnstyle/AnimationPlayer

func _process(delta: float) -> void:
	$RadialProgress.value = energy
	if energy < 100:
		if is_open:
			is_open = false
			anim.play("Idle", 1.0)
	else:
		if not is_open:
			is_open = true
			anim.play("Open", 0.2)
			$DoorBlock.position.y = -20

func open() -> void:
	if blocked: return
	energy = 100
	print("Open!")
