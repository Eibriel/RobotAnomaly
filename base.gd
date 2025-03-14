extends Node3D

const SECTION = preload("res://section.tscn")
#const LOBY = preload("res://loby.tscn")

#var main
var robot_collected:Robot
var battery_collected := -1

var robots: Array[Robot] = []

#var completed_scenarios: Array[int] = []
var selected_scenarios:Array[Robot.GLITCHES] = []
var failed_scenarios:Array[Robot.GLITCHES] = []

var introduction_done := false
var day := 1
var section: Section
var level_started := false

var task_timer := 0.0
var task_duration := 4.0
var current_task := TASKS.NONE

var tutorial_completed := false
var museum_completed := false
var scenarios_amount := 0

var game_state: GameStateResource
var game_settings: GameSettingsResource

const save_path:= "user://game_state.tres"
const settings_path:= "user://game_settings.tres"

const MESSAGES: Array[String]= [
	"Welcome",
	"Don't smile",
	"Get out"
]

enum TASKS {
	NONE,
	BATTERY_CHARGE,
	SHUT_DOWN,
	ROTATE,
	ROTATE_INVERSE
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

enum EVENTS {
	VENTILATION,
	REPORT,
	EXIT,
	CEILING,
	LINE
}
var available_events: Array[EVENTS] = []
var current_events: Array[EVENTS] = []
var events_enableable_time: Dictionary
var event_enable_time: Dictionary
var event_disable_time: Dictionary
var event_execute_time: Dictionary
var event_was_visible: Dictionary
var event_light_timer := 0.0

#var current_side := SIDES.Z_PLUS
var tonemap_tween: Tween
var target_exposure := 0.0
var lights_on := true
var lights_timer := 0.0
var lights_delay := -1.0

const FLOORS_AMOUNT := 18 #29 # Top floor
const INTRO_AMOUNT := 8 #8 # Ends section 1
const NONE_RATIO := 4

var exe_phase_2 := false
var saw_crowd_01 := false
var saw_crowd_02 := false
var saw_crowd_03 := false
var saw_crowd_04 := false

var congrats_explosion_executed := false
var museum_explosion_executed := false

# Debug
#var skip_tutorial := false
var force_anomaly := Robot.GLITCHES.NONE
var linear_game := false
var force_dressing := DRESSING.NONE
var reset_save := false
var override_state := true
var state_override := GameStateResource.new()
var fail_all := false
var force_events := true
#var force_completed_scenarios := 10

var shaders_cached := false
var shaders_cached_frame := 0

func _ready() -> void:
	if is_export():
		#skip_tutorial = false
		force_anomaly = Robot.GLITCHES.NONE
		linear_game = false
		force_dressing = DRESSING.NONE
		reset_save = false
		override_state = false
		fail_all = false
		force_events = false
		%LogLabel.visible = false
		%FPSLabel.visible = false
	state_override.congrats_completed = false
	state_override.executive_completed = false
	state_override.completed_anomalies = []
	if override_state:
		tutorial_completed = true
	var force_completed_scenarios = Robot.GLITCHES.size() - 0
	for n in range(1, force_completed_scenarios):
		state_override.completed_anomalies.append(n)
	for n in range(0, force_completed_scenarios/NONE_RATIO):
		state_override.completed_anomalies.append(Robot.GLITCHES.NONE)
	state_override.completed_anomalies.shuffle()
	#
	Global.player = %Player
	load_game_state()
	load_game_settings()
	
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
			var trf := Transform3D()
			trf = trf.scaled(Vector3.ONE * 1.4)
			var x := (width_margin*w) - ((width / 2) * width_margin)
			x += randf() * 0.2
			var z := (width_margin*d) - ((depth / 2) * width_margin)
			trf = trf.translated(Vector3(x, 0, z))
			multi.set_instance_transform((w*width)+d, trf)
	
	if not tutorial_completed:
		%Player.global_position = %InitialPositionInt.global_position
		%Player.look_rot.y = rad_to_deg(%InitialPositionInt.rotation.y)
	#
	unpause(true)
	#
	for e in EVENTS:
		events_enableable_time[EVENTS[e]] = get_next_event_time(EVENTS[e])
		event_enable_time[EVENTS[e]] = 0.0
		event_disable_time[EVENTS[e]] = 0.0
		event_execute_time[EVENTS[e]] = 0.0
		event_was_visible[EVENTS[e]] = false
		disable_event(EVENTS[e], true)
	#
	#next_event_in = get_next_event_time() + 60.0
	turn_lights_on()
	target_exposure = 6.0
	#
	if is_export():
		%FadeWhite.visible = true
		%FadeBlack.visible = true
	else:
		%FadeWhite.visible = false
		%FadeBlack.visible = false

	# Making everything visible to cache shaders
	%ShaderCache.visible = true
	%CongratsParticlesBig_cache.emitting = true
	%CongratsParticlesBigExplosion_cache.emitting = true
	var dressing_nodes: Array[Node3D]= [
		%office_warehouse,
		%office_start,
		%office_tutorial,
		%office_lobby,
		%office_design,
		%office_lab,
		%office_marketing,
		%office_party,
		%office_executive,
		%office_museum,
		%office_congrats
	]
	for dn in dressing_nodes:
		dn.visible = true
		dn.position.y = 0
	
	if Global.is_steam():
		%FollowItchioButton.visible = false

func post_shader_cache() -> void:
	%FadeWhite.visible = true
	%FadeBlack.visible = true

	%ShaderCache.visible = false
	
	reset_dressing()
	$WorldEnvironment.environment.tonemap_exposure = target_exposure
	start_game()
	#
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback($AudioStreamPlayer.play)
	tween.tween_property(%FadeWhite, "modulate:a", 0.0, 2.0)
	tween.parallel().tween_callback(Global.player.unlock_movement).set_delay(0.5)
	#


func check_if_nightmare() -> bool:
	return game_state.executive_completed

func is_export() -> bool:
	return OS.has_feature("template")

## Initializes a game
func start_game() -> void:
	#check_if_nightmare()
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
	selected_scenarios.resize(0)
	if true:
		selected_scenarios = mixed_scenarios.duplicate()
		var nones: Array[int] = []
		var none_amount := Robot.GLITCHES.size() / NONE_RATIO
		if none_amount > none_count:
			for _n in none_amount - none_count:
				nones.append(Robot.GLITCHES.NONE)
		selected_scenarios.append_array(nones)
		# LIGHTS_OFF must be > 9
		
	else:
		var none_probability := 0.3
		if game_state.executive_completed:
			none_probability = 0.2
		if Global.is_nightmare_mode:
			none_probability = 0.0
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
	test_fix_scenario_order()
	fix_scenario_order(selected_scenarios, game_state.completed_anomalies)
	
	scenarios_amount = selected_scenarios.size() + game_state.completed_anomalies.size()
	
