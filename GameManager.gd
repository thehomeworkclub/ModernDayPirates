extends Node

signal vr_mode_changed(enabled: bool)
signal equipment_changed(equipment_type: String, new_value: String)
signal gun_registered(gun_node: Node)
signal gun_unregistered(gun_node: Node)
signal wave_completed
signal enemies_changed(count: int)

# Game parameters
var game_parameters = load("res://GameParameters.gd").new()

# Wave management
var game_started: bool = false
var enemies_per_wave: int = 10  # Will be updated from GameParameters
var enemy_spawn_rate: float = 1.0
var wave_difficulty_multiplier: float = 1.0
var enemy_speed: float = 1.0
var enemy_health: float = 1.0
var enemies_spawned_in_wave: int = 0
var current_enemies_count: int = 0
var current_bomber_id: int = -1  # Tracks which enemy is the designated bomber
var bomber_ids = []  # Tracks all enemies allowed to bomb
var next_enemy_id: int = 0  # Counter for assigning unique enemy IDs

# Shop teleportation functionality
var enemy_kill_count: int = 0
var difficulty_level: int = 1
var kills_before_shop: int = 1  # Reduced to ensure shop transitions happen reliably at end of round
var shop_timer: float = 15.0  # Seconds to spend in shop (updated to 15 seconds)
var in_shop: bool = false
var shop_timer_running: bool = false
var shop_timer_remaining: float = 0.0

# Game state tracking
var current_voyage_num = 0
var current_voyage_difficulty = 0
var current_round = 1  # Current level round
var current_wave = 1   # Current wave within the round
var waves_completed_in_round = 0  # Track completed waves in current round
var voyage_name = "Modern Day Pirates"  # Name of the current voyage
var difficulty = "Normal"  # Difficulty level as a string

# Player equipment and stats
var gun_type = "basic"  # Default gun type
var player_base_health = 10.0  # Base health (10 hearts)
var player_health = 10.0       # Current health with upgrades applied
var player_max_health = 10.0   # Maximum health with upgrades applied
var player_damage_multiplier = 1.0
var player_bullet_speed_multiplier = 1.0
var player_fire_rate_multiplier = 1.0
var bronze_currency_multiplier = 1.0
var silver_currency_multiplier = 1.0
var gold_currency_multiplier = 1.0

# Upgrade values applied from shop upgrades
var extra_health = 0.0
var extra_damage = 0.0
var extra_fire_rate = 0.0
var extra_bullet_speed = 0.0
var extra_bronze = 0.0
var extra_silver = 0.0

# Percentage increases from gold shop (multiplicative)
var percent_health_increase = 1.0  # 1.0 = 100% (base)
var percent_damage_increase = 1.0
var percent_fire_rate_increase = 1.0
var percent_bronze_increase = 1.0
var percent_silver_increase = 1.0
var percent_gold_increase = 1.0

# Shop upgrade levels - persist these across shop/level transitions
# Only reset on death
var bronze_upgrade_levels = {
"ItemBox1": 1,  # M16A1 (Default)
"ItemBox2": 0,  # AK74
"ItemBox3": 0,  # SCAR-L
"ItemBox4": 0,  # HK416
"ItemBox5": 0,  # MP5
"ItemBox6": 0   # Mosin Nagant/Model 1897
}

# Map ItemBox names to gun types for the bronze shop
var gun_types_map = {
"ItemBox1": "m16a1",
"ItemBox2": "ak74",
"ItemBox3": "scarl",
"ItemBox4": "hk416", 
"ItemBox5": "mp5",
"ItemBox6": "mosin"  # Can change to model1897 if preferred
}

var silver_upgrade_levels = {
"ItemBox1": 1,  # Shield
"ItemBox2": 1,  # Dash
"ItemBox3": 1,  # Critical
"ItemBox4": 1,  # Range
"ItemBox5": 1,  # Spread
"ItemBox6": 1   # Special
}

var gold_upgrade_levels = {
"ItemBox1": 1,  # Regen
"ItemBox2": 1,  # Bounce
"ItemBox3": 1,  # Pierce
"ItemBox4": 1,  # Multi
"ItemBox5": 1,  # Homing
"ItemBox6": 1   # Ultimate
}

# Scene references
var player_boat = null
var player = null
var enemy_spawner = null
var vr_mode_enabled = false

# Gun registration and management
var registered_guns = []

# Valid equipment types
const VALID_GUN_TYPES = ["basic", "medium", "heavy"]

