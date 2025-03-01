extends Node

signal wave_completed
signal round_completed
signal campaign_completed
signal enemies_changed(count: int)

# Basic wave configuration
@export var difficulty: String = "Easy"
@export var current_round: int = 1
@export var current_wave: int = 1
@export var total_rounds: int = 3
@export var waves_per_round: int = 3

# Wave metrics
var enemies_per_wave_base: int = 10
var enemies_per_wave_max: int = 20
var current_enemies_count: int = 0
var enemies_per_wave: int = 10  # Default minimum
var wave_difficulty_multiplier: float = 1.0

# Time metrics
var wave_start_time: float = 0.0
var wave_target_time: float = 45.0  # Time to complete wave for max gold
var wave_target_time_multiplier: float = 1.2  # Increases target time for each wave

# Campaign/voyage properties
var current_voyage: int = 1
var voyage_name: String = "Calm Waters"

# Difficulty adjustments
var enemy_spawn_rate: float = 4.0  # seconds
var enemy_speed: float = 1.0       # multiplier
var enemy_health: float = 1.0      # multiplier

# Game state
var game_started: bool = false
var wave_in_progress: bool = false
var shop_open: bool = false

# Player upgrades
var gun_type: String = "standard"  # standard, double, spread, etc.
var damage_bonus: float = 0.0      # Percentage bonus to damage
var health_regen: float = 2.0      # Health regenerated per wave completion
var max_health_bonus: float = 0.0  # Bonus to max health
var coin_bonus: float = 0.0        # Bonus to coin collection

func _ready() -> void:
	# If game hasn't been started from campaign menu, show it
	if not game_started and get_tree().current_scene.name != "CampaignMenu":
		call_deferred("show_campaign_menu")

func set_difficulty(d: String) -> void:
	difficulty = d
	
	# Adjust parameters based on difficulty
	match d:
		"Easy":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 10
			wave_target_time = 45.0
		"Normal":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 12
			wave_target_time = 55.0
		"Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 15
			wave_target_time = 75.0
		"Very Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 17
			wave_target_time = 90.0
		"Extreme":
			total_rounds = 3
			waves_per_round = 3
			enemies_per_wave_base = 20
			wave_target_time = 120.0
	
	# Calculate enemies per wave based on difficulty
	calculate_enemies_per_wave()

func calculate_enemies_per_wave() -> void:
	var difficulty_factor = 0.0
	
	match difficulty:
		"Easy": difficulty_factor = 0.0
		"Normal": difficulty_factor = 0.25
		"Hard": difficulty_factor = 0.5
		"Very Hard": difficulty_factor = 0.75
		"Extreme": difficulty_factor = 1.0
	
	# Calculate enemies per wave based on:
	# 1. Base amount for difficulty (10-20 enemies)
	# 2. Scaled to add more as rounds/waves progress
	# 3. Scaled by difficulty factor
	var base = enemies_per_wave_base
	var max_enemies = enemies_per_wave_max
	var progress_factor = (current_round - 1) * waves_per_round + (current_wave - 1)
	var total_waves = total_rounds * waves_per_round
	var progress_scale = float(progress_factor) / total_waves
	
	# FIXED CALCULATION: Ensure we're getting 10-20 enemies per wave
	enemies_per_wave = int(base + (max_enemies - base) * (progress_scale + difficulty_factor))
	enemies_per_wave = max(10, min(enemies_per_wave, 20))
	
	print("DEBUG: Wave will spawn " + str(enemies_per_wave) + " enemies (difficulty: " + difficulty + ")")
	
	# Calculate wave difficulty multiplier - increases slightly with each wave
	wave_difficulty_multiplier = 1.0 + (0.05 * progress_factor)