	if fail_all:
		failed_scenarios = selected_scenarios.duplicate()
		selected_scenarios.resize(0)
	# Reset vacuum position
	%RobotVacuum.position = Vector3(3, 0, 24)
	%RobotVacuum.rotation_degrees = Vector3(0, -180, 0)
	%RobotVacuum.current_state = %RobotVacuum.STATES.FORWARD
	#
	load_main()

func test_fix_scenario_order() -> void:
	print("test_fix_scenario_order")
	# Door anomaly before Executive
	var com_scenarios:Array[Robot.GLITCHES] = []
	var sel_scenarios:Array[Robot.GLITCHES] = []
	sel_scenarios.append_array(Robot.GLITCHES.values())
	#sel_scenarios.erase(Robot.GLITCHES.LIGHTS_OFF)
	#sel_scenarios[0] = Robot.GLITCHES.LIGHTS_OFF
	print("sel_scenarios", sel_scenarios)
	print("com_scenarios", com_scenarios)
	var res:= fix_scenario_order(sel_scenarios, com_scenarios)
	print("res_scenarios", res)
	print()

func fix_scenario_order(sel_scenarios: Array[Robot.GLITCHES], com_scenarios: Array[Robot.GLITCHES]) -> Array[Robot.GLITCHES]:
	if sel_scenarios.size() == 0:
		return sel_scenarios
	var can_be_moved := Robot.GLITCHES.values()
	can_be_moved.erase(Robot.GLITCHES.NONE)
	can_be_moved.erase(Robot.GLITCHES.DOOR_OPEN)
	#can_be_moved.erase(Robot.GLITCHES.LIGHTS_OFF)
	can_be_moved.erase(Robot.GLITCHES.GRABS_BATTERY)
	var completed_amound := com_scenarios.size()
	var adjusted_floor_amount := FLOORS_AMOUNT - completed_amound
	var adjusted_intro_amount := INTRO_AMOUNT - completed_amound
	prints("adjusted_floor_amount", adjusted_floor_amount)
	prints("adjusted_intro_amount", adjusted_intro_amount)
	# None anomaly spread evenly and without repetition
	if sel_scenarios[0] != Robot.GLITCHES.NONE:
		var none_key = sel_scenarios.find(Robot.GLITCHES.NONE)
		sel_scenarios[none_key] = sel_scenarios[0]
		sel_scenarios[0] = Robot.GLITCHES.NONE
	# Door anomaly before Executive
	if adjusted_floor_amount > 0:
		var door_open_key = sel_scenarios.find(Robot.GLITCHES.DOOR_OPEN) 
		if door_open_key != -1 and door_open_key > adjusted_floor_amount:
			prints("Door anomaly after Executive!", Robot.GLITCHES.DOOR_OPEN)
			var target_keys:Array[Robot.GLITCHES] = []
			for n in range(0, adjusted_floor_amount):
				if can_be_moved.has(sel_scenarios[n]):
					target_keys.append(n)
			if target_keys.size() > 0:
				var target_key:Robot.GLITCHES = target_keys.pick_random()
				print("exchange %d and %d" %[door_open_key, target_key])
				sel_scenarios[door_open_key] = sel_scenarios[target_key]
				sel_scenarios[target_key] = Robot.GLITCHES.DOOR_OPEN
	# Lights off anomaly after congrats
	#if adjusted_intro_amount > 0:
		#var lights_off_key = sel_scenarios.find(Robot.GLITCHES.LIGHTS_OFF) 
		#if lights_off_key != -1 and lights_off_key < adjusted_intro_amount:
			#prints("Lights off anomaly before Congrats!", Robot.GLITCHES.LIGHTS_OFF)
			#var target_keys:Array[Robot.GLITCHES] = []
			#for n in range(adjusted_intro_amount+1, sel_scenarios.size()):
				#if can_be_moved.has(sel_scenarios[n]):
					#target_keys.append(n)
			#if target_keys.size() > 0:
				#var target_key:Robot.GLITCHES = target_keys.pick_random()
				#print("exchange %d and %d" %[lights_off_key, target_key])
				#sel_scenarios[lights_off_key] = sel_scenarios[target_key]
				#sel_scenarios[target_key] = Robot.GLITCHES.LIGHTS_OFF
	# Grab battery before congrats
	if adjusted_intro_amount > 0:
		var grabs_battery_key = sel_scenarios.find(Robot.GLITCHES.GRABS_BATTERY) 
		if grabs_battery_key != -1 and grabs_battery_key > adjusted_intro_amount:
			prints("Door anomaly after Congrats!", Robot.GLITCHES.GRABS_BATTERY)
			var target_keys:Array[Robot.GLITCHES] = []
			for n in range(0, adjusted_intro_amount):
				if can_be_moved.has(sel_scenarios[n]):
					target_keys.append(n)
			if target_keys.size() > 0:
				var target_key:Robot.GLITCHES = target_keys.pick_random()
				print("exchange %d and %d" %[grabs_battery_key, target_key])
				sel_scenarios[grabs_battery_key] = sel_scenarios[target_key]
				sel_scenarios[target_key] = Robot.GLITCHES.GRABS_BATTERY
	return sel_scenarios

func _process(delta: float) -> void:
	if shaders_cached_frame > 5 and not shaders_cached:
		shaders_cached = true
		post_shader_cache()
	if not shaders_cached:
		shaders_cached_frame += 1
		return
	
	if robot_collected:
		match current_task:
			TASKS.ROTATE:
				robot_collected.rotate_base(delta)
			TASKS.ROTATE_INVERSE:
				robot_collected.rotate_base(delta, true)
			TASKS.BATTERY_CHARGE:
				robot_collected.play_process()
				if robot_collected.charge_battery(delta):
					current_task = TASKS.NONE
					robot_collected.play_process(true)
			TASKS.SHUT_DOWN:
				robot_collected.play_process()
				if robot_collected.shutdown(delta):
					current_task = TASKS.NONE
					robot_collected.play_process(true)
	
	var robot_id = -1
	if robot_collected:
		robot_id = robot_collected.robot_id
	%RobotIdLabel.text = "R%d - %d" % [robot_id, battery_collected]
	%TimeLabel.text = "Day %d" % day
	
	%TaskProgressBar.value = (100.0 / task_duration) * task_timer
	
	if check_if_nightmare():
		%StairObject.chain_visible = false
		%StairObject2.chain_visible = false
	
	const disabled_sections := [
		-1,
		-2,
		-3,
		-4
	]
	
	if not lights_on:
		#print(section.scenario)
		if disabled_sections.has(section.scenario):
			lights_timer += delta * 10.0
		else:
			lights_timer += delta
	if lights_timer > 30.0:
		turn_lights_on()
	
	
	event_light_timer -= delta
	if lights_delay >= 0.0:
		lights_delay -= delta
		if lights_delay < 0.0 and \
				not disabled_sections.has(section.scenario) and \
				Global.is_player_in_room:
			turn_lights_off()
	
	game_state.seconds += delta
	%Clock.seconds = game_state.seconds
	GamePlatform.stats["time_played"] = int(game_state.seconds / 60.0)
	
	if not is_export():
		%FPSLabel.text = "%f" % Engine.get_frames_per_second()
	
	update_executive()
	update_congrats()
	update_museum()
	update_start()
	update_events(delta)
	update_cursor(delta)
	refresh_reflection_probe(delta)

func turn_lights_on() -> void:
	%LightSwitch3.turn_on_off()
	lights_on = true
	event_light_timer = randf_range(60.0*7, 60.0*15)
	lights_timer = 0.0

func turn_lights_off(delay:=0.0) -> void:
	if delay == 0.0:
		%LightSwitch3.turn_on_off()
		lights_on = false
		lights_timer = 0.0
	else:
		event_light_timer = randf_range(60.0*7, 60.0*15)
		# This function will be called in [delay] seconds
		lights_delay = delay

func get_next_event_time(event: EVENTS) -> float:
	if force_events:
		return 5.0
	return randf_range(60.0*10, 60.0*20)

func reset_events_timer(event: EVENTS, short_reset:=false) -> void:
	events_enableable_time[event] = get_next_event_time(event)
	if short_reset:
		events_enableable_time[event] *= 0.25

func event_enable_conditions(event: EVENTS) -> bool:
	if events_enableable_time[event] > 0.0: return false
	const disabled_sections := [
		#Robot.GLITCHES.LIGHTS_OFF,
		-1,
		-2,
		-3,
		-4
	]
	if disabled_sections.has(section.scenario): return false
	if section.scenario == Robot.GLITCHES.EXTRA_ROBOTS and event == EVENTS.REPORT:
		return false
	
	#if current_events.has(event): return false
	
	#if seen_events.has(event): return false
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	#print(player_pos)
	var enable := false
	
	var ventilation_pos_2d := Vector2(%EventVentilationAngle.position.x, %EventVentilationAngle.position.z)
	var player_pos_2d := Vector2(player_pos.x, player_pos.z)
	var angle_rad := player_pos_2d.angle_to_point(ventilation_pos_2d)
	var ventilation_angle := rad_to_deg(angle_rad)
	#prints(ventilation_angle)
	
	%LogLabel.text = "%d, %d" % [player_pos_2d.x, player_pos_2d.y]
	
