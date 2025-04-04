extends Area3D

@export var base_health: int = 10
@export var barrier_distance: float = 20.0  # Distance where enemies stop
var max_health: int
var health: int
var enemies_in_range: int = 0
var damage_timer: float = 0.0
var health_display: Label

func _ready() -> void:
	add_to_group("Player")
	add_to_group("player_boat")  # Add to player_boat group for health display syncing
	
	# Calculate max health with any permanent upgrades
	# Check if GameManager has max_health_bonus property
	var health_bonus = 0.0
	if GameManager.has_method("get") and GameManager.get("max_health_bonus") != null:
		health_bonus = GameManager.max_health_bonus
	
	# Check if CurrencyManager exists and has the multiplier property
	var health_multiplier = 1.0
	if Engine.has_singleton("CurrencyManager"):
		var currency_manager = Engine.get_singleton("CurrencyManager")
		if currency_manager.has_method("get") and currency_manager.get("max_health_multiplier") != null:
			health_multiplier = currency_manager.max_health_multiplier
	
	max_health = int(base_health * (1.0 + health_bonus) * health_multiplier)
	health = max_health
	
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
	update_health_display()
	
	print("DEBUG: Player took " + str(amount) + " damage, health now: " + str(health))
	
	# Update the gun health display if it exists
	var xr_origin = get_tree().get_first_node_in_group("Player")
	if xr_origin:
		var vr_gun_controller = xr_origin.get_node_or_null("VRGunController")
		if vr_gun_controller and vr_gun_controller.health_display:
			print("DEBUG: Updating gun health display to match boat health: " + str(health))
			vr_gun_controller.health_display.current_health = health
			vr_gun_controller.health_display.update_hearts()
	
	if health <= 0:
		# Game over!
		health = 0
		get_tree().paused = true
		
		# Create a simple red overlay that fades in
		var overlay = ColorRect.new()
		overlay.name = "GameOverOverlay"
		overlay.color = Color(1, 0, 0, 0) # Start transparent red
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		
		# Add to the UI layer
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100 # Make sure it's above everything
		get_tree().current_scene.add_child(canvas_layer)
		canvas_layer.add_child(overlay)
		
		# Create a fade animation
		var tween = get_tree().create_tween()
		tween.tween_property(overlay, "color:a", 1.0, 2.0)
		
		# Return to campaign menu after fade
		await get_tree().create_timer(2.0).timeout
		get_tree().paused = false
		get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

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
		
		# Get bomb damage if available or use higher default damage
		var bomb_damage = 15  # Higher default damage
		if area.has_method("get_damage"):
			bomb_damage = area.get_damage()
		elif area.get("damage") != null:
			bomb_damage = area.get("damage")
		
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
