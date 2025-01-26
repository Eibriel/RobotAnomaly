extends Node3D

const SECTION = preload("res://section.tscn")
#const LOBY = preload("res://loby.tscn")

#var main
var robot_collected:Robot
var battery_collected := -1

var robots: Array[Robot] = []

var completed_scenarios: Array[int] = []
var selected_scenarios:Array[int] = []
var failed_scenarios:Array[int] = []
#var scenario_count := 0
#const batch_count := 1 # 8

var introduction_done := false
var day := 1
var section: Section
var level_started := false

var task_timer := 0.0
var task_duration := 4.0
var current_task := TASKS.NONE

var tutorial_completed := false
var congrats_completed := false

const MESSAGES: Array[String]= [
	"Welcome",
	"Don't smile",
	"Get out"
]

enum TASKS {
	NONE,
	BATTERY_CHARGE,
	SHUT_DOWN,
	ROTATE
}

enum SIDES {
	Z_PLUS,
	Z_MINUS
}

enum DRESSING {
	NONE,
	TUTORIAL,
	LOBBY,
	DESIGN,
	LAB,
	MARKETING,
	PARTY,
	EXECUTIVE
}

var current_side := SIDES.Z_PLUS
var tonemap_tween: Tween

const FLOORS_AMOUNT := 29

# Debug
const skip_tutorial := true
const force_anomaly := Robot.GLITCHES.NONE
const linear_game := true
const force_dressing := DRESSING.LAB

func _ready() -> void:
	reset_dressing()
	$WorldEnvironment.environment.tonemap_exposure = 6.0
	#scenario_count = Robot.GLITCHES.size()
	var mixed_scenarios := Robot.GLITCHES.values()
	if not linear_game:
		mixed_scenarios.shuffle()
	mixed_scenarios.remove_at(mixed_scenarios.find(Robot.GLITCHES.NONE))
	mixed_scenarios.resize(FLOORS_AMOUNT)
	for s in mixed_scenarios:
		if force_anomaly != Robot.GLITCHES.NONE:
			selected_scenarios.append(force_anomaly)
			continue
		if randf() < 0.3 and not linear_game:
			selected_scenarios.append(Robot.GLITCHES.NONE)
		else:
			selected_scenarios.append(s)
	if not linear_game:
		selected_scenarios.shuffle()
	Global.player = %Player
	load_main()
	#
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(%FadeWhite, "modulate:a", 0.0, 2.0)

func _process(delta: float) -> void:
	#if not [TASKS.NONE, TASKS.ROTATE].has(current_task):
		#task_timer += delta
		#if task_timer >= task_duration:
			#task_timer = 0.0
			#match current_task:
				#TASKS.BATTERY_CHARGE:
					#robot_collected.battery_charge = 100
				#TASKS.SHUT_DOWN:
					#shutdown_robot()
			#current_task = TASKS.NONE
	if robot_collected:
		match current_task:
			TASKS.ROTATE:
				robot_collected.rotate_base(delta)
			TASKS.BATTERY_CHARGE:
				robot_collected.charge_battery(delta)
			TASKS.SHUT_DOWN:
				robot_collected.shutdown(delta)
	
	var robot_id = -1
	if robot_collected:
		robot_id = robot_collected.robot_id
	%RobotIdLabel.text = "R%d - %d" % [robot_id, battery_collected]
	%TimeLabel.text = "Day %d" % day
	
	if false:
		# Deprecated section.anomaly
		if section.anomaly == Robot.GLITCHES.LIGHTS_OFF:
			$WorldEnvironment.environment.background_energy_multiplier = 0.1
			if section.time > 10:
				process_failed_queue(section.scenario)
				reset_position()
				load_main()
		else:
			$WorldEnvironment.environment.background_energy_multiplier = 1.0
		if section.anomaly == Robot.GLITCHES.COUNTDOWN:
			print(section.time)
			if section.time > 30:
				print("Countdown complete!")
				process_failed_queue(section.scenario)
				reset_position()
				load_main()
		
	#%SideDoor.visible = true
	#%SideDoor.use_collision = true
	#if section.anomaly == Robot.GLITCHES.DOOR_OPEN:
		#%SideDoor.visible = false
		#%SideDoor.use_collision = false
	
	%TaskProgressBar.value = (100.0 / task_duration) * task_timer

func load_main() -> void:
	robot_collected = null
	#reset_position()
	reset_environment()
	instantiate_sections(%Environment)

func reset_dressing() -> void:
	%office_design.visible = false
	%office_executive.visible = false
	%office_lab.visible = false
	%office_lobby.visible = false
	%office_marketing.visible = false
	%office_party.visible = false
	%office_tutorial.visible = false
	%office_tutorial.position.y = -20


