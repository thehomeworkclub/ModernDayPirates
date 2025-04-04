extends Area3D

@export var base_health: int = 3
@export var base_speed: float = 8.0  # Significantly increased speed
@export var base_bronze_value: int = 2
@export var player_ship_barrier: float = 150.0  # Massively increased distance from player where ships stop

# Combat variables - will be set from GameParameters
var bomb_damage: int = 2
var bomb_cooldown: float = 10.0
var bullet_damage: int = 1
var bullet_cooldown: float = 5.0

var health: int
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0
var bronze_value: int = 0
var time_since_last_bomb: float = 0.0
var time_since_last_bullet: float = 0.0
var at_barrier: bool = false
var damage_timer: float = 0.0
var player_ref: Node = null
var player_position: Vector3 = Vector3.ZERO

# Target position variables
var target_position: Vector3 = Vector3.ZERO  # Final position where ship stops
var target_position_node: Node = null

# Ship approach animation variables
var start_position: Vector3 = Vector3.ZERO  # Position far away where ship starts
var is_approaching: bool = true  # Whether ship is still moving to target position
var approach_speed: float = 70.0  # Much faster speed for dramatic approach
var approach_threshold: float = 1.0  # Distance at which to consider arrival reached

# Boat bobbing and bouncing variables - REALISTIC VALUES FOR SMALL BOATS
var bobbing_time: float = 0.0
var bob_height_multiplier: float = 0.1  # Height of bobbing motion (reduced)
var bob_frequency: float = 6.0  # Speed of bobbing (slightly slower for more realism)
var pitch_multiplier: float = 0.08  # Much smaller pitch angle - boats don't tilt that much
var roll_multiplier: float = 0.04  # Reduced roll - small boats are more stable at speed
var boat_model: Node3D = null  # Reference to the actual boat model for rotation
var planing_angle: float = 0.12  # Constant upward tilt when moving fast (nose up)

# Combat capabilities
var can_shoot_bombs: bool = false  # Will be set if this enemy is designated as a bomber
var can_shoot_bullets: bool = true  # All enemies can shoot bullets
var bombs_shot_count: int = 0
var bullets_shot_count: int = 0
var enemy_id: int = -1

func _ready() -> void:
	# Set up group membership
	add_to_group("Enemy")
	
	# Register with the GameManager to get a unique ID
	enemy_id = GameManager.register_enemy()
	
	# Get game parameters
	bomb_damage = GameManager.game_parameters.get_bomb_damage()
	bomb_cooldown = GameManager.game_parameters.get_bomb_cooldown()
	bullet_damage = GameManager.game_parameters.get_bullet_damage()
	bullet_cooldown = GameManager.game_parameters.get_bullet_cooldown()
	
	# Check if we're designated as a bomber
	can_shoot_bombs = GameManager.current_bomber_id == enemy_id
	if can_shoot_bombs:
		print("DEBUG: Enemy " + str(enemy_id) + " initialized as a bomber")
	
	# Make sure the player's boat is in Player group
	var player_boat_node = get_tree().current_scene.find_child("Area3D", true, false)
	if player_boat_node != null and not player_boat_node.is_in_group("Player"):
		print("DEBUG: Adding player's boat to Player group")
		player_boat_node.add_to_group("Player")
	
	# Enhanced collision setup with larger hitbox
	collision_layer = 4  # Enemy layer
	collision_mask = 2   # Bullet layer
	
	# Create a larger collision area for easier targeting
	if not has_node("ExtraLargeCollision"):
		var extra_collision = CollisionShape3D.new()
		extra_collision.name = "ExtraLargeCollision"
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(15.0, 8.0, 25.0)  # Very large hitbox
		extra_collision.shape = box_shape
		add_child(extra_collision)
		print("DEBUG: Added extra large collision shape to enemy")
	
	# Ensure collision detection is enabled
	monitoring = true
	monitorable = true
	
	# Get reference to the boat model
	boat_model = get_node_or_null("ScoutBoat")
	if not boat_model:
		# Try to find it with a different approach
		for child in get_children():
			if child is MeshInstance3D or "Boat" in child.name:
				boat_model = child
				break
	
	# Calculate health based on difficulty with safe access
	var round_bonus = 0
	if GameManager.has_method("get") and GameManager.get("current_round") != null:
		round_bonus = GameManager.current_round - 1
	
	health = int(base_health * health_multiplier) + round_bonus
	
	# Use the same difficulty factors for currency as we do for enemy stats
	# This aligns with the GameManager difficulty system
	var round_value = 1
	if GameManager.has_method("get") and GameManager.get("current_round") != null:
		round_value = GameManager.current_round
	
	bronze_value = int(base_bronze_value * health_multiplier + round_value)
	
	# Connect signal using the new signal syntax
	area_entered.connect(_on_area_entered)
	
	# Find the player by searching the Player group first
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_ref = players[0]
		player_position = player_ref.global_position
		print("DEBUG: Enemy found player via Player group")
	else:
		print("DEBUG: No player found in Player group")
		# Try to find player through scene tree as fallback
		var player_boat = get_tree().current_scene.find_child("Area3D", true, false)
		if player_boat != null:
			player_ref = player_boat
			player_position = player_boat.global_position
			print("DEBUG: Enemy found player via scene tree search")
		else:
			print("DEBUG: Could not find player reference!")
	
	# Make sure the boat model is visible - wait until next frame to ensure model is loaded
	call_deferred("ensure_visibility")
	
	# Check if we should be the bomber
	check_bomber_status()
	
	# Print debug info
	print("DEBUG: Enemy ready - id: ", enemy_id, ", health: ", health, ", bombs: ", can_shoot_bombs, ", position: ", global_position)
	
	# Target position will be set by the EnemySpawner
	
