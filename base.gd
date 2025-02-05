extends Node3D

const SECTION = preload("res://section.tscn")
#const LOBY = preload("res://loby.tscn")

#var main
var robot_collected:Robot
var battery_collected := -1

var robots: Array[Robot] = []

#var completed_scenarios: Array[int] = []
var selected_scenarios:Array[int] = []
var failed_scenarios:Array[int] = []

var introduction_done := false
var day := 1
var section: Section
var level_started := false

var task_timer := 0.0
var task_duration := 4.0
var current_task := TASKS.NONE

var tutorial_completed := false
var museum_completed := false
#var congrats_completed := false
#var executive_completed := false
#var nightmare_mode := false
#var selected_scenarios_count := 0
#var completed_anomalies_count := 0
var scenarios_amount := 0

var game_state: GameStateResource

const save_path:= "user://game_state.tres"

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

#var current_side := SIDES.Z_PLUS
var tonemap_tween: Tween

const FLOORS_AMOUNT := 29
const NONE_AMOUNT := 10

var exe_phase_2 := false
var saw_crowd_01 := false
var saw_crowd_02 := false
var saw_crowd_03 := false
var saw_crowd_04 := false

# Debug
var skip_tutorial := false
var force_anomaly := Robot.GLITCHES.NONE
var linear_game := false
var force_dressing := DRESSING.NONE
var reset_save := false
var override_state := true
var state_override := GameStateResource.new()
var force_completed_scenarios := 10

func _ready() -> void:
	if OS.has_feature("template"):
		skip_tutorial = false
		force_anomaly = Robot.GLITCHES.NONE
		linear_game = false
		force_dressing = DRESSING.NONE
		reset_save = false
		override_state = false
	state_override.congrats_completed = false
	state_override.executive_completed = false
	state_override.completed_anomalies = []
	for n in range(1, 28):
		if randf() < 0.5:
			state_override.completed_anomalies.append(n)
		else:
			state_override.completed_anomalies.append(Robot.GLITCHES.NONE)
	#
	Global.player = %Player
	
	load_game_state()
	reset_dressing()
	$WorldEnvironment.environment.tonemap_exposure = 6.0
	start_game()
	#
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(%FadeWhite, "modulate:a", 0.0, 2.0)
	#
	%RobotArm/AnimationPlayer.get_animation("HandTest").loop_mode = Animation.LoopMode.LOOP_LINEAR
	%RobotArm/AnimationPlayer.play("HandTest")
	#
	var multi := %CrowdMultiMesh01.multimesh as MultiMesh
	var width := 10
	var depth := 10
	var width_margin := 0.8
	multi.visible_instance_count = width * depth
	for w in width:
		for d in depth:
			var tr := Transform3D()
			tr = tr.scaled(Vector3.ONE * 1.25)
			var x := (width_margin*w) - ((width / 2) * width_margin)
			x += randf() * 0.2
			var z := (width_margin*d) - ((depth / 2) * width_margin)
			tr = tr.translated(Vector3(x, 0, z))
			multi.set_instance_transform((w*width)+d, tr)
	unpause()

func check_if_nightmare() -> void:
	## TODO duplicated code
	#var anomalies_count := Robot.GLITCHES.size()-1
	##var completed_anomalies_count := game_state.completed_anomalies.size()
	#if anomalies_count - completed_anomalies_count < 10:
		#Global.is_nightmare_mode = true
	pass

