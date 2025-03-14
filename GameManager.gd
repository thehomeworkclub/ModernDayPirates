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
	
	# If game hasn't been started from campaign menu, show it
	if not game_started and get_tree().current_scene.name != "CampaignMenu" and get_tree().current_scene.name != "Node3D" and get_tree().current_scene.name != "3DCampaignMenu":
		call_deferred("show_campaign_menu")
		
	# Set up the main game scene if needed
	if get_tree().current_scene.name == "Node3D":
		# Always use VR mode - no dialog
		vr_mode_enabled = true
		emit_signal("vr_mode_changed", true)
		
		# Wait a moment to ensure player is fully initialized first
		await get_tree().create_timer(0.1).timeout
		call_deferred("setup_game_scene")
		
# Show a popup to select between VR and non-VR mode
func show_mode_selection_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Select Game Mode"
	dialog.dialog_text = "Would you like to play in VR mode?\n\nSelect 'OK' for VR mode or 'Cancel' for desktop mode."
	dialog.get_ok_button().text = "VR Mode"
	dialog.get_cancel_button().text = "Desktop Mode"
	dialog.size = Vector2(400, 200)
	dialog.popup_window = true
	
	# Center the dialog on screen
	var screen_size = DisplayServer.window_get_size()
	dialog.position = Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 100)
	
	# Connect signals
	dialog.confirmed.connect(_on_vr_mode_selected)
	dialog.canceled.connect(_on_desktop_mode_selected)
	
	# Add the dialog to the scene tree
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

# Called when VR mode is selected
func _on_vr_mode_selected() -> void:
	vr_mode_enabled = true
	print("DEBUG: VR mode selected")
	emit_signal("vr_mode_changed", true)

# Called when desktop mode is selected
func _on_desktop_mode_selected() -> void:
	vr_mode_enabled = false
	print("DEBUG: Desktop mode selected")
	emit_signal("vr_mode_changed", false)

func _process(_delta: float) -> void:
	# NEW: Check if we need to verify wave completion (with safety check)
	if wave_complete_check_pending and wave_in_progress:
		wave_complete_check_pending = false
		check_wave_completion()
		
func setup_game_scene() -> void:
	print("Setting up game scene components")
	
	# Use get_tree().get_first_node_in_group() to find nodes more reliably
	# It can find nodes regardless of their position in the tree
	
	# Try to find and initialize key game components - more flexible search
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
		
	# Try alternate capitalization for enemy spawner group
	if not enemy_spawner:
		enemy_spawner = get_tree().get_first_node_in_group("EnemySpawner")
		if enemy_spawner:
			print("Found enemy spawner using alternate group name: ", enemy_spawner.name)
	
	# Create the ship positioner if it doesn't exist
	if get_tree().current_scene and not get_tree().current_scene.has_node("ShipPositioner"):
		# Create the ship positioning system
		create_ship_positioner()
	
	# Reset bomber system when game scene is set up (including respawn)
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

# Retry finding components that weren't found initially
func _retry_find_components() -> void:
	print("Retrying to find game components...")
	
	# Find player boat if not already found
	if not player_boat:
		player_boat = get_tree().get_first_node_in_group("player_boat")
		if player_boat:
			print("Found player boat after retry: ", player_boat.name)
		else:
			# Try alternate group name
			player_boat = get_tree().get_first_node_in_group("PlayerBoat")
			if player_boat:
				print("Found player boat using alternate group name: ", player_boat.name)
			else:
				print("WARNING: Player boat still not found!")
	
	# Find player if not already found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("Found player after retry: ", player.name)
		else:
			# Try alternate group name
			player = get_tree().get_first_node_in_group("Player")
			if player:
				print("Found player using alternate group name: ", player.name)
			else:
				print("WARNING: Player still not found!")
	
	# Find enemy spawner if not already found
	if not enemy_spawner:
		enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
		if enemy_spawner:
			print("Found enemy spawner after retry: ", enemy_spawner.name)
		else:
			# Try alternate group name
			enemy_spawner = get_tree().get_first_node_in_group("EnemySpawner")
			if enemy_spawner:
				print("Found enemy spawner using alternate group name: ", enemy_spawner.name)
			else:
				print("WARNING: Enemy spawner still not found!")
				
	# Try direct node path as a last resort
	if not enemy_spawner and get_tree().current_scene:
		enemy_spawner = get_tree().current_scene.find_child("EnemySpawner", true, false)
		if enemy_spawner:
			print("Found enemy spawner by direct path: ", enemy_spawner.name)
		else:
			print("CRITICAL: Could not find enemy spawner by any method!")
	
	# Now check if we can start the wave
	_check_can_start_wave()