func ensure_visibility() -> void:
	# Make sure boat is visible and properly initialized
	if has_node("ScoutBoat"):
		$ScoutBoat.visible = true
		boat_model = $ScoutBoat
		print("DEBUG: Made ScoutBoat model visible for enemy " + str(enemy_id))
		
	# CRITICAL FIX: Check for any unwanted bomb-like children and remove them
	for child in get_children():
		if child.name.to_lower().contains("bomb") or child.name.to_lower().contains("sphere") or child.name.to_lower().contains("marker"):
			if child.name != "ScoutBoat" and child.name != "CollisionShape3D":
				print("DEBUG: Found and removing unwanted bomb-like model: " + child.name)
				child.queue_free()

# Check with GameManager if this ship should be the bomber
func check_bomber_status() -> void:
	if GameManager.current_bomber_id == -1:
		# No current bomber exists, try to become the bomber
		set_as_bomber()
		
# Set this ship as a designated bomber
func set_as_bomber() -> void:
	can_shoot_bombs = true
	GameManager.bomber_ids.append(enemy_id)
	if GameManager.current_bomber_id == -1:
		GameManager.current_bomber_id = enemy_id
	print("DEBUG: Enemy ID ", enemy_id, " set as a bomber")

func _physics_process(delta: float) -> void:
	# Validate target position first
	if target_position == Vector3.ZERO:
		print("WARNING: Enemy has invalid target position. Setting a default target.")
		# Set a default target position ahead of the enemy
		target_position = global_position + Vector3(0, 0, -20.0)
		
	# Also validate global position if it's absurdly large
	if abs(global_position.z) > 1000:
		print("WARNING: Enemy global position is extremely large: " + str(global_position) + ", resetting position")
		global_position = Vector3(global_position.x, global_position.y, -10.0)
	
	# Update player position reference with safety check
	if player_ref:
		# Check if reference is still valid
		if is_instance_valid(player_ref):
			# Reference is valid, update position
			player_position = player_ref.global_position
		else:
			# Reference is invalid, clear it
			print("DEBUG: Player reference was invalid, clearing it")
			player_ref = null

	# Try to find player again if we don't have a reference
	if not player_ref:
		# Look for player in Player group
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
			# Verify this object is valid
			if is_instance_valid(player_ref):
				player_position = player_ref.global_position
				print("DEBUG: Enemy found player reference")
			else:
				player_ref = null
	
	# Apply speed multiplier from difficulty
	var adjusted_speed = base_speed * speed_multiplier
	
	# Check if we're in front of the player - if so, stop at barrier
	var in_front_of_player = false
	if player_ref and is_instance_valid(player_ref):
		in_front_of_player = global_position.z < player_position.z + player_ship_barrier
	
	# Update bobbing time
	bobbing_time += delta
	
	# Handle approach animation if still approaching target position
	if is_approaching:
		# Calculate movement vector toward target using a 2D vector for perfect straight line
		var direction_2d = Vector2(target_position.x - global_position.x, target_position.z - global_position.z).normalized()
		var move_distance = approach_speed * delta
		
		# Move toward target position in a perfect straight line
		global_position.x += direction_2d.x * move_distance
		global_position.z += direction_2d.y * move_distance
		
		# CRITICAL FIX: Maintain a consistent Y position during movement
		# This ensures the ship stays at the correct height
		global_position.y = start_position.y
		
		# Apply bobbing and bouncing effect during approach
		apply_boat_bobbing_effect(delta, true)
		
		# Debug approach occasionally
		if Engine.get_physics_frames() % 60 == 0:
			var approach_distance = global_position.distance_to(target_position)
			print("DEBUG: Enemy approaching - distance remaining: ", approach_distance)
		
		# Check if we've reached the target position - use 2D distance (ignoring Y)
		var horizontal_distance = Vector2(
			target_position.x - global_position.x,
			target_position.z - global_position.z
		).length()
		
		if horizontal_distance < approach_threshold:
			is_approaching = false
			
			# Set the final position, but keep the Y value from our start position
			global_position.x = target_position.x
			global_position.z = target_position.z
			
			# IMPORTANT: Keep the Y position consistent
			global_position.y = start_position.y
			
			print("DEBUG: Enemy reached final position: ", global_position)
	else:
		# We've reached the target - stay in position and shoot bombs
		# Still apply gentle bobbing when stopped
		apply_boat_bobbing_effect(delta, false)
		
		# Debug position occasionally
		if Engine.get_physics_frames() % 120 == 0:
			print("DEBUG: Enemy at final position: ", global_position)
		
		# Only shoot bombs once we've arrived at final position
		shoot_bombs_while_stationary(delta)