## Initializes a game
func start_game() -> void:
	check_if_nightmare()
	#scenario_count = Robot.GLITCHES.size() 
	var mixed_scenarios:Array[int]
	mixed_scenarios.append_array(Robot.GLITCHES.values())
	mixed_scenarios.remove_at(mixed_scenarios.find(Robot.GLITCHES.NONE))
	
	for s in mixed_scenarios.duplicate():
		if game_state.completed_anomalies.has(s) :
			mixed_scenarios.remove_at(mixed_scenarios.find(s))
	
	var none_count := game_state.completed_anomalies.count(0)
	
	var shufled_completed_anomalies := game_state.completed_anomalies.duplicate()
	if not linear_game:
		mixed_scenarios.shuffle()
		shufled_completed_anomalies.shuffle()
	#if mixed_scenarios.size() > FLOORS_AMOUNT:
	#	mixed_scenarios.resize(FLOORS_AMOUNT)
	var none_probability := 0.3
	if game_state.executive_completed:
		none_probability = 0.2
	if Global.is_nightmare_mode:
		none_probability = 0.0
	selected_scenarios.resize(0)
	if true:
		selected_scenarios = mixed_scenarios.duplicate()
		var nones: Array[int] = []
		if NONE_AMOUNT > none_count:
			for _n in NONE_AMOUNT - none_count:
				nones.append(Robot.GLITCHES.NONE)
		selected_scenarios.append_array(nones)
		# LIGHTS_OFF must be > 9
		
	else:
		for s in mixed_scenarios:
			#if force_anomaly != Robot.GLITCHES.NONE:
			#	selected_scenarios.append(force_anomaly)
			#	continue
			if randf() < none_probability and \
					not linear_game and \
					selected_scenarios.size() > 0 and \
					not selected_scenarios.back() == Robot.GLITCHES.NONE:
				none_count -= 1
				if none_count <= 0:
					selected_scenarios.append(Robot.GLITCHES.NONE)
			else:
				selected_scenarios.append(s)
	if not linear_game:
		selected_scenarios.shuffle()
	#if force_completed_scenarios > 0:
		#for n in force_completed_scenarios:
			#game_state.completed_anomalies.append(selected_scenarios.pop_front())
	#completed_anomalies_count = game_state.completed_anomalies.size()
	#selected_scenarios_count = selected_scenarios.size()
	scenarios_amount = selected_scenarios.size() + game_state.completed_anomalies.size()
	load_main()

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
	
	update_executive()
	

func setup_executive() -> void:
	%RobotCrowd01.visible = false
	%RobotCrowd02.visible = false
	%RobotCrowd03.visible = false
	%RobotCrowd04.visible = false
	%RobotCrowd01.position.y = -20
	%RobotCrowd02.position.y = -20
	%RobotCrowd03.position.y = -20
	%RobotCrowd04.position.y = -20
	%CrowdMultiMesh01.visible = false
	%CrowdMultiMesh02.visible = false
	%CrowdMultiMesh03.visible = false
	%CrowdMultiMesh04.visible = false
	%RobotStrike.robot_rotation(deg_to_rad(180))
	if not %RobotStrike.is_connected("executive_finished", on_executive_finished):
		%RobotStrike.connect("executive_finished", on_executive_finished)

func update_executive() -> void:
	if section.scenario != -3: return
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	var pos: float = player_pos.z + 25
	#print(pos)
	#TODO move code to robot
	if saw_crowd_01 and \
			saw_crowd_02 and \
			saw_crowd_03 and \
			saw_crowd_04:
		%RobotStrike.stalk_player = Robot.STALK.SHOWUP
	else:
		%RobotStrike.stalk_player = Robot.STALK.FOLLOW
	if %ExecVisible01.is_on_screen() and %RobotCrowd01.visible:
		saw_crowd_01 = true
	if %ExecVisible02.is_on_screen() and %RobotCrowd02.visible:
		saw_crowd_02 = true
	if %ExecVisible03.is_on_screen() and %RobotCrowd03.visible:
		saw_crowd_03 = true
	if %ExecVisible04.is_on_screen() and %RobotCrowd04.visible:
		saw_crowd_04 = true
	if pos < 12:
		exe_phase_2 = true
	if pos < 27:
		if not %ExecVisible02.is_on_screen():
			%CrowdMultiMesh02.visible = true
			%RobotCrowd02.visible = true
			%RobotCrowd02.position.y = 0
	if pos < 40:
		if not %ExecVisible01.is_on_screen():
			%CrowdMultiMesh01.visible = true
			%RobotCrowd01.visible = true
			%RobotCrowd01.position.y = 0
	if exe_phase_2:
		if pos > 12:
			if not %ExecVisible03.is_on_screen():
				%CrowdMultiMesh03.visible = true
				%RobotCrowd03.visible = true
				%RobotCrowd03.position.y = 0
		if pos > 16:
			if not %ExecVisible04.is_on_screen():
				%CrowdMultiMesh04.visible = true
				%RobotCrowd04.visible = true
				%RobotCrowd04.position.y = 0

