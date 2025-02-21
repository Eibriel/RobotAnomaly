extends Node3D

@export var chain_visible := true :
	set(value):
		if chain_visible != value:
			dirty = true
		chain_visible = value

var dirty := false
var chain: Node3D

func _ready() -> void:
	chain = $stairs/Chain

func _process(delta: float) -> void:
	if not dirty: return
	dirty = false
	match chain_visible:
		false:
			%BlockStairs.position.y = -20
			chain.visible = false
		true:
			%BlockStairs.position.y = 0
			chain.visible = true
