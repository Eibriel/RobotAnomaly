extends Node3D

var robot: Robot

const anomaly_name = {
	Robot.GLITCHES.BROKEN_ANTENA: "No signal",
	Robot.GLITCHES.TELESCOPIC_EYES: "Let me see",
	Robot.GLITCHES.DOUNLE_ANTENA: "Signal",
	Robot.GLITCHES.CHEST_CONNECTION: "Power bank",
	Robot.GLITCHES.OCTOPUS: "Dexterity",
	Robot.GLITCHES.KNIFE_HAND: "Handy",
	Robot.GLITCHES.LONG_ANTENA: "Long distance",
	Robot.GLITCHES.SPIDER: "6",
	Robot.GLITCHES.TENTACLE_ARM: "Hug me",
	Robot.GLITCHES.MISSING_EYE: "Argh",
	Robot.GLITCHES.CLOCK_HEART: "Doki Doki",
	Robot.GLITCHES.HEAD_BOX: "Smarts",
	Robot.GLITCHES.BACK_BOX: "Storage",
	Robot.GLITCHES.WRIST_SCARF: "Cause",
	Robot.GLITCHES.EYES_AROUND_HEAD: "Eyes in the back",
	Robot.GLITCHES.LONG_FINGERS: "Manicure",
	Robot.GLITCHES.BRAIN_EXTENSION: "Logical",
	
	Robot.GLITCHES.RED_EYES: "Alive",
	Robot.GLITCHES.FOLLOWING_EYES: "Still",
	Robot.GLITCHES.POINTING_FINGER: "There",
#	SMILING,
	Robot.GLITCHES.GIGGLING: "Can't stop",
	#CRYING,
	Robot.GLITCHES.ROCKING: "Dance with me", #(MOVING_LIKE_PENDULUM)
	Robot.GLITCHES.LOOKING_HAND: "Self",
	Robot.GLITCHES.TOUCHING_FACE: "Shell",
	Robot.GLITCHES.MISSING_ENTIRELY: "Where am I?",
	Robot.GLITCHES.BLINKING_EYES: "Tic",
	Robot.GLITCHES.SHAKING: "Brrrr",
	Robot.GLITCHES.PROCESSING: "Processing", #(BLINKING_LIGHTS)
	Robot.GLITCHES.FACING_WRONG_DIRECTION: "North",
	Robot.GLITCHES.EXTRA_EYE: "Illumination",
	Robot.GLITCHES.GRAFFITY: "Tatoo",
	Robot.GLITCHES.DRIPPING_OIL: "Gluttony",
	Robot.GLITCHES.EXTRA_ROBOTS: "Mirage",
	
	# ATTACKS
	Robot.GLITCHES.BLOCKING_PATH: "Yall not pass",
	Robot.GLITCHES.GRABS_BATTERY: "Don't f touch me",
	Robot.GLITCHES.WALKS_NOT_LOOKING: "Play with me",
	Robot.GLITCHES.DOOR_OPEN: "Pst!",
	Robot.GLITCHES.COUNTDOWN: "Timing", #DROPS FROM CEILING
	Robot.GLITCHES.LIGHTS_OFF: "Nyctophobia"
}

func set_anomaly(anomaly: Robot.GLITCHES) -> void:
	$Label3D.text = anomaly_name[anomaly]
	if [Robot.GLITCHES.MISSING_ENTIRELY, Robot.GLITCHES.DOOR_OPEN].has(anomaly):
		return
	if robot:
		robot.queue_free()
	robot = preload("res://robot.tscn").instantiate()
	robot.set_glitch(anomaly, true)
	robot.scale = Vector3.ONE * 0.2
	robot.position.y = 0.01 + 0.01
	robot.remove_base()
	add_child(robot)

func set_anomaly_unknown() -> void:
	$Label3D.text = "??"
	if robot:
		robot.queue_free()