# Apply bobbing and bouncing effect to make the boat feel like it's on water
func apply_boat_bobbing_effect(delta: float, is_moving: bool) -> void:
	# Skip if no boat model found
	if not boat_model:
		return
		
	# Different bobbing parameters based on if we're moving or stationary
	var actual_bob_frequency = bob_frequency
	var actual_pitch_multiplier = pitch_multiplier
	var actual_roll_multiplier = roll_multiplier
	var actual_bob_height = bob_height_multiplier
	
	if is_moving:
		# More intense bobbing during movement, but still realistic
		actual_bob_frequency *= 1.2
		actual_pitch_multiplier *= 1.3  # Less extreme pitch while moving
		actual_roll_multiplier *= 1.2
		actual_bob_height *= 1.4
	else:
		# Gentle bobbing when stationary
		actual_bob_frequency *= 0.5  # Slower bobbing when stopped
		actual_pitch_multiplier *= 0.4
		actual_roll_multiplier *= 0.5
		actual_bob_height *= 0.6
	
	# Calculate bobbing effect - oscillate up and down
	var vertical_offset = sin(bobbing_time * actual_bob_frequency) * actual_bob_height
	
	# CRITICAL FIX: Use a consistent Y position, only modify for bobbing
	# Just apply bobbing offset to original position
	position.y = vertical_offset
	
	# Calculate pitch (rotation forward/backward) - realistic speedboat motion
	# Use cosine with offset to create realistic wave motion
	var pitch_angle = cos(bobbing_time * actual_bob_frequency) * actual_pitch_multiplier
	
	# Calculate roll (rotation side to side)
	# Use sine with different frequency for more natural motion
	var roll_angle = sin(bobbing_time * actual_bob_frequency * 0.7) * actual_roll_multiplier
	
	# Apply rotation to the boat model - this tilts the boat as it goes over waves
	if boat_model:
		# Reset the rotation first
		boat_model.rotation = Vector3.ZERO
		
		# IMPORTANT FIX: Rotate 180 degrees around Y-axis to make boat face forward
		boat_model.rotate_y(PI)  # 180 degrees = PI radians
		
		# If moving, the boat should have its nose up (planing)
		if is_moving:
			# REALISTIC PHYSICS: When speedboats move fast, they plane with the nose UP
			# This is opposite to the previous implementation which had nose down
			boat_model.rotate_x(planing_angle)
		
		# Apply pitch (X rotation) - this makes the boat point up and down as it moves over waves
		# We add this to the planing angle
		boat_model.rotate_x(pitch_angle)
		
		# Apply roll (Z rotation) - this makes the boat rock side to side
		boat_model.rotate_z(roll_angle)
			
