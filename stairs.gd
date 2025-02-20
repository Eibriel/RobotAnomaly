extends Node3D

var chain: Node3D

func _ready() -> void:
	chain = $stairs/Chain

func unlock() -> void:
	%BlockStairs.position.y = -20
	chain.visible = false
	
func lock() -> void:
	%BlockStairs.position.y = 0
	chain.visible = true
