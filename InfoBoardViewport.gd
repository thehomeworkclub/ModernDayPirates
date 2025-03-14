extends MeshInstance3D

# Heart textures - load these at ready time to avoid null references
var full_heart_texture
var empty_heart_texture

# Heart display settings
@export var heart_spacing = 0.7
@export var heart_size = 0.08
@export var hover_height = 1.0
@export var z_offset = 0.1

# Health tracking
var health_sprites = []

# Simple direct HUD variables
var canvas_layer
var hud_container
var hud_hearts = []

func _ready():
	# Set name for easier reference
	name = "InfoBoard"
	add_to_group("InfoBoard")
	
	# Load textures directly instead of preloading
	full_heart_texture = load("res://art/fullheart.png")
	empty_heart_texture = load("res://art/emptyheart.png")
	
	print("DEBUG: InfoBoard ready on mesh at position: ", global_position)
	print("DEBUG: InfoBoard rotation: ", global_rotation_degrees)
	print("DEBUG: InfoBoard scale: ", scale)
	
	# Make sure textures loaded properly
	if full_heart_texture == null:
		print("ERROR: Could not load full heart texture")
	if empty_heart_texture == null:
		print("ERROR: Could not load empty heart texture")
		
	# Create health display with a slight delay to make sure everything is initialized
	await get_tree().create_timer(0.5).timeout
	
	# Create a simple 2D HUD that will definitely work
	create_simple_hud()
	
	# Initial health display
	display_health(5, 10)

func create_simple_hud():
	print("DEBUG: Creating simple HUD")
	
	# Safety check
	if self == null:
		print("ERROR: InfoBoard is null when creating HUD")
		return
		
	# Create a canvas layer for UI
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "HealthHUD"
	if self != null:
		add_child(canvas_layer)
	
	# Create container for hearts
	hud_container = HBoxContainer.new()
	hud_container.name = "HeartContainer"
	hud_container.position = Vector2(20, 20)
	
	if canvas_layer != null:
		canvas_layer.add_child(hud_container)
		print("DEBUG: HUD container added to canvas layer")
	else:
		print("ERROR: Canvas layer is null")
		
	print("DEBUG: Simple HUD created")

# Update hearts in the HUD
func update_hud_hearts(current_health: int, max_health: int):
	if hud_container == null:
		print("ERROR: HUD container is null when updating hearts")
		return
		
	# Clear existing hearts
	for heart in hud_hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	hud_hearts.clear()
	
	# Make sure textures are loaded
	if full_heart_texture == null or empty_heart_texture == null:
		print("ERROR: Heart textures not loaded when updating HUD")
		return
	
	# Create heart textures
	for i in range(max_health):
		var texture_rect = TextureRect.new()
		texture_rect.name = "HUDHeart_" + str(i)
		
		# Choose texture based on health
		if i < current_health:
			texture_rect.texture = full_heart_texture
		else:
			texture_rect.texture = empty_heart_texture
			
		# Configure appearance
		texture_rect.custom_minimum_size = Vector2(32, 32)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Add to container
		if hud_container != null:
			hud_container.add_child(texture_rect)
			hud_hearts.append(texture_rect)
	
	print("DEBUG: Updated HUD hearts: ", current_health, "/", max_health)

# Display health with 3D sprites hovering above the mesh
func display_health(current_health: int, max_health: int):
	print("DEBUG: InfoBoard updating health display: ", current_health, "/", max_health)
	
	# Update HUD as well
	update_hud_hearts(current_health, max_health)
	
	# Creating 3D sprites that hover above the mesh
	# First clear existing hearts
	print("DEBUG: Clearing existing heart sprites")
	for sprite in health_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	health_sprites.clear()
	
	# Safety check
	if full_heart_texture == null or empty_heart_texture == null:
		print("ERROR: Heart textures not loaded")
		return
		
	if self == null:
		print("ERROR: InfoBoard is null when creating 3D hearts")
		return
	
	# Get mesh dimensions if possible
	var mesh_aabb = get_aabb()
	print("DEBUG: Mesh AABB size: ", mesh_aabb.size)
	
	# Calculate start position (centered on mesh width)
	var start_x = -2.0
	print("DEBUG: Starting X position for hearts: ", start_x)
	
	# Create heart sprites
	for i in range(max_health):
		var sprite = Sprite3D.new()
		sprite.name = "Heart_" + str(i)
		
		# Set correct texture
		if i < current_health:
			sprite.texture = full_heart_texture
			print("DEBUG: Creating full heart at index ", i)
		else:
			sprite.texture = empty_heart_texture
			print("DEBUG: Creating empty heart at index ", i)
			
		# Position sprite ABOVE the mesh
		var x_pos = start_x + (heart_spacing * i)
		sprite.position = Vector3(x_pos, hover_height, z_offset)
		
		# Configure appearance for maximum visibility
		sprite.pixel_size = heart_size
		sprite.billboard = true  # Always face camera
		sprite.no_depth_test = true  # Show through objects
		sprite.modulate = Color(1, 1, 1, 1)  # Full opacity
		
		# Debug info about this sprite
		print("DEBUG: Heart ", i, " position (local): ", sprite.position)
		
		# Add sprite to the mesh
		if self != null:
			add_child(sprite)
			health_sprites.append(sprite)
		
		# Get world position for debugging
		await get_tree().process_frame
		print("DEBUG: Heart ", i, " position (global): ", sprite.global_position)
	
	print("DEBUG: Created ", health_sprites.size(), " heart sprites")

# Called by player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: InfoBoard received health change: ", current_health, "/", max_health)
	display_health(current_health, max_health)
	
func _process(delta):
	# Make sprites more visible in game view
	for i in range(health_sprites.size()):
		var sprite = health_sprites[i]
		if is_instance_valid(sprite):
			# Add slight rotation to make sprites more noticeable
			sprite.rotate_y(delta * 0.5)