# Function for shooting bombs and bullets when the ship is stationary
func shoot_bombs_while_stationary(delta: float) -> void:
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player_position)
	
	# Output debug info occasionally
	if Engine.get_physics_frames() % 300 == 0:
		print("DEBUG: Enemy " + str(enemy_id) + " combat check - distance: ", distance_to_player, 
		", bomb timer: ", time_since_last_bomb, ", bullet timer: ", time_since_last_bullet,
		", can bomb: ", can_shoot_bombs, ", active bomber: ", (GameManager.current_bomber_id == enemy_id))
	
	# Combat distance ranges
	var max_shoot_range = 250.0
	var min_shoot_range = 15.0
	
	if distance_to_player < max_shoot_range && distance_to_player > min_shoot_range:
		# Update timers
		time_since_last_bomb += delta
		time_since_last_bullet += delta
		
		# Check if we can shoot a bomb (only if we're the active bomber)
		if can_shoot_bombs and GameManager.current_bomber_id == enemy_id and time_since_last_bomb >= bomb_cooldown:
			print("DEBUG: Enemy " + str(enemy_id) + " attempting to shoot bomb!")
			shoot_bomb()
			time_since_last_bomb = 0.0
		
		# Check if we can shoot a bullet (all enemies)
		if time_since_last_bullet >= bullet_cooldown:
			print("DEBUG: Enemy " + str(enemy_id) + " attempting to shoot bullet!")
			shoot_bullet()
			time_since_last_bullet = 0.0