# Convert difficulty strings to numerical values
const DIFFICULTY_VALUES = {
	"Easy": 1,
	"Normal": 2,
	"Hard": 3,
	"Very Hard": 4,
	"Extreme": 5
}

func _ready() -> void:
	print("Initializing GameManager...")
	initialize_game_state()
	
# Reset all upgrade levels when player dies
func reset_upgrade_levels() -> void:
	# For bronze shop (guns), set everything to 0 except the default gun (M16A1)
	for key in bronze_upgrade_levels.keys():
		bronze_upgrade_levels[key] = 0
	bronze_upgrade_levels["ItemBox1"] = 1  # M16A1 is the default gun
	
	# Reset silver and gold upgrades to level 1
	for key in silver_upgrade_levels.keys():
		silver_upgrade_levels[key] = 1
	for key in gold_upgrade_levels.keys():
		gold_upgrade_levels[key] = 1
	
	# Reset all player stat upgrades to base values
	extra_health = 0.0
	extra_damage = 0.0
	extra_fire_rate = 0.0
	extra_bullet_speed = 0.0
	extra_bronze = 0.0
	extra_silver = 0.0
	
	# Reset all percentage modifiers to base (100%)
	percent_health_increase = 1.0
	percent_damage_increase = 1.0
	percent_fire_rate_increase = 1.0
	percent_bronze_increase = 1.0
	percent_silver_increase = 1.0
	percent_gold_increase = 1.0
	
	# Update player stats with reset values
	update_player_stats()
		
	print("GameManager: Upgrade levels and stats reset - Default gun selected")

# Calculate and apply all player stat modifiers from shop upgrades
func update_player_stats() -> void:
	print("Updating player stats based on shop upgrades...")
	
	# Apply direct increases from Silver shop
	# Silver shop mapping:
	# 1. Extra silver
	# 2. Faster bullets 
	# 3. Extra bronze
	# 4. Extra damage
	# 5. Quicker fire rate
	# 6. Extra health
	
	# Calculate direct increases (each level = +10% of base value)
	extra_silver = (silver_upgrade_levels["ItemBox1"] - 1) * 0.1
	extra_bullet_speed = (silver_upgrade_levels["ItemBox2"] - 1) * 0.1
	extra_bronze = (silver_upgrade_levels["ItemBox3"] - 1) * 0.1
	extra_damage = (silver_upgrade_levels["ItemBox4"] - 1) * 0.1
	extra_fire_rate = (silver_upgrade_levels["ItemBox5"] - 1) * 0.1
	extra_health = (silver_upgrade_levels["ItemBox6"] - 1) * 1.0  # Each level = +1 health
	
	# Apply percentage increases from Gold shop
	# Gold shop mapping:
	# 1. % Bronze increase
	# 2. % Silver increase
	# 3. % Gold increase
	# 4. % Damage increase
	# 5. % Fire rate increase
	# 6. % Health increase
	
	# Calculate percentage increases (each level = +5% multiplicative)
	percent_bronze_increase = pow(1.05, gold_upgrade_levels["ItemBox1"] - 1)
	percent_silver_increase = pow(1.05, gold_upgrade_levels["ItemBox2"] - 1)
	percent_gold_increase = pow(1.05, gold_upgrade_levels["ItemBox3"] - 1)
	percent_damage_increase = pow(1.05, gold_upgrade_levels["ItemBox4"] - 1)
	percent_fire_rate_increase = pow(1.05, gold_upgrade_levels["ItemBox5"] - 1)
	percent_health_increase = pow(1.05, gold_upgrade_levels["ItemBox6"] - 1)
	
	# Apply all multipliers to player stats
	player_damage_multiplier = (1.0 + extra_damage) * percent_damage_increase
	player_bullet_speed_multiplier = (1.0 + extra_bullet_speed)
	player_fire_rate_multiplier = (1.0 + extra_fire_rate) * percent_fire_rate_increase
	bronze_currency_multiplier = (1.0 + extra_bronze) * percent_bronze_increase
	silver_currency_multiplier = (1.0 + extra_silver) * percent_silver_increase
	gold_currency_multiplier = 1.0 * percent_gold_increase
	
	# Calculate health with all modifiers
	player_max_health = (player_base_health + extra_health) * percent_health_increase
	
	# Log results
	print("Player stats updated:")
	print("- Damage multiplier: ", player_damage_multiplier)
	print("- Bullet speed multiplier: ", player_bullet_speed_multiplier)
	print("- Fire rate multiplier: ", player_fire_rate_multiplier)
	print("- Bronze currency multiplier: ", bronze_currency_multiplier)
	print("- Silver currency multiplier: ", silver_currency_multiplier)
	print("- Gold currency multiplier: ", gold_currency_multiplier)
	print("- Max health: ", player_max_health)