func on_executive_finished():
	
	var reset := func():
		game_state.executive_completed = true
		tutorial_completed = false
		#current_side = SIDES.Z_PLUS
		#completed_scenarios.resize(0)
		selected_scenarios.resize(0)
		failed_scenarios.resize(0)
		reset_position()
		start_game()
	
	var exec_tween := create_tween()
	exec_tween.tween_interval(2.0)
	#
	exec_tween.tween_property(%FadeWhite, "modulate:a", 1.0, 2.0)
	exec_tween.tween_callback(reset.call_deferred)
	exec_tween.tween_property(%FadeWhite, "modulate:a", 0.0, 2.0)

func save_game_state() -> void:
	#var unique_completed_scenarios: Array[int] = game_state.completed_anomalies.duplicate()
	#for s in completed_scenarios:
		#if s == Robot.GLITCHES.NONE: continue
		#if not unique_completed_scenarios.has(s):
			#unique_completed_scenarios.append(s)
	#game_state.completed_anomalies = unique_completed_scenarios
	#game_state.completed_anomalies = completed_scenarios.duplicate()
	ResourceSaver.save(game_state, save_path)

func load_game_state() -> void:
	game_state = load(save_path)
	if override_state:
		game_state = state_override
	if reset_save or not ResourceLoader.exists(save_path):
		game_state = GameStateResource.new()
		load_settings()
		return
	if game_state.completed_anomalies.size() < 8:
		game_state.completed_anomalies.resize(0)
	else:
		print("Tutorial completed")
		tutorial_completed = true
	load_settings()

func load_settings() -> void:
	%VolumeSlider.set_value_no_signal(game_state.volume_level)
	%MouseSenSlider.set_value_no_signal(game_state.mouse_sensibility)
	%FullscreenCheckBox.set_pressed_no_signal(game_state.full_screen)
	Global.player.sensitivity = remap(game_state.mouse_sensibility, 0, 100, 0.01, 2.0)
	var volume_level := remap(game_state.volume_level, 0, 100, -30, 20)
	var sfx_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(sfx_index, volume_level)
	if game_state.volume_level < 5:
		AudioServer.set_bus_mute(sfx_index, true)
	else:
		AudioServer.set_bus_mute(sfx_index, false)
	if game_state.full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	prints("Mouse", Global.player.sensitivity, %MouseSenSlider.value)
	prints("Volume", volume_level, %VolumeSlider.value)

func load_main() -> void:
	robot_collected = null
	save_game_state()
	reset_environment()
	instantiate_sections(%Environment)

func reset_dressing() -> void:
	var dressing_nodes: Array[Node3D]= [
		%office_tutorial,
		%office_lobby,
		%office_design,
		%office_lab,
		%office_marketing,
		%office_party,
		%office_executive,
		%office_museum
	]
	for dn in dressing_nodes:
		dn.visible = false
		dn.position.y = -20

func dressing_visible(dressing_node: Node3D) -> void:
	dressing_node.visible = true
	dressing_node.position.y = 0

