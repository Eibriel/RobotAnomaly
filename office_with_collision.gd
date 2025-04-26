extends Node3D

@export var lights_on := true :
	set(value):
		if value != lights_on:
			lights_on_dirty = true
		lights_on = value
@export var anomaly_position:Vector2 : 
	set(value):
		if value != anomaly_position:
			anomaly_position_dirty = true
		anomaly_position = value
@export var light_event: LIGHT_EVENTS=LIGHT_EVENTS.QUIET :
	set(value):
		if value != light_event:
			light_event_dirty = true
		light_event = value

var lines: Dictionary

enum LINE_NAMES {
	LINEA_A,
	LINEA_B,
	LINEA_C,
	LINEA_A_END,
	LINEA_B_END,
	LINEA_C_END
}

enum LIGHT_EVENTS {
	QUIET,
	ONE_BLINKING,
	MANY_BLINKING,
	ROW_EFFECT
}

const LIGHTS_OFF_MATERIAL = preload("res://materials/office_mats/lights_off_material.tres")

var time := 0.0
var lights_on_dirty:= false
var light_event_dirty:=false
var anomaly_position_dirty:=false

var timer_to_quiet:=0.0
var timer_to_blink:=0.0

var lights_data: Array = []
var unstable_lights: Array[int] = []
var unstable_light: int
var lights_percent := 1.0

func _ready() -> void:
	lines[LINE_NAMES.LINEA_A] = $office2/LineaA
	lines[LINE_NAMES.LINEA_B] = $office2/LineaB
	lines[LINE_NAMES.LINEA_C] = $office2/LineaC
	lines[LINE_NAMES.LINEA_A_END] = $office2/LineaA_End
	lines[LINE_NAMES.LINEA_B_END] = $office2/LineaB_End
	lines[LINE_NAMES.LINEA_C_END] = $office2/LineaC_End
	hide_all_lines()
	generate_light_blockers()


func _process(delta: float) -> void:
	time += delta
	if timer_to_quiet > 0.0:
		timer_to_quiet -= delta
		if timer_to_quiet <= 0.0:
			light_event = LIGHT_EVENTS.QUIET
	
	if lights_on_dirty:
		lights_on_dirty = false
		if lights_on:
			timer_to_blink = 0.0
			unblock_all_lights()
		else:
			block_all_lights()
	
	#if anomaly_position_dirty:
	#	anomaly_position_dirty = false
	#	unstable_light = 1
	
	match light_event:
		LIGHT_EVENTS.QUIET:
			if light_event_dirty:
				if lights_on:
					unblock_all_lights()
				else:
					block_all_lights()
				lights_percent = 1.0
		LIGHT_EVENTS.ONE_BLINKING:
			var lon := blink_light(unstable_light, delta)
			lights_percent = 1.0
			if not lon:
				lights_percent = 0.9
		LIGHT_EVENTS.MANY_BLINKING:
			var lon := []
			for l_id in lights_data.size():
				lon.append(blink_light(l_id, delta))
			lights_percent = float(lon.count(true)) / float(lon.size())
	
	if anomaly_position_dirty:
		prints("anomaly_position_dirty", anomaly_position)
		anomaly_position_dirty = false
		var min_distance := 9999999.0
		#var min_light_id := 0
		for l_id in lights_data.size():
			#var l_pos:Vector2 = lights_data[l_id][2] as Vector2
			var block_instance = lights_data[l_id][0]
			var l_pos:Vector2 = Vector2(block_instance.global_position.x, block_instance.global_position.z)
			var dist := l_pos.distance_to(anomaly_position)
			if min_distance > dist:
				min_distance = dist
				unstable_light = l_id
				
	#print(anomaly_position)
	if anomaly_position != Vector2.ZERO:
		if not lights_on:
			# Lights turn on when lights_timer > 30.0
			if timer_to_blink < 20.0:
				timer_to_blink += delta
			else:
				blink_light(unstable_light, delta, true)
			#lights_data[unstable_light][0].visible = false
	
	light_event_dirty = false
	
	
	
	if false:
		for u: int in unstable_lights:
			lights_data[u][1] -= delta
			if lights_data[u][1] <= 0.0:
				lights_data[u][0].visible = false
				unstable_lights.erase(u)
				continue
			#print()
			var sin_val := sin(lights_data[u][1]*10)
			var light_on := sin_val < 0.0
			#print(rand_from_seed(u + int(time))[0])
			#var light_on := randf() < 0.5
			lights_data[u][0].visible = light_on

func blink_light(light_id: int, delta: float, force:bool = false) -> bool:
	if lights_on or force:
		lights_data[light_id][1] -= delta
		if lights_data[light_id][1] <= 0.0:
			lights_data[light_id][0].visible = !lights_data[light_id][0].visible
			lights_data[light_id][1] = randf_range(0.05, 0.2)
			if !lights_data[light_id][0].visible:
				if randf() < 0.1:
					lights_data[light_id][1] *= 6.0
	else:
		lights_data[light_id][0].visible = true
	return !lights_data[light_id][0].visible

func generate_light_blockers() -> void:
	var block_mesh := PlaneMesh.new()
	block_mesh.size = Vector2(1.77, 1.77)
	block_mesh.material = LIGHTS_OFF_MATERIAL
	for x in 2:
		for y in 13:
			var block_instance := MeshInstance3D.new()
			block_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			block_instance.mesh = block_mesh
			%LightBlockers.add_child(block_instance)
			if x == 0:
				block_instance.position.x = -1.802
			else:
				block_instance.position.x = 1.802
			block_instance.position.y = 3.989
			block_instance.position.z = remap(y, 0, 12, -22.967, 22.634)
			block_instance.rotation_degrees.z = 180
			block_instance.visible = false
			lights_data.append([
				block_instance,
				0.0,
				Vector2(block_instance.global_position.x, block_instance.global_position.z)
			])

func set_timer_to_quiet(_timer_to_quiet: float) -> void:
	timer_to_quiet = _timer_to_quiet
	

func block_all_lights() -> void:
	for l in lights_data:
		l[0].visible = true

func unblock_all_lights() -> void:
	print("UNBLOCK")
	#var l_id := 0
	for l in lights_data:
		l[0].visible = false
		#if randf() < 0.1:
		#	set_light_unstable(l_id, 3.0)
		#l_id += 1

func set_light_unstable(light_id: int, _time: float) -> void:
	if not unstable_lights.has(light_id):
		unstable_lights.append(light_id)
	#lights_data[light_id][1] = time

func hide_all_lines() -> void:
	for n in lines:
		lines[n].visible = false

func show_line(line_id: LINE_NAMES) -> void:
	lines[line_id].visible = true

func set_wall_writting(weight: float) -> void:
	const WALL_WRITTING = preload("res://materials/office_mats/WallWritting.tres")
	WALL_WRITTING.set_shader_parameter("writting_1_weight", weight)

func get_wall_writting() -> float:
	const WALL_WRITTING = preload("res://materials/office_mats/WallWritting.tres")
	return WALL_WRITTING.get_shader_parameter("writting_1_weight")