func _process(delta: float) -> void:
	# Only handle shop timer when in shop
	if in_shop and shop_timer_running:
		shop_timer_remaining -= delta
		if shop_timer_remaining <= 0:
			print("Shop timer expired, teleporting back to level")
			teleport_to_level()

# Teleport to shop after defeating N enemies
func teleport_to_shop() -> void:
	print("GAMEMANAGER: Teleporting to shop1.tscn")
	in_shop = true
	shop_timer_running = true
	shop_timer_remaining = shop_timer
	enemy_kill_count = 0
	
	# Increase difficulty for next round
	difficulty_level += 1
	print("GAMEMANAGER: Difficulty level increased to: " + str(difficulty_level))
	
	# Save XR state
	var xr_interface = XRServer.find_interface("OpenXR")
	var was_vr_enabled = false
	if xr_interface and xr_interface.is_initialized():
		was_vr_enabled = true
	
	# Use the scene transition system if available
	if get_node_or_null("/root/SceneTransition") != null:
		print("GAMEMANAGER: Using SceneTransition to load shop1.tscn")
		get_node("/root/SceneTransition").change_scene_with_fade("res://shop1.tscn")
		# Return early as the scene transition will handle the rest
		return
	
	# Fallback to direct scene change
	print("GAMEMANAGER: SceneTransition not found, direct loading shop1.tscn")
	var err = get_tree().change_scene_to_file("res://shop1.tscn")
	if err == OK:
		print("Shop scene loaded")
		
		# Re-enable VR if it was enabled
		if was_vr_enabled and xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
			vr_mode_enabled = true
			emit_signal("vr_mode_changed", true)
			print("VR mode re-enabled in shop")
	else:
		print("ERROR: Failed to load shop scene! Error code: ", err)
		# Fallback if shop loading fails
		teleport_to_level()

# Teleport back to level1 after shop timer expires
func teleport_to_level() -> void:
	print("GAMEMANAGER: Teleporting back to level with difficulty: " + str(difficulty_level))
	in_shop = false
	shop_timer_running = false
	
	# Increment round counter for new round
	current_round += 1
	print("GAMEMANAGER: Starting round: " + str(current_round))
	
	# Save XR state
	var xr_interface = XRServer.find_interface("OpenXR")
	var was_vr_enabled = false
	if xr_interface and xr_interface.is_initialized():
		was_vr_enabled = true
	
	# Reinitialize game state with new difficulty
	initialize_game_state()
	
	# Use the scene transition system if available
	if get_node_or_null("/root/SceneTransition") != null:
		print("GAMEMANAGER: Using SceneTransition to load level1.tscn")
		get_node("/root/SceneTransition").change_scene_with_fade("res://level1.tscn")
		# Return early as the scene transition will handle the rest
		return
	
	# Fallback to direct scene change
	print("GAMEMANAGER: SceneTransition not found, direct loading level1.tscn")
	var err = get_tree().change_scene_to_file("res://level1.tscn")
	if err == OK:
		print("Level1 scene loaded")
		
		# Re-enable VR if it was enabled
		if was_vr_enabled and xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
			vr_mode_enabled = true
			emit_signal("vr_mode_changed", true)
			print("VR mode re-enabled in level")
	else:
		print("ERROR: Failed to load level1 scene! Error code: ", err)

# Register an enemy and return a unique ID
func register_enemy() -> int:
	var new_id = next_enemy_id
	next_enemy_id += 1
	print("Registered enemy with ID: ", new_id)
	
	# Check if we need to assign a new bomber
	if current_bomber_id == -1 and bomber_ids.size() < game_parameters.max_bombers:
		current_bomber_id = new_id
		bomber_ids.append(new_id)
		print("Setting enemy ", new_id, " as bomber (", bomber_ids.size(), "/", game_parameters.max_bombers, ")")
	
	update_enemy_count(current_enemies_count + 1)
	return new_id

