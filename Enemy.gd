extends Area3D

@export var base_health: int = 3
@export var base_speed: float = 8.0  # Significantly increased speed
@export var base_bronze_value: int = 2
@export var bomb_damage: int = 15     # INCREASED damage to make bomb hits more obvious
@export var bomb_cooldown: float = 4.0  # Reduced cooldown to increase bomb frequency
@export var bomb_chance: float = 0.7    # Increased chance to throw a bomb when cooldown expires
@export var player_ship_barrier: float = 150.0  # Massively increased distance from player where ships stop

var health: int
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0
var bronze_value: int = 0
var time_since_last_bomb: float = 0.0
var at_barrier: bool = false
var damage_timer: float = 0.0
var player_ref: Node = null
var player_position: Vector3 = Vector3.ZERO

# Target position variables
var target_position: Vector3 = Vector3.ZERO
var target_position_node: Node = null

# Bombing capability - will be controlled centrally
var can_shoot_bombs: bool = false
# Debug - track if bombs are being shot
var bombs_shot_count: int = 0
# Unique ID for this enemy
var enemy_id: int = -1

func _ready() -> void:
	# Set up group membership
	add_to_group("Enemy")
	
	# Register with the GameManager to get a unique ID
	enemy_id = GameManager.register_enemy()
	
	# Basic collision setup - keep it simple
	collision_layer = 4  # Enemy layer
	collision_mask = 2   # Bullet layer
	
	# Ensure collision detection is enabled
	monitoring = true
	monitorable = true
	
	# Calculate health based on difficulty
	var round_bonus = GameManager.current_round - 1
	health = int(base_health * health_multiplier) + round_bonus
	
	# Use the same difficulty factors for currency as we do for enemy stats
	# This aligns with the GameManager difficulty system
	bronze_value = int(base_bronze_value * health_multiplier + GameManager.current_round)
	
	# Connect signal using the new signal syntax
	area_entered.connect(_on_area_entered)
	
	# Find the player's boat first, since visibility depends on proper initialization
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_ref = players[0]
		player_position = player_ref.global_position
	else:
		print("WARNING: No player found, enemy may not behave correctly")
		
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
		
# Set this ship as the designated bomber
func set_as_bomber() -> void:
	can_shoot_bombs = true
	GameManager.current_bomber_id = enemy_id
	print("DEBUG: Enemy ID ", enemy_id, " set as the bomber")

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
	
	# Update player position reference
	if player_ref:
		player_position = player_ref.global_position
	else:
		# Try to find player again if we don't have a reference
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
			player_position = player_ref.global_position
			print("DEBUG: Enemy found player reference")
	
	# Apply speed multiplier from difficulty
	var adjusted_speed = base_speed * speed_multiplier
	
	# Determine state based on distance to target
	var distance_to_target = global_position.distance_to(target_position)
	
	# Check if we're in front of the player - if so, stop at barrier
	var in_front_of_player = false
	if player_ref:
		in_front_of_player = global_position.z < player_position.z + player_ship_barrier
	
	# Debug info
	if Engine.get_physics_frames() % 120 == 0:
		print("DEBUG: Enemy distance to target: ", distance_to_target, 
			", Target: ", target_position, 
			", Current: ", global_position)
	
	# No movement - boats stay where they spawn 
	# Debug position occasionally
	if Engine.get_physics_frames() % 120 == 0:
		print("DEBUG: Enemy at position: ", global_position)
		
	# Shoot bombs from fixed position
	shoot_bombs_while_stationary(delta)
		
	# Ensure Y position stays at ground level
	if global_position.y != 0:
		global_position.y = 0
		
