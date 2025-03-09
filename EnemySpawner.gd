# EnemySpawner.gd
extends Node3D

@export var enemy_scene: PackedScene  # assign Enemy.tscn in the Inspector
@export var base_spawn_interval: float = 2.0

var spawn_timer: Timer
var batch_timer: Timer
var enemies_spawned: int = 0  # Count of enemies spawned in current wave
var spawning_paused: bool = false
var wave_in_progress: bool = false

# Storage for used target positions to avoid overlap
var used_target_positions = []

# NEW: Store enemies we've spawned this wave for stronger tracking
var spawned_enemies = []

# Batch tracking variables
var current_batch_size: int = 0
var next_batch_ready: bool = false
var enemies_spawned_in_current_batch: int = 0

func _ready() -> void:
	# Add to enemy spawner group for easier access
	add_to_group("EnemySpawner")
	
	print("DEBUG: EnemySpawner initialized at position: ", global_position)
	
	# Create and start a timer to spawn enemies at fixed intervals.
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.3  # Fast timer for batch spawning
	spawn_timer.one_shot = false
	spawn_timer.autostart = false  # Don't auto start - wait for wave to begin
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_Timer_timeout)
	
	# Create a timer for batch delays
	batch_timer = Timer.new()
	batch_timer.name = "BatchTimer"
	batch_timer.wait_time = 5.0  # 5 seconds between batches
	batch_timer.one_shot = true
	batch_timer.autostart = false
	batch_timer.timeout.connect(_on_batch_timer_timeout)
	add_child(batch_timer)
	
	# Connect to GameManager signals
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.connect("enemies_changed", _on_enemies_changed)
	
	# Force the spawner position to be closer to the player for better visibility
	# This overrides the position in the scene
	# Only adjust position if we're not in the campaign scene
	if get_tree().current_scene.name != "CampaignMenu" and get_tree().current_scene.name != "3DCampaignMenu":
		# Find the player's boat to position relative to it
		var boats = get_tree().get_nodes_in_group("Player")
		if boats.size() > 0:
			var player_boat = boats[0]
			# Position in front of the player boat at a reasonable distance
			var target_z = player_boat.global_position.z + 25.0
			if abs(target_z) > 100:  # If it's too large, use a sensible value
				print("WARNING: Player Z position is very large: " + str(player_boat.global_position.z))
				target_z = -10.0
			global_position = Vector3(0, 0, target_z)
			print("DEBUG: EnemySpawner position set relative to player: ", global_position)
		else:
			# Use a sensible default if no player is found
			print("DEBUG: No player found, using default position")
	
	# Start the first wave if game is already started
	if GameManager.game_started:
		start_wave_spawning()

func start_wave_spawning() -> void:
	# Reset all tracking values for this wave
	enemies_spawned = 0
	enemies_spawned_in_current_batch = 0
	spawned_enemies.clear()
	used_target_positions.clear()
	current_batch_size = 0
	next_batch_ready = false
	spawning_paused = false
	wave_in_progress = true
	
	print("DEBUG: WAVE START - Will spawn " + str(GameManager.enemies_per_wave) + " enemies")
	
	# Set spawn timer wait time based on difficulty (but ensure it's not too fast or too slow)
	spawn_timer.wait_time = clamp(GameManager.enemy_spawn_rate * 0.1, 0.2, 0.8)
	print("DEBUG: Spawn timer set to " + str(spawn_timer.wait_time) + " seconds between enemies")
	
	# Make sure spawn timer is not already running
	if spawn_timer.timeout.is_connected(_on_Timer_timeout):
		spawn_timer.stop()
	
	# CRITICAL: Calculate the correct batch size based on difficulty
	calculate_first_batch_size()
	
	# Spawn first batch immediately with new approach
	start_next_batch()