# Reset enemy tracking - important to call between waves
func reset_enemy_tracking() -> void:
	print("DEBUG: Resetting enemy tracking. Current count: " + str(current_enemies_count))
	current_enemies_count = 0
	bomber_ids.clear()
	current_bomber_id = -1
	# Don't reset next_enemy_id as it's used to generate unique IDs across the game

# Handle enemy defeat
func enemy_defeated(enemy_id: int) -> void:
	print("Enemy ", enemy_id, " defeated")
	
	# Update enemy count
	update_enemy_count(current_enemies_count - 1)
	
	# If the bomber was defeated, remove from bomber list
	if enemy_id == current_bomber_id:
		current_bomber_id = -1
		bomber_ids.erase(enemy_id)
		print("Bomber defeated, remaining bombers: ", bomber_ids.size())
		
		# Assign a new active bomber if other bombers exist
		if bomber_ids.size() > 0:
			current_bomber_id = bomber_ids[0]
			print("Setting existing bomber as active: ", current_bomber_id)
	
	# Directly notify the enemy spawner to check for wave completion
	# This ensures that wave completion is checked immediately when an enemy is defeated
	var enemy_spawner = get_tree().get_first_node_in_group("EnemySpawner")
	if enemy_spawner and enemy_spawner.has_method("check_wave_completion"):
		print("DEBUG: Directly calling check_wave_completion after enemy defeat")
		enemy_spawner.check_wave_completion()

func update_enemy_count(count: int) -> void:
	if current_enemies_count != count:
		current_enemies_count = count
		emit_signal("enemies_changed", current_enemies_count)

func complete_wave() -> void:
	print("GAMEMANAGER: Wave completed")
	current_enemies_count = 0
	emit_signal("enemies_changed", current_enemies_count)
	
	# Track wave progression within the round
	waves_completed_in_round += 1
	current_wave += 1
	print("GAMEMANAGER: Wave " + str(waves_completed_in_round) + "/" + str(game_parameters.waves_per_round) + " completed")
	
	# DO NOT increment enemy kill count here - it's already incremented by each defeated enemy
	# This was causing double-counting and premature round completion
	
	# Print enhanced debug information about game state
	print("GAMEMANAGER: Current state:")
	print("- Round: " + str(current_round))
	print("- Wave: " + str(current_wave))
	print("- Waves completed in round: " + str(waves_completed_in_round))
	print("- Total waves per round: " + str(game_parameters.waves_per_round))
	print("- Enemy kill count: " + str(enemy_kill_count))
	
	# Check if we've completed all waves in the round
	if waves_completed_in_round >= game_parameters.waves_per_round:
		print("GAMEMANAGER: ROUND " + str(current_round) + " COMPLETE! All " + 
			str(game_parameters.waves_per_round) + " waves finished")
		
		# Important: Don't reset waves_completed_in_round here, as it could cause issues with shop transitions
		# It will be reset when the player is teleported or a new round begins
		
		# Trigger shop transition
		call_deferred("teleport_to_shop")
	else:
		print("GAMEMANAGER: Starting next wave (" + str(waves_completed_in_round + 1) + "/" + 
			str(game_parameters.waves_per_round) + ")")
	
	# Send the wave_completed signal AFTER processing wave counting
	# This ensures all state updates are done before handlers are called
	print("DEBUG: Emitting wave_completed signal")
	emit_signal("wave_completed")

func initialize_game_state() -> void:
	# Reset wave-related variables
	enemies_spawned_in_wave = 0
	current_enemies_count = 0
	bomber_ids.clear()
	current_bomber_id = -1
	waves_completed_in_round = 0
	current_wave = 1
	emit_signal("enemies_changed", current_enemies_count)
	
	# Update game parameters with current difficulty level
	game_parameters.set_difficulty(difficulty_level)
	
	# Scale difficulty based on both voyage difficulty and current difficulty level
	wave_difficulty_multiplier = 1.0 + (current_voyage_difficulty * 0.2) + (difficulty_level * 0.1)
	enemy_spawn_rate = 1.0 + (current_voyage_difficulty * 0.1)
	enemy_speed = 1.0 + (current_voyage_difficulty * 0.15)
	
	# Scale enemy health with both difficulty sources
	enemy_health = 1.0 + (current_voyage_difficulty * 0.2) + (difficulty_level * 0.3)
	
	# Get enemy count from game parameters
	enemies_per_wave = game_parameters.get_total_ships_per_wave()
	
	print("Setting up initial game state with difficulty level: ", difficulty_level)
	verify_equipment()
	
	# Find player and initialize equipment
	player = get_tree().get_first_node_in_group("Player")
	if player:
		print("Found player node")
		# Check for guns in player's equipment
		var gun_pivot = player.get_node_or_null("Head/GunPivot/Gun")
		if gun_pivot:
			print("Found gun in player's equipment")
			register_gun(gun_pivot)
	else:
		print("WARNING: Player node not found")

	# Look for any guns in the scene
	print("Looking for guns to register...")
	var guns = get_tree().get_nodes_in_group("gun")
	for gun in guns:
		register_gun(gun)

	if registered_guns.size() > 0:
		print("Total guns registered: ", registered_guns.size())
	else:
		print("WARNING: No guns found in scene")

