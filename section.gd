class_name Section
extends Node3D

signal glitch_failed
signal request_environment_change

@export var level := 1
@export var message := ""
@export var scenario = 0
@export var last = false
@export var last_day = false

var robots: Array[Robot] = []
var finished := false
var active := false

var time := 0.0
var glitch_time := 0.0
var anomaly: Robot.GLITCHES
var report: Array

const RESET_BUTTON = preload("res://reset_button.tscn")
const ROBOT = preload("res://robot.tscn")
const BATTERY_CHARGER = preload("res://battery_charger.tscn")

enum ENV_CHANGE {
	OPEN_DOOR
}

func _ready() -> void:
	#%SectionEnd.visible = true
	if last:
		#$FinishArea.position.z = -40
		pass
	else:
		#%SectionEnd.queue_free()
		pass
	if false:
		setup_congrats()
	elif scenario == -2:
		setup_tutorial()
	elif scenario == -1:
		setup_congrats()
	elif scenario == -3:
		setup_ending()
	else:
		start_day()
	#activate.call_deferred()
	#%MessageLabel.text = message

func activate() -> void:
	active = true

func setup_tutorial() -> void:
	var r := ROBOT.instantiate()
	r.robot_id = 10
	r.battery_charge = 50
	r.set_glitch(Robot.GLITCHES.RED_EYES)
	r.connect("anomaly_failed", on_failed_glitch)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(-1.5, 0.5, -10))
	r.robot_rotation(deg_to_rad(-90-70-180))
	
	r = ROBOT.instantiate()
	r.robot_id = 11
	r.battery_charge = 60
	r.set_glitch(r.GLITCHES.NONE)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(1.5, 0.5, -10))
	r.robot_rotation(deg_to_rad(90+70+180))
	
	r = ROBOT.instantiate()
	r.robot_id = 0
	r.battery_charge = 100
	#r.set_glitch(Robot.GLITCHES.RED_EYES)
	r.connect("anomaly_failed", on_failed_glitch)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(-1.5, 0.5, -10+7))
	r.robot_rotation(deg_to_rad(-90-70-180))
	
	r = ROBOT.instantiate()
	r.robot_id = 1
	r.battery_charge = 100
	r.set_glitch(r.GLITCHES.NONE)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(1.5, 0.5, -10+7))
	r.robot_rotation(deg_to_rad(90+70+180))

func setup_congrats() -> void:
	var r := ROBOT.instantiate()
	r.robot_id = 42
	r.battery_charge = 100
	r.looking_player = true
	r.set_pose(Robot.POSES.CLAPPING)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(-2, 0, -10))
	r.robot_rotation(deg_to_rad(45))
	r.remove_base()
	#
	r = ROBOT.instantiate()
	r.robot_id = 24
	r.battery_charge = 100
	r.looking_player = true
	r.set_pose(Robot.POSES.CLAPPING)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(2, 0, -10))
	r.robot_rotation(deg_to_rad(-45))
	r.remove_base()

func setup_ending() -> void:
	var r := ROBOT.instantiate()
	r.robot_id = 666
	r.battery_charge = 90
	r.set_pose(Robot.POSES.SITTING)
	r.remove_base()
	robots.append(r)
	r.get_node("%robotObject").scale = Vector3.ONE
	#r.looking_player = true
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(0, 0, 0))
	#
	r = ROBOT.instantiate()
	r.robot_id = 24
	r.battery_charge = 100
	r.looking_player = true
	#r.set_pose(Robot.POSES.CLAPPING)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(3, 0, 0))
	r.robot_rotation(deg_to_rad(-45))
	r.remove_base()
	#
	r = ROBOT.instantiate()
	r.robot_id = 24
	r.battery_charge = 100
	r.looking_player = true
	#r.set_pose(Robot.POSES.CLAPPING)
	robots.append(r)
	%Robots.add_child.call_deferred(r)
	r.robot_position(Vector3(-3, 0, 0))
	r.robot_rotation(deg_to_rad(45))
	r.remove_base()

