extends Node

signal wave_started
signal wave_completed
signal round_completed
signal game_ready
signal campaign_completed
signal enemies_changed(count: int)
signal vr_mode_changed(enabled: bool)

# Flag to track which ship is currently the assigned bomber
var current_bomber_id: int = -1

# Basic wave configuration
@export var difficulty: String = "Easy"
var current_wave: int = 1
var current_round: int = 1
var total_rounds: int = 3
var waves_per_round: int = 3

# Wave metrics
var enemies_per_wave_base: int = 8      # Base number of enemies per wave
var enemies_per_wave_max: int = 20      # Maximum enemies per wave
var enemies_per_wave: int = 8           # Actual enemies for current wave
var wave_difficulty_multiplier: float = 1.0  # Multiplier for wave difficulty
var spawn_interval_multiplier: float = 1.0   # Multiplier for enemy spawn intervals
var current_enemies_count: int = 0
var enemies_spawned_in_wave: int = 0    # How many enemies have been spawned in current wave
var wave_in_progress: bool = false
var next_enemy_id: int = 0     # Used to give each enemy a unique ID

# Time metrics
var wave_start_time: float = 0.0
var wave_target_time: float = 45.0  # Time to complete wave for max gold
var wave_target_time_multiplier: float = 1.2  # Increases target time for each wave

# Campaign/voyage properties
var current_voyage: int = 1
var voyage_name: String = "Calm Waters"

# Difficulty adjustments - these are modified in set_difficulty()
var enemy_spawn_rate: float = 4.0  # seconds
var enemy_speed: float = 1.0       # multiplier 
var enemy_health: float = 1.0      # multiplier

# Game state
var game_started: bool = false
var shop_open: bool = false
var wave_complete_check_pending: bool = false  # NEW: Track pending completion checks
var vr_mode_enabled: bool = false  # For VR mode tracking

# Player upgrades
var gun_type: String = "standard"  # standard, double, spread, etc.
var damage_bonus: float = 0.0      # Percentage bonus to damage
var health_regen: float = 2.0      # Health regenerated per wave completion
var max_health_bonus: float = 0.0  # Bonus to max health
var coin_bonus: float = 0.0        # Bonus to coin collection

# Game references
var player = null
var player_boat = null
var enemy_spawner = null

# Don't preload the scene - we'll load it at runtime instead
var main_scene_packed = null  # Will be loaded when needed

func _ready() -> void:
	# Initialize bomber tracker
	current_bomber_id = -1
	
	# Get current scene name
	var current_scene_name = get_tree().current_scene.name if get_tree().current_scene else ""
	print("Current scene: " + current_scene_name)
	
	# If game hasn't been started from campaign menu, show it
	if not game_started and current_scene_name != "CampaignMenu" and current_scene_name != "Node3D" and current_scene_name != "3DCampaignMenu" and current_scene_name != "ShopScene":
		call_deferred("show_campaign_menu")
	
	# Set up the main game scene if needed
	if current_scene_name == "Node3D":
		# Always use VR mode - no dialog
		vr_mode_enabled = true
		emit_signal("vr_mode_changed", true)
		
		# Wait a moment to ensure player is fully initialized first
		await get_tree().create_timer(0.1).timeout
		call_deferred("setup_game_scene")

func _process(_delta: float) -> void:
	# Check if we need to verify wave completion (with safety check)
	if wave_complete_check_pending and wave_in_progress:
		wave_complete_check_pending = false
		check_wave_completion()

func setup_game_scene() -> void:
	print("Setting up game scene components")
	
	# Try to find and initialize key game components
	player_boat = get_tree().get_first_node_in_group("player_boat")
	if player_boat:
		print("Found player boat: ", player_boat.name)
	else:
		print("WARNING: No player boat found in the scene! Will search again after scene is fully loaded")
		# Schedule a retry after a short delay to give scene time to initialize
		get_tree().create_timer(0.5).timeout.connect(_retry_find_components)
	
	# Find and assign the player node
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("Found player: ", player.name)
	else:
		print("WARNING: No player found in the scene! Will retry later")
	
	# Find and assign the enemy spawner
	enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner:
		print("Found enemy spawner: ", enemy_spawner.name)
	else:
		print("WARNING: No enemy spawner found in the scene! Will retry later")
	
	# Create the ship positioner if it doesn't exist
	if get_tree().current_scene and not get_tree().current_scene.has_node("ShipPositioner"):
		create_ship_positioner()
	
	# Reset bomber system when game scene is set up
	reset_bomber_system()
	
	# Set initial game state
	wave_in_progress = false
	
	# Apply any modifiers from the selected voyage
	update_modifiers()
	
	print("Game scene setup complete!")
	
	# We'll setup the wave after we retry finding components
	call_deferred("_check_can_start_wave")
	
	# Emit signal to notify that game is ready
	emit_signal("game_ready")

