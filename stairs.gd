extends Node3D

@export var chain_visible := true :
	set(value):
		if chain_visible != value:
			dirty = true
		chain_visible = value

@export var block_player := false :
	set(value):
		if block_player != value:
			dirty = true
		block_player = value

var dirty := false
var chain: Node3D
var lines: Dictionary

enum LINE_NAMES {
	LINEA_A,
	LINEA_B,
	LINEA_C,
	LINEA_A_END,
	LINEA_B_END,
	LINEA_C_END
}

func _ready() -> void:
	chain = $stairs/Chain
	lines[LINE_NAMES.LINEA_A] = $stairs/LineaA_stairs
	lines[LINE_NAMES.LINEA_B] = $stairs/LineaB_stairs
	lines[LINE_NAMES.LINEA_C] = $stairs/LineaC_stairs
	lines[LINE_NAMES.LINEA_A_END] = $stairs/LineaA_stairs
	lines[LINE_NAMES.LINEA_B_END] = $stairs/LineaB_stairs
	lines[LINE_NAMES.LINEA_C_END] = $stairs/LineaC_stairs

func _process(_delta: float) -> void:
	if not dirty: return
	dirty = false
	match chain_visible:
		false:
			%BlockStairs.position.y = -20
			chain.visible = false
		true:
			%BlockStairs.position.y = 0
			chain.visible = true
	match block_player:
		false:
			%BlockStairs2.position.y = -20
		true:
			%BlockStairs2.position.y = 0

func hide_all_lines() -> void:
	for n in lines:
		lines[n].visible = false

func show_line(line_id: int) -> void:
	lines[line_id].visible = true