# Check if we have all required components to start the wave
func _check_can_start_wave() -> void:
	print("Checking if wave can be started...")
	if enemy_spawner:
		print("Enemy spawner found, setting up wave")
		call_deferred("setup_wave")
	else:
		print("Cannot setup wave yet - enemy spawner not found")
		# Schedule another retry
		get_tree().create_timer(1.0).timeout.connect(_retry_find_components)

# Update game modifiers based on difficulty and other settings
func update_modifiers() -> void:
	print("Applying game modifiers (difficulty: %s)" % difficulty)
	
	# Set wave difficulty multiplier based on selected difficulty
	match difficulty:
		"easy":
			wave_difficulty_multiplier = 0.7
			spawn_interval_multiplier = 1.5
		"medium":
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
	
	# Apply enemy attribute settings
	if enemy_health > 0:
		print("Setting enemy health modifier: %f" % enemy_health)
	
	if enemy_speed > 0:
		print("Setting enemy speed modifier: %f" % enemy_speed)
	
	if enemy_spawn_rate > 0:
		print("Setting enemy spawn rate modifier: %f" % enemy_spawn_rate)

func create_ship_positioner() -> void:
	# Check if a TargetPlane already exists in the scene
	var target_plane = get_tree().current_scene.get_node_or_null("TargetPlane")
	
	# If no TargetPlane exists, create one from the packed scene
	if not target_plane:
		var target_plane_scene = load("res://TargetPlane.tscn")
		if target_plane_scene:
			target_plane = target_plane_scene.instantiate()
			
			# Wait one frame to ensure the player is fully initialized
			await get_tree().process_frame
			
			# Position it in front of the player's boat
			var boats = get_tree().get_nodes_in_group("Player")
			if boats.size() > 0:
				var player_boat = boats[0]
				# Use the player's actual position rather than a hardcoded one
				if player_boat.global_position == Vector3.ZERO:
					print("WARNING: Player boat at origin (0,0,0), using scene transform value")
					# Use the transform from the scene as fallback
					var player_node = get_tree().current_scene.get_node_or_null("Player")
					if player_node:
						target_plane.global_position = Vector3(0, 0.1, player_node.transform.origin.z + 20.0)
					else:
						target_plane.global_position = Vector3(0, 0.1, -10.0)
				else:
					target_plane.global_position = Vector3(0, 0.1, player_boat.global_position.z + 20.0)
			else:
				target_plane.global_position = Vector3(0, 0.1, -10.0)
			
			# Add to scene
			get_tree().current_scene.add_child(target_plane)
			
			# Make sure it's invisible in game
			target_plane.visible = false
			
			print("DEBUG: Created target plane at ", target_plane.global_position)
	
	# Load the positioner script
	var positioner_script = load("res://ShipPositioner.gd")
	
	# Create the positioner node
	var positioner = Node3D.new()
	positioner.name = "ShipPositioner"
	
	# Add script
	if positioner_script:
		positioner.set_script(positioner_script)
	else:
		print("ERROR: Could not load ShipPositioner.gd script")
		return
	
	# Add the positioner to the scene
	get_tree().current_scene.add_child(positioner)
	print("DEBUG: Created ship positioner")
	