func instantiate_sections(Env: Node3D) -> void:
	prints("Selected Scenarios", selected_scenarios)
	prints("Failed Scenarios", failed_scenarios)
	prints("Completed Scenarios", completed_scenarios)
	var scenario = 0
	if not tutorial_completed and not skip_tutorial:
		scenario = -2
	elif completed_scenarios.size() >= 8 and not congrats_completed:
		scenario = -1
	elif completed_scenarios.size() >= 30:
		scenario = -3
	elif selected_scenarios.size() > 0:
		scenario = selected_scenarios.pop_front()
	elif failed_scenarios.size() > 0:
		scenario = failed_scenarios.pop_front()
	else:
		push_error("No more scenarios")
	var available_scenarios_count := selected_scenarios.size() + failed_scenarios.size()
	for c in Env.get_children():
		c.queue_free()
	prints("Scenario:", scenario)
	section = SECTION.instantiate()
	section.level = available_scenarios_count
	section.connect("glitch_failed", on_glitch_failed)
	section.connect("request_environment_change", on_environment_change)
	#%LevelCountLabel.text = "%d" % (scenario_count - available_scenarios_count)
	if [-1, -2, -3].has(scenario):
		%LevelCountLabel.mesh.text = "-"
	else:
		%LevelCountLabel.mesh.text = "%d" % (completed_scenarios.size() + 1)
	if completed_scenarios.size() < 8:
		%TotalLevelsCountLabel.mesh.text = "/ %d" % 8
	else:
		%TotalLevelsCountLabel.mesh.text = "/ %d" % FLOORS_AMOUNT
		
	#main.level = scenarios.size() - n
	section.scenario = scenario
	#section.last_day = available_scenarios_count <= batch_count
	#var message_id := FLOORS_AMOUNT-available_scenarios_count
	var message_id := completed_scenarios.size()
	reset_dressing()
	prints("message_id", message_id)
	if scenario == -2:
		%office_tutorial.visible = true
		%office_tutorial.position.y = 0
	elif scenario == -3:
		%MessageLabel.text = "Executive"
		%office_executive.visible = true
	elif message_id <= 0:
		%MessageLabel.text = "Lobby"
		%office_lobby.visible = true
		#%office_design.visible = true
	elif message_id <= 8:
		%MessageLabel.text = "Empty Room"
		%office_lobby.visible = true
	elif message_id <= 12:
		%MessageLabel.text = "Design Room"
		%office_design.visible = true
	elif message_id <= 18:
		%MessageLabel.text = "Lab"
		%office_lab.visible = true
	elif message_id <= 25:
		%MessageLabel.text = "Marketing"
		%office_marketing.visible = true
	elif message_id <= 28:
		%MessageLabel.text = "Party"
		%office_party.visible = true
	
	if force_dressing > -1:
		reset_dressing()
		match force_dressing:
			DRESSING.LOBBY:
				%office_lobby.visible = true
			DRESSING.DESIGN:
				%office_design.visible = true
			DRESSING.LAB:
				%office_lab.visible = true
			DRESSING.MARKETING:
				%office_marketing.visible = true
			DRESSING.PARTY:
				%office_party.visible = true
			DRESSING.EXECUTIVE:
				%office_executive.visible = true
	
	#message_id = min(message_id, MESSAGES.size()-1)
	#main.message = "%d" % message_id
	#%MessageLabel.text = MESSAGES[message_id]
	#if n == scenarios.size()-1:
	#	main.last = true
	#main.connect("finish", _on_finished)
	#main.connect("exit", _on_exit)
	#main.connect("end_day", _on_end_day)
	Env.add_child(section)
	#main.position.z = -29 - (50*n)
	#
	#var loby = LOBY.instantiate()
	#Env.add_child(loby)
	
	#loby.set_day(day)
	#loby.set_level_count(available_scenarios_count)
	#if completed_scenarios.size() >= batch_count:
	#	loby.show_counter()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		#day += 1
		#load_main()
		Global.player.rumble()
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventMouseButton:
		if event.pressed:
			fire_ray()
		else:
			task_timer = 0.0
			current_task = TASKS.NONE

func process_failed_queue(scenario: int) -> void:
	if completed_scenarios.size() < 8:
		selected_scenarios.append_array(completed_scenarios)
		completed_scenarios.resize(0)
	#if not failed_scenarios.has(scenario):
	failed_scenarios.append(scenario)