func _retry_find_components() -> void:
	print("Retrying to find game components...")
	
	# Find player boat if not already found
	if not player_boat:
		player_boat = get_tree().get_first_node_in_group("player_boat")
		if not player_boat:
			player_boat = get_tree().get_first_node_in_group("PlayerBoat")
	
	# Find player if not already found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_tree().get_first_node_in_group("Player")
	
	# Find enemy spawner if not already found
	if not enemy_spawner:
		enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
		if not enemy_spawner:
			enemy_spawner = get_tree().get_first_node_in_group("EnemySpawner")
			if not enemy_spawner:
				enemy_spawner = get_tree().current_scene.find_child("EnemySpawner", true, false)
	
	# Now check if we can start the wave
	_check_can_start_wave()

func _check_can_start_wave() -> void:
	print("Checking if wave can be started...")
	if enemy_spawner:
		print("Enemy spawner found, setting up wave")
		call_deferred("setup_wave")
	else:
		print("Cannot setup wave yet - enemy spawner not found")
		# Schedule another retry
		get_tree().create_timer(1.0).timeout.connect(_retry_find_components)

func update_modifiers() -> void:
	print("Applying game modifiers (difficulty: %s)" % difficulty)
	
	# Set wave difficulty multiplier based on selected difficulty
	match difficulty.to_lower():
		"easy":
			wave_difficulty_multiplier = 0.7
			spawn_interval_multiplier = 1.5
		"medium", "normal":
			wave_difficulty_multiplier = 1.0
			spawn_interval_multiplier = 1.0
		"hard":
			wave_difficulty_multiplier = 1.5
			spawn_interval_multiplier = 0.7
		_:
			wave_difficulty_multiplier = 1.0
			spawn_interval_multiplier = 1.0
	
	print("Wave difficulty multiplier: %f" % wave_difficulty_multiplier)
	print("Spawn interval multiplier: %f" % spawn_interval_multiplier)

func create_ship_positioner() -> void:
	# Check if a TargetPlane already exists in the scene
	var target_plane = get_tree().current_scene.get_node_or_null("TargetPlane")
	
	# If no TargetPlane exists, create one from the packed scene
	if not target_plane:
		var target_plane_scene = load("res://TargetPlane.tscn")
		if target_plane_scene:
			target_plane = target_plane_scene.instantiate()
			
			# Position it in front of the player's boat
			var boats = get_tree().get_nodes_in_group("Player")
			if boats.size() > 0:
				var player_boat = boats[0]
				if player_boat.global_position == Vector3.ZERO:
					var player_node = get_tree().current_scene.get_node_or_null("Player")
					if player_node:
						target_plane.global_position = Vector3(0, 0.1, player_node.transform.origin.z + 20.0)
					else:
						target_plane.global_position = Vector3(0, 0.1, -10.0)
				else:
					target_plane.global_position = Vector3(0, 0.1, player_boat.global_position.z + 20.0)
			
			# Add to scene and hide
			get_tree().current_scene.add_child(target_plane)
			target_plane.visible = false
	
	# Create the ship positioner
	var positioner_script = load("res://ShipPositioner.gd")
	var positioner = Node3D.new()
	positioner.name = "ShipPositioner"
	
	if positioner_script:
		positioner.set_script(positioner_script)
		get_tree().current_scene.add_child(positioner)
		print("DEBUG: Created ship positioner")
	else:
		print("ERROR: Could not load ShipPositioner.gd script")

func set_difficulty(d: String) -> void:
	difficulty = d
	
	# Adjust parameters based on difficulty
	match d:
		"Easy":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 3
			wave_target_time = 45.0
			enemy_spawn_rate = 5.0
			enemy_speed = 0.8
			enemy_health = 0.8
		"Normal":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 12
			wave_target_time = 55.0
			enemy_spawn_rate = 4.0
			enemy_speed = 1.0
			enemy_health = 1.0
		"Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 15
			wave_target_time = 75.0
			enemy_spawn_rate = 3.5
			enemy_speed = 1.2
			enemy_health = 1.2
		"Very Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 17
			wave_target_time = 90.0
			enemy_spawn_rate = 3.0
			enemy_speed = 1.4
			enemy_health = 1.5
		"Extreme":
			total_rounds = 3
			waves_per_round = 3
			enemies_per_wave_base = 20
			wave_target_time = 120.0
			enemy_spawn_rate = 2.5
			enemy_speed = 1.6
			enemy_health = 2.0
	
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
	
	# Calculate enemies per wave based on progress and difficulty
	var base = enemies_per_wave_base
	var max_enemies = enemies_per_wave_max
	var progress_factor = (current_round - 1) * waves_per_round + (current_wave - 1)
	var total_waves = total_rounds * waves_per_round
	var progress_scale = float(progress_factor) / total_waves
	
	# Ensure we're getting 10-20 enemies per wave
	enemies_per_wave = int(base + (max_enemies - base) * (progress_scale + difficulty_factor))
	enemies_per_wave = max(10, min(enemies_per_wave, 20))
	
	# Calculate wave difficulty multiplier
	wave_difficulty_multiplier = 1.0 + (0.05 * progress_factor)