func calculate_first_batch_size() -> void:
	# Calculate batch size based on difficulty (10-20% of total enemies)
	var difficulty_factor = 0.0
	match GameManager.difficulty:
		"Easy": difficulty_factor = 0.1  # 10% at a time (1-2 enemies)
		"Normal": difficulty_factor = 0.12
		"Hard": difficulty_factor = 0.15
		"Very Hard": difficulty_factor = 0.18
		"Extreme": difficulty_factor = 0.2  # 20% at a time (4-5 enemies)
	
	# Calculate first batch size (at least 1 enemy, at most the calculated percentage)
	var batch_size = int(ceil(GameManager.enemies_per_wave * difficulty_factor))
	current_batch_size = max(1, min(batch_size, GameManager.enemies_per_wave))
	
	print("DEBUG: First batch will spawn " + str(current_batch_size) + " enemies")

func start_next_batch() -> void:
	if not wave_in_progress or spawning_paused:
		return
		
	# Calculate how many enemies remain to be spawned
	var remaining = GameManager.enemies_per_wave - enemies_spawned
	
	# Only proceed if enemies remain to be spawned
	if remaining <= 0:
		print("DEBUG: All enemies spawned for this wave, no more batches needed")
		return
	
	# Make sure batch size doesn't exceed remaining enemies
	var actual_batch_size = min(current_batch_size, remaining)
	
	print("DEBUG: Starting new batch of " + str(actual_batch_size) + " enemies")
	
	# Reset the batch counter
	enemies_spawned_in_current_batch = 0
	
	# Make sure spawn timer is stopped before restarting
	spawn_timer.stop()
		
	# Start the timer to spawn enemies in this batch
	spawn_timer.start()

func _on_batch_timer_timeout() -> void:
	print("DEBUG: Batch timer expired, preparing next batch")
	next_batch_ready = true
	
	# Check if we should spawn the next batch now
	check_for_next_batch()

func check_for_next_batch() -> void:
	# Only spawn next batch if:
	# 1. Wave is in progress
	# 2. Spawning isn't paused
	# 3. Next batch is ready
	# 4. We haven't spawned all enemies yet
	# 5. Active enemy count is low
	
	if not wave_in_progress or spawning_paused or not next_batch_ready:
		return
		
	if enemies_spawned >= GameManager.enemies_per_wave:
		print("DEBUG: All enemies already spawned, no need for next batch")
		return
	
	# Calculate threshold for spawning next batch - with difficulty factored in
	var difficulty_factor = 0.0
	match GameManager.difficulty:
		"Easy": difficulty_factor = 0.1  # Only when few enemies remain
		"Normal": difficulty_factor = 0.15
		"Hard": difficulty_factor = 0.2
		"Very Hard": difficulty_factor = 0.25
		"Extreme": difficulty_factor = 0.3  # Allow more active enemies
		
	var threshold = max(2, int(GameManager.enemies_per_wave * difficulty_factor))
	
	# Count actual active enemies based on our tracked list
	var active_count = count_active_enemies()
	
	print("DEBUG: Active enemies: " + str(active_count) + ", threshold: " + str(threshold))
	
	if active_count <= threshold:
		print("DEBUG: Active enemy count is low, starting next batch")
		next_batch_ready = false
		start_next_batch()
	else:
		print("DEBUG: Too many active enemies (" + str(active_count) + 
			"), waiting for more to be defeated before next batch")

func count_active_enemies() -> int:
	# Count enemies that are still alive from our spawned list
	var count = 0
	var to_remove = []
	
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			count += 1
			print("DEBUG: Enemy " + str(enemy.get("enemy_id") if enemy.get("enemy_id") != null else "unknown") + 
				" at position " + str(enemy.global_position) + " is valid")
		else:
			print("DEBUG: Found invalid enemy in list")
			to_remove.append(enemy)  # Mark for removal
	
	# Clean up our list
	for enemy in to_remove:
		spawned_enemies.erase(enemy)
		print("DEBUG: Removed invalid enemy from tracking list")
		
	return count