func create_enemy_barrier() -> void:
	# Load the barrier script
	var barrier_script = load("res://EnemyBarrier.gd")
	
	# Create the barrier node
	var barrier = Node3D.new()
	barrier.name = "EnemyBarrier"
	
	# Add script
	if barrier_script:
		barrier.set_script(barrier_script)
	
	# Create a visual representation
	var barrier_mesh = MeshInstance3D.new()
	barrier_mesh.name = "BarrierVisual"
	
	# Create a box mesh
	var box = BoxMesh.new()
	box.size = Vector3(30.0, 2.0, 0.5)  # Wide but thin barrier
	barrier_mesh.mesh = box
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)  # Semi-transparent red
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 0.0)
	material.emission_energy = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = material
	
	# Position the mesh
	barrier_mesh.position = Vector3(0, 0, 0)
	
	# Add mesh to barrier
	barrier.add_child(barrier_mesh)
	
	# Position the barrier in front of the player's boat
	# Find the player's boat position
	var boat = get_tree().get_nodes_in_group("Player")[0] if get_tree().get_nodes_in_group("Player").size() > 0 else null
	if boat:
		# Position in front of the boat
		barrier.global_position = Vector3(0, 1.0, boat.global_position.z + 15.0)
	else:
		# Default position if boat not found
		barrier.global_position = Vector3(0, 1.0, -10.0)
	
	# Add the barrier to the scene
	get_tree().current_scene.add_child(barrier)
	print("DEBUG: Created enemy barrier at ", barrier.global_position)

func set_difficulty(d: String) -> void:
	difficulty = d
	
	# Adjust parameters based on difficulty
	match d:
		"Easy":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 3
			wave_target_time = 45.0
			enemy_spawn_rate = 5.0    # Slower spawning
			enemy_speed = 0.8         # Slower enemies
			enemy_health = 0.8        # Lower health
		"Normal":
			total_rounds = 1
			waves_per_round = 3
			enemies_per_wave_base = 12
			wave_target_time = 55.0
			enemy_spawn_rate = 4.0    # Default spawning
			enemy_speed = 1.0         # Default speed
			enemy_health = 1.0        # Default health
		"Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 15
			wave_target_time = 75.0
			enemy_spawn_rate = 3.5    # Faster spawning
			enemy_speed = 1.2         # Faster enemies
			enemy_health = 1.2        # More health
		"Very Hard":
			total_rounds = 2
			waves_per_round = 3
			enemies_per_wave_base = 17
			wave_target_time = 90.0
			enemy_spawn_rate = 3.0    # Even faster spawning
			enemy_speed = 1.4         # Even faster enemies
			enemy_health = 1.5        # Even more health
		"Extreme":
			total_rounds = 3
			waves_per_round = 3
			enemies_per_wave_base = 20
			wave_target_time = 120.0
			enemy_spawn_rate = 2.5    # Fastest spawning
			enemy_speed = 1.6         # Fastest enemies
			enemy_health = 2.0        # Most health
	
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
	print("GameManager: Starting campaign")
	
	# Reset game metrics for a fresh start
	current_round = 1
	current_wave = 1
	
	# Set the difficulty multiplier based on the selected difficulty
	set_difficulty(difficulty)
	
	# Reset enemy counts and IDs for the new campaign
	enemies_per_wave = calculate_enemies_for_wave()
	current_enemies_count = 0
	next_enemy_id = 0
	
	# Reset in-progress flags
	game_started = true
	wave_in_progress = false
	
	# Handle scene transition based on current scene
	var current_scene_name = get_tree().current_scene.name
	print("Current scene: " + current_scene_name)
	
	if current_scene_name == "3DCampaignMenu" or current_scene_name == "CampaignMenu":
		print("Transitioning from campaign menu to main scene")
		call_deferred("_load_main_scene_directly")
	else:
		print("Already in a gameplay scene, setting up wave")
		setup_wave()

