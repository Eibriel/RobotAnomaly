extends Node3D

var time := 0.0

func _process(delta: float) -> void:
	time += delta
	if time < 0.1: return
	time = 0
	$LevelCountLabel5.mesh.text = "%d" % randi_range(0, 29)
	$TotalLevelsCountLabel5.mesh.text = "/ %d" % randi_range(0, 29)