	match event:
		EVENTS.VENTILATION:
			# Player at center, not looking at ventilation
			if Global.is_player_in_room and \
					#Global.is_nomber_between(player_pos.z, -5, 5) and \
					player_pos.x < 1 and \
					( \
						Global.is_nomber_between(ventilation_angle, -37, 15) or\
						Global.is_nomber_between(ventilation_angle, -64, -48) or\
						Global.is_nomber_between(ventilation_angle, 37, 55)\
					) and \
					not (%EventVentilationOnScreen.is_on_screen() and \
					not current_events.has(EVENTS.VENTILATION))\
					# Keeps event enabled if is on screen and already enabled
					# or (%EventVentilationOnScreen.is_on_screen() and current_events.has(EVENTS.VENTILATION)):
					:
				enable = true
		EVENTS.REPORT:
			# Player at center, not looking at ventilation
			if Global.is_player_in_room and \
					(
						Global.is_point_inside(-2, 2, 8, 15, player_pos_2d) or\
						Global.is_nomber_between(player_pos.z, 15, 18)
					) and \
					not (%EventReportOnScreen.is_on_screen() and not current_events.has(EVENTS.REPORT))\
					# Keeps event enabled if is on screen and already enabled
					# or (%EventReportOnScreen.is_on_screen() and current_events.has(EVENTS.REPORT)):
					:
				enable = true
		EVENTS.EXIT:
			# Player at center, not looking at ventilation
			if Global.is_player_in_room and \
					(
						#Global.is_nomber_between(player_pos.z, -20, -16) or \
						# Center
						Global.is_point_inside(-2, 2, -8, -19, player_pos_2d) or \
						# Left
						Global.is_point_inside(-4, -2, -10, -16, player_pos_2d)
					) and \
					not (%EventExitOnScreen.is_on_screen() and not current_events.has(EVENTS.EXIT))\
					# Keeps event enabled if is on screen and already enabled
					#or (%EventExitOnScreen.is_on_screen() and current_events.has(EVENTS.EXIT)):
					:
				enable = true
		EVENTS.CEILING:
			# Player at center, not looking at ventilation
			if Global.is_player_in_room and \
					(
						player_pos.z < -16 or \
						# Center
						Global.is_point_inside(-2, 2, -8, -19, player_pos_2d) or \
						# Left
						Global.is_point_inside(-4, -2, -16, -7, player_pos_2d) or \
						# Right
						Global.is_point_inside(2, 4, -16, -13, player_pos_2d) \
					) and\
					not (%EventCeilingOnScreen.is_on_screen() and not current_events.has(EVENTS.CEILING))\
					# Keeps event enabled if is on screen and already enabled
					#or (%EventCeilingOnScreen.is_on_screen() and current_events.has(EVENTS.CEILING)):
					:
				enable = true
		EVENTS.LINE:
			if Global.is_player_in_room and \
					Global.is_nomber_between(player_pos.z, 0, 17) and \
					player_pos.x > 3 and \
					not (%OnScreenEventLine.is_on_screen() and not current_events.has(EVENTS.LINE)) \
					# Keeps event enabled if is on screen and already enabled
					#or (%OnScreenEventLine.is_on_screen() and current_events.has(EVENTS.LINE)):
					:
				enable = true
		
		
	match event:
		EVENTS.VENTILATION:
			if current_events.has(EVENTS.VENTILATION):
				if %EventVentilationOnScreen.is_on_screen():
					event_was_visible[EVENTS.VENTILATION] = true
				elif event_was_visible[EVENTS.VENTILATION]:
					enable = false
		EVENTS.REPORT:
			if current_events.has(EVENTS.REPORT):
				if %EventReportOnScreen.is_on_screen():
					event_was_visible[EVENTS.REPORT] = true
				elif event_was_visible[EVENTS.REPORT]:
					enable = false
		EVENTS.EXIT:
			if current_events.has(EVENTS.EXIT):
				if %EventExitOnScreen.is_on_screen():
					event_was_visible[EVENTS.EXIT] = true
				elif event_was_visible[EVENTS.EXIT]:
					enable = false
		EVENTS.CEILING:
			if current_events.has(EVENTS.CEILING):
				if %EventCeilingOnScreen.is_on_screen():
					event_was_visible[EVENTS.CEILING] = true
				elif event_was_visible[EVENTS.CEILING]:
					enable = false
		EVENTS.LINE:
			#print(event_was_visible[EVENTS.LINE])
			if current_events.has(EVENTS.LINE):
				if %OnScreenEventLine.is_on_screen():
					event_was_visible[EVENTS.LINE] = true
				elif event_was_visible[EVENTS.LINE]:
					enable = false
				
	return enable

# TODO add timer to disable and enable
func maybe_enable_event(delta: float) -> void:
	const time_threshold := 0.5
	for event in EVENTS.values():
		if event_enable_conditions(event):
			event_enable_time[event] += delta
			event_disable_time[event] = 0.0
			if event_enable_time[event] > time_threshold:
				enable_event(event)
		else:
			event_disable_time[event] += delta
			event_enable_time[event] = 0.0
			if event_disable_time[event] > time_threshold:
				disable_event(event)

func disable_event(_event:EVENTS, force:=false) -> void:
	if not current_events.has(_event) and not force: return
	prints("Disabling event", EVENTS.find_key(_event))
	event_was_visible[_event] = false
	current_events.erase(_event)
	reset_events_timer(_event, true)
	match _event:
		EVENTS.VENTILATION:
			%RobotEventVentilation.remove_base()
			%RobotEventVentilation.play_animation("EventVentilation")
			#%EventVentilationAudio.position.x = 4.25
			%RobotEventVentilation.visible = false
			%RobotEventVentilation.disable_colliders()
			%RobotEventVentilation.silence_motor()
		EVENTS.REPORT:
			%RobotEventReport.remove_base()
			%RobotEventReport.visible = false
			%RobotEventReport.disable_colliders()
			%RobotEventReport.silence_motor()
		EVENTS.EXIT:
			%RobotEventExit.remove_base()
			%RobotEventExit.play_animation("EventExit")
			%RobotEventExit.visible = false
			%RobotEventExit.disable_colliders()
			%RobotEventExit.silence_motor()
		EVENTS.CEILING:
			%RobotEventCeiling.remove_base()
			%RobotEventCeiling.play_animation("EventCeiling")
			%RobotEventCeiling.visible = false
			%RobotEventCeiling.disable_colliders()
			%RobotEventCeiling.silence_motor()
		EVENTS.LINE:
			%RobotEventLine.remove_base()
			%RobotEventLine.play_animation("EventLine")
			%RobotEventLine.visible = false
			%RobotEventLine.disable_colliders()
			%RobotEventLine.silence_motor()

func enable_event(_event:EVENTS) -> void:
	if current_events.has(_event): return
	current_events.append(_event)
	prints("Enabling event", EVENTS.find_key(_event))
	match _event:
		EVENTS.VENTILATION:
			%RobotEventVentilation.visible = true
			%RobotEventVentilation.first_frame_animation("EventVentilation")
		EVENTS.REPORT:
			%RobotEventReport.visible = true
			%RobotEventReport.first_frame_animation("EventReport")
		EVENTS.EXIT:
			%RobotEventExit.visible = true
			%RobotEventExit.first_frame_animation("EventExit")
		EVENTS.CEILING:
			%RobotEventCeiling.visible = true
			%RobotEventCeiling.first_frame_animation("EventCeiling")
		EVENTS.LINE:
			%RobotEventLine.visible = true
			%RobotEventLine.first_frame_animation("EventLine")
	#print(_event)

func is_point_centered(object: Node3D, cursor_treshold: float, angle_treshold: float, distance: float = 5.0) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam.is_position_behind(object.global_position):
		return false
	var screen_pos := cam.unproject_position(object.global_position)
	var screen_size := get_viewport().get_visible_rect().size
	
	if not(Global.is_nomber_between(screen_pos.x, 0, screen_size.x) and Global.is_nomber_between(screen_pos.y, 0, screen_size.y)):
		return false
		
	var screen_ratio := screen_pos / screen_size
	
	#print (screen_pos, screen_size, screen_ratio)
	
	if Global.is_nomber_between(screen_ratio.x, cursor_treshold, 1.0-cursor_treshold) \
			and Global.is_nomber_between(screen_ratio.y, cursor_treshold, 1.0-cursor_treshold):
		#prints("x:", screen_ratio.x, cursor_treshold, 1.0-cursor_treshold)
		#prints("y:", screen_ratio.y, cursor_treshold, 1.0-cursor_treshold)
		return true
	
	return false

func is_point_centered_old(object: Node3D, cursor_treshold: float, angle_treshold: float, distance: float = 5.0) -> bool:
	# NOTE Distance from margins
	var cam := get_viewport().get_camera_3d()
	var screen_pos := cam.unproject_position(object.global_position) / get_viewport().get_visible_rect().size
	var dist := Vector2(0.5, 0.5).distance_to(screen_pos)
	if cam.is_position_behind(object.global_position):
		return false

	var object_vector := (cam.global_position - object.global_position).normalized()
	
	var object_vector_2:Vector3 = object.global_basis * Vector3.RIGHT
	var dot := object_vector.dot(object_vector_2)
	
	var flat_object_position := object.global_position
	flat_object_position.y = 0
	var flat_player_position := Global.player.global_position
	flat_player_position.y = 0
	
	var player_dist := flat_object_position.distance_to(flat_player_position)
	
	# dist < cursor_treshold
	# dot > angle_treshold
	# player_dist < distance
	
	return dist < cursor_treshold and \
		dot > angle_treshold and \
		player_dist < distance

func too_close_to_event(event_pos: Node3D, robot: Robot, min_dist: float = 0.0) -> bool:
	var flat_object_position := event_pos.global_position
	flat_object_position.y = 0
	var flat_player_position := Global.player.global_position
	flat_player_position.y = 0
	
	var player_dist := flat_object_position.distance_to(flat_player_position)
	var is_too_close := player_dist < min_dist and robot.is_on_screen() or \
						player_dist < min_dist * 0.5
	if is_too_close:
		print("Too close!")
	return is_too_close

func update_events(delta: float) -> void:
	#event_watch_timer += delta
	for e in EVENTS:
		events_enableable_time[EVENTS[e]] -= delta
	maybe_enable_event(delta)
	
	const execute_threshold := 0.3
	