func _on_enemies_changed(count: int) -> void:
	# When enemy count changes, check if we should start preparing the next batch
	if wave_in_progress and not spawning_paused and not next_batch_ready:
		var active_count = count_active_enemies()
		
		# If we're running low on enemies and haven't spawned all yet
		if active_count <= 3 and enemies_spawned < GameManager.enemies_per_wave:
			print("DEBUG: Enemy count dropped, starting batch timer")
			var batch_timer = get_node_or_null("BatchTimer")
			if batch_timer:
				batch_timer.start()
			else:
				# Fallback - just set the flag directly
				next_batch_ready = true
				check_for_next_batch()
	
	# Also check wave completion
	check_wave_completion()

func pause_spawning() -> void:
	spawning_paused = true
	spawn_timer.stop()
	var batch_timer = get_node_or_null("BatchTimer")
	if batch_timer:
		batch_timer.stop()

func resume_spawning() -> void:
	if wave_in_progress:
		spawning_paused = false
		
		# Resume batch spawning if needed
		check_for_next_batch()

func _on_wave_completed() -> void:
	pause_spawning()
	wave_in_progress = false
	enemies_spawned = 0
	spawned_enemies.clear()
	
	# Clear used positions for next wave
	used_target_positions.clear()
	
	# Clear any target markers
	var markers = get_tree().get_nodes_in_group("TargetMarker")
	for marker in markers:
		marker.queue_free()
		
	print("Wave completed, cleaned up for next wave")

func _on_Timer_timeout() -> void:
	if spawning_paused or not wave_in_progress:
		spawn_timer.stop()
		return
	
	# Only spawn if we haven't reached the wave total
	if enemies_spawned < GameManager.enemies_per_wave:
		# Spawn a single enemy
		spawn_enemy_with_random_positions()
		
		# Increment the count for this batch
		enemies_spawned_in_current_batch += 1
		
		# Log spawning progress
		print("DEBUG: Spawned enemy " + str(enemies_spawned) + " (batch: " + 
			str(enemies_spawned_in_current_batch) + "/" + str(current_batch_size) + ")")
		
		# If we've spawned enough for this batch or reached total, stop timer
		if enemies_spawned_in_current_batch >= current_batch_size or enemies_spawned >= GameManager.enemies_per_wave:
			print("DEBUG: Batch of " + str(enemies_spawned_in_current_batch) + " enemies complete")
			spawn_timer.stop()
			
			# Start timer for next batch if we have more enemies to spawn
			if enemies_spawned < GameManager.enemies_per_wave:
				print("DEBUG: Scheduling next batch in 5 seconds")
				
				# Make sure batch timer is stopped before restarting
				batch_timer.stop()
					
				# Start the delay timer
				batch_timer.start()
			else:
				print("DEBUG: All " + str(enemies_spawned) + " enemies have been spawned")
				check_wave_completion()
	else:
		# No more enemies to spawn
		spawn_timer.stop()
		print("DEBUG: All " + str(enemies_spawned) + " enemies have been spawned")
		
		# Check for wave completion
		check_wave_completion()

