extends Node


var stats_ready := false
var stats = {
	"time_played": 0, # Minutes
	"light_switch": 0, # Light switch turned on or off
	"deaths": 0, # Deaths by robots
	"floor_down": 0, # Going downstairs 1 floor (even if the floor repeats)
	"anomalies_found": 0, # Anomalies successfully completed
}

var stats_time: float = 0.0

func _process(delta: float) -> void:
	stats_time += delta
	if not stats_ready and GlobalSteam.stats_ready:
		sync_stats()
		stats_ready = true
	if not stats_ready: return
	if stats_time > 10:
		stats_time = 0.0
		for s in stats:
			GlobalSteam.set_stat(s, int(stats[s]))
		print(stats)

func sync_stats():
	var steam_stats := GlobalSteam.get_stats()
	for s in steam_stats:
		stats[s] = steam_stats[s]

func _init() -> void:
	if OS.has_feature("steam"):
		print("steam")

func set_stat(stat_name:String, value: Variant) -> void:
	GlobalSteam.set_stat(stat_name, value)

func get_stats(stat_name:String) -> void:
	GlobalSteam.get_stat(stat_name)

func set_achievement(value:String) -> void:
	GlobalSteam._fire_Steam_Achievement(value)

func get_achievements():
	pass

func set_rich_presence():
	pass