func shoot_bomb() -> void:
	# Only shoot bombs if we're designated as the active bomber
	if GameManager.current_bomber_id != enemy_id:
		print("DEBUG: Enemy " + str(enemy_id) + " is not the active bomber, cannot shoot bombs")
		return
		
	# CRITICAL FIX: Re-find player reference if missing
	if not player_ref:
		print("DEBUG: Trying to find player again")
		
		# Look for player in Player group
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
			player_position = player_ref.global_position
			print("DEBUG: Found player at " + str(player_position))
		else:
			print("DEBUG: Can not shoot bomb - no player reference")
			return
		
	# Instead, just count existing bombs for debugging
	var existing_bombs = get_tree().get_nodes_in_group("EnemyBomb")
	var count = 0
	for bomb in existing_bombs:
		if is_instance_valid(bomb) and bomb.has_method("get_owner_id") and bomb.get_owner_id() == enemy_id:
			count += 1
	print("DEBUG: Enemy has " + str(count) + " existing bombs")
	
	# Increment debug counter 
	bombs_shot_count += 1
	print("DEBUG: Enemy " + str(enemy_id) + " (designated bomber) attempting to shoot bomb #" + str(bombs_shot_count))

	# Create the bomb as a completely separate entity in the scene
	var bomb = Area3D.new()
	bomb.name = "EnemyBomb_" + str(enemy_id) + "_" + str(bombs_shot_count)
	bomb.add_to_group("EnemyBomb")
	
	# Set up collision
	bomb.collision_layer = 8  # Bomb layer
	bomb.collision_mask = 3   # Player (1) and Bullet (2) layers
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 1.5  # Bigger collision radius for easier shooting
	collision.shape = sphere_shape
	bomb.add_child(collision)
	
	# Create bomb mesh (large red sphere)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BombMesh"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.5
	sphere_mesh.height = 3.0
	mesh_instance.mesh = sphere_mesh
	
	# Create bomb material (red glowing)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.1, 0.0)  # Red
	material.metallic = 0.7
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.0)
	material.emission_energy = 2.5
	sphere_mesh.material = material
	
	mesh_instance.mesh.surface_set_material(0, material)
	bomb.add_child(mesh_instance)
	
	# Add a script to the bomb
	var script = load("res://EnemyBomb.gd")
	if script:
		bomb.set_script(script)
	else:
		print("ERROR: Failed to load EnemyBomb.gd script")
		bomb.queue_free()
		return
		
	# Calculate direction to player
	var direction = (player_position - global_position).normalized()
	
	# Position the bomb above the enemy with an offset toward the player
	var spawn_offset = direction * 2.0  # Position bomb slightly ahead in player direction
	var bomb_pos = global_position + Vector3(spawn_offset.x, 2.5, spawn_offset.z)
	
	# IMPORTANT: First add to scene, then position - this ensures it's not attached to the enemy
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = bomb_pos
	
	# Explicitly set the bomb's transform to ensure it doesn't inherit from parent
	bomb.global_transform.origin = bomb_pos
	
	# Now initialize the bomb with targeting information AFTER it's in the scene
	if bomb.has_method("initialize"):
		# Initialize with this enemy's ID as the owner
		bomb.set_owner_id(enemy_id)
		
		# Initialize the bomb with target information
		bomb.initialize(direction, bomb_damage, player_ref)
		
		print("DEBUG: Bomb successfully initialized for enemy " + str(enemy_id))
	else:
		print("ERROR: Bomb creation failed!")
		bomb.queue_free()

func shoot_bullet() -> void:
	# Increment debug counter
	bullets_shot_count += 1
	print("DEBUG: Enemy " + str(enemy_id) + " shooting bullet #" + str(bullets_shot_count))
	
	# Make sure we have a player reference
	if not player_ref or not is_instance_valid(player_ref):
		print("DEBUG: Cannot shoot bullet - no valid player reference")
		return
	
	# Calculate direction to player - straight line
	var direction = (player_position - global_position).normalized()
	
	# Instance the M16A1Bullet.tscn scene instead of creating a custom bullet
	var bullet_scene = load("res://M16A1Bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.name = "EnemyBullet_" + str(enemy_id) + "_" + str(bullets_shot_count)
	bullet.add_to_group("EnemyBullet")
	
	# Set up collision for enemy bullets - only collide with player, not player bullets
	bullet.collision_layer = 16  # Enemy bullet layer
	bullet.collision_mask = 1    # Player layer only
	
	# Position the bullet in front of the enemy, pointing toward player
	var spawn_offset = direction * 2.0
	var bullet_pos = global_position + Vector3(spawn_offset.x, 1.5, spawn_offset.z)
	
	# Add to scene first
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bullet_pos
	
	# Scale up the bullet by a factor of 5
	bullet.scale = Vector3(5.0, 5.0, 5.0)
	
	# Set bullet properties
	bullet.direction = direction
	
	# Get damage value and set it
	var actual_bullet_damage = GameManager.game_parameters.get_bullet_damage() if GameManager.has_method("get") and GameManager.get("game_parameters") != null else bullet_damage
	bullet.damage = actual_bullet_damage
	
	# Override some of the EnhancedBullet behavior to ensure bullets travel straight
	bullet.set_script(load("res://EnhancedBullet.gd").duplicate())
	bullet.get_script().source_code = bullet.get_script().source_code.replace(
		"func _physics_process(delta: float) -> void:",
		"""func _physics_process(delta: float) -> void:
	# Move in straight line toward target - no gravity for enemy bullets
	global_position += direction * speed * delta
	"""
	)
	
	# Customize area_entered to only damage player
	bullet.get_script().source_code = bullet.get_script().source_code.replace(
		"func _on_area_entered(area: Area3D) -> void:",
		"""func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player") or area.is_in_group("player_boat"):
		if area.has_method("take_damage"):
			print("DEBUG: Enemy bullet hit player, applying damage: ", damage)
			area.take_damage(damage)
			queue_free()
	return  # Don't process other collisions for enemy bullets
	"""
	)
	bullet.get_script().reload()
	
	# Add a distinctive material to enemy bullets (red)
	var bullet_parts = ["BulletMesh/BulletHead", "BulletMesh/BulletBody", "Trail"]
	for part_path in bullet_parts:
		var part = bullet.get_node_or_null(part_path)
		if part:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 0.2, 0.0)  # Red
			material.metallic = 0.7
			material.roughness = 0.2
			material.emission_enabled = true
			material.emission = Color(1.0, 0.3, 0.0)  # Red glow
			material.emission_energy = 2.0
			part.material = material
	
	print("DEBUG: Enemy bullet fired successfully using M16A1Bullet model at 5x scale")
	