# Spawn an enemy with completely random positions
func spawn_enemy_with_random_positions() -> void:
	if not enemy_scene:
		print("ERROR: No enemy scene assigned!")
		return
		
	var enemy = enemy_scene.instantiate()
	
	# Apply difficulty modifiers from GameManager
	enemy.speed_multiplier = GameManager.enemy_speed * GameManager.wave_difficulty_multiplier
	enemy.health_multiplier = GameManager.enemy_health * GameManager.wave_difficulty_multiplier
	
	# Find TargetPlane for enemy initial spawn positions
	var target_plane = get_tree().current_scene.get_node_or_null("TargetPlane") 
	
	# Default spawn area if no target plane
	var spawn_min_x = -20.0
	var spawn_max_x = 20.0
	var spawn_min_z = -15.0
	var spawn_max_z = 15.0
	
	if target_plane:
		# If target plane exists, use its size and position
		if target_plane is MeshInstance3D and target_plane.mesh is PlaneMesh:
			var plane_mesh = target_plane.mesh as PlaneMesh
			var plane_size = plane_mesh.size
			spawn_min_x = target_plane.global_position.x - plane_size.x/2
			spawn_max_x = target_plane.global_position.x + plane_size.x/2
			spawn_min_z = target_plane.global_position.z - plane_size.y/2
			spawn_max_z = target_plane.global_position.z + plane_size.y/2
			print("DEBUG: Using TargetPlane for enemy spawn area: ", spawn_min_x, ",", spawn_max_x, " / ", spawn_min_z, ",", spawn_max_z)
	
	# Create a random spawn position in the spawn area
	var spawn_position = Vector3(
		randf_range(spawn_min_x, spawn_max_x),  # Random X position
		0.0,                                    # Y is always 0
		randf_range(spawn_min_z, spawn_max_z)   # Random Z position in spawn range
	)
	
	# Position must be set BEFORE adding to scene to avoid flash at origin
	# Just setting a property doesn't require deferred calls
	enemy.position = spawn_position

	# Add enemy to scene with position already set
	get_tree().current_scene.call_deferred("add_child", enemy)
	await get_tree().create_timer(0.1).timeout  # Wait a bit longer for proper initialization
	
	# Ensure position is still correct after adding to scene
	enemy.position = spawn_position
	
	# Set target position to the same as spawn position - no movement needed
	enemy.target_position = spawn_position
	
	# Track spawning in GameManager
	GameManager.enemies_spawned_in_wave += 1
	
	# Create a visual debug marker if it's a debug build
	if OS.is_debug_build():
		var marker = MeshInstance3D.new()
		marker.name = "TargetMarker" + str(enemies_spawned)
		marker.add_to_group("TargetMarker")  # Add to group for easy finding
		
		# Small sphere
		var sphere = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		marker.mesh = sphere
		
		# Orange material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.0, 0.5)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.0)
		material.emission_energy = 1.5
		sphere.material = material
		
		# Set position and defer adding to scene
		marker.position = spawn_position
		get_tree().current_scene.call_deferred("add_child", marker)
	
	# Make sure the enemy is visible
	enemy.visible = true

	# Ensure the model is properly initialized
	if enemy.has_method("ensure_visibility"):
		enemy.ensure_visibility()
	
	# Track this enemy in our spawned enemies list
	spawned_enemies.append(enemy)
	
	# Debug info
	print("DEBUG: Enemy " + str(enemies_spawned) + " spawned")
	
	# Increment enemies spawned counter
	enemies_spawned += 1

# Unified wave completion check that coordinates with GameManager
func check_wave_completion() -> void:
	# Only check completion if all enemies have been spawned
	if enemies_spawned < GameManager.enemies_per_wave or not wave_in_progress:
		return
		
	# Count how many enemies are still alive
	var active_count = count_active_enemies()
	
	# Ensure GameManager tracking is accurate
	GameManager.enemies_spawned_in_wave = enemies_spawned
	GameManager.current_enemies_count = active_count
	
	if active_count <= 0:
		print("DEBUG: WAVE COMPLETE - All " + str(GameManager.enemies_per_wave) + 
			" enemies have been spawned and defeated")
		complete_wave()
	else:
		print("DEBUG: Wave not complete yet - " + str(active_count) + 
			" enemies still active out of " + str(GameManager.enemies_per_wave) + " total")

func complete_wave() -> void:
	# Only complete the wave once
	if not wave_in_progress:
		return
		
	wave_in_progress = false
	pause_spawning()
	
	print("DEBUG: Wave complete signal emitted")
	
	# Notify GameManager
	GameManager.complete_wave()