func set_voyage(voyage_num: int, diff: String) -> void:
	current_voyage = voyage_num
	set_difficulty(diff)
	
	# Set voyage name based on the pattern in CampaignMenu.gd
	match voyage_num:
		1: voyage_name = "Calm Waters"
		2: voyage_name = "Rough Seas"
		3: voyage_name = "Storm Warning"
		4: voyage_name = "Hurricane"
		5: voyage_name = "Maelstrom"
		_: voyage_name = "Custom Voyage"

func start_campaign() -> void:
	current_round = 1
	current_wave = 1
	game_started = true
	CurrencyManager.reset_temp_currency()
	start_wave()

func start_wave() -> void:
	# Calculate wave parameters
	calculate_enemies_per_wave()
	current_enemies_count = 0
	wave_in_progress = true
	wave_start_time = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	
	print("DEBUG: Starting wave " + str(current_wave) + " of round " + str(current_round))
	print("DEBUG: Wave will have " + str(enemies_per_wave) + " enemies")
	
	# Wait a short moment before starting spawner to ensure everything is ready
	await get_tree().create_timer(0.5).timeout
	
	# Tell spawn system to start spawning enemies - search by both group and script
	var spawner = get_tree().get_nodes_in_group("EnemySpawner")
	if spawner.size() > 0:
		print("DEBUG: Found enemy spawner in group, starting wave")
		spawner[0].start_wave_spawning()
	else:
		# Try finding by node type/script
		spawner = get_tree().get_nodes_with_script(load("res://EnemySpawner.gd"))
		if spawner.size() > 0:
			print("DEBUG: Found enemy spawner by script, starting wave")
			spawner[0].add_to_group("EnemySpawner")  # Add to group for future reference
			spawner[0].start_wave_spawning()
		else:
			# Last resort - try to find by node name
			spawner = [get_tree().current_scene.find_child("EnemySpawner", true, false)]
			if spawner[0] != null:
				print("DEBUG: Found enemy spawner by name, starting wave")
				spawner[0].add_to_group("EnemySpawner")  # Add to group for future reference
				spawner[0].start_wave_spawning()
			else:
				print("ERROR: No enemy spawner found in the scene!")
	
	# Calculate target time for this wave
	# Each wave gets progressively longer target times
	var wave_progress = (current_round - 1) * waves_per_round + (current_wave - 1)
	var target_time_factor = pow(wave_target_time_multiplier, wave_progress)
	var base_target_time = wave_target_time
	
	# Set target time based on difficulty and wave progression
	match difficulty:
		"Easy": base_target_time = 45.0
		"Normal": base_target_time = 55.0
		"Hard": base_target_time = 75.0
		"Very Hard": base_target_time = 90.0 
		"Extreme": base_target_time = 120.0
	
	wave_target_time = base_target_time * target_time_factor

func register_enemy() -> void:
	current_enemies_count += 1
	emit_signal("enemies_changed", current_enemies_count)

func enemy_defeated() -> void:
	current_enemies_count -= 1
	emit_signal("enemies_changed", current_enemies_count)
	
	print("DEBUG: Enemy defeated. " + str(current_enemies_count) + " enemies remaining.")
	
	# Check for wave completion if all enemies are gone
	if current_enemies_count <= 0 and wave_in_progress:
		check_wave_completion()
		
	# If only 1 enemy remains, tell spawner to check for next batch
	if current_enemies_count <= 1 and wave_in_progress:
		var spawner = get_tree().get_nodes_in_group("EnemySpawner")
		if spawner.size() > 0 and spawner[0].enemies_spawned < enemies_per_wave:
			# This will trigger the timer check in the spawner
			print("DEBUG: Enemy count is low, checking if we should prepare next batch")
			spawner[0]._on_Timer_timeout()