func verify_equipment() -> void:
	if gun_type == "":
		gun_type = "basic"
		print("No gun type set, defaulting to: basic")
	else:
		print("Current gun type: ", gun_type)

func is_valid_gun(gun_node: Node) -> bool:
	if not is_instance_valid(gun_node):
		print("Gun node is invalid")
		return false
	if not gun_node.has_method("set_gun_type"):
		print("Gun node missing set_gun_type method: ", gun_node.name)
		return false
	return true

func set_gun_type(type: String) -> void:
	if not type in VALID_GUN_TYPES:
		print("ERROR: Invalid gun type: ", type)
		return
		
	if gun_type != type:
		gun_type = type
		emit_signal("equipment_changed", "gun", type)
		print("Changed gun type to: ", type)
		update_all_guns()
		
func get_gun_type() -> String:
	return gun_type

func register_gun(gun_node: Node) -> void:
	if not is_valid_gun(gun_node):
		return
		
	if not gun_node in registered_guns:
		print("Registering new gun: ", gun_node.name)
		registered_guns.append(gun_node)
		initialize_gun(gun_node)
		emit_signal("gun_registered", gun_node)
		
		# Connect to tree_exited to handle cleanup
		if not gun_node.tree_exiting.is_connected(unregister_gun):
			gun_node.tree_exiting.connect(func(): unregister_gun(gun_node))

func unregister_gun(gun_node: Node) -> void:
	if gun_node in registered_guns:
		print("Unregistering gun: ", gun_node.name)
		registered_guns.erase(gun_node)
		emit_signal("gun_unregistered", gun_node)

func initialize_gun(gun_node: Node) -> void:
	if gun_node:
		print("Initializing gun node with type: ", gun_type)
		if gun_node.has_method("set_gun_type"):
			gun_node.set_gun_type(gun_type)
			if not gun_node.is_in_group("gun"):
				gun_node.add_to_group("gun")
		else:
			print("ERROR: Gun node does not have set_gun_type method")

func update_all_guns() -> void:
	print("Updating all registered guns to type: ", gun_type)
	for gun in registered_guns:
		if is_instance_valid(gun):
			initialize_gun(gun)
		else:
			registered_guns.erase(gun)

func set_voyage(voyage_num: int, difficulty: String) -> void:
	current_voyage_num = voyage_num
	current_voyage_difficulty = DIFFICULTY_VALUES.get(difficulty, 1)  # Default to Easy (1) if string not found
	print("Set voyage: ", voyage_num, " with difficulty: ", difficulty, " (Level ", current_voyage_difficulty, ")")

func start_campaign() -> void:
	print("Starting campaign voyage: ", current_voyage_num, " difficulty: ", current_voyage_difficulty)
	_load_main_scene_directly()

func setup_game_scene():
	print("Setting up game scene for voyage ", current_voyage_num, " with difficulty ", current_voyage_difficulty)

	# Configure enemy spawner with difficulty settings
	if enemy_spawner:
		# Adjust spawn rates and enemy attributes based on difficulty
		enemy_spawner.base_spawn_interval = 5.0 / (1 + current_voyage_difficulty * 0.2)
		print("Enemy spawn interval set to: ", enemy_spawner.base_spawn_interval)

	# Scale player boat stats based on upgrades/progression
	if player_boat:
		print("Player boat configured for voyage ", current_voyage_num)

	print("Game scene setup complete")

