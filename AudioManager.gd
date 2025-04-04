extends Node

signal music_ended

# Music files (now WAVs instead of M4As)
var music = {
	"lofi": preload("res://art/music/Lofi.wav"),
	"somalian_pirates": preload("res://art/music/SomalianPirates.wav"),
	"egypt": preload("res://art/music/EgyptBeat.wav"),
	"montuno": preload("res://art/music/Montuno.wav"),
	"japan_night_race": preload("res://art/music/JapanNightRace.wav")
}

# Gun sound paths (loaded on demand to avoid errors with missing files)
var gun_sound_paths = {
	# AK-74 sounds
	"ak74_shoot": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/AKS-74U/ak_545_shoot.wav",
	"ak74_bolt_close": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/AKS-74U/ak_bolt_close.wav",
	"ak74_bolt_open": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/AKS-74U/ak_bolt_open.wav",
	
	# Generic rifle sounds (fallbacks)
	"generic_rifle_shoot": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/Generic/rifle_shoot.wav",
	"generic_rifle_reload": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/Generic/rifle_reload.wav",
	"generic_rifle_bolt": "res://assets/guns_hands/VRFPS_Kit/Models/Weapons/Sounds/Generic/rifle_bolt.wav"
}

# Cache of loaded sounds
var gun_sounds = {}

# Map gun types to their sound sets - uses fallbacks as needed
var gun_sound_map = {
	"ak74": {
		"shoot": "ak74_shoot",
		"reload_start": "generic_rifle_reload",
		"reload_end": "generic_rifle_reload",
		"bolt": "ak74_bolt_close"
	},
	"m16a1": {
		"shoot": "generic_rifle_shoot",
		"reload_start": "generic_rifle_reload",
		"reload_end": "generic_rifle_reload", 
		"bolt": "generic_rifle_bolt"
	},
	"scarl": {
		"shoot": "generic_rifle_shoot",
		"reload_start": "generic_rifle_reload",
		"reload_end": "generic_rifle_reload",
		"bolt": "generic_rifle_bolt"
	},
	"hk416": {
		"shoot": "generic_rifle_shoot",
		"reload_start": "generic_rifle_reload",
		"reload_end": "generic_rifle_reload",
		"bolt": "generic_rifle_bolt"
	},
	"mp5": {
		"shoot": "generic_rifle_shoot",
		"reload_start": "generic_rifle_reload",
		"reload_end": "generic_rifle_reload",
		"bolt": "generic_rifle_bolt"
	},
	"mosin": {
		"shoot": "generic_rifle_shoot", 
		"reload_start": "generic_rifle_bolt",
		"reload_end": "generic_rifle_bolt",
		"bolt": "generic_rifle_bolt"
	},
	"model1897": {
		"shoot": "generic_rifle_shoot",
		"reload_start": "generic_rifle_bolt",
		"reload_end": "generic_rifle_bolt",
		"bolt": "generic_rifle_bolt"
	}
}

# Loop and timing information in seconds
var loop_info = {
	"lofi": {
		"loop_start": 0.0,  # Entire song loops
		"loop_end": 0.0,    # Will be set dynamically when loaded
		"has_ending": false
	},
	"somalian_pirates": {
		"loop_start": 78.545,  # 1:18.545
		"loop_end": 113.455,   # 1:53.455
		"ending_duration": 45.0,
		"has_ending": true
	},
	"egypt": {
		"loop_start": 106.667,   # 1:46.667
		"loop_end": 144.0,       # 2:24.000
		"ending_duration": 120.0, # 2 minutes
		"has_ending": true
	},
	"montuno": {
		"loop_start": 34.286,    # 0:34.286
		"loop_end": 104.288,     # 1:44.288
		"ending_duration": 75.712, # Approximately until 3 mins
		"has_ending": true
	},
	"japan_night_race": {
		"loop_start": 13.521,    # 0:13.521
		"loop_end": 54.084,      # 0:54.084
		"ending_duration": 4.0,   # 4 seconds after loop end
		"has_ending": true
	}
}

# Audio players
var music_player = AudioStreamPlayer.new()
var fade_player = AudioStreamPlayer.new()

