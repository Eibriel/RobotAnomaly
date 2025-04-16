extends Node

#App Ids:
# - Robot Anomaly: 3583330
# - Robot Anomaly Demo:
# - Robot Anomaly Playtest: 3608100
const APP_ID := 3583330
const APP_ID_DEMO := 3619430
const APP_ID_PLAYTEST := 3608100

# Steam variables
var initialized: bool = false
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
#var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""

var stats_ready := false

var _stats = {
	"time_played": 0, # Minutes
	"light_switch": 0, # Light switch turned on or off
	"deaths": 0, # Deaths by robots
	"floor_down": 0, # Going downstairs 1 floor (even if the floor repeats)
	"anomalies_found": 0, # Anomalies successfully completed
}

const _increment_limit = {
	"time_played": 1,
	"light_switch": 10,
	"deaths": 2,
	"floor_down": 10,
	"anomalies_found": 2,
}

var _achievements = {
	"HALF_HOUR_GAME": false,
	"WAKE_UP_REACHED": false,
	"TRAPPED_REACHED": false,
	"MASTERMIND_REACHED": false,
	"ONE_HOUR_GAME": false,
	"TWO_HOUR_GAME": false,
	"LIGHT_SWITCH_INSPECTOR": false,
}

var stats: Dictionary

func _init() -> void:
	var current_app_id:int
	if Global.is_playtest():
		current_app_id = APP_ID_PLAYTEST
	elif Global.is_demo():
		current_app_id = APP_ID_DEMO
	else:
		current_app_id = APP_ID
	# Set your game's Steam app ID here
	OS.set_environment("SteamAppId", str(current_app_id))
	OS.set_environment("SteamGameId", str(current_app_id))

func _ready() -> void:
	if Global.is_steam() or not OS.has_feature("template"):
		initialize_steam()

func set_stat(stat_name:String, value: int):
	if not stats_ready:
		push_warning("Stats not ready")
		return
	if not _stats.has(stat_name):
		push_warning("Attempting to set non existent stat %s" % stat_name)
		return
	if value < _stats[stat_name]:
		push_warning("Stat value can't decrease for %s, %d (%d)" % [stat_name, value, _stats[stat_name]])
		return
	if value - _stats[stat_name] > _increment_limit[stat_name]:
		value = _stats[stat_name] + _increment_limit[stat_name]
		print("Limiting value to %d" % value)
	#print("Stat %s set with value %d" % [stat_name, value])
	Steam.setStatInt(stat_name, value)
	Steam.storeStats()
	Steam.requestUserStats(steam_id)

func get_stats() -> Dictionary:
	return Dictionary(_stats)

func _process(_delta: float) -> void:
	if not initialized: return
	Steam.run_callbacks()
	

func initialize_steam() -> void:
	if not Steam.isSteamRunning():
		print("Steam is not running")
		return
	
	var initialize_response: Dictionary = Steam.steamInitEx(true)
	print("Did Steam initialize?: %s " % initialize_response)

	if initialize_response['status'] > 0:
		print("Failed to initialize Steam: %s" % initialize_response)
		return
	
	initialized = true
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	prints("is_on_steam_deck", is_on_steam_deck)
	prints("is_online", is_online)
	prints("is_owned", is_owned)
	prints("steam_id", steam_id)
	prints("steam_username", steam_username)
	
	# BUG this is never fired
	print("Connecting Signal")
	Steam.user_stats_received.connect(_on_steam_stats_ready)
	Steam.requestUserStats(steam_id)

func _on_steam_stats_ready(_game: int, _result: int, _user: int) -> void:
	stats_ready = true
	#print("## STATS RECEIVED ##")
	#print("This game's ID: %s" % game)
	#print("Call result: %s" % result)
	#print("This user's Steam ID: %s" % user)
	
	for st in _stats:
		_stats[st] = Steam.getStatInt(st)
	#prints("stats", _stats)
	for ac in _achievements:
		_achievements[ac] = get_achievement(ac)
	#prints("achievements", _achievements)

func get_achievement(value: String) -> bool:
	var this_achievement: Dictionary = Steam.getAchievement(value)
	#print(this_achievement)
	# Achievement exists
	if this_achievement['ret']:
		# Achievement is unlocked
		if this_achievement['achieved']:
			return true
		# Achievement is locked
		else:
			return false
	# Achievement does not exist
	else:
		return false

func _fire_Steam_Achievement(value: String) -> void:
	# Set the achievement to an in-game variable
	if not _achievements.has(value):
		print("Achievement %s don't exist" % value)
		return
	if _achievements[value]: return
	_achievements[value] = true
	# Pass the value to Steam then fire it
	Steam.setAchievement(value)
	Steam.storeStats()

func set_rich_presence(token: String, value: String = "") -> void:
	if not initialized: return
	var _setting_presence
	if value.length() > 0:
		_setting_presence = Steam.setRichPresence(token, value)
	else:
		# Set the token
		_setting_presence = Steam.setRichPresence("steam_display", token)
		
	# Tutorial
	# https://www.youtube.com/watch?v=VCwNxfYZ8Cw&t=4762s

	# Debug it
	#print("Setting rich presence to "+str(token)+": "+str(setting_presence))

func open_url(url:String) -> void:
	if initialized and Steam.isOverlayEnabled():
		prints("Overlay browser", url)
		Steam.activateGameOverlayToWebPage(url, Steam.OVERLAY_TO_WEB_PAGE_MODE_MODAL)
		#Steam.activateGameOverlayToWebPage(url)
	else:
		prints("System browser", url)
		OS.shell_open(url)

func timeline_event(event_type: GamePlatform.EVENT) -> void:
	if not initialized: return
	match event_type:
		GamePlatform.EVENT.DEATH:
			Steam.addInstantaneousTimelineEvent(
				"Death",
				"An anomaly killed you",
				"steam_death",
				Steam.TimelineEventClipPriority.TIMELINE_EVENT_CLIP_PRIORITY_FEATURED,
				0
			)
		GamePlatform.EVENT.FAILED:
			Steam.addInstantaneousTimelineEvent(
				"Floor failed",
				"There was something you overlook",
				"steam_x",
				Steam.TimelineEventClipPriority.TIMELINE_EVENT_CLIP_PRIORITY_STANDARD,
				0
			)
		GamePlatform.EVENT.SUCCESS:
			Steam.addInstantaneousTimelineEvent(
				"Floor succeded",
				"You taked care of all your tasks",
				"steam_completed",
				Steam.TimelineEventClipPriority.TIMELINE_EVENT_CLIP_PRIORITY_STANDARD,
				0
			)
	
