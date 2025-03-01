# EnemySpawner.gd
extends Node3D

@export var enemy_scene: PackedScene  # assign Enemy.tscn in the Inspector
@export var base_spawn_interval: float = 2.0

var spawn_timer: Timer
var enemies_spawned: int = 0
var spawning_paused: bool = false
var wave_in_progress: bool = false

func _ready() -> void:
	# Add to enemy spawner group for easier access
	add_to_group("EnemySpawner")
	
	print("DEBUG: EnemySpawner initialized at position: ", global_position)
	
	# Create and start a timer to spawn enemies at fixed intervals.
	spawn_timer = Timer.new()
	spawn_timer.wait_time = get_adjusted_spawn_interval()
	spawn_timer.one_shot = false
	spawn_timer.autostart = false  # Don't auto start - wait for wave to begin
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_Timer_timeout)
	
	# Connect to GameManager signals
	GameManager.wave_completed.connect(_on_wave_completed)
	
	# Force the spawner position to be closer to the player for better visibility
	# This overrides the position in the scene
	global_position = Vector3(0, 0, 10.0)
	
	print("DEBUG: EnemySpawner position reset to: ", global_position)
	
	# Start the first wave if game is already started
	if GameManager.game_started:
		start_wave_spawning()

func _process(_delta: float) -> void:
	# Update timer based on current difficulty
	if not spawning_paused and spawn_timer.wait_time != get_adjusted_spawn_interval():
		spawn_timer.wait_time = get_adjusted_spawn_interval()

func get_adjusted_spawn_interval() -> float:
	# Use the spawn rate from GameManager, adjusted for wave difficulty
	var interval = GameManager.enemy_spawn_rate
	if interval <= 0:
		interval = base_spawn_interval
		
	# Make spawning faster as waves progress
	interval /= GameManager.wave_difficulty_multiplier
	
	return interval

func start_wave_spawning() -> void:
	enemies_spawned = 0
	spawning_paused = false
	wave_in_progress = true
	
	print("DEBUG: EnemySpawner starting wave with " + str(GameManager.enemies_per_wave) + " enemies")
	
	# Calculate batch size based on difficulty (10-20% of total enemies)
	var difficulty_factor = 0.0
	match GameManager.difficulty:
		"Easy": difficulty_factor = 0.1  # 10% at a time
		"Normal": difficulty_factor = 0.12
		"Hard": difficulty_factor = 0.15
		"Very Hard": difficulty_factor = 0.18
		"Extreme": difficulty_factor = 0.2  # 20% at a time
	
	# Calculate first batch size (at least 2 enemies)
	var batch_size = max(2, int(GameManager.enemies_per_wave * difficulty_factor))
	var initial_batch = min(batch_size, GameManager.enemies_per_wave)
	
	print("DEBUG: First batch will spawn " + str(initial_batch) + " enemies (" + 
		  str(int(difficulty_factor * 100)) + "% of total)")
	
	# Spawn first batch with proper spacing
	spawn_batch(initial_batch)
	
	# Start timer for remaining enemies
	if enemies_spawned < GameManager.enemies_per_wave:
		spawn_timer.start()
	else:
		print("DEBUG: All enemies spawned in first batch")

func pause_spawning() -> void:
	spawning_paused = true
	spawn_timer.stop()

func resume_spawning() -> void:
	if wave_in_progress:
		spawning_paused = false
		spawn_timer.start()

func _on_wave_completed() -> void:
	pause_spawning()
	wave_in_progress = false
	enemies_spawned = 0