func on_environment_change(change: Section.ENV_CHANGE) -> void:
	match change:
		Section.ENV_CHANGE.OPEN_DOOR:
			var office_obj := %MainOfficeWithCollision.get_node("office2") as Node3D
			var door_obj := office_obj.get_node("Puerta") as Node3D
			door_obj.rotation.y = 45
			var door_coll := %MainOfficeWithCollision.get_node("office2/DoorCollider") as Node3D
			door_coll.position.y = 50

func reset_environment() -> void:
	var office_obj := %MainOfficeWithCollision.get_node("office2") as Node3D
	var door_obj := office_obj.get_node("Puerta") as Node3D
	door_obj.rotation.y = deg_to_rad(180)
	var door_coll := %MainOfficeWithCollision.get_node("office2/DoorCollider") as Node3D
	door_coll.position.y = 0

func _on_finished(success: bool, scenario: int, last: bool) -> void:
	#prints("_on_finished")
	#$OfficeWithCollision.rotate_y(deg_to_rad(180))
	#$OfficeWithCollision2.rotate_y(deg_to_rad(180))
	#$OfficeWithCollision3.rotate_y(deg_to_rad(180))
	#print("Rotate")
	%LevelReport.update_report(section.report)
	level_started = false
	if scenario == -2:
		if not success:
			load_main()
			return
		else:
			tutorial_completed = true
			load_main()
			return
	if scenario == -1:
		congrats_completed = true
		load_main()
		return
	if not success:
		process_failed_queue(scenario)
		load_main()
		#print("Wrong!")
		return
	#if not completed_scenarios.has(scenario):
	completed_scenarios.append(scenario)
	#if last and completed_scenarios.size() > batch_count and completed_scenarios.size() != scenario_count:
	#	load_main()
	load_main()
	#prints("completed: ", completed_scenarios)

func _on_exit() -> void:
	process_failed_queue(section.scenario)
	load_main()

func _on_end_day() -> void:
	day += 1
	load_main()

func reset_position() -> void:
	%Player.global_position = %InitialPosition.global_position
	%Player.look_rot.y = rad_to_deg(%InitialPosition.rotation.y)
	if false:
		if introduction_done:
			#%Player.global_position = %InitialPosition.global_position
			#%Player.look_rot.y = rad_to_deg(%InitialPosition.rotation.y)
			%Player.position.y -= 4.1
		else:
			%Player.look_rot.x = 0.0
			%Player.velocity = Vector3.ZERO
			%Player.global_position = %InitialPosition.global_position
			#%Player.global_position = %InitialPosition.global_position
			#%Player.look_rot.y = rad_to_deg(%InitialPosition.rotation.y)
			#%Player.look_rot.y += rad_to_deg(180)
		introduction_done = true
	

func fire_ray() -> void:
	var ray_range := 4.0
	var center := Vector2(get_viewport().get_visible_rect().size / 2)
	var cam := get_viewport().get_camera_3d()
	var ray_origin := cam.project_ray_origin(center)
	var ray_end := ray_origin + (cam.project_ray_normal(center) * ray_range)
	var new_intersection := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1<<1)
	new_intersection.collide_with_areas = true
	new_intersection.collide_with_bodies = false
	var intersection := get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if intersection.is_empty():
		new_intersection.collide_with_bodies = true
		intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if not intersection.is_empty():
		var coll: Node3D = intersection.collider
		#print(coll.name)
		if coll.has_meta("is_id"):
			robot_collected = coll.get_parent().get_parent().get_parent()
			if not robot_collected.power_on:
				current_task = TASKS.ROTATE
			else:
				%Player.note_visible(true)
				task_timer = 0.0
				current_task = TASKS.SHUT_DOWN
		elif coll.has_meta("is_battery"):
			var rob := coll.get_parent().get_parent().get_parent() as Robot
			if not rob.power_on:
				robot_collected = rob
				current_task = TASKS.ROTATE
			else:
				charge_battery(rob)
			if false:
				# If I've a battery and the charger is empty
				if battery_collected != -1 and coll.get_parent().battery_charge == -1:
					coll.get_parent().battery_charge = battery_collected
					battery_collected = -1
					%Player.battery_visible(false)
				# If I don't have a battery and the robot has
				elif battery_collected == -1 and coll.get_parent().battery_charge != -1:
					battery_collected = coll.get_parent().battery_charge
					coll.get_parent().battery_charge = -1
					%Player.battery_visible(true)
		elif coll.has_meta("is_battery_charger"):
			# If I've a battery and the charger is empty
			if battery_collected != -1 and coll.get_parent().battery_charge == -1:
				coll.get_parent().battery_charge = battery_collected
				battery_collected = -1
				%Player.battery_visible(false)
			# If I don't have a battery and the charger has
			elif battery_collected == -1 and coll.get_parent().battery_charge != -1:
				#battery_from_robot(coll.get_parent())
				battery_collected = coll.get_parent().battery_charge
				coll.get_parent().battery_charge = -1
				%Player.battery_visible(true)
		elif coll.has_meta("is_button"):
			shutdown_robot()
		elif coll.has_meta("is_robot"):
			#$PokeAudio.play()
			#find_glitch(coll.get_parent())
			#coll.get_parent().rotate_base()
			if coll.get_parent().get_parent() is Robot:
				robot_collected = coll.get_parent().get_parent()
			else:
				robot_collected = coll.get_parent().get_parent().get_parent()
			current_task = TASKS.ROTATE
		elif coll.has_meta("is_rotate"):
			#coll.get_parent().rotate_base()
			if coll.get_parent().get_parent() is Robot:
				robot_collected = coll.get_parent().get_parent()
			else:
				robot_collected = coll.get_parent().get_parent().get_parent()
			current_task = TASKS.ROTATE
		elif coll.has_meta("is_turnstile"):
			print("is_turnstile")
			coll.get_parent().open()