func _on_area_entered(area: Area3D) -> void:
	print("DEBUG: Enemy collision with ", area.name)
	
	# Simple group-based check
	if area.is_in_group("Bullet"):
		print("DEBUG: Enemy hit by bullet")
		var damage = area.get_damage() if area.has_method("get_damage") else 1
		take_damage(damage)

func take_damage(damage: int) -> void:
	print("DEBUG: Enemy taking damage: ", damage)
	health -= damage
	
	# Flash or visual indicator could be added here
	
	if health <= 0:
		print("DEBUG: Enemy defeated! ID: ", enemy_id)
		
		# Before removing - let the spawner know this enemy is no longer valid
		remove_from_spawner_tracking()
		
		# Instead, just count and log existing bombs for debugging
		var existing_bombs = get_tree().get_nodes_in_group("EnemyBomb")
		var bomb_count = 0
		for bomb in existing_bombs:
			if is_instance_valid(bomb) and bomb.has_method("get_owner_id") and bomb.get_owner_id() == enemy_id:
				bomb_count += 1
		print("DEBUG: Enemy " + str(enemy_id) + " defeated, leaving " + str(bomb_count) + " active bombs!")
		
		# Award currency for defeating enemy - 3 bronze, 2 silver, 1 gold
		CurrencyManager.add_bronze(3)
		CurrencyManager.add_silver(2)
		CurrencyManager.add_gold(1, 1.0)
		
		# Increment kill counter in GameManager for shop teleporting
		GameManager.enemy_kill_count += 1
		print("Enemy kill count: " + str(GameManager.enemy_kill_count))
		
		# IMPORTANT - Update enemy count first
		# We need to decrease enemy count BEFORE notifying GameManager to ensure 
		# accurate count when wave completion is checked
		GameManager.current_enemies_count -= 1
		
		# Notify GameManager that an enemy has been defeated - pass our ID
		GameManager.enemy_defeated(enemy_id)
		
		# Clean up target position
		var ship_manager = get_node_or_null("/root/ShipManager")
		if ship_manager:
			ship_manager.clear_target_position(target_position)
		
		# Immediately check if this was the last enemy in the wave
		# Get enemy spawner to force a wave completion check
		var spawner = get_tree().get_first_node_in_group("EnemySpawner")
		if spawner and spawner.has_method("check_wave_completion"):
			spawner.check_wave_completion()
		
		# CRITICAL: Force a scheduled check to make sure wave completes even if there's a discrepancy
		if spawner and spawner.has_method("schedule_force_wave_completion_check"):
			spawner.schedule_force_wave_completion_check()
		
		# Now it's safe to destroy the enemy
		queue_free()

# Explicitly remove this enemy from the spawner's tracking
func remove_from_spawner_tracking() -> void:
	var spawner = get_tree().get_first_node_in_group("EnemySpawner")
	if spawner and spawner.has_method("remove_from_tracking"):
		spawner.remove_from_tracking(self)
	else:
		print("WARNING: Could not find spawner to remove from tracking")