func start_day() -> void:
	#if randf() < 0.0:
		#anomaly = Robot.GLITCHES.NONE
	#else:
		#anomaly = randi_range(1, Robot.GLITCHES.size()-1)
	anomaly = scenario
	print("Anomaly: %s %d" % [Robot.GLITCHES.find_key(anomaly), anomaly])
	
	const DIST_X := 3
	const DIST_X_INCREASE := 0.2
	
	var y_count := 10
	if anomaly == Robot.GLITCHES.EXTRA_ROBOTS:
		y_count += 1
	
	if true:
		for rx in 2:
			for ry in y_count:
				var r := ROBOT.instantiate()
				r.connect("anomaly_failed", on_failed_glitch)
				r.robot_id = (rx * 6) + ry
				r.battery_charge = 100
				if randf() < 0.05:
					r.battery_charge = randi_range(60, 80)
				robots.append(r)
				%Robots.add_child.call_deferred(r)
				var dist := DIST_X + (ry * DIST_X_INCREASE)
				#r.position.x = (rx * dist) - (dist * 0.5)
				#r.position.y = 0.4
				#r.position.z = (ry * 3) - 16
				var robot_position := Vector3(
					(rx * dist) - (dist * 0.5),
					0.4,
					(ry * 3) - 16
				)
				r.robot_position(robot_position)
				match rx:
					0:
						r.robot_rotation(deg_to_rad(90-40))
					1:
						r.robot_rotation(deg_to_rad(-90+40))
	else:
		var r := ROBOT.instantiate()
		r.robot_id = 10
		r.battery_charge = 100
		if randf() < 0.05:
			r.battery_charge = randi_range(60, 80)
		robots.append(r)
		%Robots.add_child.call_deferred(r)
		r.robot_position(Vector3(0, 0.5, -10))
	
	var sr := robots.pick_random() as Robot
	var no_anomaly: Array[int] = [
		Robot.GLITCHES.EXTRA_ROBOTS,
		Robot.GLITCHES.LIGHTS_OFF,
		Robot.GLITCHES.BLOCKING_PATH
	]
	if not no_anomaly.has(anomaly):
		sr.set_glitch(anomaly)
		sr.battery_charge = randi_range(70, 80)
		
	
	if anomaly == Robot.GLITCHES.LIGHTS_OFF:
		# Create countdown
		# If the level is not completed before countdown
		# game over
		pass
	if anomaly == Robot.GLITCHES.DOOR_OPEN:
		request_environment_change.emit(Section.ENV_CHANGE.OPEN_DOOR)
	if anomaly == Robot.GLITCHES.GRABS_BATTERY:
		sr.battery_charge = 66
	if anomaly == Robot.GLITCHES.EXTRA_ROBOTS:
		robots[robots.size()-1].set_glitch(anomaly)
		robots[robots.size()-1-y_count].set_glitch(anomaly)
		robots[robots.size()-1].battery_charge = randi_range(60, 80)
		robots[robots.size()-1-y_count].battery_charge = randi_range(60, 80)
	if anomaly == Robot.GLITCHES.BLOCKING_PATH:
		robots[0].set_glitch(anomaly)
		robots[0].block_id = 0
		robots[0].battery_charge = randi_range(60, 80)
		robots[1].set_glitch(anomaly)
		robots[1].block_id = 1
		robots[1].battery_charge = randi_range(60, 80)
	if false:
		var charger := BATTERY_CHARGER.instantiate()
		add_child(charger)
		charger.position = Vector3(2.5, 1.5, 2)
		charger.rotation.y = deg_to_rad(-90)
		charger = BATTERY_CHARGER.instantiate()
		add_child(charger)
		charger.position = Vector3(2.5, 1.5, -20)
		charger.rotation.y = deg_to_rad(-90)
		
		var reset := RESET_BUTTON.instantiate()
		add_child(reset)
		reset.position = Vector3(-2.5, 0, 2)
		reset = RESET_BUTTON.instantiate()
		add_child(reset)
		reset.position = Vector3(-2.5, 0, -20)

func _process(delta: float) -> void:
	time += delta
	if Global.is_player_in_room:
		glitch_time += delta
	if time > 0.5:
		activate()
	if scenario == Robot.GLITCHES.LIGHTS_OFF and glitch_time > 10:
		glitch_failed.emit()
	if scenario == Robot.GLITCHES.LIGHTS_OFF and Global.is_player_in_room:
		Global.player.rumble(0.1)
	#%LevelCountLabel.text = "%d" % level
	
	#Check if day is complete
	#var complete := true
	#for r in robots:
		#if r.battery_charge != 100:
			#complete = false
			#break
	#if complete:
		#%ExitRamp.visible = true
		#%ExitRamp.use_collision = true
	#else:
		#%ExitRamp.visible = false
		#%ExitRamp.use_collision = false

func on_failed_glitch() -> void:
	glitch_failed.emit()

func is_success() -> bool:
	var success := true
	var success_glitches: Array[Robot.GLITCHES] = [
		Robot.GLITCHES.NONE,
		Robot.GLITCHES.MISSING_ENTIRELY,
		Robot.GLITCHES.DOOR_OPEN
	]
	for r in robots:
		var rok := true
		if (not success_glitches.has(r.glitch)) and r.power_on:
			print("Failed! robot with glitch, and power is on %s" % Robot.GLITCHES.find_key(r.glitch))
			success = false
			rok = false
		if success_glitches.has(r.glitch) and not r.power_on:
			print("Failed! robot without glitch, and power is off")
			success = false
			rok = false
		if r.glitch == Robot.GLITCHES.NONE and r.battery_charge < 100.0:
			print("Failed! robot without glitch, and battery is low. %f" % r.battery_charge)
			success = false
			rok = false
		report.append({
			"power": r.power_on,
			"glitched": r.glitch != Robot.GLITCHES.NONE,
			"handled_correctly": rok
		})
	return success

#func _on_finish_area_body_entered(_body: Node3D) -> void:
	#prints("body_entered", _body)
	#if not active: return
	#if finished: return
	#finished = true
	#if not (last and last_day):
		#finish.emit(is_success(), scenario, last)


#func _on_exit_area_body_entered(body: Node3D) -> void:
	#if not active: return
	#exit.emit()
#
#
#func _on_room_area_body_entered(body: Node3D) -> void:
	#if not active: return
	#end_day.emit()