func charge_battery(robot: Robot) -> void:
	# On Robot
	if robot.power_on and robot.glitch == Robot.GLITCHES.GRABS_BATTERY:
		robot.grab_battery()
		return
	task_timer = 0.0
	current_task = TASKS.BATTERY_CHARGE
	robot_collected = robot

func shutdown_robot() -> void:
	#print("Button!")
	if robot_collected:
		#robot_collected.remove_glitch()
		robot_collected.shut_down()
		robot_collected = null
		%Player.note_visible(false)

func refresh_reflection_probe():
	$ReflectionProbe.position.x = randf()*0.01
	

func _on_finish_area_body_entered(_body: Node3D) -> void:
	# When player signals that the level is done
	# Not needed anymore
	return
	var sc := section.is_success()
	prints("\nsuccess:", sc)
	_on_finished(sc, section.scenario, false)


func _on_exit_area_body_entered(_body: Node3D) -> void:
	return
	_on_exit()


func _on_inside_area_body_entered(_body: Node3D) -> void:
	#$WorldEnvironment.environment.sky.sky_material = preload("res://sky/room_panorama_01.tres")
	#$ReflectionProbe.position.x = randf()*0.01
	Global.is_player_in_room = true
	var exposure_value := 1.0
	if section.anomaly == Robot.GLITCHES.LIGHTS_OFF:
		exposure_value = 0.05
	if tonemap_tween:
		tonemap_tween.stop()
	tonemap_tween = create_tween()
	tonemap_tween.EASE_OUT
	tonemap_tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", exposure_value, 1.0)
	tonemap_tween.tween_callback(refresh_reflection_probe)
	#$WorldEnvironment.environment.tonemap_exposure = 1.0
	%ExtraStairs.visible = false
	%ExtraOffices.visible = false


func _on_inside_area_body_exited(_body: Node3D) -> void:
	#$WorldEnvironment.environment.sky.sky_material = preload("res://sky/stairs_panorama_01.tres")
	#$ReflectionProbe.position.x = randf()*0.01
	Global.is_player_in_room = false
	if tonemap_tween:
		tonemap_tween.stop()
	tonemap_tween = create_tween()
	tonemap_tween.EASE_OUT
	tonemap_tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 6.0, 1.0)
	tonemap_tween.tween_callback(refresh_reflection_probe)
	#$WorldEnvironment.environment.tonemap_exposure = 1.9
	%ExtraStairs.visible = true
	%ExtraOffices.visible = true


func _on_loop_up_body_entered(body: Node3D) -> void:
	print("Loop Up") # Player is going Down
	%Player.position.y += 4.1


func _on_loop_down_body_entered(body: Node3D) -> void:
	print("Loop Down") # Player is going Up
	var end_level := false
	#if current_side == SIDES.Z_MINUS and %Player.position.z > 0:
	if %Player.position.z > 0:
		%OfficeNode.rotation.y = deg_to_rad(0)
	else:
		%OfficeNode.rotation.y = deg_to_rad(180)
	if level_started:
		end_level = true
	%Player.position.y -= 4.1
	if end_level:
		var sc := section.is_success()
		prints("\nsuccess:", sc)
		_on_finished(sc, section.scenario, false)


func on_glitch_failed() -> void:
	#var sc := section.is_success()
	#prints("\nsuccess:", sc)
	#TODO sometimes reset_position don't reset velocity
	reset_position()
	_on_finished(false, section.scenario, false)

func _on_start_level_body_entered(body: Node3D) -> void:
	level_started = true