func setup_museum() -> void:
	%MuseumStatsLabel.text = "Stats\n"
	#%MuseumStatsLabel.text += "%d / %d\n" % [completed_anomalies_count, anomalies_count]
	#for ss in game_state.completed_anomalies:
	#	%MuseumStatsLabel.text += "%s\n" % Robot.GLITCHES.find_key(ss)
	var anom_displays := %AnomalyDisplay.get_children()
	var gid := 0
	for glitch in Robot.GLITCHES.values():
		if glitch == Robot.GLITCHES.NONE: continue
		if game_state.completed_anomalies.has(glitch):
			anom_displays[gid].set_anomaly(glitch)
		else:
			anom_displays[gid].set_anomaly_unknown()
		gid += 1
		if gid >= anom_displays.size(): break

func instantiate_sections(Env: Node3D) -> void:
	prints("Selected Scenarios", selected_scenarios)
	prints("Failed Scenarios", failed_scenarios)
	#prints("Completed Scenarios", completed_scenarios)
	prints("Completed Anomalies", game_state.completed_anomalies)
	var scenario = 0
	if force_anomaly != Robot.GLITCHES.NONE:
		scenario = force_anomaly
	elif not tutorial_completed and not skip_tutorial and not museum_completed and ((not game_state.congrats_completed) or game_state.executive_completed):
		if game_state.executive_completed:
			scenario = -4 # Museum
		else:
			scenario = -2 # Tutorial
	#elif completed_scenarios.size() >= 8 and not game_state.congrats_completed:
	elif game_state.completed_anomalies.size() >= 8 and not game_state.congrats_completed:
		scenario = -1 # Congrats
	elif game_state.completed_anomalies.size() >= FLOORS_AMOUNT and not game_state.executive_completed:
		scenario = -3 # Executive
	#elif completed_scenarios.size() >= 30 and game_state.executive_completed:
	#	scenario = -4
	elif selected_scenarios.size() > 0:
		scenario = selected_scenarios.pop_front()
	elif failed_scenarios.size() > 0:
		scenario = failed_scenarios.pop_front()
	else:
		# game completed
		scenario = -4
		#push_error("No more scenarios")
	var available_scenarios_count := selected_scenarios.size() + failed_scenarios.size()
	for c in Env.get_children():
		c.queue_free()
	prints("Scenario:", scenario)
	section = SECTION.instantiate()
	section.level = available_scenarios_count
	section.connect("glitch_failed", on_glitch_failed)
	section.connect("request_environment_change", on_environment_change)
	#%LevelCountLabel.text = "%d" % (scenario_count - available_scenarios_count)
	var anomalies_count := Robot.GLITCHES.size()-1
	#var completed_anomalies_count := game_state.completed_anomalies.size()
	if [-1, -2, -3, -4].has(scenario):
		%LevelCountLabel.mesh.text = "-"
	else:
		%LevelCountLabel.mesh.text = "%d" % (game_state.completed_anomalies.size() + 1)
	if game_state.completed_anomalies.size() < 8 and not game_state.congrats_completed:
		%TotalLevelsCountLabel.mesh.text = "/ %d" % 8
	#elif game_state.executive_completed:
	#	%TotalLevelsCountLabel.mesh.text = "/ %d" % (anomalies_count-completed_anomalies_count)
	elif game_state.completed_anomalies.size() < FLOORS_AMOUNT:
		%TotalLevelsCountLabel.mesh.text = "/ %d" % FLOORS_AMOUNT
	else:
		%TotalLevelsCountLabel.mesh.text = "/ %d" % scenarios_amount
		
	#main.level = scenarios.size() - n
	section.scenario = scenario
	#section.last_day = available_scenarios_count <= batch_count
	#var message_id := FLOORS_AMOUNT-available_scenarios_count
	#var message_id := completed_scenarios.size()
	var message_id := game_state.completed_anomalies.size()
	reset_dressing()
	prints("message_id", message_id)
	if scenario == -2: # Tutorial
		dressing_visible(%office_tutorial)
	elif scenario == -3: # Executive
		%MessageLabel.text = "Executive"
		dressing_visible(%office_executive)
		setup_executive()
	elif scenario == -4: # Museum
		%MessageLabel.text = "Museum"
		dressing_visible(%office_museum)
		#check_if_nightmare()
		#if Global.is_nightmare_mode:
			#%NightmareModeIndicator.visible = true
		#else:
			#%NightmareModeIndicator.visible = false
		setup_museum()
	elif scenario == -1: # Congrats
		dressing_visible(%office_lobby)
	elif message_id <= 0:
		%MessageLabel.text = "Lobby"
		dressing_visible(%office_lobby)
	elif message_id <= 7:
		%MessageLabel.text = "Empty Room"
		dressing_visible(%office_lobby)
	elif message_id <= 12:
		%MessageLabel.text = "Design Room"
		dressing_visible(%office_design)
	elif message_id <= 18:
		%MessageLabel.text = "Lab"
		dressing_visible(%office_lab)
	elif message_id <= 25:
		%MessageLabel.text = "Marketing"
		dressing_visible(%office_marketing)
	elif message_id <= 28:
		%MessageLabel.text = "Party"
		dressing_visible(%office_party)
	else:
		# Random
		var pick_dressing := randi_range(0, 4)
		match pick_dressing:
			0:
				dressing_visible(%office_lobby)
			1:
				dressing_visible(%office_design)
			2:
				dressing_visible(%office_lab)
			3:
				dressing_visible(%office_marketing)
			4:
				dressing_visible(%office_party)
	
	if force_dressing > 0:
		reset_dressing()
		match force_dressing:
			DRESSING.LOBBY:
				dressing_visible(%office_lobby)
			DRESSING.DESIGN:
				dressing_visible(%office_design)
			DRESSING.LAB:
				dressing_visible(%office_lab)
			DRESSING.MARKETING:
				dressing_visible(%office_marketing)
			DRESSING.PARTY:
				dressing_visible(%office_party)
			DRESSING.EXECUTIVE:
				dressing_visible(%office_executive)
	
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

