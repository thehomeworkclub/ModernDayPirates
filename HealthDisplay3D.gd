extends Node3D

# Health tracking
var current_health = 5
var max_health = 10

# Heart sprites
var heart_sprites = []

# Heart textures
var full_heart_texture
var empty_heart_texture

# Display settings
@export var heart_spacing = 0.4
@export var heart_size = 0.05
@export var world_position = Vector3(5, 2, -15)  # Position in the 3D world

func _ready():
	# Set name and group for easy reference
	name = "HealthDisplay3D"
	add_to_group("InfoBoard")  # Use same group for compatibility
	
	# Load textures
	full_heart_texture = load("res://art/fullheart.png")
	empty_heart_texture = load("res://art/emptyheart.png")
	
	# Position this node in the world
	global_position = world_position
	
	# Debug info
	print("DEBUG: HealthDisplay3D positioned at ", global_position)
	
	# Initial health display
	create_hearts(current_health, max_health)

func create_hearts(current_health: int, max_health: int):
	# Clear any existing hearts
	for sprite in heart_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	heart_sprites.clear()
	
	# Calculate starting position (centered)
	var total_width = heart_spacing * (max_health - 1)
	var start_x = -total_width / 2
	
	# Create heart sprites
	for i in range(max_health):
		var sprite = Sprite3D.new()
		sprite.name = "Heart_" + str(i)
		
		# Set texture based on health
		if i < current_health:
			sprite.texture = full_heart_texture
		else:
			sprite.texture = empty_heart_texture
		
		# Position heart
		var x_pos = start_x + (heart_spacing * i)
		sprite.position = Vector3(x_pos, 0, 0)
		
		# Configure appearance
		sprite.pixel_size = heart_size
		sprite.billboard = true  # Always face camera
		sprite.no_depth_test = true  # Ensure visibility through objects
		
		# Make it bright and visible
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(1, 1, 1, 1)
		material.emission_energy_multiplier = 1.5
		material.flags_unshaded = true
		sprite.material_override = material
		
		# Add to scene
		add_child(sprite)
		heart_sprites.append(sprite)
		
		print("DEBUG: Created heart at position ", sprite.global_position)
	
	print("DEBUG: Created ", heart_sprites.size(), " hearts in 3D space")

# Called by player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: HealthDisplay3D received health update: ", current_health, "/", max_health)
	self.current_health = current_health
	self.max_health = max_health
	create_hearts(current_health, max_health)

func _process(delta):
	# Make sure hearts always face the camera
	var cam = get_viewport().get_camera_3d()
	if cam:
		# Rotate the entire display to face the camera, but only on Y axis
		var direction = cam.global_position - global_position
		direction.y = 0  # Keep upright
		if direction.length() > 0.01:
			look_at(global_position + direction, Vector3.UP)