func _on_Timer_timeout() -> void:
	if spawning_paused or not wave_in_progress:
		return
	
	# Only spawn more enemies if active enemy count is low
	if GameManager.current_enemies_count <= 1 and enemies_spawned < GameManager.enemies_per_wave:
		# Calculate batch size based on difficulty (10-20% of total)
		var difficulty_factor = 0.0
		match GameManager.difficulty:
			"Easy": difficulty_factor = 0.1  # 10% at a time
			"Normal": difficulty_factor = 0.12
			"Hard": difficulty_factor = 0.15
			"Very Hard": difficulty_factor = 0.18
			"Extreme": difficulty_factor = 0.2  # 20% at a time
		
		# Calculate next batch size
		var remaining = GameManager.enemies_per_wave - enemies_spawned
		var batch_size = max(2, int(GameManager.enemies_per_wave * difficulty_factor))
		var to_spawn = min(batch_size, remaining)
		
		print("DEBUG: Spawning next batch of " + str(to_spawn) + " enemies")
		
		# Spawn next batch with proper spacing
		spawn_batch(to_spawn)
		
		# Check if we've spawned all enemies
		if enemies_spawned >= GameManager.enemies_per_wave:
			spawn_timer.stop()
			print("DEBUG: All " + str(enemies_spawned) + " enemies have been spawned")
	
	# Check if all enemies are defeated and all have been spawned
	if GameManager.current_enemies_count <= 0 and enemies_spawned >= GameManager.enemies_per_wave:
		GameManager.check_wave_completion()

# Create a new function to spawn a batch of enemies with proper spacing
func spawn_batch(count: int) -> void:
	# Define the spawn area bounds relative to spawner position
	var min_x = -5.0
	var max_x = 5.0
	var min_z_offset = -5.0  # 5 units in front of the spawner
	var max_z_offset = 5.0   # 5 units behind the spawner
	
	# Get the spawner's global position
	var spawner_position = global_position
	
	print("DEBUG: Spawner is at position: ", spawner_position)
	print("DEBUG: Spawning batch around spawner: X=" + str(spawner_position.x + min_x) + 
		  " to " + str(spawner_position.x + max_x) + 
		  ", Z=" + str(spawner_position.z + min_z_offset) + 
		  " to " + str(spawner_position.z + max_z_offset))
	
	# Calculate spacing based on count
	var used_positions = []
	
	for i in range(count):
		# Calculate absolute position from spawner position and offsets
		var position = Vector3(
			spawner_position.x + randf_range(min_x, max_x),
			0,  # Y is always 0
			spawner_position.z + randf_range(min_z_offset, max_z_offset)
		)
		
		# Ensure positions aren't too close
		var valid_position = true
		for pos in used_positions:
			if position.distance_to(pos) < 2.0:  # Minimum separation
				valid_position = false
				break
				
		if not valid_position:
			# If invalid, try again with a different position
			position = Vector3(
				spawner_position.x + randf_range(min_x, max_x),
				0,
				spawner_position.z + randf_range(min_z_offset, max_z_offset)
			)
				
		used_positions.append(position)
		
		# Spawn the enemy at this position
		spawn_enemy_at_position(position)
		
	print("DEBUG: Spawned batch of " + str(count) + " enemies with spacing")

# Spawn a single enemy at the specified position
func spawn_enemy_at_position(position: Vector3) -> void:
	var enemy = enemy_scene.instantiate()
	
	# Apply difficulty modifiers
	enemy.speed_multiplier = GameManager.enemy_speed * GameManager.wave_difficulty_multiplier
	enemy.health_multiplier = GameManager.enemy_health * GameManager.wave_difficulty_multiplier
	
	# Add enemy to scene first
	get_tree().current_scene.add_child(enemy)
	
	# Then set position - this order is important!
	enemy.global_position = position
	
	# Make sure it's visible
	enemy.visible = true
	
	# Debug info
	print("DEBUG: Enemy spawned at ", enemy.global_position)
	
	# Track the enemy in the GameManager
	GameManager.register_enemy()
	enemies_spawned += 1

# Keep this for backwards compatibility, but use a random position
func spawn_enemy() -> void:
	# Define the spawn area bounds - use the spawner's position
	var spawner_position = global_position
	var min_x = -5.0
	var max_x = 5.0
	var z_offset = randf_range(-5.0, 5.0)  # Random offset around spawner
	
	var position = Vector3(
		spawner_position.x + randf_range(min_x, max_x),
		0,  # Y is always 0
		spawner_position.z + z_offset
	)
	
	spawn_enemy_at_position(position)