func pause() -> void:
	%PauseMenu.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unpause() -> void:
	%PauseMenu.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		#day += 1
		#load_main()
		Global.player.rumble()
	if event.is_action_pressed("ui_cancel"):
		pause()
	if event is InputEventMouseButton:
		if event.pressed:
			fire_ray()
		else:
			task_timer = 0.0
			current_task = TASKS.NONE

func process_failed_queue(scenario: int) -> void:
	if game_state.completed_anomalies.size() < 8:
		#completed_scenarios.shuffle()d
		selected_scenarios.append_array(game_state.completed_anomalies)
		game_state.completed_anomalies.resize(0)
	#if not failed_scenarios.has(scenario):
	failed_scenarios.append(scenario)
	#failed_scenarios.shuffle()

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
			# TODO do nothing?
			load_main()
			return
		else:
			tutorial_completed = true
			load_main()
			return
	if scenario == -3:
		# TODO do nothing?
		if not success:
			load_main()
			return
		else:
			#Global.complete = true
			load_main()
			return
	if scenario == -1:
		game_state.congrats_completed = true
		load_main()
		return
	if scenario == -4:
		museum_completed = true
		load_main()
		return
	if not success:
		process_failed_queue(scenario)
		load_main()
		#print("Wrong!")
		return
	#if not completed_scenarios.has(scenario):
	game_state.completed_anomalies.append(scenario)
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
	#current_side = SIDES.Z_PLUS
	Global.player.get_camera().current = true
	%OfficeNode.rotation.y = deg_to_rad(0)
	%Player.halt_velocity = true
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
	var ray_range := 6.0
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
	section.is_success() # Force generate report
	_on_finished(false, section.scenario, false)

func _on_start_level_body_entered(body: Node3D) -> void:
	level_started = true


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_pressed() -> void:
	unpause()


func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_state.volume_level = %VolumeSlider.value
		load_settings()


func _on_mouse_sen_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_state.mouse_sensibility = %MouseSenSlider.value
		load_settings()


func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	game_state.full_screen = toggled_on
	load_settings()