# Sound effect players (pool for multiple simultaneous sounds)
var sound_players = []
var max_sound_players = 8  # Maximum number of simultaneous sound effects
var next_player_index = 0  # For round-robin allocation
var current_track = ""
var next_track = ""
var is_looping = false
var loop_timer = null
var ending_timer = null
var fade_tween = null
# Music for each round, will repeat after round 5
# Round 1: SomalianPirates
# Round 2: JapanNightRace
# Round 3: Montuno
# Round 4: JapanNightRace
# Round 5: SomalianPirates (pattern repeats)
var round_music_pattern = ["somalian_pirates", "japan_night_race", "montuno", "japan_night_race", "somalian_pirates"]
var is_in_lobby = false
var ending_started = false

func _ready():
	# Set up music players
	add_child(music_player)
	add_child(fade_player)
	
	# Set up sound effect player pool
	for i in range(max_sound_players):
		var player = AudioStreamPlayer.new()
		player.name = "SoundPlayer" + str(i)
		player.bus = "SFX" # Use a separate audio bus for sound effects
		add_child(player)
		sound_players.append(player)
	
	# Create loop timer
	loop_timer = Timer.new()
	loop_timer.one_shot = true
	loop_timer.timeout.connect(_on_loop_timer_timeout)
	add_child(loop_timer)
	
	# Create ending timer
	ending_timer = Timer.new()
	ending_timer.one_shot = true
	ending_timer.timeout.connect(_on_ending_timer_timeout)
	add_child(ending_timer)
	
	# Wait a bit after adding to scene to connect signals
	await get_tree().create_timer(0.5).timeout
	
	# Variables for scene change detection
	self.current_scene_path = ""
	
	# Process the first scene
	call_deferred("_check_for_scene_change")
	
	# Connect to wave completed signal from GameManager
	GameManager.wave_completed.connect(_on_wave_completed)
	
	# Start with determining correct music based on current scene
	determine_initial_music()

func determine_initial_music():
	# Identify the current scene
	var current_scene = get_tree().current_scene
	if current_scene == null:
		await get_tree().process_frame
		current_scene = get_tree().current_scene
	
	var scene_name = current_scene.name
	
	print("AudioManager: Starting music for scene: ", scene_name)
	
	# Lobby scenes should play lofi
	if scene_name == "CampaignMenu" or scene_name == "3dcampaignmenu" or "shop" in scene_name.to_lower():
		is_in_lobby = true
		play_music("lofi")
	else:
		is_in_lobby = false
		play_round_music()

# Variable to track current scene path
var current_scene_path = ""
var previous_scene = null


func _check_for_scene_change():
	# Get the current scene
	var scene = get_tree().current_scene
	if scene == null:
		return
		
	# Get the current scene path
	var new_scene_path = scene.scene_file_path
	
	# If the scene path changed, we have a new scene
	if new_scene_path != current_scene_path:
		# Update the current scene path
		current_scene_path = new_scene_path
		
		# Handle the scene change
		_on_scene_change(scene)

func _on_scene_change(scene):
	var scene_name = scene.name
	print("AudioManager: Scene changed to: ", scene_name, " (", current_scene_path, ")")
	
	# Play appropriate music for the scene
	if scene_name == "CampaignMenu" or scene_name == "3dcampaignmenu" or "shop" in scene_name.to_lower():
		is_in_lobby = true
		cross_fade_to("lofi")
	else:
		is_in_lobby = false
		play_round_music()

func play_round_music():
	# Get the current round and play music according to the pattern
	var round_index = (GameManager.current_round - 1) % round_music_pattern.size()
	var track_to_play = round_music_pattern[round_index]
	cross_fade_to(track_to_play)
	print("AudioManager: Playing round music: ", track_to_play, " for round ", GameManager.current_round)

func _on_wave_completed():
	print("AudioManager: Wave completed, checking if it's the last wave in round")
	# Check if this was the last wave in the round
	if GameManager.waves_completed_in_round >= GameManager.game_parameters.waves_per_round:
		print("AudioManager: Last wave in round completed, playing ending section")
		play_ending_section()

