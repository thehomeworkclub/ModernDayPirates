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
	
	# Calculate max health with any permanent upgrades
	max_health = int(base_health * (1.0 + GameManager.max_health_bonus) * CurrencyManager.max_health_multiplier)
	health = max_health
	
	monitoring = true
	monitorable = true
	collision_layer = 1  # Player layer
	collision_mask = 12  # Enemy (4) and Bomb (8) layers
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Create health display
	create_health_display()
	
	# Debug collision info
	print("DEBUG: Boat collision shape set up, layer: ", collision_layer, ", mask: ", collision_mask)

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
	
	if health <= 0:
		# Game over!
		health = 0
		get_tree().paused = true
		
		# Show game over UI
		var game_over_scene = load("res://GameOverMenu.tscn")
		if game_over_scene:
			var game_over_instance = game_over_scene.instantiate()
			
			# Connect the retry button to return to 3D campaign menu
			if game_over_instance.has_node("RetryButton"):
				game_over_instance.get_node("RetryButton").pressed.connect(func(): 
					get_tree().paused = false
					get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")
				)
				
			get_tree().current_scene.add_child(game_over_instance)
		else:
			# Fallback if game over scene doesn't exist yet - go directly to 3D menu
			get_tree().paused = false
			get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")

func heal(amount: float) -> void:
	var heal_amount = int(amount)
	health = min(health + heal_amount, max_health)
	update_health_display()

func upgrade_max_health(bonus: float) -> void:
	max_health = int(base_health * (1.0 + GameManager.max_health_bonus + bonus) * CurrencyManager.max_health_multiplier)
	# Also heal when max health increases
	health += int(base_health * bonus * CurrencyManager.max_health_multiplier)
	health = min(health, max_health)
	update_health_display()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		enemies_in_range += 1
	elif area.is_in_group("EnemyBomb"):
		# Handle bomb collision
		if area.has_method("explode"):
			area.explode(true)  # Explode and damage player

func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		enemies_in_range -= 1