	if current_events.has(EVENTS.VENTILATION):
		if is_point_centered(%EventVentilationVisible, 0.3, 0.6, 10.0):
			event_execute_time[EVENTS.VENTILATION] += delta
		else:
			event_execute_time[EVENTS.VENTILATION] = 0.0
		if event_execute_time[EVENTS.VENTILATION] > execute_threshold:
			print("Executing event Ventilation")
			event_execute_time[EVENTS.VENTILATION] = 0.0
			reset_events_timer(EVENTS.VENTILATION)
			%EventVentilationAudio.position.x = 4.148
			current_events.erase(EVENTS.VENTILATION)
			#seen_events.append(EVENTS.VENTILATION)
			%RobotEventVentilation.play_animation("EventVentilation")
			$Stinger.play()
			var tween := create_tween()
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			#tween.tween_interval(0.2)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
			tween.tween_interval(1.0)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			tween.tween_callback(%RobotEventVentilation.set_visible.bind(false))
			tween.tween_callback(%EventVentilationAudio.play)
			#tween.tween_interval(0.1)
			tween.tween_property(%EventVentilationAudio, "position:x", 50, 3)
			#tween.parallel().tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.02)
	if current_events.has(EVENTS.REPORT):
		if is_point_centered(%EventReportVisible, 0.2, 0.5, 20.0) or \
				too_close_to_event(%EventReportVisible, %RobotEventReport, 2.0):
			event_execute_time[EVENTS.REPORT] += delta
		else:
			event_execute_time[EVENTS.REPORT] = 0.0
		if event_execute_time[EVENTS.REPORT] > execute_threshold:
			print("Executing event Report")
			event_execute_time[EVENTS.REPORT] = 0.0
			reset_events_timer(EVENTS.REPORT)
			current_events.erase(EVENTS.REPORT)
			#seen_events.append(EVENTS.REPORT)
			%RobotEventReport.play_animation("EventReport")
			$Stinger.play()
			var tween := create_tween()
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			#tween.tween_interval(0.2)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
			tween.tween_interval(1.0)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			tween.tween_callback(%RobotEventReport.set_visible.bind(false))
			#tween.tween_callback(%EventReportAudio.play)
			#tween.tween_interval(0.1)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
	if current_events.has(EVENTS.EXIT):
		if is_point_centered(%EventExitVisible, 0.2, 0.55, 10.0) or \
				too_close_to_event(%EventExitVisible, %RobotEventExit, 4.0):
			event_execute_time[EVENTS.EXIT] += delta
		else:
			event_execute_time[EVENTS.EXIT] = 0.0
		if event_execute_time[EVENTS.EXIT] > execute_threshold:
			print("Executing event Exit")
			event_execute_time[EVENTS.EXIT] = 0.0
			reset_events_timer(EVENTS.EXIT)
			current_events.erase(EVENTS.EXIT)
			#seen_events.append(EVENTS.EXIT)
			%RobotEventExit.play_animation("EventExit")
			$Stinger.play()
			var tween := create_tween()
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			#tween.tween_interval(0.2)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
			tween.tween_interval(0.8)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			tween.tween_callback(%RobotEventExit.set_visible.bind(false))
			tween.tween_callback(%EventExitAudio.play)
			#tween.tween_interval(0.1)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
	if current_events.has(EVENTS.CEILING):
		if is_point_centered(%EventCeilingVisible, 0.1, 0.6, 20.0):
			event_execute_time[EVENTS.CEILING] += delta
		else:
			event_execute_time[EVENTS.CEILING] = 0.0
		if event_execute_time[EVENTS.CEILING] > execute_threshold:
			event_execute_time[EVENTS.CEILING] = 0.0
			print("Executing event Ceiling")
			reset_events_timer(EVENTS.CEILING)
			current_events.erase(EVENTS.CEILING)
			#seen_events.append(EVENTS.CEILING)
			%RobotEventCeiling.play_animation("EventCeiling")
			$Stinger.play()
			var tween := create_tween()
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			#tween.tween_interval(0.2)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
			tween.tween_interval(0.8)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", 0.015, 0.05)
			tween.tween_callback(%RobotEventCeiling.set_visible.bind(false))
			#tween.tween_callback(%EventCeilingAudio.play)
			#tween.tween_interval(0.1)
			#tween.tween_property($WorldEnvironment.environment, "tonemap_exposure", target_exposure, 0.05)
	if current_events.has(EVENTS.LINE):
		if is_point_centered(%VisibleEventLine, 0.17, 0.6, 20.0):
			event_execute_time[EVENTS.LINE] += delta
		else:
			event_execute_time[EVENTS.LINE] = 0.0
		if event_execute_time[EVENTS.LINE] > execute_threshold:
			print("Executing event Line")
			event_execute_time[EVENTS.LINE] = 0.0
			reset_events_timer(EVENTS.LINE)
			current_events.erase(EVENTS.LINE)
			%RobotEventLine.play_animation("EventLine")
			$Stinger.play()
			var tween := create_tween()
			tween.tween_interval(0.733)
			tween.tween_callback(%RobotEventLine.set_visible.bind(false))

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
	%RobotStrike.remove_base()
	%RobotStrike.robot_position(Vector3(-3.89, 0, 0.492))
	%RobotStrike.robot_rotation(deg_to_rad(-93))
	%RobotStrike.rotation = Vector3.ZERO
	%RobotStrike.position = Vector3(0, -100, 0)
	%CrowdMultiMeshStorage.visible = false
	%RobotVacuum.global_position = %ExecVacuumMarker.global_position
	%RobotVacuum.global_rotation = %ExecVacuumMarker.global_rotation
	%RobotVacuum.current_state = %RobotVacuum.STATES.CIRCLES
	#
	%StairSign.visible = false

var exec_done := false
var door_open := false
func update_executive() -> void:
	if section.scenario != -3: return
	if exec_done: return
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	var pos: float = player_pos.z + 25
	#print(pos)
	#TODO move code to robot
	if saw_crowd_01 and \
			saw_crowd_02 and \
			saw_crowd_03 and \
			saw_crowd_04 and %DoorOnScreenSmall.is_on_screen() and not door_open:
		#%RobotStrike.stalk_player = Robot.STALK.SHOWUP
		open_storage_door(false)
		door_open = true
	else:
		#%RobotStrike.stalk_player = Robot.STALK.FOLLOW
		pass
	if Global.is_player_in_storage and %DoorOnScreenSmall.is_on_screen():
		close_storage_door()
		%RobotStrike.position.y = 0
		exec_done = true
		on_executive_finished()
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

func update_congrats() -> void:
	if section.scenario != -1: return
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	var pos: float = player_pos.z + 25
	if pos < 15 and not game_state.congrats_completed:
		turn_lights_off()
		game_state.congrats_completed = true
		%RobotsOnTheFloor.visible = false
	if not congrats_explosion_executed:
		if pos < 45:
			var tween_particles := create_tween()
			tween_particles.tween_callback(%CongratsParticlesBigExplosion1.set_emitting.bind(true))
			tween_particles.tween_callback(%CongratsParticlesAudio1.play)
			tween_particles.tween_interval(0.1)
			tween_particles.tween_callback(%CongratsParticlesBigExplosion2.set_emitting.bind(true))
			tween_particles.tween_callback(%CongratsParticlesAudio2.play)
			tween_particles.tween_callback(%CongratsParticlesBig.set_emitting.bind(true))
			#%CongratsParticlesBigExplosion2.emitting = true
			#%CongratsParticlesBig.emitting = true
			congrats_explosion_executed = true
			GamePlatform.set_achievement("WAKE_UP_REACHED")
	else:
		if %BalloonsCongrats.get_children().size() < 40:
			var ball = preload("res://physics_balloon.tscn").instantiate()
			ball.position.x = randf_range(-3.5, 3.6)
			ball.position.y = 3.0
			ball.position.z = randf_range(-15, 0)
			ball.rotation.x = randf() * PI * 2
			ball.rotation.y = randf() * PI * 2
			ball.rotation.z = randf() * PI * 2
			%BalloonsCongrats.add_child(ball)

func on_executive_finished():
	
	var reset := func():
		game_state.executive_completed = true
		tutorial_completed = false
		#current_side = SIDES.Z_PLUS
		#completed_scenarios.resize(0)
		selected_scenarios.resize(0)
		failed_scenarios.resize(0)
		start_game()
		reset_position()
		Global.player.lock_movement()
		GamePlatform.set_achievement("TRAPPED_REACHED")
	