func play_ending_section():
	# If already playing an ending or in lobby, don't do anything
	if ending_started or is_in_lobby:
		return
	
	ending_started = true
	
	# Stop any active loop
	is_looping = false
	if loop_timer.is_stopped() == false:
		loop_timer.stop()
	
	# If the current track has an ending section, play it
	if current_track in loop_info and loop_info[current_track]["has_ending"]:
		var ending_duration = min(loop_info[current_track]["ending_duration"], 5.0)  # Cap at 5 seconds
		
		print("AudioManager: Playing ending section of ", current_track, " for ", ending_duration, " seconds")
		
		# Set timer to finish after the ending section duration (capped at 5 seconds)
		ending_timer.wait_time = ending_duration
		ending_timer.start()
		
		# Let the music continue playing until the timer expires
		# The music is already playing, we just let it continue past the loop point
	else:
		# If no ending section, just fade out
		fade_out()

func _on_ending_timer_timeout():
	print("AudioManager: Ending section complete, fading out")
	ending_started = false
	fade_out()

func play_music(track_name):
	# Stop any active music
	stop_music()
	
	if track_name in music:
		current_track = track_name
		music_player.stream = music[track_name]
		
		# For lofi, set the loop end to the track length since we loop the entire file
		if track_name == "lofi":
			# We'll set this when the stream is actually loaded
			music_player.finished.connect(_on_lofi_finished, CONNECT_ONE_SHOT)
		else:
			is_looping = true
			music_player.finished.disconnect(_on_lofi_finished) if music_player.finished.is_connected(_on_lofi_finished) else null
		
		# Set player to the start of the track
		music_player.play(0.0)
		
		# If this is a looping track, set up the loop timer
		if track_name != "lofi" and is_looping:
			setup_loop(track_name)
			
		# Fade in
		fade_in(music_player)
		
		print("AudioManager: Started playing ", track_name)

func _on_lofi_finished():
	# Simply restart lofi from the beginning
	if current_track == "lofi" and is_in_lobby:
		music_player.play(0.0)
		print("AudioManager: Restarting lofi loop")

func setup_loop(track_name):
	if not track_name in loop_info:
		return
	
	var loop_start = loop_info[track_name]["loop_start"]
	var loop_end = loop_info[track_name]["loop_end"]
	
	# If already past the loop end, don't set up loop
	if music_player.get_playback_position() >= loop_end:
		return
	
	# Calculate time until loop point
	var time_to_loop_end = loop_end - music_player.get_playback_position()
	
	# Set timer to loop back when reaching the loop end point
	loop_timer.wait_time = time_to_loop_end
	loop_timer.start()
	
	print("AudioManager: Loop set up for ", track_name, ", will loop in ", time_to_loop_end, " seconds")

func _on_loop_timer_timeout():
	if not is_looping or current_track == "":
		return
	
	# Get loop points
	var loop_start = loop_info[current_track]["loop_start"]
	
	# Jump back to loop start
	music_player.seek(loop_start)
	
	# Set up the next loop
	setup_loop(current_track)
	
	print("AudioManager: Looped back to ", loop_start, " seconds in ", current_track)

func cross_fade_to(track_name):
	# If already playing this track, do nothing
	if current_track == track_name:
		return
	
	print("AudioManager: Cross-fading from ", current_track, " to ", track_name)
	
	# Stop any active loop
	is_looping = false
	if loop_timer.is_stopped() == false:
		loop_timer.stop()
	
	# Remember what we're switching to
	next_track = track_name
	
	# Start the fade out
	fade_out()

func fade_in(player, duration = 1.0):
	# Cancel any existing tween
	if fade_tween:
		fade_tween.kill()
	
	# Start from silent
	player.volume_db = -80.0
	
	# Create a new tween for fading in
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", 0.0, duration)
	
	print("AudioManager: Fading in over ", duration, " seconds")

func fade_out(duration = 1.0):
	# Cancel any existing tween
	if fade_tween:
		fade_tween.kill()
	
	# Create a new tween for fading out
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, duration)
	fade_tween.tween_callback(func(): 
		stop_music()
		if next_track != "":
			# Play the next track
			play_music(next_track)
			next_track = ""
	)
	
	print("AudioManager: Fading out over ", duration, " seconds")

