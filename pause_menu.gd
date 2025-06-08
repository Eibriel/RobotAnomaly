extends Control

signal unpause

var demo_ended := false

func _input(event: InputEvent) -> void:
	# NOTE
	# added controller button to ui_accept
	# to allow controlling the menu

	# NOTE workaround. Godot bug?
	if event.is_released():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is HSlider:
			focused.emit_signal("drag_ended", true)

	if event.is_action_pressed("pause"):
		if not demo_ended:
			unpause.emit()