	var exec_tween := create_tween()
	exec_tween.tween_interval(2.5)
	#
	exec_tween.tween_property(%FadeBlack, "modulate:a", 1.0, 4.0)
	exec_tween.tween_callback(reset.call_deferred)
	exec_tween.tween_interval(3.0)
	exec_tween.tween_callback($AudioStreamPlayer.play)
	exec_tween.tween_property(%FadeBlack, "modulate:a", 0.0, 4.0)
	exec_tween.parallel().tween_callback(Global.player.unlock_movement).set_delay(1.0)

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
	prints("Global.reset_save", Global.reset_save)
	game_state = load(save_path)
	if override_state:
		game_state = state_override
	if reset_save or not ResourceLoader.exists(save_path) or Global.reset_save:
		var old_seconds := game_state.seconds
		game_state = GameStateResource.new()
		game_state.seconds = old_seconds
		Global.reset_save = false
		print("Reset game save")
		return
	if game_state.completed_anomalies.size() < INTRO_AMOUNT:
		if not override_state:
			game_state.completed_anomalies.resize(0)
	else:
		print("Tutorial completed")
		tutorial_completed = true

func save_game_settings() -> void:
	ResourceSaver.save(game_settings, settings_path)

## From file
func load_game_settings() -> void:
	if not ResourceLoader.exists(settings_path):
		game_settings = GameSettingsResource.new()
	else:
		game_settings = load(settings_path)
	load_settings()

func load_settings() -> void:
	%VolumeSlider.set_value_no_signal(game_settings.volume_level)
	%MouseSenSlider.set_value_no_signal(game_settings.mouse_sensibility)
	%MouseAccSlider.set_value_no_signal(game_settings.mouse_acceleration)
	%CameraShakeSlider.set_value_no_signal(game_settings.camera_shake)
	%FullscreenCheckBox.set_pressed_no_signal(game_settings.full_screen)
	%VSyncCheckBox.set_pressed_no_signal(game_settings.vsync)
	%MaxFPSSpin.set_value_no_signal(game_settings.max_fps)
	Global.player.sensitivity = remap(game_settings.mouse_sensibility, 0, 100, 0.01, 2.0)
	Global.player.rotation_accel = game_settings.mouse_acceleration
	Global.player.camera_shake = game_settings.camera_shake
	Global.player.update_breathing_tween()
	var volume_level := remap(game_settings.volume_level, 0, 100, -30, 20)
	var sfx_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(sfx_index, volume_level)
	if game_settings.volume_level < 5:
		AudioServer.set_bus_mute(sfx_index, true)
	else:
		AudioServer.set_bus_mute(sfx_index, false)
	if game_settings.full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if game_settings.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = game_settings.max_fps
	prints("Mouse sensibility", Global.player.sensitivity, %MouseSenSlider.value)
	prints("Camera Acceleration", %MouseAccSlider.value)
	prints("Camera shake", %CameraShakeSlider.value)
	prints("Volume", volume_level, %VolumeSlider.value)

func load_main() -> void:
	robot_collected = null
	save_game_state()
	reset_environment()
	instantiate_sections(%Environment)

func reset_dressing() -> void:
	var dressing_nodes: Array[Node3D]= [
		%office_warehouse,
		%office_start,
		%office_tutorial,
		%office_lobby,
		%office_design,
		%office_lab,
		%office_marketing,
		%office_party,
		%office_executive,
		%office_museum,
		%office_congrats
	]
	for dn in dressing_nodes:
		dn.visible = false
		dn.position.y = -20
	%CongratsParticlesBig.emitting = false
	%CongratsParticlesBigExplosion1.emitting = false
	%CongratsParticlesBigExplosion2.emitting = false
	%CrowdMultiMeshStorage.visible = false
	#
	%StairSign.visible = true

func dressing_visible(dressing_node: Node3D) -> void:
	dressing_node.visible = true
	dressing_node.position.y = 0

var start_scape_executed := false
func update_start() -> void:
	if section.scenario != -2: return
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	#print(player_pos.z)
	if not start_scape_executed:
		if player_pos.z < 15:
			start_scape_executed = true
			turn_lights_off()
			%WoodCratesCovers.visible = true
			for c in %WoodCratesToOpen.get_children():
				c.is_open = true
			for c in %StartSmashAudios.get_children():
				c.play()
			%StartRunningRobots.visible = true
			for c in %StartRunningRobots.get_children():
				var r_tween := create_tween()
				r_tween.tween_interval(0.5)
				r_tween.tween_property(c, "position:z", -30, randf_range(0.5, 1.0))
				r_tween.parallel().tween_property(c, "position:y", -1, randf_range(0.5, 1.0))
	if start_scape_executed and lights_on:
		%StartRunningRobots.visible = false
		%DarknessCollision.set_collision_layer_value(1, false)

func setup_start() -> void:
	%WoodCratesCovers.visible = false
	%StartRunningRobots.visible = false

func update_museum() -> void:
	if section.scenario != -4: return
	if selected_scenarios.size() != 0: return
	var player_pos: Vector3= %MainOfficeWithCollision.to_local(Global.player.global_position)
	var pos: float = player_pos.z + 25
	if not museum_explosion_executed:
		if pos < 20:
			var tween_particles := create_tween()
			tween_particles.tween_callback(%CongratsParticlesBigExplosion3.set_emitting.bind(true))
			tween_particles.tween_callback(%CongratsParticlesAudio3.play)
			tween_particles.tween_interval(0.1)
			tween_particles.tween_callback(%CongratsParticlesBigExplosion4.set_emitting.bind(true))
			tween_particles.tween_callback(%CongratsParticlesAudio4.play)
			tween_particles.tween_callback(%CongratsParticlesBig2.set_emitting.bind(true))
			museum_explosion_executed = true
			GamePlatform.set_achievement("MASTERMIND_REACHED")

func setup_museum() -> void:
	var anomalies_count := 0
	for _n in game_state.completed_anomalies:
		if _n != Robot.GLITCHES.NONE:
			anomalies_count += 1
	%MuseumStatsLabel.text = "%s\n" % tr("FOUND ANOMALIES")
	%MuseumStatsLabel.text += "%d / %d\n" % [anomalies_count, Robot.GLITCHES.size()-1]
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
	
	if selected_scenarios.size() == 0:
		%VacuumReveal.position.y = 0
		%StairSign.visible = false
		%StairSign2.visible = false
		%RobotVacuum.global_position = %VacuumRevealMarker.global_position
		%RobotVacuum.global_rotation = %VacuumRevealMarker.global_rotation
		%RobotVacuum.current_state = %RobotVacuum.STATES.STILL
	else:
		%VacuumReveal.position.y = -20

func instantiate_sections(Env: Node3D) -> void:
	prints("Selected Scenarios", selected_scenarios)
	prints("Failed Scenarios", failed_scenarios)
	#prints("Completed Scenarios", completed_scenarios)
	prints("Completed Anomalies", game_state.completed_anomalies)
	var scenario = 0
	if force_anomaly != Robot.GLITCHES.NONE:
		scenario = force_anomaly
	elif not tutorial_completed and not museum_completed and ((not game_state.congrats_completed) or game_state.executive_completed):
		if game_state.executive_completed:
			scenario = -4 # Museum
		else:
			scenario = -2 # Tutorial
	#elif completed_scenarios.size() >= 8 and not game_state.congrats_completed:
	elif game_state.completed_anomalies.size() >= INTRO_AMOUNT and not game_state.congrats_completed:
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
	section.is_nightmare_mode = check_if_nightmare()
	section.level = available_scenarios_count
	#section.batteries_charged_required = not(game_state.completed_anomalies.size() < INTRO_AMOUNT)
	section.connect("glitch_failed", on_glitch_failed)
	section.connect("request_environment_change", on_environment_change)
	#%LevelCountLabel.text = "%d" % (scenario_count - available_scenarios_count)
	#var anomalies_count := Robot.GLITCHES.size()-1
	#var completed_anomalies_count := game_state.completed_anomalies.size()
	%FloorData_A2.text = "%d" % (FLOORS_AMOUNT - INTRO_AMOUNT)
	%FloorData_B2.text = "%d" % 0
	%FloorData_C2.text = "%d" % (FLOORS_AMOUNT - scenarios_amount)
	#
	#%TasksLabel2.text = "Anomalous activity detected!"
	#%TasksLabel3.text = "Shutdown any suspicious robot"
	#if not(game_state.completed_anomalies.size() < INTRO_AMOUNT) or true:
		#%TasksLabel.text = "Remove battery from all robots"
	#%TasksLabel4.text = "Go to the ground floor"
	#if game_state.completed_anomalies.size() < FLOORS_AMOUNT:
		#%TasksLabel5.text = "Robot without battery, harmless robot"
	#%TasksLabel.text += "\n\n> Never go back!"
	if [-1, -2, -3, -4].has(scenario) and false:
		%LevelCountLabel.mesh.text = "-"
	else:
		#%LevelCountLabel.mesh.text = "%d" % (game_state.completed_anomalies.size() + 1)
		var floor_number := FLOORS_AMOUNT - game_state.completed_anomalies.size()
		if game_state.executive_completed:
			floor_number -= 1
		%LevelCountLabel.mesh.text = "%d" % floor_number
	if false:
		if game_state.completed_anomalies.size() < INTRO_AMOUNT and not game_state.congrats_completed:
			%TotalLevelsCountLabel.mesh.text = "/ %d" % INTRO_AMOUNT
		#elif game_state.executive_completed:
		#	%TotalLevelsCountLabel.mesh.text = "/ %d" % (anomalies_count-completed_anomalies_count)
		elif game_state.completed_anomalies.size() < FLOORS_AMOUNT:
			%TotalLevelsCountLabel.mesh.text = "/ %d" % FLOORS_AMOUNT
		else:
			%TotalLevelsCountLabel.mesh.text = "/ %d" % scenarios_amount
	else:
		%TotalLevelsCountLabel.mesh.text = ""
		