func stop_music():
	# Stop any active loop
	is_looping = false
	ending_started = false
	if loop_timer.is_stopped() == false:
		loop_timer.stop()
	if ending_timer.is_stopped() == false:
		ending_timer.stop()
	
	# Stop the music player
	music_player.stop()
	
	print("AudioManager: Music stopped")

# Gun sound methods

# Play a gun sound for a specific gun type and action
func play_gun_sound(gun_type: String, action: String, volume_db: float = 0.0) -> void:
	# Get the appropriate sound name from the gun mapping
	if gun_type in gun_sound_map and action in gun_sound_map[gun_type]:
		var sound_name = gun_sound_map[gun_type][action]
		play_sound(sound_name, volume_db)
	else:
		print("WARNING: No sound mapping for gun_type: " + gun_type + ", action: " + action)

# Load a sound file if it exists
func load_sound(sound_name: String) -> AudioStream:
	# Check if we already loaded this sound
	if sound_name in gun_sounds:
		return gun_sounds[sound_name]
	
	# Get the path for this sound
	if not sound_name in gun_sound_paths:
		print("WARNING: No path defined for sound: " + sound_name)
		return null
		
	var path = gun_sound_paths[sound_name]
	
	# Try to load the file
	if ResourceLoader.exists(path):
		var sound = load(path)
		gun_sounds[sound_name] = sound
		return sound
	else:
		print("WARNING: Sound file not found: " + path)
		return null

# Play a specific sound by name
func play_sound(sound_name: String, volume_db: float = 0.0) -> void:
	# Try to load the sound
	var sound = load_sound(sound_name)
	
	# If sound wasn't found, try to use a generic sound
	if sound == null and sound_name != "generic_rifle_shoot":
		print("Trying generic sound instead")
		sound = load_sound("generic_rifle_shoot")
	
	# If we have a valid sound, play it
	if sound != null:
		# Get the next available player in the pool
		var player = get_next_sound_player()
		if player:
			player.stream = sound
			player.volume_db = volume_db
			player.play()
			print("AudioManager: Playing sound: ", sound_name)
		else:
			print("WARNING: No available sound players")

# Find an available sound player or reuse the oldest one
func get_next_sound_player() -> AudioStreamPlayer:
	# First try to find a player that's not currently playing
	for player in sound_players:
		if not player.playing:
			return player
	
	# If all players are busy, use round-robin to replace the "oldest" one
	var player = sound_players[next_player_index]
	next_player_index = (next_player_index + 1) % max_sound_players
	return player

# Convenience methods for common gun actions
func play_gun_shoot(gun_type: String) -> void:
	play_gun_sound(gun_type, "shoot", -5.0)  # Slightly reduced volume

func play_gun_reload_start(gun_type: String) -> void:
	play_gun_sound(gun_type, "reload_start")
	
func play_gun_reload_end(gun_type: String) -> void:
	play_gun_sound(gun_type, "reload_end")

func play_gun_bolt(gun_type: String) -> void:
	play_gun_sound(gun_type, "bolt")

func play_bullet_impact() -> void:
	play_sound("bullet_impact", -10.0)  # Lower volume for impacts

func play_bullet_flyby() -> void:
	play_sound("bullet_flyby", -15.0)  # Much lower volume for flybys

func _process(_delta):
	# Check for scene changes
	_check_for_scene_change()
	
	# For debugging
	if Input.is_action_just_pressed("key_1"):
		print("Current position: ", music_player.get_playback_position(), " seconds")
	
	# Debug - test gun sounds with key presses
	if Input.is_action_just_pressed("key_2"):
		play_gun_shoot("ak74")
	if Input.is_action_just_pressed("key_3"):
		play_gun_reload_start("ak74")
	if Input.is_action_just_pressed("key_4"):
		play_gun_reload_end("ak74")
	
	# Update track position for debugging
	if Engine.is_editor_hint():
		if music_player.playing:
			var position = music_player.get_playback_position()
			var minutes = int(position / 60)
			var seconds = position - (minutes * 60)
			print(str(minutes) + ":" + "%02d" % seconds)
