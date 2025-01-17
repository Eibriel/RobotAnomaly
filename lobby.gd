extends Node3D

func _ready() -> void:
	%LevelCountLabel.visible = false
	#show_counter()

func set_level_count(num: int) -> void:
	%LevelCountLabel.text = "%d left" % num

func show_counter() -> void:
	%LevelCountLabel.visible = true

func set_day(day: int) -> void:
	%DayLabel.text = "Day %d" % day