	#main.level = scenarios.size() - n
	section.scenario = scenario
	#section.last_day = available_scenarios_count <= batch_count
	#var message_id := FLOORS_AMOUNT-available_scenarios_count
	#var message_id := completed_scenarios.size()
	var message_id := game_state.completed_anomalies.size()
	reset_dressing()
	prints("message_id", message_id)
	hide_all_lines()
	var LINE_NAMES = %MainOfficeWithCollision.LINE_NAMES
	if scenario == -2: # Tutorial
		#dressing_visible(%office_tutorial)
		#dressing_visible(%office_lobby)
		dressing_visible(%office_start)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_C)
		setup_start()
	elif scenario == -3: # Executive
		%MessageLabel.text = "Executive"
		dressing_visible(%office_executive)
		setup_executive()
		show_line_upto(LINE_NAMES.LINEA_B_END)
	elif scenario == -4: # Museum
		%MessageLabel.text = "Museum"
		dressing_visible(%office_museum)
		if selected_scenarios.size() == 0:
			show_line_upto(LINE_NAMES.LINEA_A_END)
		else:
			show_line_upto(LINE_NAMES.LINEA_A)
		#check_if_nightmare()
		#if Global.is_nightmare_mode:
			#%NightmareModeIndicator.visible = true
		#else:
			#%NightmareModeIndicator.visible = false
		setup_museum()
		#$UberLightmapGI.light_data = preload("res://lightmaps/museum_office.lmbake")
	elif scenario == -1: # Congrats
		dressing_visible(%office_congrats)
		show_line_upto(LINE_NAMES.LINEA_C_END)
	#elif message_id <= 0:
		#%MessageLabel.text = "Lobby"
		#dressing_visible(%office_lobby)
		#dressing_visible(%office_warehouse)
	elif message_id <= 3:
		%MessageLabel.text = "Lab"
		dressing_visible(%office_lab)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_C)
		#$UberLightmapGI.light_data = preload("res://lightmaps/lab_office.lmbake")
	elif message_id <= 7:
		%MessageLabel.text = "Design Room"
		dressing_visible(%office_design)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_C)
		#$UberLightmapGI.light_data = preload("res://lightmaps/design_office.lmbake")
	#elif message_id <= 25:
		#%MessageLabel.text = "Lab"
		#dressing_visible(%office_lab)
		#dressing_visible(%office_warehouse)
	elif message_id <= 12:
		%MessageLabel.text = "Marketing"
		dressing_visible(%office_marketing)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_B)
		#$UberLightmapGI.light_data = preload("res://lightmaps/marketing_office.lmbake")
	elif message_id <= 17 and not game_state.executive_completed:
		%MessageLabel.text = "Party"
		dressing_visible(%office_party)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_B)
		#$UberLightmapGI.light_data = preload("res://lightmaps/party_office.lmbake")
	else:
		# Underground
		%MessageLabel.text = "Underground"
		dressing_visible(%office_lobby)
		dressing_visible(%office_warehouse)
		show_line_upto(LINE_NAMES.LINEA_A)
		var robot_pics: Array[Node3D]= [
			%RobotPictureFrame,
			%RobotPictureFrame2,
			%RobotPictureFrame3,
			%RobotPictureFrame4
		]
		for rp in robot_pics:
			rp.visible = false
		var rp:Node3D = robot_pics.pick_random()
		rp.visible = true
	
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
	
	%StairSign2.visible = check_if_nightmare()
	if scenario == -3:
		%StairSign2.visible = false
	const audio_distance := 50.0
	var city_audio_distance := clampf(remap(message_id, 0, INTRO_AMOUNT, 0, audio_distance), 0, audio_distance)
	var street_audio_distance := clampf(remap(message_id, 0, INTRO_AMOUNT, audio_distance, 0), 0, audio_distance)
	prints("city_audio_distance", city_audio_distance)
	prints("street_audio_distance", street_audio_distance)
	%CityAudio.position.z = city_audio_distance
	%CityAudio2.position.z = city_audio_distance
	%StreetAudio.position.z = street_audio_distance
	%StreetAudio2.position.z = street_audio_distance
	if message_id > 25:
		%CityAudio.stop()
		%CityAudio2.stop()
		%StreetAudio.stop()
		%StreetAudio2.stop()
		if not %UndergroundAudio.playing:
			%UndergroundAudio.play()
		if not %UndergroundAudio2.playing:
			%UndergroundAudio2.play()
	else:
		%UndergroundAudio.stop()
		%UndergroundAudio2.stop()
		if not %CityAudio.playing:
			%CityAudio.play()
		if not %CityAudio2.playing:
			%CityAudio2.play()
		if not %StreetAudio.playing:
			%StreetAudio.play()
		if not %StreetAudio2.playing:
			%StreetAudio2.play()
	#
	var creepy_music_tween := create_tween()
	const creepy_music_volume := -20.0
	if [-1, -3, -4].has(scenario):
		#$CreepyMusic.play()
		creepy_music_tween.tween_property($CreepyMusic, "volume_db", creepy_music_volume, 20.0)
	else:
		creepy_music_tween.tween_property($CreepyMusic, "volume_db", -80, 20.0)
		#creepy_music_tween.tween_callback($CreepyMusic.stop)
	#
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
	#
	#maybe_enable_event()

func hide_all_lines() -> void:
	%MainOfficeWithCollision.hide_all_lines()
	%StairObject.hide_all_lines()
	%StairObject2.hide_all_lines()
	%StairObject3.hide_all_lines()
	%StairObject4.hide_all_lines()
	%FloorDataBackground_A.visible = false
	%FloorDataBackground_B.visible = false
	%FloorDataBackground_C.visible = false

func show_line_upto(line_id:int) -> void:
	var LINE_NAMES = %MainOfficeWithCollision.LINE_NAMES
	var next_stair_line: int
	match line_id:
		LINE_NAMES.LINEA_A:
			next_stair_line = LINE_NAMES.LINEA_A
		LINE_NAMES.LINEA_B:
			next_stair_line = LINE_NAMES.LINEA_B
		LINE_NAMES.LINEA_C:
			next_stair_line = LINE_NAMES.LINEA_C
		LINE_NAMES.LINEA_A_END:
			next_stair_line = -1
		LINE_NAMES.LINEA_B_END:
			next_stair_line = LINE_NAMES.LINEA_A
		LINE_NAMES.LINEA_C_END:
			next_stair_line = LINE_NAMES.LINEA_B
	
	var lines_ordered := [
		LINE_NAMES.LINEA_A_END,
		LINE_NAMES.LINEA_A,
		LINE_NAMES.LINEA_B_END,
		LINE_NAMES.LINEA_B,
		LINE_NAMES.LINEA_C_END,
		LINE_NAMES.LINEA_C
	]
	
	for l in lines_ordered:
		show_line(l)
		if l == line_id: break
	
	if Global.player.global_position.z > 0:
		for l in lines_ordered:
			%StairObject.show_line(l)
			%StairObject3.show_line(l)
			if l == line_id: break
		for ln in lines_ordered:
			if next_stair_line == -1: break
			%StairObject2.show_line(ln)
			%StairObject4.show_line(ln)
			if ln == next_stair_line: break
	else:
		for l in lines_ordered:
			%StairObject2.show_line(l)
			%StairObject3.show_line(l)
			if l == line_id: break
		for ln in lines_ordered:
			if next_stair_line == -1: break
			%StairObject.show_line(ln)
			%StairObject4.show_line(ln)
			if ln == next_stair_line: break

func show_line(line_id: int) -> void:
	var LINE_NAMES = %MainOfficeWithCollision.LINE_NAMES
	%MainOfficeWithCollision.show_line(line_id)
	if [LINE_NAMES.LINEA_A, LINE_NAMES.LINEA_A_END].has(line_id):
		#%FloorData_A.visible = true
		#%FloorData_A2.visible = true
		%FloorDataBackground_A.visible = true
		if LINE_NAMES.LINEA_A_END == line_id:
			%FloorDataBackground_A.rotation.y = %BackgroundEnd_Position.rotation.y
			%FloorDataBackground_A.position.x = %BackgroundEnd_Position.position.x
			%FloorDataBackground_A.position.z = %BackgroundEnd_Position.position.z
		else:
			%FloorDataBackground_A.rotation.y = %BackgroundFull_Position.rotation.y
			%FloorDataBackground_A.position.x = %BackgroundFull_Position.position.x
			%FloorDataBackground_A.position.z = %BackgroundFull_Position.position.z
	elif [LINE_NAMES.LINEA_B, LINE_NAMES.LINEA_B_END].has(line_id):
		#%FloorData_B.visible = true
		#%FloorData_B2.visible = true
		%FloorDataBackground_B.visible = true
		if LINE_NAMES.LINEA_B_END == line_id:
			%FloorDataBackground_B.rotation.y = %BackgroundEnd_Position.rotation.y
			%FloorDataBackground_B.position.x = %BackgroundEnd_Position.position.x
			%FloorDataBackground_B.position.z = %BackgroundEnd_Position.position.z
		else:
			%FloorDataBackground_B.rotation.y = %BackgroundFull_Position.rotation.y
			%FloorDataBackground_B.position.x = %BackgroundFull_Position.position.x
			%FloorDataBackground_B.position.z = %BackgroundFull_Position.position.z
	elif [LINE_NAMES.LINEA_C, LINE_NAMES.LINEA_C_END].has(line_id):
		#%FloorData_C.visible = true
		#%FloorData_C2.visible = true
		%FloorDataBackground_C.visible = true
		if LINE_NAMES.LINEA_C_END == line_id:
			%FloorDataBackground_C.rotation.y = %BackgroundEnd_Position.rotation.y
			%FloorDataBackground_C.position.x = %BackgroundEnd_Position.position.x
			%FloorDataBackground_C.position.z = %BackgroundEnd_Position.position.z
		else:
			%FloorDataBackground_C.rotation.y = %BackgroundFull_Position.rotation.y
			%FloorDataBackground_C.position.x = %BackgroundFull_Position.position.x
			%FloorDataBackground_C.position.z = %BackgroundFull_Position.position.z

