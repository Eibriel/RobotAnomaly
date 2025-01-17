extends Node3D

var battery_charge: float = -1.0

func _process(delta: float) -> void:
	$Label3D.text = "%d%%" % battery_charge
	if battery_charge >= 0.0:
		battery_charge += delta * 4.0
	if battery_charge > 100.0:
		battery_charge = 100.0