# Function for shooting bombs when the ship is stationary
func shoot_bombs_while_stationary(delta: float) -> void:
	# Shoot bombs at player - prioritize designated bombers
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player_position)
	
	# Output debug info occasionally
	if Engine.get_physics_frames() % 300 == 0:
		print("DEBUG: Stationary enemy bomb check - distance to player: ", distance_to_player, 
		", bomb timer: ", time_since_last_bomb, ", can bomb: ", can_shoot_bombs)
	
	# Only shoot if within range (close enough to hit, but not too close)
	var max_shoot_range = 250.0  # Greatly increased shooting range to match actual distances
	var min_shoot_range = 15.0  # Don't shoot if too close
	
	if distance_to_player < max_shoot_range && distance_to_player > min_shoot_range:
		time_since_last_bomb += delta
		if time_since_last_bomb >= bomb_cooldown:
			# Designated bombers have full chance, others have reduced chance
			var effective_chance = bomb_chance if can_shoot_bombs else bomb_chance * 0.3
			var roll = randf()
			print("DEBUG: Stationary enemy bomb roll: ", roll, " vs threshold: ", effective_chance)
			
			if roll <= effective_chance:
				print("DEBUG: Stationary enemy attempting to shoot bomb!")
				shoot_bomb()
			time_since_last_bomb = 0.0

func shoot_bomb() -> void:
	# CRITICAL CHECK: Only the designated bomber can shoot bombs
	if enemy_id != GameManager.current_bomber_id:
		print("DEBUG: Enemy " + str(enemy_id) + " NOT allowed to shoot bombs - not the current bomber!")
		return
		
	if not player_ref:
		print("DEBUG: Can't shoot bomb - no player reference")
		return
		
	# COMMENTED OUT: Code that was removing existing bombs
	# This was clearing old bombs when creating new ones
	# var existing_bombs = get_tree().get_nodes_in_group("EnemyBomb")
	# for bomb in existing_bombs:
	# 	# Remove ALL bombs that originated from this enemy - prevents accumulation
	# 	if is_instance_valid(bomb) and bomb.has_method("get_owner_id") and bomb.get_owner_id() == enemy_id:
	# 		print("DEBUG: Removing existing bomb from enemy " + str(enemy_id))
	# 		bomb.queue_free()
	
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
	
	# Create the bomb as a completely separate entity in the scene - never attached to the enemy boat
	var bomb = Area3D.new()
	bomb.name = "EnemyBomb_" + str(enemy_id) + "_" + str(bombs_shot_count)
	bomb.add_to_group("EnemyBomb")
	
	# Set up collision
	bomb.collision_layer = 8  # Bomb layer (new layer)
	bomb.collision_mask = 3   # Player (1) and Bullet (2) layers
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 1.5  # Much bigger collision radius for easier shooting
	collision.shape = sphere_shape
	bomb.add_child(collision)
	
	# Create main bomb body (sphere)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BombMesh"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.5  # Much bigger visual size for easier visibility
	sphere_mesh.height = 3.0  # Keep the height proportional
	mesh_instance.mesh = sphere_mesh
	
	# Create bomb material with stronger emissive properties for better visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.1, 0.0)  # Brighter red
	material.metallic = 0.7
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.0)
	material.emission_energy = 2.5  # Increased glow
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
		
		# COMMENTED OUT: Code that was removing bombs when enemy is defeated
		# var existing_bombs = get_tree().get_nodes_in_group("EnemyBomb")
		# for bomb in existing_bombs:
		#     if is_instance_valid(bomb) and bomb.has_method("get_owner_id") and bomb.get_owner_id() == enemy_id:
		#         print("DEBUG: Removing bomb from defeated enemy " + str(enemy_id))
		#         bomb.queue_free()
		
		# Instead, just count and log existing bombs for debugging
		var existing_bombs = get_tree().get_nodes_in_group("EnemyBomb")
		var bomb_count = 0
		for bomb in existing_bombs:
			if is_instance_valid(bomb) and bomb.has_method("get_owner_id") and bomb.get_owner_id() == enemy_id:
				bomb_count += 1
		print("DEBUG: Enemy " + str(enemy_id) + " defeated, leaving " + str(bomb_count) + " active bombs!")
		
		# Award bronze for defeating enemy
		CurrencyManager.add_bronze(bronze_value)
		
		# Notify GameManager that an enemy has been defeated - pass our ID
		GameManager.enemy_defeated(enemy_id)
		
		# Clean up target position
		var ship_manager = get_node_or_null("/root/ShipManager")
		if ship_manager:
			ship_manager.clear_target_position(target_position)
		
		# Destroy the enemy
		queue_free()
