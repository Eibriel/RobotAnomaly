extends Node3D

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
	lines[LINE_NAMES.LINEA_A] = $office2/LineaA
	lines[LINE_NAMES.LINEA_B] = $office2/LineaB
	lines[LINE_NAMES.LINEA_C] = $office2/LineaC
	lines[LINE_NAMES.LINEA_A_END] = $office2/LineaA_End
	lines[LINE_NAMES.LINEA_B_END] = $office2/LineaB_End
	lines[LINE_NAMES.LINEA_C_END] = $office2/LineaC_End

func hide_all_lines() -> void:
	for n in lines:
		lines[n].visible = false

func show_line(line_id: LINE_NAMES) -> void:
	lines[line_id].visible = true
