extends Area3D

@export var base_health: int = 10
@export var barrier_distance: float = 20.0  # Distance where enemies stop
var max_health: int = 10  # Fixed max health at 10
var health: int = 10      # Starting health at 10
var enemies_in_range: int = 0
var damage_timer: float = 0.0
var health_display: Label

func _ready() -> void:
	add_to_group("Player")
	add_to_group("player_boat")  # Add to player_boat group for health display syncing
	
	# Set fixed health values (ignoring bonuses/multipliers)
	max_health = 10  # Force max health to exactly 10
	health = 10      # Start with full health
	
	print("DEBUG: Player health initialized at ", health, "/", max_health)
	
	monitoring = true
	monitorable = true
	collision_layer = 1  # Player layer
	collision_mask = 12  # Enemy (4) and Bomb (8) layers
	
	# CRITICAL: Create a larger collision box around the boat for bomb detection
	#create_damage_box()
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Create health display
	create_health_display()
	
	# Debug collision info
	print("DEBUG: Boat collision shape set up, layer: ", collision_layer, ", mask: ", collision_mask)

## Create a larger collision box around the boat to detect bombs more reliably
#func create_damage_box() -> void:
	## Check if we already have a collision shape
	#var existing_shape = get_node_or_null("CollisionShape3D")
	#
	## If we don't have one, create a new one
	#if not existing_shape:
		#existing_shape = CollisionShape3D.new()
		#existing_shape.name = "CollisionShape3D"
		#add_child(existing_shape)
	#
	## Create a larger box shape
	#var box_shape = BoxShape3D.new()
	#box_shape.size = Vector3(8.0, 5.0, 10.0)  # Much larger box for better bomb detection
	#
	## Apply the shape
	#existing_shape.shape = box_shape
	#
	## Optional visual representation of the box (for debugging)
	#var debug_mesh = MeshInstance3D.new()
	#debug_mesh.name = "DebugCollisionBox"
	#debug_mesh.mesh = BoxMesh.new()
	#debug_mesh.mesh.size = box_shape.size
	#
	## Make it semi-transparent
	#var material = StandardMaterial3D.new()
	#material.albedo_color = Color(1.0, 0.0, 0.0, 0.3)  # Semi-transparent red
	#material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#debug_mesh.mesh.material = material
	#
	## Position slightly above the boat for visibility
	#debug_mesh.position = Vector3(0, 0.5, 0)
	#
	## Only show in debug builds
	#if OS.is_debug_build():
		#add_child(debug_mesh)
		#print("DEBUG: Added visual debug collision box")
	#
	#print("DEBUG: Created larger damage box for bomb detection with size: ", box_shape.size)

func create_health_display() -> void:
	# Create a simple health label
	health_display = Label.new()
	health_display.text = "Health: " + str(health) + "/" + str(max_health)
	health_display.position = Vector2(20, 20)
	health_display.add_theme_color_override("font_color", Color(1, 0, 0))
	
	# Get the camera if it exists
	var camera = get_viewport().get_camera_3d()
	
	# Add to viewport (UI layer)
	get_tree().root.add_child(health_display)
	
	# Update the display
	update_health_display()

func update_health_display() -> void:
	if health_display:
		health_display.text = "Health: " + str(health) + "/" + str(max_health)
		
		# Color-code based on health percentage
		var health_percent = float(health) / float(max_health)
		if health_percent < 0.3:
			health_display.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		elif health_percent < 0.7:
			health_display.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
			health_display.add_theme_color_override("font_color", Color(0, 1, 0))  # Green

func _physics_process(delta: float) -> void:
	# Handle enemy damage over time
	if enemies_in_range > 0:
		damage_timer += delta
		if damage_timer >= 2.0:  # Changed to 2 seconds as per requirements
			take_damage(1)
			damage_timer = 0.0
	
	# Enforce enemy barrier - find all enemies and check their distance
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		var distance = enemy.global_position.distance_to(global_position)
		var z_distance = global_position.z - enemy.global_position.z
		
		# Check if enemy is too close
		if distance < barrier_distance || z_distance > -8.0:
			# Force enemy to stop by setting at_barrier flag
			enemy.at_barrier = true
			
			# Debug when enemy hits barrier
			if Engine.get_physics_frames() % 300 == 0:
				print("DEBUG: Forcing enemy to stop at barrier, distance: ", distance, ", z-distance: ", z_distance)

func take_damage(amount: int) -> void:
	health -= amount
	
	# Ensure health never goes below 0
	if health < 0:
		health = 0
	
	update_health_display()
	
	print("DEBUG: Player took ", amount, " damage, health now: ", health)
	
	# Check if player is dead
	if health <= 0:
		print("DEBUG: Player health reached 0, showing game over screen")
		show_game_over_screen()
	
	# DIRECT HEALTH DISPLAY UPDATE - Force update XROrigin controllers
	force_health_update()
	
	# Update the gun health display if it exists - CRITICAL SECTION
	var xr_origin = get_tree().get_first_node_in_group("Player")
	if xr_origin:
		var vr_gun_controller = xr_origin.get_node_or_null("VRGunController")
		if vr_gun_controller:
			if vr_gun_controller.has_method("get") and vr_gun_controller.get("health_display"):
				print("DEBUG: Updating gun health display to match boat health: ", health)
				vr_gun_controller.health_display.current_health = health
				vr_gun_controller.health_display.update_hearts()
			else:
				print("DEBUG: VRGunController found but health_display is null")
		else:
			print("DEBUG: XROrigin found but VRGunController not found")
	else:
		print("DEBUG: No Player group node found")
		
	# DIRECT TEST - Enable key-based testing for quick heart updates
	if Input.is_key_pressed(KEY_F1):
		force_health_update()
		
