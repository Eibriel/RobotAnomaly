class_name GameSettingsResource
extends Resource

@export var volume_level := 68.0

@export var mouse_sensibility := 7.0

@export var mouse_acceleration := 25.0

@export var camera_shake := 1.0

@export var full_screen := true

@export var vsync := true

@export var max_fps :int = 60

@export var language: locale_names = locale_names.en

#@export var seconds := 0.0

@export var screen_filter := true

@export var cursor_on := false

@export var invert_x := false

@export var invert_y := false

@export var quality: int = 3

@export var window_position: Vector2

@export var window_size: Vector2

@export var window_screen: int

@export var ui_scale: float = 1.0

enum locale_names {
	en,
	es_AR,
	pt_BR,
	zh_Hans,
	ru,
	de,
	ja
}