func set_voyage(voyage_num: int, diff: String) -> void:
	current_voyage = voyage_num
	set_difficulty(diff)
	
	# Set voyage name
	match voyage_num:
		1: voyage_name = "Calm Waters"
		2: voyage_name = "Rough Seas"
		3: voyage_name = "Storm Warning"
		4: voyage_name = "Hurricane"
		5: voyage_name = "Maelstrom"
		_: voyage_name = "Custom Voyage"

func start_campaign() -> void:
	print("GameManager: Starting campaign")
	
	# Reset game state
	current_round = 1
	current_wave = 1
	game_started = true
	wave_in_progress = false
	
	# Reset enemy tracking
	enemies_per_wave = calculate_enemies_for_wave()
	current_enemies_count = 0
	next_enemy_id = 0
	
	# Handle scene transition
	var current_scene_name = get_tree().current_scene.name
	if current_scene_name == "3DCampaignMenu" or current_scene_name == "CampaignMenu":
		call_deferred("_load_main_scene_directly")
	else:
		setup_wave()

func _load_main_scene_directly() -> void:
	print("LOADING MAIN SCENE DIRECTLY")
	
	# Ensure XR is still enabled
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = true
		vr_mode_enabled = true
		emit_signal("vr_mode_changed", true)
	
	# Change scene
	var err = get_tree().change_scene_to_file("res://Main.tscn")
	if err == OK:
		# Wait for scene to load
		await get_tree().create_timer(0.5).timeout
		
		# Re-enable VR and setup game
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
			vr_mode_enabled = true
			emit_signal("vr_mode_changed", true)
		
		setup_game_scene()
		setup_wave()

func start_wave() -> void:
	# Calculate wave parameters
	calculate_enemies_per_wave()
	current_enemies_count = 0
	enemies_spawned_in_wave = 0
	
	# Reset bomber system
	reset_bomber_system()
	
	# Set wave state
	wave_in_progress = true
	wave_complete_check_pending = false
	wave_start_time = Time.get_unix_time_from_system()
	
	print("Starting wave %d of round %d with %d enemies" % [current_wave, current_round, enemies_per_wave])
	
	# Start spawning
	var spawners = get_tree().get_nodes_in_group("EnemySpawner")
	if spawners.size() > 0:
		spawners[0].start_wave_spawning()

func check_wave_completion() -> void:
	var spawners = get_tree().get_nodes_in_group("enemy_spawner")
	if spawners.size() > 0:
		spawners[0].check_wave_completion()

func complete_wave() -> void:
	wave_in_progress = false
	
	# Calculate rewards
	var elapsed_time = (Time.get_unix_time_from_system() - wave_start_time)
	var time_ratio = wave_target_time / elapsed_time
	var time_percent = clamp(time_ratio, 0.0, 1.0)
	
	var silver_reward = 10 + (5 * current_wave)
	var gold_reward = 2 + current_wave
	
	# Award currency
	CurrencyManager.add_silver(silver_reward)
	CurrencyManager.add_gold(gold_reward, time_percent)
	
	# Apply healing
	var player_boat = get_tree().get_nodes_in_group("Player")
	if player_boat.size() > 0 and player_boat[0].has_method("heal"):
		var heal_amount = health_regen * CurrencyManager.health_regen_multiplier
		player_boat[0].heal(heal_amount)
	
	emit_signal("wave_completed")
	show_shop()

func show_shop() -> void:
	shop_open = true
	
	# Pause enemy spawning
	var spawner = get_tree().get_nodes_in_group("EnemySpawner")
	if spawner.size() > 0:
		spawner[0].pause_spawning()
	
	# Show shop UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	var shop_scene = load("res://shop1.tscn")
	var shop_instance = shop_scene.instantiate()
	get_tree().current_scene.add_child(shop_instance)

func close_shop() -> void:
	shop_open = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
	
	if current_round > total_rounds:
		campaign_complete()
	else:
		show_round_complete_screen()

func show_round_complete_screen() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	var round_complete_scene = load("res://RoundCompleteMenu.tscn")
	if round_complete_scene:
		var round_complete_instance = round_complete_scene.instantiate()
		get_tree().current_scene.add_child(round_complete_instance)
	else:
		continue_to_next_round()

func continue_to_next_round() -> void:
	get_tree().paused = false
	start_wave()

func campaign_complete() -> void:
	emit_signal("campaign_completed")
	get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

func show_campaign_menu() -> void:
	get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

func reset_bomber_system() -> void:
	current_bomber_id = -1

func calculate_enemies_for_wave() -> int:
	var enemy_count = enemies_per_wave_base
	enemy_count += (current_wave - 1) * 2
	enemy_count += (current_round - 1) * 5
	enemy_count = int(enemy_count * wave_difficulty_multiplier)
	enemy_count = min(enemy_count, enemies_per_wave_max)
	return enemy_count

func setup_wave() -> void:
	print("Setting up wave %d of round %d" % [current_wave, current_round])
	
	enemies_per_wave = calculate_enemies_for_wave()
	enemies_spawned_in_wave = 0
	current_enemies_count = 0
	
	if wave_in_progress:
		wave_in_progress = false
	
	emit_signal("enemies_changed", current_enemies_count)
	call_deferred("start_wave")
