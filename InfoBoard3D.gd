extends MeshInstance3D

# Health icons array
var health_sprites = []

# Heart textures
@onready var full_heart_texture = preload("res://art/fullheart.png")
@onready var empty_heart_texture = preload("res://art/emptyheart.png")

# Heart display settings
@export var heart_spacing = 0.7  # Horizontal spacing between hearts
@export var heart_size = 0.03   # Size of heart sprites - much larger for visibility
@export var y_position = 0.5    # Vertical position on mesh
@export var z_offset = -0.05    # Slightly in front of mesh surface

func _ready():
	# Set unique name for easier reference
	name = "InfoBoard"
	add_to_group("InfoBoard")
	print("DEBUG: InfoBoard3D ready on mesh. Transform: ", global_transform)
	
	# Force the mesh to be visible
	visible = true
	
	# Display test hearts initially with a delay (after mesh is fully initialized)
	await get_tree().create_timer(1.0).timeout
	display_health(5, 10)
	
func _process(delta):
	# Make sure the sprites are always visible
	for sprite in health_sprites:
		if is_instance_valid(sprite):
			# Ensure sprite faces the camera
			var cam = get_viewport().get_camera_3d()
			if cam:
				sprite.global_transform = sprite.global_transform.looking_at(cam.global_position, Vector3.UP)

# Display health with appropriate number of hearts
func display_health(current_health: int, max_health: int):
	print("DEBUG: InfoBoard3D updating health display: ", current_health, "/", max_health)
	
	# Clear existing hearts
	for sprite in health_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	health_sprites.clear()
	
	# Calculate total width needed for hearts
	var total_width = heart_spacing * max_health
	
	# Print information about mesh to help with debugging
	print("DEBUG: InfoBoard global position: ", global_position)
	print("DEBUG: InfoBoard global rotation: ", global_rotation_degrees)
	print("DEBUG: InfoBoard scale: ", scale)
	
	# Calculate start position (centered on mesh width)
	var start_x = -2.5  # Starting position further left
	
	# Create heart sprites
	for i in range(max_health):
		var sprite = Sprite3D.new()
		sprite.name = "Heart_" + str(i)
		
		# Set texture based on current health
		if i < current_health:
			sprite.texture = full_heart_texture
		else:
			sprite.texture = empty_heart_texture
		
		# Position sprite relative to the mesh
		var x_pos = start_x + (heart_spacing * i)
		sprite.position = Vector3(x_pos, y_position, z_offset)
		
		# Configure appearance for maximum visibility
		sprite.pixel_size = heart_size
		sprite.billboard = true  # Always face camera
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.modulate = Color(1, 1, 1, 1)  # Full brightness, no transparency
		sprite.no_depth_test = true  # Ensure visibility through other objects
		
		# Make sprite much larger for visibility
		sprite.scale = Vector3(1.5, 1.5, 1.5)
		
		# Add sprite to mesh
		add_child(sprite)
		health_sprites.append(sprite)
		
		print("DEBUG: Created heart at local position: ", sprite.position)
	
	print("DEBUG: Created ", health_sprites.size(), " heart sprites on 3D board")

# Called by player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: InfoBoard3D received health change: ", current_health, "/", max_health)
	display_health(current_health, max_health)