# Manual testing function to update the gun hearts display
func force_health_update() -> void:
	print("DEBUG: Force updating health display - DIRECT SCENE SEARCH METHOD")
	
	# SEARCH EVERYWHERE FOR HEALTHDISPLAY
	var origin_nodes = get_tree().get_nodes_in_group("Player")
	print("DEBUG: Found ", origin_nodes.size(), " player nodes")
	
	# First try - XROrigin/VRGunController path
	for origin in origin_nodes:
		print("DEBUG: Checking player node: ", origin.name, " (type: ", origin.get_class(), ")")
		
		# APPROACH 1: Direct known path
		for child in origin.get_children():
			print("DEBUG: Found child: ", child.name)
			if "GunController" in child.name:
				print("DEBUG: Found controller: ", child.name)
				var gun_controller = child
				
				if gun_controller.has_method("get") and gun_controller.get("health_display") != null:
					print("DEBUG: Found health_display via property!")
					gun_controller.health_display.current_health = health
					gun_controller.health_display.update_hearts()
					return
					
				for gun_child in gun_controller.get_children():
					print("DEBUG: Checking gun controller child: ", gun_child.name)
					if gun_child.name == "GunInstance":
						for instance_child in gun_child.get_children():
							if instance_child.name == "HealthDisplay":
								print("DEBUG: FOUND HEALTH DISPLAY VIA DEEP PATH!")
								instance_child.current_health = health
								instance_child.update_hearts()
								return
	
	# APPROACH 2: Recursive search through entire scene
	print("DEBUG: Trying recursive health display search...")
	var found_displays = []
	_find_health_displays(get_tree().current_scene, found_displays)
	
	for display in found_displays:
		print("DEBUG: Found health display: ", display.get_path())
		display.current_health = health
		display.update_hearts()
		return

# Helper to recursively find health displays
func _find_health_displays(node: Node, result: Array) -> void:
	if node.get_script() and node.get_script().resource_path == "res://GunHealthDisplay.gd":
		print("DEBUG: Found health display via script path at: ", node.get_path())
		result.append(node)
		
	if node.name == "HealthDisplay" and node.has_method("update_hearts"):
		print("DEBUG: Found health display via name at: ", node.get_path())
		result.append(node)
		
	for child in node.get_children():
		_find_health_displays(child, result)

# Show the game over screen
func show_game_over_screen() -> void:
	# Pause the game
	get_tree().paused = true
	
	# Create and show the GameOverMenu
	var game_over_scene = load("res://GameOverMenu.tscn")
	if game_over_scene:
		var game_over_instance = game_over_scene.instantiate()
		# Add to the main viewport rather than as a child of this node
		get_tree().root.add_child(game_over_instance)
		print("DEBUG: Game over screen displayed")
	else:
		print("ERROR: Could not load GameOverMenu.tscn")
		
	# Ensure GameManager is reset to round 1
	if GameManager:
		GameManager.current_round = 1
		print("DEBUG: GameManager reset to round 1")

func heal(amount: float) -> void:
	var heal_amount = int(amount)
	health = min(health + heal_amount, max_health)
	update_health_display()

func upgrade_max_health(bonus: float) -> void:
	# Get max_health_bonus if it exists
	var health_bonus = 0.0
	if GameManager.has_method("get") and GameManager.get("max_health_bonus") != null:
		health_bonus = GameManager.max_health_bonus
	
	# Get max_health_multiplier if it exists
	var health_multiplier = 1.0
	if Engine.has_singleton("CurrencyManager"):
		var currency_manager = Engine.get_singleton("CurrencyManager")
		if currency_manager.has_method("get") and currency_manager.get("max_health_multiplier") != null:
			health_multiplier = currency_manager.max_health_multiplier
	
	max_health = int(base_health * (1.0 + health_bonus + bonus) * health_multiplier)
	# Also heal when max health increases
	health += int(base_health * bonus * health_multiplier)
	health = min(health, max_health)
	update_health_display()

func _on_area_entered(area: Area3D) -> void:
	print("DEBUG: Boat detected collision with: ", area.name, ", groups: ", area.get_groups())
	
	if area.is_in_group("Enemy"):
		enemies_in_range += 1
		print("DEBUG: Enemy entered range, count: ", enemies_in_range)
	elif area.is_in_group("EnemyBomb"):
		# ULTRA-RELIABLE BOMB DETECTION - Large collision box ensures this will trigger
		print("DEBUG: 💥 BOMB HIT BOAT DIRECTLY! 💥")
		
		# Use GameParameters damage value instead of hardcoded
		var bomb_damage = 2  # Default base damage
		
		# Try to get bomb damage from the area first
		if area.has_method("get_damage"):
			bomb_damage = area.get_damage()
		elif area.get("damage") != null:
			bomb_damage = area.get("damage")
		
		# As fallback, try to get from GameParameters
		if GameManager.has_method("get") and GameManager.get("game_parameters") != null:
			bomb_damage = GameManager.game_parameters.get_bomb_damage()
		
		# Apply damage directly
		take_damage(bomb_damage)
		print("DEBUG: 💥 HEALTH REDUCED by ", bomb_damage, " from bomb hit! 💥")
		
		# Then trigger explosion
		if area.has_method("explode"):
			area.explode()
		else:
			# If no explode method, destroy the bomb anyway
			area.queue_free()

func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		enemies_in_range -= 1