func pause() -> void:
	%PauseMenu.visible = true
	%ResetGameMenu.visible = false
	%InitialMenu.visible = true
	%HowToPlay.visible = false
	%DisplaySettingsMenu.visible = false
	%AudioSettingsMenu.visible = false
	%GameplaySettingsMenu.visible = false
	%QuitGameMenu.visible = false
	$PauseSound.pitch_scale = 1.0
	$PauseSound.play()
	%PauseMenu.modulate.a = 0.0
	var pause_tween := get_tree().create_tween().bind_node(%PauseMenu)
	pause_tween.tween_property(%PauseMenu, "modulate:a", 1.0, 0.5)
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unpause(no_sound:=false) -> void:
	%PauseMenu.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	release_action_button()
	if not no_sound:
		$PauseSound.pitch_scale = 1.1
		$PauseSound.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		#day += 1
		#load_main()
		Global.player.rumble()
	if event.is_action_pressed("ui_cancel"):
		pause()
	if event is InputEventMouseButton:
		if event.pressed:
			fire_ray(event.button_index)
		else:
			release_action_button()
	if event.is_action("main_action") or event.is_action("secondary_action"):
		var b_idx := 1
		if event.is_action("secondary_action"):
			b_idx = 0
		if event.is_pressed():
			fire_ray(b_idx)
		else:
			release_action_button()

func release_action_button() -> void:
	task_timer = 0.0
	current_task = TASKS.NONE
	if robot_collected:
		robot_collected.play_process(true)
		robot_collected.stop_rotation_sound()
	if event_light_timer < 0 and Global.is_player_in_room:
		turn_lights_off(randf_range(3.0, 6.0))

func process_failed_queue(scenario: int) -> void:
	var append_scenario := true
	if game_state.completed_anomalies.size() < INTRO_AMOUNT:
		# Force having a Robot.GLITCHES.NONE
		# at the begining
		if game_state.completed_anomalies.find(Robot.GLITCHES.NONE) >= 0:
			game_state.completed_anomalies.erase(Robot.GLITCHES.NONE)
			selected_scenarios.push_front(Robot.GLITCHES.NONE)
		elif failed_scenarios.find(Robot.GLITCHES.NONE) >= 0:
			failed_scenarios.erase(Robot.GLITCHES.NONE)
			selected_scenarios.push_front(Robot.GLITCHES.NONE)
		elif scenario == 0:
			selected_scenarios.push_front(Robot.GLITCHES.NONE)
			append_scenario = false
		#
		selected_scenarios.append_array(game_state.completed_anomalies)
		game_state.completed_anomalies.resize(0)
	if append_scenario:
		failed_scenarios.append(scenario)

func open_storage_door(with_crowd:=true) -> void:
	var office_obj := %MainOfficeWithCollision.get_node("office2") as Node3D
	var door_obj := office_obj.get_node("Puerta") as Node3D
	%DoorAudio.stream = preload("res://sounds/storage_door_open.mp3")
	%DoorAudio.pitch_scale = 1.2
	%DoorAudio.play()
	#door_obj.rotation.y = 45
	var tween := create_tween()
	#tween.set_trans(Tween.TRANS_EXPO)
	#tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(door_obj, "rotation_degrees:y", -300, 3.0)
	var door_coll := %MainOfficeWithCollision.get_node("office2/DoorCollider") as Node3D
	door_coll.position.y = 50
	if with_crowd:
		%CrowdMultiMeshStorage.visible = true

func close_storage_door() -> void:
	var office_obj := %MainOfficeWithCollision.get_node("office2") as Node3D
	var door_obj := office_obj.get_node("Puerta") as Node3D
	%DoorAudio.stream = preload("res://sounds/storage_door_closes.mp3")
	%DoorAudio.pitch_scale = 1.0
	%DoorAudio.play()
	#door_obj.rotation.y = -180
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(door_obj, "rotation_degrees:y", -180, 3.0)
	tween.tween_callback(%CrowdMultiMeshStorage.set_visible.bind(false))
	var door_coll := %MainOfficeWithCollision.get_node("office2/DoorCollider") as Node3D
	door_coll.position.y = 0

func on_environment_change(change: Section.ENV_CHANGE) -> void:
	match change:
		Section.ENV_CHANGE.OPEN_DOOR:
			open_storage_door()

func reset_environment() -> void:
	var office_obj := %MainOfficeWithCollision.get_node("office2") as Node3D
	var door_obj := office_obj.get_node("Puerta") as Node3D
	door_obj.rotation.y = deg_to_rad(-180)
	var door_coll := %MainOfficeWithCollision.get_node("office2/DoorCollider") as Node3D
	door_coll.position.y = 0

func _on_finished(success: bool, scenario: int, _last: bool) -> void:
	#prints("_on_finished")
	#$OfficeWithCollision.rotate_y(deg_to_rad(180))
	#$OfficeWithCollision2.rotate_y(deg_to_rad(180))
	#$OfficeWithCollision3.rotate_y(deg_to_rad(180))
	#print("Rotate")
	level_started = false
	if scenario == -2: # Tutorial
		if not success:
			load_main()
			return
		else:
			tutorial_completed = true
			load_main()
			return
	if scenario == -3: # Executive
		# Do nothing, can't scape ending
		#load_main()
		return
	if scenario == -1: # Congrats
		# Can't scape congrats, unlesh finished
		if game_state.congrats_completed == true:
			load_main()
		return
	if scenario == -4: # Museum
		museum_completed = true
		load_main()
		return
	%LevelReport.update_report(section.report)
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
	Global.is_player_grabbed = false
	Global.player.get_camera().current = true
	Global.set_blood_vignete(0.0)
	%OfficeNode.rotation.y = deg_to_rad(0)
	%Player.halt_velocity = true
	%Player.global_position = %InitialPosition.global_position
	%Player.look_rot.y = rad_to_deg(%InitialPosition.rotation.y)
	if section.scenario == -2:
		%Player.global_position = %InitialPositionInt.global_position
		%Player.look_rot.y = rad_to_deg(%InitialPositionInt.rotation.y)

func build_ray() -> Dictionary:
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
	return intersection

func fire_ray(button_index: int) -> void:
	var intersection := build_ray()
	if not intersection.is_empty():
		var coll: Node3D = intersection.collider
		#print(coll.name)
		if coll.has_meta("is_id"):
			robot_collected = coll.get_parent().get_parent().get_parent()
			if not robot_collected.power_on and false:
				current_task = TASKS.ROTATE
			else:
				%Player.note_visible(true)
				task_timer = 0.0
				current_task = TASKS.SHUT_DOWN
		elif coll.has_meta("is_battery"):
			var rob := coll.get_parent().get_parent().get_parent() as Robot
			if rob.battery_charge == 0.0:
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
			#print("is_turnstile")
			coll.get_parent().open()
		elif coll.has_meta("is_lightswitch"):
			#print("is_lightswitch")
			var click_dist:float = intersection.position.distance_to(get_viewport().get_camera_3d().global_position)
			#print(click_dist)
			if click_dist < 1.8:
				coll.get_parent().turn_on_off()
				lights_on = !lights_on
	if current_task == TASKS.ROTATE:
		if button_index == 1:
			current_task = TASKS.ROTATE_INVERSE

