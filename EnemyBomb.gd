extends Area3D

var damage: int = 2  # Default damage, will be updated from GameParameters during initialization
var age: float = 0.0
var owner_id: int = -1
var target_player = null
var exploded: bool = false

# Physics variables for high-arc trajectory
var start_pos: Vector3
var target_pos: Vector3
var v_horizontal: Vector3
var v_vertical: float
var bomb_gravity: float = 30.0  # Reduced gravity for longer arcs
var arc_height: float = 50.0  # Increased arc height for better visibility and trajectory
var min_arc_duration: float = 2.5  # Longer minimum duration
var max_arc_duration: float = 4.0  # Longer maximum duration
var arc_duration: float = 2.0
var time_passed: float = 0.0
var initialized = false
var sea_level: float = 0.0

func _ready():
	area_entered.connect(_on_area_entered)
	add_to_group("EnemyBomb")
	collision_layer = 8
	collision_mask = 3
	monitoring = true
	monitorable = true
	
	# Make the bomb much larger for better visibility and easier shooting
	scale = Vector3(3.0, 3.0, 3.0)  # Triple-sized bombs for better visibility and collision
	
	print("DEBUG: Bomb created at " + str(global_position))

func is_initialized() -> bool:
	return initialized

func get_age() -> float:
	return age

func set_owner_id(id: int):
	owner_id = id

func get_owner_id() -> int:
	return owner_id

func get_damage() -> int:
	return damage

func initialize(dir: Vector3, dmg: int, target: Node3D = null):
	exploded = false  # Reset on initialization
	print("DEBUG: Initializing bomb at " + str(global_position))
	
	# Get damage from GameParameters if available, otherwise use the provided value
	if GameManager.has_method("get") and GameManager.get("game_parameters") != null:
		damage = GameManager.game_parameters.get_bomb_damage() 
	else:
		damage = dmg
		
	print("DEBUG: Bomb initialized with damage: " + str(damage))
	start_pos = global_position
	
	# Look for any player or player boat in the scene
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		target_player = players[0]
		target_pos = target_player.global_position
		
		# Calculate horizontal distance and direction
		var delta = target_pos - start_pos
		var horizontal_distance = Vector2(delta.x, delta.z).length()
		
		# Calculate time based on distance (slower speed)
		arc_duration = clamp(sqrt(horizontal_distance / 15.0), min_arc_duration, max_arc_duration)
		
		# Calculate horizontal velocity (constant speed towards target)
		delta.y = 0
		v_horizontal = delta / arc_duration
		
		# Calculate vertical velocity using projectile motion equations
		# For a projectile to hit a target:
		# y = y0 + v0y*t - (1/2)*g*t^2
		# where y is target height, y0 is start height, t is time
		
		var height_diff = target_pos.y - start_pos.y
		
		# Calculate vertical velocity needed to reach target
		# v0y = (y - y0 + (1/2)*g*t^2) / t
		var base_velocity = (height_diff + (0.5 * bomb_gravity * arc_duration * arc_duration)) / arc_duration
		
		# Add extra velocity to reach desired arc height at midpoint
		var mid_time = arc_duration * 0.5
		var extra_velocity = (2.0 * arc_height) / mid_time
		
		v_vertical = base_velocity + extra_velocity * 0.75  # Increased multiplier for higher arc
		
		initialized = true
		print("DEBUG: Bomb initialized with corrected trajectory:")
		print("DEBUG: - Start position: ", start_pos)
		print("DEBUG: - Target position: ", target_pos)
		print("DEBUG: - Height difference: ", height_diff)
		print("DEBUG: - Horizontal distance: ", horizontal_distance)
		print("DEBUG: - Flight time: ", arc_duration)
		print("DEBUG: - Base vertical velocity: ", base_velocity)
		print("DEBUG: - Final vertical velocity: ", v_vertical)
		print("DEBUG: - Horizontal velocity: ", v_horizontal)
	else:
		print("DEBUG: NO PLAYER FOUND!")
		queue_free()
		return

func _physics_process(delta):
	if not initialized:
		return
	
	age += delta
	time_passed += delta
	
	# Calculate new position using projectile motion equations
	var new_pos = start_pos
	
	# Horizontal motion (constant velocity)
	new_pos += v_horizontal * time_passed
	
	# Vertical motion (parabolic arc)
	new_pos.y = start_pos.y + (v_vertical * time_passed) - (0.5 * bomb_gravity * time_passed * time_passed)
	
	# Update bomb position
	global_position = new_pos
	
	# Orient bomb to face direction of travel
	var velocity = Vector3(v_horizontal.x, v_vertical - (bomb_gravity * time_passed), v_horizontal.z)
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized(), Vector3.UP)
		rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Debug position occasionally
	if Engine.get_physics_frames() % 30 == 0:
		print("DEBUG: Bomb position - Height: ", new_pos.y, ", Distance to target: ", 
			  global_position.distance_to(target_pos))
	
	# Only explode if we hit water or reached target position
	if new_pos.y <= sea_level:
		print("DEBUG: Bomb hit water")
		explode()

func handle_impact():
	# Only handle actual collisions with player
	if target_player != null and is_instance_valid(target_player):
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player < 15.0:  # Greatly increased collision radius for easier hits
			if target_player.has_method("take_damage"):
				target_player.take_damage(damage)
				print("DEBUG: DAMAGE APPLIED - Direct hit!")
				explode()
				
func _on_area_entered(area):
	# Increased hitbox detection at this point
	if area.is_in_group("Player") and age > 0.5:
		print("DEBUG: Direct collision with player!")
		if area.has_method("take_damage") and not exploded:
			exploded = true
			print("DEBUG: Applying damage to player: ", damage)
			area.take_damage(damage)
			explode()
	elif area.is_in_group("player_boat") and age > 0.5:
		print("DEBUG: Direct collision with player boat!")
		if area.has_method("take_damage") and not exploded:
			exploded = true
			print("DEBUG: Applying damage to player boat: ", damage)
			area.take_damage(damage)
			explode()
	elif area.is_in_group("Bullet") and age > 0.5:
		print("DEBUG: Bomb hit by bullet - exploding!")
		# Make sure bomb explodes when hit by bullet
		exploded = true  # Mark as exploded to prevent multiple explosions
		explode()

func explode():
	exploded = true
	print("DEBUG: Bomb exploded at " + str(global_position))
	create_explosion_effect()
	queue_free()

func create_explosion_effect():
	var explosion = Node3D.new()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	for i in range(10):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = randf_range(0.1, 0.3)
		sphere.height = sphere.radius * 2
		particle.mesh = sphere
		
		var material = StandardMaterial3D.new()
		var r = randf_range(0.8, 1.0)
		var g = randf_range(0.2, 0.6)
		var b = randf_range(0.0, 0.1)
		
		material.albedo_color = Color(r, g, b)
		material.emission_enabled = true
		material.emission = Color(r, g, b)
		material.emission_energy = 5.0
		sphere.material = material
		
		var angle = randf() * TAU
		var radius = randf() * 2.0
		var pos = Vector3(cos(angle) * radius, randf_range(-0.5, 2.0), sin(angle) * radius)
		particle.position = pos
		
		explosion.add_child(particle)
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.autostart = true
	explosion.add_child(timer)
	timer.timeout.connect(func(): explosion.queue_free())
