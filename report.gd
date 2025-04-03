extends Node3D

var OK = [
	preload("res://textures/whiteboard_tick_01.jpg"),
	preload("res://textures/whiteboard_tick_02.jpg"),
	preload("res://textures/whiteboard_tick_03.jpg"),
	preload("res://textures/whiteboard_tick_04.jpg"),
]
var ERROR = [
	preload("res://textures/whiteboard_cross_01.jpg"),
	preload("res://textures/whiteboard_cross_02.jpg"),
	preload("res://textures/whiteboard_cross_03.jpg"),
	preload("res://textures/whiteboard_cross_04.jpg"),
]

var sound_played := false
var correct := false
var something_to_report := false

var light_mat: StandardMaterial3D

func _ready() -> void:
	light_mat = $ReportLight/ReportLight.mesh.surface_get_material(1)
	light_mat.emission = Color.BLACK
	light_mat.albedo_color = Color.BLACK

func update_report(data: Array) -> void:
	sound_played = false
	something_to_report = true
	for c in %ReportSubviewportNode.get_children():
		c.queue_free()
	var robot_with_anomaly := false
	var robot_off_without_anomaly := false
	var robot_with_battery := false
	var r_row := 0
	var r_column := 0
	#var batteries_charged_required := false
	for r: Dictionary in data:
		var icon := Sprite2D.new()
		if r.handled_correctly:
			icon.texture = OK.pick_random()
		else:
			icon.texture = ERROR.pick_random()
		%ReportSubviewportNode.add_child(icon)
		icon.position = Vector2(200+(r_column*450), 300+(r_row*150))
		if r.glitched:
			icon.position.x += 200
			if r.power and not r.handled_correctly:
				robot_with_anomaly = true
			if r.full_battery:
				robot_with_battery = true
		else:
			if r.full_battery:
				robot_with_battery = true
			if not r.power:
				robot_off_without_anomaly = true
		icon.scale = Vector2.ONE * 0.2
		r_row += 1
		if r_row == floor(data.size()*0.5):
			r_row = 0
			r_column += 1
		#batteries_charged_required = r.batteries_charged_required
	
	correct = true
	if robot_off_without_anomaly:
		$PowerErrorLabel.text = "ERROR OFF NO ANOMALY"
		correct = false
	elif robot_with_anomaly:
		$PowerErrorLabel.text = "ERROR ANOMALY ON"
		correct = false
	else:
		$PowerErrorLabel.text = "NO ERROR"
	if robot_with_battery:
		$BatteryErrorLabel.text = "ERROR FULL BATTERY"
		correct = false
	else:
		$BatteryErrorLabel.text = "NO ERROR"

func play_sound() -> void:
	if not something_to_report: return
	if sound_played: return
	sound_played = true
	if correct:
		$CorrectSound.play()
		light_mat.emission = Color.GREEN
		light_mat.albedo_color = Color.GREEN
	else:
		$IncorrectSound.play()
		light_mat.emission = Color.RED
		light_mat.albedo_color = Color.RED
	var color := light_mat.emission
	var light_tween := create_tween()
	var light_tween_al := create_tween()
	for _n in 10:
		light_tween.tween_property(light_mat, "emission", Color.BLACK, 0.25)
		light_tween.tween_property(light_mat, "emission", color, 0.25)
	for _n in 10:
		light_tween_al.tween_property(light_mat, "albedo_color", Color.BLACK, 0.25)
		light_tween_al.tween_property(light_mat, "albedo_color", color, 0.25)