func setup_wave():
	print("Setting up wave with difficulty level: ", current_voyage_difficulty)

	if enemy_spawner:
		# Start enemy spawning
		enemy_spawner.active = true

		# Configure wave parameters based on difficulty
		var wave_enemies = 5 + (current_voyage_difficulty * 2)  # More enemies at higher difficulties
		enemy_spawner.enemies_per_wave = wave_enemies

		# Scale enemy health/damage with difficulty
		enemy_spawner.enemy_health_multiplier = 1.0 + (current_voyage_difficulty * 0.1) + (difficulty_level * 0.3)
		enemy_spawner.enemy_damage_multiplier = 1.0 + (current_voyage_difficulty * 0.15)

		print("Wave configured with:")
		print("- Enemies per wave: ", wave_enemies)
		print("- Enemy health multiplier: ", enemy_spawner.enemy_health_multiplier)
		print("- Enemy damage multiplier: ", enemy_spawner.enemy_damage_multiplier)
	else:
		print("ERROR: Cannot setup wave - enemy spawner not found!")

func _load_main_scene_directly() -> void:
	print("LOADING MAIN SCENE DIRECTLY")
	registered_guns.clear()  # Clear any existing registrations
	initialize_game_state()  # Ensure equipment is properly initialized

	# Store XR state before scene change
	var xr_interface = XRServer.find_interface("OpenXR")
	var was_vr_enabled = false
	if xr_interface and xr_interface.is_initialized():
		was_vr_enabled = true
		print("Storing VR state before scene change")

	# Change scene
	print("Changing to Main scene...")
	var err = get_tree().change_scene_to_file("res://Main.tscn")
	if err == OK:
		print("Main scene loaded, waiting for initialization...")
		# Wait longer for scene to be fully ready
		await get_tree().process_frame
		await get_tree().create_timer(1.0).timeout

		print("Re-enabling VR...")
		# Re-enable VR if it was enabled
		if was_vr_enabled and xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
			vr_mode_enabled = true
			emit_signal("vr_mode_changed", true)
			print("VR mode re-enabled")

		# Wait for XR to initialize
		await get_tree().create_timer(0.5).timeout

		# Find and position VR origin
		var xr_origin = get_tree().get_first_node_in_group("Player")
		if xr_origin:
			print("Found XR Origin, positioning...")
			# Position XR origin near the boat's expected position
			var origin_pos = Vector3(8.38106, 7.24827, -16.5409)
			xr_origin.global_transform.origin = origin_pos
			print("XR Origin position set to: ", xr_origin.global_position)

		# Wait for everything to be properly positioned
		await get_tree().create_timer(0.5).timeout

		print("Setting up game scene...")

		# Find boat and ensure it's in correct position
		player_boat = get_tree().get_first_node_in_group("player_boat")
		if not player_boat:
			print("Searching for Area3D node as player boat...")
			var area3d = get_tree().current_scene.find_child("Area3D", true, false)
			if area3d:
				print("Found Area3D node, setting up as player boat")
				area3d.add_to_group("player_boat")
				player_boat = area3d

		if player_boat:
			print("Found player boat, setting up transform...")
			# Set the exact transform from the scene
			player_boat.transform.origin = Vector3(8.38106, 0, -36.1083)
			player_boat.scale = Vector3(-2.64326, 2.62623, -1.91512)
			print("Player boat transform set:")
			print("- Position: ", player_boat.global_position)
			print("- Scale: ", player_boat.scale)
		else:
			print("ERROR: Could not find or create player boat!")

		# Setup game scene and wait for completion
		await setup_game_scene()

		# Final check for components with increased retry count
		var retry_count = 0
		while (not player_boat or not player or not enemy_spawner) and retry_count < 10:
			print("Waiting for components... Attempt %d" % retry_count)
			await get_tree().create_timer(0.5).timeout

			if not player_boat:
				player_boat = get_tree().get_first_node_in_group("player_boat")
			if not player:
				player = get_tree().get_first_node_in_group("Player")
			if not enemy_spawner:
				enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
			retry_count += 1

		print("Component status (Attempt %d):" % retry_count)
		if player_boat:
			print("- Player boat found at: ", player_boat.global_position)
		if player:
			print("- Player found at: ", player.global_position)
		if enemy_spawner:
			print("- Enemy spawner found at: ", enemy_spawner.global_position)

		if player_boat and player and enemy_spawner:
			print("All components found, starting wave...")
			setup_wave()
		else:
			print("ERROR: Failed to find all required components!")
			print("Final component status:")
			print("- Player boat: ", player_boat != null)
			print("- Player: ", player != null)
			print("- Enemy spawner: ", enemy_spawner != null)
	else:
		print("ERROR: Failed to load Main scene! Error code: ", err)
