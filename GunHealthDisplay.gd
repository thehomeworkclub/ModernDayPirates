extends Node3D

# Health settings
var max_health = 10
var current_health = 10

# Heart textures
var full_heart_texture = preload("res://art/fullheart.png")
var empty_heart_texture = preload("res://art/emptyheart.png")

# Display properties
var heart_spacing = 0.05  # Space between hearts
var heart_scale = 0.05    # Size of each heart sprite
var heart_sprites = []

func _ready():
	# Create hearts
	create_hearts()
	
	# Create a damage cooldown timer
	var timer = Timer.new()
	timer.name = "DamageTimer"
	timer.wait_time = 0.3
	timer.one_shot = true
	add_child(timer)
	
	# Sync with boat health on startup
	call_deferred("sync_with_boat_health")
	
	# Add a direct test keyboard handler
	set_process_input(true)

func _input(event):
	# Add keyboard shortcuts for testing
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			take_damage(1)
			print("DEBUG: Manual damage test triggered - current health: " + str(current_health))
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			heal(1)
			print("DEBUG: Manual healing test triggered - current health: " + str(current_health))

func sync_with_boat_health():
	# Wait a frame to ensure all nodes are loaded
	await get_tree().process_frame
	
	# Find the player boat and sync health
	var boat = get_tree().get_first_node_in_group("player_boat")
	if boat and boat.has_method("get") and boat.get("health") != null:
		current_health = boat.health
		max_health = boat.max_health
		print("DEBUG: Gun health display synced with boat: " + str(current_health) + "/" + str(max_health))
		update_hearts()
	else:
		print("DEBUG: Failed to sync with boat health - boat not found or missing health property")

func _process(delta):
	# Check for damage input (key 9)
	if Input.is_key_pressed(KEY_9):
		# Add a small delay to prevent multiple hits in one press
		if $DamageTimer.is_stopped():
			take_damage(1)
			$DamageTimer.start()

func create_hearts():
	# Remove any existing hearts
	for heart in heart_sprites:
		if is_instance_valid(heart):
			heart.queue_free()
	
	heart_sprites = []
	
	# Create hearts container to position them correctly
	var container = Node3D.new()
	container.name = "HeartsContainer"
	
	# Position on the left side of gun
	container.transform.origin = Vector3(-0.1, 0.05, -0.18)
	# Rotate to face outward from gun (left side, so rotate -90 degrees)
	container.rotation_degrees = Vector3(0, -90, 0)
	
	add_child(container)
	
	# Create hearts in a horizontal arrangement
	for i in range(max_health):
		var heart = Sprite3D.new()
		heart.texture = full_heart_texture
		heart.pixel_size = 0.0007  # Slightly larger for better visibility
		
		# Position hearts in a horizontal line
		# Start with hearts to the left so they don't go too far to the right
		heart.transform.origin.x = (-max_health/2.0 + i) * heart_spacing * 0.8
		
		# Make sure hearts are visible and well-lit
		heart.shaded = false
		heart.double_sided = true
		heart.no_depth_test = false  # We want depth testing for 3D
		heart.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # No billboard to stay fixed to gun
		
		container.add_child(heart)
		heart_sprites.append(heart)
	
	update_hearts()
	print("DEBUG: Created " + str(heart_sprites.size()) + " heart sprites")

func take_damage(amount):
	current_health = max(0, current_health - amount)
	update_hearts()
	print("DEBUG: GunHealthDisplay - Player took damage! Health: " + str(current_health) + "/" + str(max_health))
	
	# Check for death
	if current_health <= 0:
		print("DEBUG: GunHealthDisplay - Player died!")
		# For testing, reset health after death
		await get_tree().create_timer(1.0).timeout
		heal(max_health)

func heal(amount):
	current_health = min(max_health, current_health + amount)
	update_hearts()
	print("DEBUG: GunHealthDisplay - Player healed! Health: " + str(current_health) + "/" + str(max_health))

func update_hearts():
	# Print debug to confirm this function is called
	print("DEBUG: Updating heart display: " + str(current_health) + "/" + str(max_health) + " hearts")
	
	# Update the heart textures based on current health
	for i in range(heart_sprites.size()):
		if is_instance_valid(heart_sprites[i]):
			if i < current_health:
				heart_sprites[i].texture = full_heart_texture
			else:
				heart_sprites[i].texture = empty_heart_texture
