extends AnimationPlayer

var rotation_value := 0.0

const step := 1.0/30.0

func _init() -> void:
	#print("Robot script")
	pass

func _process(delta: float) -> void:
	if not is_playing():
		rotation_value = 0.0
		print("not playing")
		return
	var anim := get_animation(current_animation)
	const monitored_bones:Array[String] = [
		"waist",
		"chest",
		"head",
		#
		"clavicle.L",
		"shoulder.L",
		"upperArm.L",
		"upperArmKnot.L",
		"foreArmKnot.L",
		"palmKnot.L",
		"thigh.L",
		"knee.L",
		"calf.L",
		#
		"clavicle.R",
		"shoulder.R",
		"upperArm.R",
		"upperArmKnot.R",
		"foreArmKnot.R",
		"palmKnot.R",
		"thigh.R",
		"knee.R",
		"calf.R",
	]
	rotation_value = 0.0
	for bone_name in monitored_bones:
		var tid := anim.find_track("Armature/Skeleton3D:%s" % bone_name, Animation.TYPE_ROTATION_3D)
		print(tid)
		if tid == -1: continue
		var value_a:Quaternion = anim.rotation_track_interpolate(
			tid, current_animation_position)
		var value_b:Quaternion = anim.rotation_track_interpolate(
			tid, current_animation_position + step)
		rotation_value = value_a.angle_to(value_b)