func _load_main_scene_directly() -> void:
	print("LOADING MAIN SCENE DIRECTLY")
	
	# Ensure XR is still enabled
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("Setting viewport for XR use during direct scene load")
		get_viewport().use_xr = true
		vr_mode_enabled = true
		emit_signal("vr_mode_changed", true)
	
	# Use the simpler change_scene_to_file method which is more reliable
	print("Using change_scene_to_file for VR scene transition")
	var err = get_tree().change_scene_to_file("res://Main.tscn")
	
	if err == OK:
		print("Scene change initiated successfully, waiting for scene to load...")
		# Wait for the scene to fully load
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Setup game with a delay to ensure everything is initialized
		await get_tree().create_timer(0.5).timeout
		
		# Ensure VR is still enabled
		if xr_interface and xr_interface.is_initialized():
			print("Re-enabling XR for new scene")
			get_viewport().use_xr = true
			vr_mode_enabled = true
			emit_signal("vr_mode_changed", true)
		
		print("Setting up game scene in new Main scene")
		setup_game_scene()
		
		print("Setting up first wave in new Main scene")
		setup_wave()
	else:
		print("ERROR: Failed to change scene to Main.tscn, error: ", err)
		
		# Fall back to manual scene instantiation as a last resort
		print("Falling back to manual scene instantiation")
		var main_scene_packed = load("res://Main.tscn")
		
		if main_scene_packed:
			print("Successfully loaded Main.tscn")
			var main_instance = main_scene_packed.instantiate()
			
			# Get root and clear current scene
			var root = get_tree().root
			if get_tree().current_scene:
				get_tree().current_scene.queue_free()
			
			# Wait a moment for cleanup
			await get_tree().create_timer(0.3).timeout
			
			# Add new scene
			root.add_child(main_instance)
			get_tree().current_scene = main_instance
			
			# Wait for initialization
			await get_tree().create_timer(0.5).timeout
			
			# Make sure VR is enabled
			get_viewport().use_xr = true
			
			# Complete setup
			setup_game_scene()
			setup_wave()
		else:
			print("CRITICAL: Failed to load Main.tscn by any means")

func start_wave() -> void:
	# Calculate wave parameters
	calculate_enemies_per_wave()
	current_enemies_count = 0
	enemies_spawned_in_wave = 0  # Reset spawning counter
	
	# Reset bomber system at the start of each wave
	reset_bomber_system()
	
	# Set wave state
	wave_in_progress = true
	wave_complete_check_pending = false
	wave_start_time = Time.get_unix_time_from_system()
	
	print("DEBUG: Starting wave ", current_wave, " of round ", current_round)
	print("DEBUG: Wave will have ", enemies_per_wave, " enemies")
	
	# Try to find the enemy spawner
	var spawners = get_tree().get_nodes_in_group("EnemySpawner")
	if spawners.size() > 0:
		print("DEBUG: Found enemy spawner in group, starting wave")
		spawners[0].start_wave_spawning()
	else:
		print("ERROR: No enemy spawner found in group. Looking for ungrouped spawner...")
		
		# Try looking for the EnemySpawner by node name
		var spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
		if spawner:
			print("DEBUG: Found EnemySpawner by node path, adding to group")
			spawner.add_to_group("EnemySpawner")
			
			if spawner.has_method("start_wave_spawning"):
				print("DEBUG: Starting wave on found spawner")
				spawner.start_wave_spawning()
			else:
				print("ERROR: Found spawner doesn't have start_wave_spawning method")
		else:
			# Last attempt - look for any node with EnemySpawner script
			print("ERROR: No spawner found by node path. Attempting full scene search...")
			
			# Use a simpler non-recursive approach to search for spawners
			var found = false
			var nodes_to_check = [get_tree().current_scene]
			var current_node
			
			while nodes_to_check.size() > 0 and not found:
				current_node = nodes_to_check.pop_front()
				
				# Check if this node is a spawner
				if current_node.name.contains("Spawner") or (current_node.get_script() and current_node.get_script().resource_path.contains("EnemySpawner")):
					print("DEBUG: Found spawner node during deep search: ", current_node.name)
					current_node.add_to_group("EnemySpawner")
					if current_node.has_method("start_wave_spawning"):
						current_node.start_wave_spawning()
					found = true
					break
				
				# Add all children to the check list
				for child in current_node.get_children():
					nodes_to_check.push_back(child)
			if not found:
				print("CRITICAL ERROR: Could not find any enemy spawner in the scene!")

func register_enemy() -> int:
	# Increment the enemy counter
	current_enemies_count += 1
	emit_signal("enemies_changed", current_enemies_count)
	
	# Assign a unique ID to this enemy
	var enemy_id = next_enemy_id
	next_enemy_id += 1
	
	return enemy_id