# Separate function to check if wave should be completed
func check_wave_completion() -> void:
	# Check if enough enemies have been spawned
	var spawner = get_tree().get_nodes_in_group("EnemySpawner")
	var spawned_enough = true
	var spawned_count = 0
	
	if spawner.size() > 0:
		spawned_count = spawner[0].enemies_spawned
		spawned_enough = spawned_count >= enemies_per_wave
	
	# Only complete wave if all enemies are defeated AND enough have been spawned
	if current_enemies_count <= 0 and wave_in_progress and spawned_enough:
		print("DEBUG: All enemies defeated and all " + str(enemies_per_wave) + " have been spawned, completing wave!")
		complete_wave()
	elif current_enemies_count <= 0 and wave_in_progress:
		print("DEBUG: Enemy count is 0 but only " + str(spawned_count) + " of " + 
			  str(enemies_per_wave) + " enemies have been spawned - waiting for more batches.")

func complete_wave() -> void:
	wave_in_progress = false
	
	# Calculate time-based rewards
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - wave_start_time
	var time_ratio = wave_target_time / elapsed_time
	var time_percent = clamp(time_ratio, 0.0, 1.0)
	
	# Award silver for wave completion
	var silver_reward = 10 + (5 * current_wave) 
	CurrencyManager.add_silver(silver_reward)
	
	# Award gold based on completion time
	var gold_reward = 2 + current_wave
	CurrencyManager.add_gold(gold_reward, time_percent)
	
	# Apply health regeneration
	var player_boat = get_tree().get_nodes_in_group("Player")
	if player_boat.size() > 0 and player_boat[0].has_method("heal"):
		var heal_amount = health_regen * CurrencyManager.health_regen_multiplier
		player_boat[0].heal(heal_amount)
	
	# Signal wave completion
	emit_signal("wave_completed")
	
	# Open shop
	show_shop()

func show_shop() -> void:
	shop_open = true
	
	# Pause enemy spawning
	var spawner = get_tree().get_nodes_in_group("EnemySpawner")
	if spawner.size() > 0:
		spawner[0].pause_spawning()
	
	# Release mouse for UI interaction BEFORE showing shop
	# This is CRITICAL for mouse to work in UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("DEBUG: Mouse mode set to VISIBLE for shop")
	
	# Show shop UI
	get_tree().paused = true  # Pause the game
	var shop_scene = load("res://ShopMenu.tscn")
	var shop_instance = shop_scene.instantiate()
	get_tree().current_scene.add_child(shop_instance)

func close_shop() -> void:
	shop_open = false
	get_tree().paused = false  # Unpause the game
	
	# Restore mouse capture for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("DEBUG: Mouse mode set to CAPTURED for gameplay")
	
	# Move to next wave/round
	next_wave()

func next_wave() -> void:
	current_wave += 1
	if current_wave > waves_per_round:
		next_round()
	else:
		start_wave()

func next_round() -> void:
	emit_signal("round_completed")
	current_round += 1
	current_wave = 1
	
	print("DEBUG: Completed round " + str(current_round-1) + " of " + str(total_rounds))
	
	if current_round > total_rounds:
		# Campaign complete
		print("DEBUG: Campaign completed!")
		campaign_complete()
	else:
		# Show round completion screen
		show_round_complete_screen()

func show_round_complete_screen() -> void:
	# Release mouse for UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Pause the game
	get_tree().paused = true
	
	# Show round complete UI
	var round_complete_scene = load("res://RoundCompleteMenu.tscn")
	if round_complete_scene:
		var round_complete_instance = round_complete_scene.instantiate()
		get_tree().current_scene.add_child(round_complete_instance)
	else:
		# If the scene doesn't exist yet, just continue to next round
		print("WARNING: RoundCompleteMenu.tscn not found, continuing to next round")
		continue_to_next_round()

func continue_to_next_round() -> void:
	# Unpause and continue
	get_tree().paused = false
	start_wave()

func campaign_complete() -> void:
	emit_signal("campaign_completed")
	# Return to campaign menu with victory message
	get_tree().change_scene_to_file("res://CampaignMenu.tscn")
	
func show_campaign_menu() -> void:
	get_tree().change_scene_to_file("res://CampaignMenu.tscn")
