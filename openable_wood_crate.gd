extends Node3D

@export var is_open := false :
	set(value):
		is_open = value
		dirty = true

var dirty := true

func _ready() -> void:
	$GPUParticles3D_cache.emitting = true

func _process(_delta: float) -> void:
	if not dirty: return
	dirty = false
	$WoodCrate.visible = false
	$WoodCrateOpen.visible = false
	if is_open:
		$WoodCrateOpen.visible = true
		$EscapingAudio.play(randf_range(0.0, 2.0))
		var audio_tween := create_tween()
		audio_tween.tween_property($EscapingAudio, "position:x", 5.0, 3.0)
		$GPUParticles3D.emitting = true
	else:
		$WoodCrate.visible = true
