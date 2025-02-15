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

func update_report(data: Array) -> void:
	for c in %ReportSubviewportNode.get_children():
		c.queue_free()
	var robot_with_anomaly := false
	var robot_without_battery := false
	var r_row := 0
	var r_column := 0
	var batteries_charged_required := false
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
		else:
			if r.full_battery:
				robot_without_battery = true
		icon.scale = Vector2.ONE * 0.2
		r_row += 1
		if r_row == floor(data.size()*0.5):
			r_row = 0
			r_column += 1
		batteries_charged_required = r.batteries_charged_required
	
	var text := "Error\n"
	if robot_with_anomaly:
		text += "- Robot with anomaly was on\n"
	if batteries_charged_required and robot_without_battery:
		text += "- A Robot had full battery"
	if not robot_with_anomaly and not (batteries_charged_required and robot_without_battery):
		text += "- None"
	$Label3D.text = text
