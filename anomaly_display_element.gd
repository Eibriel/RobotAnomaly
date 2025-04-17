extends Node3D

@export var display_id := 0

var robot: Robot
var robot_b: Robot

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
	#Robot.GLITCHES.BACK_BOX: "Storage",
	#Robot.GLITCHES.WRIST_SCARF: "Hurts",
	Robot.GLITCHES.EYES_AROUND_HEAD: "Eyes in the back",
	Robot.GLITCHES.LONG_FINGERS: "Manicure",
	Robot.GLITCHES.BRAIN_EXTENSION: "Logical",
	
	#Robot.GLITCHES.RED_EYES: "Alive",
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
	#Robot.GLITCHES.PROCESSING: "Processing", #(BLINKING_LIGHTS)
	Robot.GLITCHES.FACING_WRONG_DIRECTION: "North",
	Robot.GLITCHES.EXTRA_EYE: "Illumination",
	Robot.GLITCHES.GRAFFITY: "Tatoo",
	#Robot.GLITCHES.DRIPPING_OIL: "Gluttony",
	Robot.GLITCHES.EXTRA_ROBOTS: "Mirage",
	
	# ATTACKS
	Robot.GLITCHES.BLOCKING_PATH: "Yall not pass",
	Robot.GLITCHES.GRABS_BATTERY: "Don't f touch me",
	Robot.GLITCHES.WALKS_NOT_LOOKING: "Play with me",
	Robot.GLITCHES.DOOR_OPEN: "Pst!",
	Robot.GLITCHES.COUNTDOWN: "Timing", #DROPS FROM CEILING
	#Robot.GLITCHES.LIGHTS_OFF: "Nyctophobia"
}

var anomaly_to_set: Robot.GLITCHES
var anomaly_set:= true
var anomaly_frame:=0

func _ready() -> void:
	anomaly_frame = display_id
	$DoorStorage.visible = false
	$DoorStorageFrame.visible = false

func _process(_delta: float) -> void:
	if anomaly_frame > 0:
		anomaly_frame -= 1
		return
	if anomaly_to_set and not anomaly_set:
		implement_anomaly(anomaly_to_set)

func set_anomaly(anomaly: Robot.GLITCHES) -> void:
	anomaly_to_set = anomaly
	anomaly_set = false
	anomaly_frame = display_id

func implement_anomaly(anomaly: Robot.GLITCHES) -> void:
	if robot: return
	anomaly_set = true
	#print("implement_anomaly")
	$Label3D.text = anomaly_name[anomaly]
	if [Robot.GLITCHES.MISSING_ENTIRELY].has(anomaly):
		return
	robot = get_robot_instance() #preload("res://robot.tscn").instantiate()
	robot.set_glitch(anomaly, true)
	robot.scale = Vector3.ONE * 0.2
	robot.position.y = 0.01 + 0.01
	robot.remove_base()
	add_child(robot)
	if anomaly == Robot.GLITCHES.BLOCKING_PATH:
		robot = get_robot_instance() #preload("res://robot.tscn").instantiate()
		robot.block_id = 1
		robot.set_glitch(anomaly, true)
		robot.scale = Vector3.ONE * 0.2
		robot.position.y = 0.01 + 0.01
		robot.remove_base()
		add_child(robot)
	elif anomaly == Robot.GLITCHES.EXTRA_ROBOTS:
		robot.position.x -= 0.08
		robot.rotation.y = deg_to_rad(45)
		robot = get_robot_instance() #preload("res://robot.tscn").instantiate()
		robot.set_glitch(anomaly, true)
		robot.scale = Vector3.ONE * 0.2
		robot.position.y = 0.01 + 0.01
		robot.position.x += 0.08
		robot.rotation.y = deg_to_rad(-45)
		robot.remove_base()
		add_child(robot)
	elif anomaly == Robot.GLITCHES.DOOR_OPEN:
		robot.set_glitch(Robot.GLITCHES.NONE, true)
		robot.scale = Vector3.ONE * 0.2 * 0.8
		$DoorStorage.visible = true
		$DoorStorageFrame.visible = true

func get_robot_instance() -> Robot:
	var r := Global.get_robot_instance()
	if r.get_parent():
		r.get_parent().remove_child(r)
	return r

func set_anomaly_unknown() -> void:
	$Label3D.text = "??"
	if robot:
		robot.queue_free()