func update_cursor(delta) -> void:
	var intersection := build_ray()
	var robot_node: Robot
	var cursor_type := 0
	if intersection:
		var coll: Node3D = intersection.collider
		if coll.has_meta("is_battery"):
			#print("Battery")
			robot_node = coll.get_parent().get_parent().get_parent()
			if not robot_node.is_demo and not robot_node.is_event and robot_node.battery_charge > 0.0:
				cursor_type = 2
			elif not robot_node.is_demo and not robot_node.is_event:
				cursor_type = 1
		if coll.has_meta("is_id"):
			#print("Id")
			robot_node = coll.get_parent().get_parent().get_parent()
			if not robot_node.is_demo and not robot_node.is_event:
				cursor_type = 2
		if coll.has_meta("is_robot"):
			#print("Robot")
			if coll.get_parent().get_parent() is Robot:
				robot_node = coll.get_parent().get_parent()
			else:
				robot_node = coll.get_parent().get_parent().get_parent()
			#prints(robot_node.is_demo, robot_node.is_event, robot_node is Robot)
			if (not robot_node.is_demo) and (not robot_node.is_event):
				cursor_type = 1
		if coll.has_meta("is_lightswitch"):
			var click_dist:float = intersection.position.distance_to(get_viewport().get_camera_3d().global_position)
			if click_dist < 1.8:
				cursor_type = 2
	
	match cursor_type:
		0:
			%FPSCursor.modulate.a = 0.0
		1:
			%FPSCursor.modulate.a = 0.459
			%FPSCursor.scale = Vector2.ONE * 0.15
		2:
			%FPSCursor.modulate.a = 0.6
			%FPSCursor.scale = Vector2.ONE * 0.2

func charge_battery(robot: Robot) -> void:
	# On Robot
	if robot.power_on and robot.glitch == Robot.GLITCHES.GRABS_BATTERY:
		robot.grab_battery()
		$Stinger.play()
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

var last_exposure := 0.0
var refresh_reflection_probe_time := 0.0
func refresh_reflection_probe(delta: float):
	refresh_reflection_probe_time += delta
	if lights_on:
		$WorldEnvironment.environment.tonemap_exposure = target_exposure
	else:
		$WorldEnvironment.environment.tonemap_exposure = 0.05
	var current_exposure: float = $WorldEnvironment.environment.tonemap_exposure
	if last_exposure != current_exposure and refresh_reflection_probe_time > .3:
		refresh_reflection_probe_time = 0.0
		last_exposure = current_exposure
		$ReflectionProbe.position.x = randf()*0.01
		#print("Refresh Reflection Probe")
	

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
	#target_exposure = 1.0
	#if section.anomaly == Robot.GLITCHES.LIGHTS_OFF:
		#target_exposure = 0.05
	if tonemap_tween:
		tonemap_tween.stop()
	tonemap_tween = create_tween()
	tonemap_tween.tween_property(self, "target_exposure", 1.0, 1.0)
	#tonemap_tween.tween_callback(refresh_reflection_probe)
	#$WorldEnvironment.environment.tonemap_exposure = 1.0
	%ExtraStairs.visible = false
	%ExtraOffices.visible = false


func _on_inside_area_body_exited(_body: Node3D) -> void:
	#$WorldEnvironment.environment.sky.sky_material = preload("res://sky/stairs_panorama_01.tres")
	#$ReflectionProbe.position.x = randf()*0.01
	Global.is_player_in_room = false
	#target_exposure = 6.0
	if tonemap_tween:
		tonemap_tween.stop()
	tonemap_tween = create_tween()
	tonemap_tween.tween_property(self, "target_exposure", 6.0, 1.0)
	#tonemap_tween.tween_callback(refresh_reflection_probe)
	#$WorldEnvironment.environment.tonemap_exposure = 1.9
	%ExtraStairs.visible = true
	%ExtraOffices.visible = true


func _on_loop_up_body_entered(_body: Node3D) -> void:
	print("Loop Up") # Player is going Down
	%Player.position.y += 4.1
	%StairObject.chain_visible = false
	%StairObject2.chain_visible = false
	GamePlatform.stats["floor_down"] += 1
	#
	var end_level := false
	#if current_side == SIDES.Z_MINUS and %Player.position.z > 0:
	if %Player.position.z > 0:
		%OfficeNode.rotation.y = deg_to_rad(0)
	else:
		%OfficeNode.rotation.y = deg_to_rad(180)
	if level_started:
		end_level = true
	if end_level:
		var sc := section.is_success()
		prints("\nsuccess:", sc)
		_on_finished(sc, section.scenario, false)


func _on_loop_down_body_entered(_body: Node3D) -> void:
	print("Loop Down") # Player is going Up
	%Player.position.y -= 4.1
	#
	if check_if_nightmare():
		tutorial_completed = false
		museum_completed = false
		process_failed_queue(section.scenario)
		load_main()
		return


func on_glitch_failed() -> void:
	var reset := func():
		#var sc := section.is_success()
		#prints("\nsuccess:", sc)
		section.is_success() # Force generate report
		_on_finished(false, section.scenario, false)
		#TODO sometimes reset_position don't reset velocity
		reset_position()
		GamePlatform.stats["deaths"] += 1
	
	var exec_tween := create_tween()
	#exec_tween.tween_interval(2.5)
	#
	exec_tween.tween_property(%FadeBlack, "modulate:a", 1.0, 1.0)
	exec_tween.tween_callback(reset.call_deferred)
	exec_tween.tween_interval(1.0)
	exec_tween.tween_callback($AudioStreamPlayer.play)
	exec_tween.tween_property(%FadeBlack, "modulate:a", 0.0, 4.0)

func _on_start_level_body_entered(_body: Node3D) -> void:
	level_started = true
	%LevelReport.play_sound()
	if not check_if_nightmare():
		%StairObject.chain_visible = true
		%StairObject2.chain_visible = true

func _on_storage_area_body_entered(_body: Node3D) -> void:
	Global.is_player_in_storage = true

func _on_storage_area_body_exited(_body: Node3D) -> void:
	Global.is_player_in_storage = false

# Pause Menu #####

func _on_resume_button_pressed() -> void:
	unpause()

func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_settings.volume_level = %VolumeSlider.value
		save_game_settings()
		load_settings()

func _on_mouse_sen_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_settings.mouse_sensibility = %MouseSenSlider.value
		save_game_settings()
		load_settings()

func _on_mouse_acc_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_settings.mouse_acceleration = %MouseAccSlider.value
		save_game_settings()
		load_settings()

func _on_camera_shake_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		game_settings.camera_shake = %CameraShakeSlider.value
		save_game_settings()
		load_settings()

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void:
	game_settings.full_screen = toggled_on
	save_game_settings()
	load_settings()

func _on_v_sync_check_box_toggled(toggled_on: bool) -> void:
	game_settings.vsync = toggled_on
	save_game_settings()
	load_settings()

func _on_max_fps_spin_value_changed(value: float) -> void:
	game_settings.max_fps = value
	save_game_settings()
	load_settings()

func show_menu_tween(menu: Control) -> void:
	menu.modulate.a = 0.0
	var audio_settings_tween = get_tree().create_tween().bind_node(%PauseMenu)
	audio_settings_tween.tween_property(menu, "modulate:a", 1.0, 0.1)

func _on_quit_button_pressed() -> void:
	%QuitGameMenu.visible = true
	show_menu_tween(%QuitGameMenu)

func _on_reset_button_pressed() -> void:
	#%ResetButton.visible = false
	%ResetGameMenu.visible = true
	show_menu_tween(%ResetGameMenu)

func _on_confirm_reset_button_pressed() -> void:
	Global.reset_save = true
	get_tree().change_scene_to_file("res://base.tscn")

func _on_cancel_reset_button_pressed() -> void:
	#%ResetButton.visible = true
	%ResetGameMenu.visible = false

func _on_how_to_play_button_pressed() -> void:
	%HowToPlay.visible = true
	show_menu_tween(%HowToPlay)

func _on_how_to_play_back_button_pressed() -> void:
	%HowToPlay.visible = false

func _on_settings_button_pressed() -> void:
	%SettingsMenu.visible = true
	show_menu_tween(%SettingsMenu)

func _on_settings_back_button_pressed() -> void:
	%SettingsMenu.visible = false

func _on_audio_settings_button_pressed() -> void:
	%AudioSettingsMenu.visible = true
	show_menu_tween(%AudioSettingsMenu)

func _on_display_settings_button_pressed() -> void:
	%DisplaySettingsMenu.visible = true
	show_menu_tween(%DisplaySettingsMenu)

func _on_audio_settings_back_button_pressed() -> void:
	%AudioSettingsMenu.visible = false

func _on_display_settings_back_button_pressed() -> void:
	%DisplaySettingsMenu.visible = false

func _on_gameplay_settings_button_pressed() -> void:
	%GameplaySettingsMenu.visible = true
	show_menu_tween(%GameplaySettingsMenu)

func _on_gameplay_settings_back_button_pressed() -> void:
	%GameplaySettingsMenu.visible = false

func _on_cancel_quit_button_pressed() -> void:
	%QuitGameMenu.visible = false

func _on_confirm_quit_button_pressed() -> void:
	get_tree().quit()

func _on_follow_itchio_button_pressed() -> void:
	OS.shell_open("https://eibriel.itch.io/") 

func _on_follow_steam_button_pressed() -> void:
	GlobalSteam.open_url("https://store.steampowered.com/developer/eibriel")

func _on_follow_mastodon_button_pressed() -> void:
	OS.shell_open("https://sigmoid.social/@eibriel")