func enemy_defeated(enemy_id: int = -1) -> void:
	# Decrement the enemy counter
	current_enemies_count -= 1
	emit_signal("enemies_changed", current_enemies_count)
	
	# If this was the bomber, clear the bomber assignment
	if enemy_id == current_bomber_id:
		current_bomber_id = -1
		print("DEBUG: Bomber ship destroyed, bomber status reset")
		
	# Check if we need to assign a new bomber
	if current_bomber_id == -1:
		# Find enemy ships and assign one as bomber
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			var new_bomber = enemies[0]
			if new_bomber.has_method("set_as_bomber"):
				new_bomber.set_as_bomber()
			else:
				new_bomber.can_shoot_bombs = true
			
			# Store the ID if we can get it
			if new_bomber.get("enemy_id") != null:
				current_bomber_id = new_bomber.enemy_id
				print("DEBUG: New bomber assigned with ID: ", current_bomber_id)
			else:
				print("DEBUG: New bomber assigned but ID unknown")
	
	print("DEBUG: Enemy defeated. " + str(current_enemies_count) + " enemies remaining.")
	
	# Trigger wave completion check if no enemies remain and we've spawned all for this wave
	if current_enemies_count <= 0 and enemies_spawned_in_wave >= enemies_per_wave and wave_in_progress:
		wave_complete_check_pending = true
		
	# If only a few enemies remain, check if we should spawn more
	if current_enemies_count <= 2 and wave_in_progress:
		var spawner = get_tree().get_nodes_in_group("EnemySpawner")
		if spawner.size() > 0:
			var spawned_count = spawner[0].enemies_spawned
			var total_to_spawn = enemies_per_wave
			
			# Only try to spawn more if we haven't reached the total
			if spawned_count < total_to_spawn:
				# This will trigger the timer check in the spawner
				print("DEBUG: Enemy count is low (" + str(current_enemies_count) + 
					  "), checking if we should prepare next batch. " + 
					  str(spawned_count) + "/" + str(total_to_spawn) + " enemies spawned so far")
				spawner[0].check_for_next_batch()

# Unified wave completion check - defers to the EnemySpawner
# which has the most accurate information about enemy states
func check_wave_completion() -> void:
	# Pass the check to the spawner which tracks all spawned enemies
	var spawners = get_tree().get_nodes_in_group("enemy_spawner")
	if spawners.size() > 0:
		spawners[0].check_wave_completion()
	else:
		# Fallback if spawner not found
		print("WARNING: No spawner found for wave completion check")

# This now gets called by the spawner
func complete_wave() -> void:
	wave_in_progress = false
	
	# Calculate time-based rewards
	var elapsed_time = (Time.get_unix_time_from_system() - wave_start_time)
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
	get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")
	
func show_campaign_menu() -> void:
	get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

# Reset the bomber system to allow a new enemy to become bomber
func reset_bomber_system() -> void:
	current_bomber_id = -1
	print("DEBUG: Bomber system reset - new bomber will be assigned")

# Calculate the number of enemies for the current wave based on difficulty and progress
func calculate_enemies_for_wave() -> int:
	# Start with the base number of enemies
	var enemy_count = enemies_per_wave_base
	
	# Add enemies based on wave number (waves get progressively harder)
	enemy_count += (current_wave - 1) * 2
	
	# Add enemies based on round number (rounds get progressively harder)
	enemy_count += (current_round - 1) * 5
	
	# Apply difficulty multiplier
	enemy_count = int(enemy_count * wave_difficulty_multiplier)
	
	# Cap at the maximum enemies per wave
	enemy_count = min(enemy_count, enemies_per_wave_max)
	
	print("DEBUG: Wave will spawn %d enemies (difficulty: %s)" % [enemy_count, difficulty])
	
	return enemy_count

# Set up a new wave with proper initialization
func setup_wave() -> void:
	print("Setting up wave %d of round %d" % [current_wave, current_round])
	
	# Calculate the number of enemies for this wave
	enemies_per_wave = calculate_enemies_for_wave()
	enemies_spawned_in_wave = 0
	
	# Make sure wave is not already in progress
	if wave_in_progress:
		print("WARNING: Wave was already in progress when setup_wave() was called")
		wave_in_progress = false
	
	# Reset enemy count
	current_enemies_count = 0
	emit_signal("enemies_changed", current_enemies_count)
	
	# Start the wave after a short delay
	call_deferred("start_wave")
