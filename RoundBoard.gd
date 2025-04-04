extends Node3D

# Default values
var voyage_num = 1
var voyage_name = "VR Pirates"
var difficulty = "Normal"
var current_round = 1
var current_wave = 1

func _ready() -> void:
	$Label3D.position = Vector3.ZERO
	$Label3D.scale = Vector3(0.2, 0.2, 0.2)

func _process(_delta: float) -> void:
	# Get values from GameManager if they exist
	if GameManager.has_method("get"):
		if GameManager.get("current_voyage_num") != null:
			voyage_num = GameManager.current_voyage_num
		# Removed invalid reference to 'current_voyage'
		
		if GameManager.get("voyage_name") != null:
			voyage_name = GameManager.voyage_name
		
		if GameManager.get("current_voyage_difficulty") != null:
			difficulty = str(GameManager.current_voyage_difficulty)
		if GameManager.get("difficulty") != null:
			difficulty = GameManager.difficulty
		
		if GameManager.get("current_round") != null:
			current_round = GameManager.current_round
		
		if GameManager.get("current_wave") != null:
			current_wave = GameManager.current_wave
		elif GameManager.get("enemies_spawned_in_wave") != null:
			current_wave = GameManager.enemies_spawned_in_wave
	
	# Get total waves per round from GameParameters
	var total_waves = 5
	if GameManager.has_method("get") and GameManager.get("game_parameters") != null:
		total_waves = GameManager.game_parameters.waves_per_round
	
	# Calculate the current wave within round
	var wave_in_round = GameManager.waves_completed_in_round + 1
	if wave_in_round > total_waves:
		wave_in_round = total_waves
	
	# Update the display
	$Label3D.text = "Voyage %d: %s\nDifficulty: %s\nRound: %d\nWave: %d/%d" % [
		voyage_num,
		voyage_name,
		difficulty,
		current_round,
		wave_in_round,
		total_waves
	]
