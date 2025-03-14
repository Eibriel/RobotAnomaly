extends Node3D

@export var skin:=  SKINS.NEW

var switch_up: MeshInstance3D
var switch_down: MeshInstance3D

enum SKINS {
	OLD,
	NEW
}

func _ready() -> void:
	match skin:
		SKINS.NEW:
			switch_up = $LightSwitchNew/SwitchUp
			switch_down = $LightSwitchNew/SwitchDown
			$LightSwitchOld.visible = false
		SKINS.OLD:
			switch_up = $LightSwitchOld/LightSwitchOld_Up
			switch_down = $LightSwitchOld/LightSwitchOld_Down
			$LightSwitchNew.visible = false
	switch_up.visible = false

func turn_on_off() -> void:
	GamePlatform.stats["light_switch"] += 1
	switch_up.visible = !switch_up.visible
	switch_down.visible = !switch_down.visible
	if switch_down.visible:
		$SwitchOffAudio.play()
	else:
		$SwitchOnAudio.play()
